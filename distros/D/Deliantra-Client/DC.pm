=head1 NAME

DC - undocumented utility garbage for our deliantra client

=head1 SYNOPSIS

 use DC;

=head1 DESCRIPTION

=over 4

=cut

package DC;

use Carp ();

our $VERSION;

BEGIN {
   $VERSION = '2.11';

   use XSLoader;
   XSLoader::load "Deliantra::Client", $VERSION;
}

use utf8;
use strict qw(vars subs);

use Socket ();
use AnyEvent ();
use AnyEvent::Util ();
use Pod::POM ();
use File::Path ();
use Storable (); # finally
use Fcntl ();
use JSON::XS qw(encode_json decode_json);
use Guard qw(guard);

=item shorten $string[, $maxlength]

=cut

sub shorten($;$) {
   my ($str, $len) = @_;
   substr $str, $len, (length $str), "..." if $len + 3 <= length $str;
   $str
}

sub asxml($) {
   local $_ = $_[0];

   s/&/&amp;/g;
   s/>/&gt;/g;
   s/</&lt;/g;

   $_
}

sub background(&;&) {
   my ($bg, $cb) = @_;

   my ($fh_r, $fh_w) = AnyEvent::Util::portable_socketpair
     or die "unable to create background socketpair: $!";

   my $pid = fork;

   if (defined $pid && !$pid) {
      local $SIG{__DIE__};

      open STDOUT, ">&", $fh_w;
      open STDERR, ">&", $fh_w;
      close $fh_r;
      close $fh_w;

      $| = 1;

      eval { $bg->() };

      if ($@) {
         my $msg = $@;
         $msg =~ s/\n+/\n/;
         warn "FATAL: $msg";
         DC::_exit 1;
      }

      # win32 is fucked up, of course. exit will clean stuff up,
      # which destroys our database etc. _exit will exit ALL
      # forked processes, because of the dreaded fork emulation.
      DC::_exit 0;
   }

   close $fh_w;

   my $buffer;

   my $w; $w = AnyEvent->io (fh => $fh_r, poll => 'r', cb => sub {
      unless (sysread $fh_r, $buffer, 4096, length $buffer) {
         undef $w;
         $cb->();
         return;
      }

      while ($buffer =~ s/^(.*)\n//) {
         my $line = $1;
         $line =~ s/\s+$//;
         utf8::decode $line;
         if ($line =~ /^\x{e877}json_msg (.*)$/s) {
            $cb->(JSON::XS->new->allow_nonref->decode ($1));
         } else {
            ::message ({
               markup => "background($pid): " . DC::asxml $line,
            });
         }
      }
   });
}

sub background_msg {
   my ($msg) = @_;

   $msg = "\x{e877}json_msg " . JSON::XS->new->allow_nonref->encode ($msg);
   $msg =~ s/\n//g;
   utf8::encode $msg;
   print $msg, "\n";
}

package DC;

our $RC_THEME;
our %THEME;
our @RC_PATH;
our $RC_BASE;

for (grep !ref, @INC) {
   $RC_BASE = "$_/Deliantra/Client/private/resources";
   last if -d $RC_BASE;
}

sub find_rcfile($) {
   my $path;

   for (@RC_PATH, "") {
      $path = "$RC_BASE/$_/$_[0]";
      return $path if -e $path;
   }

   die "FATAL: can't find required file \"$_[0]\" in \"$RC_BASE\"\n";
}

sub load_json($) {
   my ($file) = @_;

   open my $fh, $file
      or return;

   local $/;
   eval { JSON::XS->new->utf8->relaxed->decode (<$fh>) }
}

sub set_theme($) {
   return if $RC_THEME eq $_[0];
   $RC_THEME = $_[0];

   # kind of hacky, find the main theme file, then load all theme files and merge them

   %THEME = ();
   @RC_PATH = "theme-$RC_THEME";

   my $theme = load_json find_rcfile "theme.json"
      or die "FATAL: theme resource file not found";

   @RC_PATH = @{ $theme->{path} } if $theme->{path};

   for (@RC_PATH, "") {
      my $theme = load_json "$RC_BASE/$_/theme.json"
         or next;

      %THEME = ( %$theme, %THEME );
   }
}

sub read_cfg {
   my ($file) = @_;

   $::CFG = (load_json $file) || (load_json "$file.bak");
}

sub write_cfg {
   my $file = "$Deliantra::VARDIR/client.cf";

   $::CFG->{VERSION} = $::VERSION;
   $::CFG->{layout}  = DC::UI::get_layout ();

   open my $fh, ">:utf8", "$file~"
      or return;
   print $fh JSON::XS->new->utf8->pretty->encode ($::CFG);
   close $fh;

   rename $file, "$file.bak";
   rename "$file~", $file;
}

sub http_proxy {
   my @proxy = win32_proxy_info;

   if (@proxy) {
      "http://" . (@proxy < 2 ? "" : @proxy < 3 ? "$proxy[1]\@" : "$proxy[1]:$proxy[2]\@") . $proxy[0]
   } elsif (exists $ENV{http_proxy}) {
      $ENV{http_proxy}
   } else {
     ()
   }
}

sub set_proxy {
   my $proxy = http_proxy
      or return;

   $ENV{http_proxy} = $proxy;
}

sub lwp_useragent {
   require LWP::UserAgent;
   
   DC::set_proxy;

   my $ua = LWP::UserAgent->new (
      agent      => "deliantra $VERSION",
      keep_alive => 1,
      env_proxy  => 1,
      timeout    => 30,
   );
}

sub lwp_check($) {
   my ($res) = @_;

   $res->is_error
      and die $res->status_line;

   $res
}

sub fh_nonblocking($$) {
   my ($fh, $nb) = @_;

   if ($^O eq "MSWin32") {
      $nb = (! ! $nb) + 0;
      ioctl $fh, 0x8004667e, \$nb; # FIONBIO
   } else {
      fcntl $fh, &Fcntl::F_SETFL, $nb ? &Fcntl::O_NONBLOCK : 0;
   }
}

package DC::Layout;

$DC::OpenGL::INIT_HOOK{"DC::Layout"} = sub {
   glyph_cache_restore;
};

$DC::OpenGL::SHUTDOWN_HOOK{"DC::Layout"} = sub {
   glyph_cache_backup;
};

1;

=back

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

