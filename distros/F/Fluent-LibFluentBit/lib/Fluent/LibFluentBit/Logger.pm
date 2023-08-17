package Fluent::LibFluentBit::Logger;
our $VERSION = '0.03'; # VERSION
use strict;
use warnings;
use Carp;
use Time::HiRes 'time';
use JSON::MaybeXS;

# ABSTRACT: Perl-style logger object that logs to the 'lib' input of fluent-bit


sub include_caller {
   $_[0]{include_caller}= $_[1] if @_ > 1;
   $_[0]{include_caller}
}


sub new {
   my $class= shift;
   my %attrs= @_;
   defined $attrs{context} or croak "Missing required attribute 'context'";
   defined $attrs{input_id} or croak "Missing required attribute 'input_id'";
   $attrs{context}->start unless $attrs{context}->started;
   bless \%attrs, $class;
}

sub _log_data {
   my ($self, $data, $level)= @_;
   $data= ref $data eq 'HASH'? { %$data } : { message => $data };
   $data->{status}= $level;
   if ($self->{include_caller}) {
      my ($i, $pkgname, $file, $line, $callname)= (1);
      while (($pkgname, $file, $line)= caller($i++) and substr($pkgname,0,5) eq 'Log::') {}
      # up one more level tells us the name of the function it happened in.
      # ...but skip functions named '(eval)'
      while (($callname)= (caller($i++))[3] and $callname eq '(eval)') {}
      $data->{caller}= $callname // $pkgname;
      $data->{file}= $file;
      $data->{line}= $line;
   }
   my $code= $self->{context}->flb_lib_push($self->{input_id}, encode_json([ time, $data ]));
   $code >= 0 or croak "flb_lib_push failed: $code";
   return $self;
}

sub trace { $_[0]->_log_data( $_[1], 'trace') }
sub debug { $_[0]->_log_data( $_[1], 'debug') }
sub info  { $_[0]->_log_data( $_[1], 'info' ) }
sub warn  { $_[0]->_log_data( $_[1], 'warn' ) }
sub notice{ $_[0]->_log_data( $_[1], 'notice') }
sub error { $_[0]->_log_data( $_[1], 'error') }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Fluent::LibFluentBit::Logger - Perl-style logger object that logs to the 'lib' input of fluent-bit

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  my $logger= Fluent::LibFluentBit->new_logger;
  $logger->trace(...);
  $logger->debug(...);
  $logger->info(...);
  $logger->warn(...);
  $logger->notice(...);
  $logger->error(...);

=head1 DESCRIPTION

The fluent-bit library allows an input of type "lib" which is written directly from code
in the same process.  (this is the primary point of the library)

This logger object writes to that input, using a key of C<"message"> for the text of the
log message, and a key of C<"status"> for the log-level.

=head1 ATTRIBUTES

=head2 context

An instance of Fluent::LibFluentBit.  Read-only.  Required.

=head2 input_id

The ID of the 'lib' input for libfluent-bit, which these messages are written into.
Read-only.  Required.

=head2 include_caller

Boolean.  If set to true, this will inspect the caller on each log message and include that
in the logged data as keys C<'file'>, C<'line'>, and C<'caller'> (package or function name
where the call was made).

=head1 METHODS

=head2 Log Delivery Methods

  $logger->info("message");
  $logger->info(message => "message");
  $logger->info({ message => "message" });

Each method allows a single scalar, or hashref, or list of key/value pairs.
A single scalar becomes the value for the key 'message'.  They all return $self.

=over

=item trace

=item debug

=item info

=item warn

=item notice

=item error

=back

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
