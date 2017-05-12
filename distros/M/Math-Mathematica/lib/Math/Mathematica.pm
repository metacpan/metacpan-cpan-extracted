package Math::Mathematica;

=head1 NAME

Math::Mathematica - A Simple PTY connection to Wolfram's Mathematica

=head1 SYNOPSIS

 use Math::Mathematica;
 my $math = Math::Mathematica->new;
 my $result = $math->evaluate('Integrate[Sin[x],{x,0,Pi}]'); # 2

=head1 DESCRIPTION

Although there are more clever mechanisms to interact with Wolfram's Mathematica (namely MathLink) they are very hard to write. L<Math::Mathematica> simply starts a PTY, runs the command line C<math> program, and manages input/output via string transport. While a MathLink client for Perl would be ideal, this module gets the job done.

This module does not contain a Mathematica interpreter. Mathematica must be installed on the computer before installing/using L<Math::Mathematica>.

=cut

use strict;
use warnings;

our $VERSION = '0.002';
$VERSION = eval $VERSION;

use Carp;
use IO::Pty::Easy;

my $re_new_prompt = qr/In\[\d+\]:=\s*/;
my $re_result = qr/Out\[\d+\]=\s*(.*?)$re_new_prompt/ms;

=head1 METHODS

=head2 new

Constructor method. Takes hash or hashreference of options:

=over 

=item *

log - If set to a true value (true by default), the full log will be available via the C<log> method.

=item *

command - The command to invoke to start the Mathematica interpreter. The default is C<math>.

=item *

warn_after - Number of seconds to wait before warning when waiting for a response from the Mathematica interpreter. After this time, a warning is issued, which one might want to trap.

=item *

pty - An L<IO::Pty::Easy> object (or one which satisfies its api). If this is not specified, one will be created.

=item *

debug - If set to true (or if C<PERL_MATHEMATICA_DEBUG> environment variable is true) then some debug statements are printed to C<STDERR>.

=back

=cut

sub new {
  my $class = shift;
  my %opts = ref $_[0] ? %{ shift() } : @_;

  $opts{log} = 1 unless defined $opts{log};

  my $self = {
    pty        => $opts{pty}        || IO::Pty::Easy->new(),
    warn_after => $opts{warn_after} || 10,
    command    => $opts{command}    || 'math',
    log        => $opts{log} ? '' : undef,
    debug      => $opts{debug} || $ENV{PERL_MATHEMATICA_DEBUG} || 0,
  };

  bless $self, $class;

  $self->pty->spawn($self->{command}) 
    or croak "Could not connect to Mathematica";
  my $output = $self->_wait_for_prompt;
  $self->log($output);

  return $self;
}

=head2 evaluate

Takes a string to pass to the Mathematica interpreter for evaluation. Returns a string of results. Prompt makers are stripped from the result.

=cut

sub evaluate {
  my ($self, $command) = @_;
  my $pty = $self->pty;
  $command .= "\n";

  $self->log($command);
  $pty->write($command, 0) or croak "No data sent";

  my $output = $self->_wait_for_prompt;
  $self->log($output);

  my $return = $1 if $output =~ $re_result;
  $return =~ s/[\n\s]*$//;
  
  return $return;
}

# internal method _wait_for_prompt
#   receives strings from the Mathematica interpreter,
#   once a prompt is detected return the string

sub _wait_for_prompt {
  my $self = shift;
  my $pty = $self->pty;

  my $null_loops = 0;
  my $output = '';
  while ($pty->is_active) {
    my $read = $pty->read(1);

    if (defined $read) {
      $output .= $read;
      $null_loops = 0;

      print STDERR "Got: ===>$read<===\n" if $self->{debug};

      last if $output =~ $re_new_prompt;

      print STDERR "Status: Did not match prompt\n\n" if $self->{debug};

    } else {

      carp "Response from Mathematica is taking longer than expected" 
        if ++$null_loops >= $self->{warn_after};

    }
  }

  print STDERR "Status: Matched prompt\n\n" if $self->{debug};
  return $output;
}

=head2 log

If the C<log> constructor option was set, this accessor will contain the full I/O log of the PTY connection, including Mathematica prompts.

=cut

sub log {
  my $self = shift;
  if ( @_ and defined $self->{log} ) {
    $self->{log} .= $_ for @_;
  }
  return $self->{log};
}

=head2 pty

Accessor method which returns the active L<IO::Pty::Easy> object. This object will be closed when the L<Math::Mathematica> object is destroyed.

=cut

sub pty {shift->{pty}}

sub DESTROY { shift->pty->close }

1;

=head1 SEE ALSO

=over

=item L<IO::Pty::Easy>

=item L<IO::Pty>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Math-Mathematica>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Mathematica, MathLink and Wolfram are trademarks of Wolfram Research, Inc. L<http://www.wolfram.com>

