package Games::Sudoku::Component::TkPlayer::Splashscreen;
{
  use strict;
  use warnings;
  use Carp;

  use Tk::widgets qw/Toplevel/;
  use base qw/Tk::Toplevel/;

  Construct Tk::Widget 'Splashscreen';

  use Tk::ProgressBar;

  sub Populate {
    my $this = shift;

    $this->withdraw;
    $this->geometry('300x50+0+0');
    $this->overrideredirect(1);

    $this->SUPER::Populate(@_);

    $this->Label(
      -text => 'Loading...',
    )->pack(
      -fill => 'x',
      -expand => 1,
    );
    $this->{pbar} = $this->ProgressBar(
      -anchor => 'w',
      -colors => [0, 'blue'],
    )->pack(
      -side  => 'top',
      -fill  => 'x',
      -padx  => 10,
      -pady  => 10,
    );
  }

  sub progress {
    my ($this, $value) = @_;

    $this->{pbar}->value($value);
  }

  sub Show {
    my ($this, %args) = @_;

    $this->{pbar}->configure(
      -blocks => int($args{-max} / 5),
      -to     => $args{-max},
    );

    $this->{old_focus} = $this->focusSave;
    $this->{old_grab}  = $this->grabSave;

    $this->transient($this->Parent->toplevel);

    $this->Popup(
      -popover => $this->Parent,
      -overanchor => 'c',
      -popanchor => 'se',
    );

    $this->grab;

    if (my $focusw = $this->cget(-focus)) {
      $focusw->focus;
    }
    else {
      $this->focus;
    }
  }

  sub Hide {
    my $this = shift;

    $this->grabRelease;

    $this->{old_focus}->();
    $this->{old_grab}->();

    $this->withdraw;
  }
}

1;

__END__

=head1 NAME

Games::Sudoku::Component::TkPlayer::Splashscreen - shows a splashscreen with a progress bar

=head1 SYNOPSIS

    use Games::Sudoku::Component::TkPlayer::Selector;
    my $popup = MainWindow->Selector;
    $popup->Show;

=head1 DESCRIPTION

This is an internal class.

=head1 METHODS

=over 4

=item progress

changes a value of the progress bar.

=back

=head1 TK METHODS

Consult appropriate pods for details.

=over 4

=item Populate, Show, Hide

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
