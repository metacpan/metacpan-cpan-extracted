package Mail::Colander::Server;
use v5.24;
use warnings;
use experimental qw< signatures >;
{ our $VERSION = '0.004' }

use constant DEFAULT_CHAIN => 'DEFAULT';

use Ouch qw< :trytiny_var >;
use Try::Catch;
use Scalar::Util qw< blessed >;
use Log::Any qw< $log >;
use Mail::Colander::Session;
use Mail::Colander::Server::Util qw< xxd_message >;
use Data::Annotation::Overlay;
use IO::Handle;
use Module::Runtime qw< require_module >;
use Net::Server::Mail::ESMTP;
use JSON::PP ();

use Exporter qw< import >;
our @EXPORT_OK = qw<
   mojo_ioloop_server_callback_factory
>;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub _encode_json_pretty ($data) {
   state $encoder = JSON::PP->new->ascii->canonical->pretty;
   return $encoder->encode($data);
}

sub _require_class_module ($module) {
   require_module($module) unless $module->can('new');
   return $module;
}

sub _resolve ($in, $class) {
   return blessed($in) ? $in : _require_class_module($class)->new($in);
}

sub _argslist ($in) {
   ref($in) eq 'ARRAY' ? $in->@* : defined($in) ? $in->%* : ()
}

sub _sieve_call ($sieve, $command, $overlay) {
   my $outcome = try {
      my ($out, $data, $call_sequence)
         = $sieve->policy_for($command, $overlay);

      if ($log->is_debug && $call_sequence && $call_sequence->@*) {
         my $calls = join "\n", map { '  ' . $_->{chain} } $call_sequence->@*;
         $log->debug(
            join ' ', 
            "Colander check $command:",
            (
               join ' -> ',
                  map {
                     my ($chain, $rule) = $_->@{qw< chain rule >};
                     length($rule) ? "$chain $rule" : $chain;
                  } $call_sequence->@*
            ),
            '=> ' . $call_sequence->[-1]{outcome}
         );
      }
      $log->trace(_encode_json_pretty($call_sequence))
         if $log->is_trace;

      $out eq 'accept';
   }
   catch {
      my $e = $_;
      $log->error(_encode_json_pretty($e->data));
      undef;
   };
   return $outcome;
}

sub mojo_ioloop_server_callback_factory (%args) {
   _require_class_module(__PACKAGE__ . '::IOWrapper');

   my @extensions = map {
      m{\A /}mxs ? substr($_, 1) : 'Net::Server::Mail::ESMTP::' . $_
   } ($args{esmtp_extensions} // [])->@*;

   my %subargs = (
      sieve => _resolve($args{sieve}, 'Mail::Colander'),
      esmtp_args => [ _argslist($args{esmtp_args}) ],
      esmtp_extensions => \@extensions,
      callback_for => ($args{callback_for} // {}),
   );

   return sub ($loop, $stream, $id) {

      my $sh = $stream->handle;
      my ($ip, $port) = ($sh->peerhost, $sh->peerport);
      $log->debug("$id: connection from $ip:$port");

      # this is what will handle the SMTP exchange for us
      my ($banner, $reader) = _mios_smtp_factory($stream, %subargs);
      if (! defined($banner)) { # connection has not been accepted!
         $stream->close;
         return;
      }

      # "connect" the stream to input parsing
      $stream->on(close => sub ($stream) { $log->debug("$id: closed") });
      $stream->on(error => sub ($stream, $error) { ...  });
      $stream->on(
         read => sub ($stream, $bytes) {
            if ($log->is_trace) {
               my $n_bytes = length($bytes);
               $log->trace($_) for (
                  "$id: $n_bytes",
                  xxd_message($bytes, max_lines => -1),
               );
            }
            if ($log->is_debug) {
               my $n_bytes = length($bytes);
               $log->trace($_) for (
                  "$id: $n_bytes",
                  xxd_message($bytes, max_lines => 3),
               );
            }
            $stream->close if defined($reader->($bytes));
         }
      );
      $stream->on(timeout => sub ($strm) { $log->info("$id: timed out") });
      $stream->timeout($args{timeout} // 3);

      # setup complete, kick-start the ESMTP session
      $banner->();
   };
}

sub _mios_smtp_factory ($stream, %args) {

   # this is used to figure out whether something can be admitted or not
   my $sieve   = $args{sieve};

   # collect events inside a $session object that we can eventually
   # pass down to the $sieve
   my $sh = $stream->handle;
   my $session = Mail::Colander::Session->new(
      peer_ip   => $sh->peerhost,
      peer_port => $sh->peerport,
   );
   my $overlay = Data::Annotation::Overlay->new(
      under => $session,
      cache_existing => 0,
   );

   # first of all collect the peer IP address and figure out whether
   # it's worth bothering or not
   my $outcome = _sieve_call($sieve, connect => $overlay);
   if ($outcome) {
      $args{callback_for}{connect}->($session)
         if $args{callback_for}{connect};
   }
   else {
      $args{callback_for}{reject}->(connect => $session)
         if $args{callback_for}{reject};
      return;
   }

   # this wraps IO operations to make Net::Server::Mail::ESMTP happy
   # for interacting with IO::Handles and pass data around.
   my $iowrap = Mail::Colander::Server::IOWrapper->new(stream => $stream);

   my $smtp_in = Net::Server::Mail::ESMTP->new(

      # defaults
      error_sleep_time => 2,
      idle_timeout => 5,

      # whatever came in
      $args{esmtp_args}->@*,

      # overridden for sure
      handle_in  => IO::Handle->new,   # anything goes
      handle_out => $iowrap->ofh,

   ) or ouch 500, "can't start server";

   # register supported extensions
   $smtp_in->register($_) for $args{esmtp_extensions}->@*;

   my @cmds = qw< HELO EHLO MAIL RCPT DATA-INIT DATA-PART DATA QUIT >;
   for my $command (@cmds) {
      my $method  = $session->can($command =~ s{\W+}{_}rgmxs)
         or next; # no support, no party

      $smtp_in->set_callback(
         $command,
         sub {
            return unless eval { $session->$method(@_) };   # accumulate

            # call the $sieve if so instructed
            my $outcome = _sieve_call($sieve, $command, $overlay);
            if (! $outcome) {
               $args{callback_for}{reject}->($command, $session)
                  if $args{callback_for}{reject};
               $session->reset;
               return;
            }

            # if we are here we can hand over to the callbacks, if any,
            # or just return a true value.
            return 1 unless defined($args{callback_for}{$command});
            return $args{callback_for}{$command}->($session);
         }
      );
   }

   # return a pair of callbacks, one for sending out the banner and one
   # for processing data as they arrive.
   return (
      sub {
         my $rv = $smtp_in->banner;
         $iowrap->write_output;
         return $rv;
      },
      sub {
         my $rv = $smtp_in->process_once($iowrap->read_input($_[0]));
         $iowrap->write_output;
         return $rv;
      },
   );

}

1;
