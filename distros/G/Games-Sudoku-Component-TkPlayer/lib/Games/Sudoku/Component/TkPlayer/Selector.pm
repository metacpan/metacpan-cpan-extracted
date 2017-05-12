package Games::Sudoku::Component::TkPlayer::Selector;
{
  use strict;
  use warnings;
  use Carp;

  use Tk::widgets qw/Toplevel/;
  use base qw/Tk::Toplevel/;

  Construct Tk::Widget 'Selector';

  sub Populate {
    my $this = shift;

    $this->SUPER::Populate(@_);
    $this->transient($this->Parent->toplevel);
    $this->withdraw;
    $this->{result} = undef;
    $this->protocol(
      'WM_DELETE_WINDOW' => sub { $this->{result} = 0 }
    );
  }

  sub set_allowed {
    my ($this, $allowed_only, @allowed) = @_;

    my $target = 0;
    foreach my $id (1..$this->{size}) {
      my $color = 'gray';

      if ($allowed_only) {
        $target ||= shift @allowed if @allowed;
        $color = 'red';
        if ($id == $target) {
          $target = 0;
          $color  = 'gray';
        }
      }
      $this->{buttons}[$id]->configure(
        -background => $color,
      );
    }
  }

  sub setsize {
    my ($this, $size) = @_;

    $this->{size} = $size;

    foreach my $button (@{ $this->{buttons} }) {
      $button->destroy;
    }
    $this->{frame}->destroy if $this->{frame};

    my $blocksize = int(sqrt($size - 1)) + 1;

    my $frame = $this->Frame;
    foreach my $num (1..$size) {
      my $row = int(($num - 1) / $blocksize);
      my $col = ($num - 1) % $blocksize;

      $this->{buttons}[$num] = $this->Button(
        -text => $num,
        -font => [
          -size => 25,
        ],
        -command => sub { $this->{result} = $num }
      )->grid(
        -in     => $frame,
        -row    => $row,
        -column => $col,
        -sticky => 'news',
      );
    }
    $frame->pack(
      -side => 'left',
      -padx => 0,
      -pady => 0,
    );
    $this->{frame} = $frame;
    $this->bind('<KeyPress>' => \&keypress);
  }

  sub keypress {
    my $this = shift;
    my $e = $this->XEvent;
    if ($e->K eq 'Escape') { $this->{result} = 0 }
    if (my ($num) = $e->K =~ /^(\d)$/) { $this->{result} = $num; }
  }

  sub Show {
    my $this = shift;

    $this->{old_focus} = $this->focusSave;
    $this->{old_grab}  = $this->grabSave;

    $this->Popup(
      -popover    => $this->Parent,
      -overanchor => 'c',
      -popanchor  => 'c',
    );

    $this->grab;

    if (my $focusw = $this->cget(-focus)) {
      $focusw->focus;
    }
    else {
      $this->focus;
    }

    $this->Wait;

    $this->{old_focus}->();
    $this->{old_grab}->();

    return $this->{result};
  }

  sub Wait {
    my $this = shift;

    $this->Callback(-showcommand => $this);
    $this->waitVariable(\$this->{result});
    $this->grabRelease;
    $this->withdraw;
    $this->Callback(-command => $this->{result});
  }
}

1;

__END__

=head1 NAME

Games::Sudoku::Component::TkPlayer::Selector - UI class

=head1 SYNOPSIS

    use Games::Sudoku::Component::TkPlayer::Selector;
    my $popup = Games::Sudoku::Component::TkPlayer::Selector->new;

=head1 DESCRIPTION

This is an internal class.

=head1 METHODS

=over 4

=item set_allowed

turns the buttons you shouldn't push red if you enable "Allowed value only" option.

=item setsize

sets the size of the puzzle board (used internally).

=back

=head1 TK METHODS

Consult appropriate pods for details.

=over 4

=item Populate, Show, Wait, keypress

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
