package Image::Synchronize::ProgressBar;

=head1 NAME

Image::Synchronize::ProgressBar - A simple progress bar that also
works in closures.

=head1 SYNOPSIS

=head1 DESCRIPTION

This class implements a simple progress bar based on
L<Term::ProgressBar>, somewhat similar to
L<Term::ProgressBar::Simple>.  The latter doesn't work well in
closures; the current implementation does.

=head1 METHODS

=cut

use strict;
use warnings;

use IO::Interactive qw(is_interactive);
use Term::ProgressBar;

=head2 new

  $pb = Image::Synchronize::ProgressBar->new(%options);

Creates a new instance of the progress bar.  Accepts the following
options (mostly similar to L<Term::ProgressBar>):

=over

=item count

The target count for the progress bar.  When the progress count
reaches this value, then the task is assumed to be complete.

=item fh

The filehandle to output to.  Defaults to STDERR.

=item name

The name of the progress bar.  This name is printed at the left-hand
side of the progress bar.

=item show_bar

Should the progress bar be displayed?  If set to a true value, then
the progress bar is always displayed.  If set to a false value, then
the progress bar is not displayed, but the L<message> method still
prints to standard output (unlike for the C<silent> option).  If not
set, then the progress bar is displayed only if the program detects
that it is running interactively.

This option is not inherited from C<Term::ProgressBar>.

=item silent

If set to a true value, then the progress bar does nothing.  In
particular, it does not print anything when you call the L<message>
method on it.  Is ignored if C<show_bar> is defined.  For an
alternative, see C<show_bar>.

=item term_width

The width of the terminal.  Use if the automatic detection fails.

=back

The progress bar is removed when the task is complete, and displays an
estimate of how long it will take for the task to complete.

=cut

sub new {
  my ( $class, $options ) = @_;
  my $self;
  my $interactive;
  if ( defined $options->{show_bar} ) {
    $interactive = $options->{show_bar};
    delete $options->{show_bar};
    delete $options->{silent};    # show_bar trumps silent
  }
  else {
    $interactive = is_interactive();
  }
  if ($interactive) {
    $options->{ETA} = 'linear';
    $self = bless {
      backend     => Term::ProgressBar->new($options),
      progress    => 0,
      next_update => 0,
    }, $class;
    $self->{target} = $options->{count};
    $self->{backend}->remove(1);
  }
  else {
    $self = bless {}, $class;
  }
  $self->{interactive} = $interactive;
  return $self;
}

=head2 add

  $pb->add($amount);
  $pb->add;                     # adds 1

Add the indicated C<$amount>, or 1, toward the target of the progress
bar.

=cut

sub add {
  my ( $self, $amount ) = @_;
  if ( $self->{interactive} ) {
    $amount //= 1;
    $self->{progress} += $amount;
    if ( $self->{progress} >= $self->{next_update} ) {
      $self->{next_update} = $self->{backend}->update( $self->{progress} );
    }
  }
  return $self;
}

=head2 done

  $pb->done;

Declare the task to be complete.

=cut

sub done {
  my ($self) = @_;
  $self->{backend}->update( $self->{target} ) if $self and $self->{backend};
}

=head2 message

  $pb->message(@message);

Prints a message (like L<print>), taking into account the progress
bar.

=cut

sub message {
  my ( $self, @message ) = @_;
  if ( $self->{interactive} ) {
    $self->{backend}->message(@message);
  }
  else {
    print @message;
  }
  return $self;
}

sub DESTROY {
  my ($self) = @_;
  $self->done;
}

=head1 DEPENDENCIES

This module uses the following non-core Perl modules:

=over

=item

L<IO::Interactive>

=item

L<Term::ProgressBar>

=back

=head1 AUTHOR

Louis Strous E<lt>LS@quae.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016-2018 Louis Strous.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
