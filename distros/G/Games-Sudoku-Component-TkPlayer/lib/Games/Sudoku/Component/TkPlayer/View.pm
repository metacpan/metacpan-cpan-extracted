package Games::Sudoku::Component::TkPlayer::View;
{
  use strict;
  use warnings;
  use Carp;

  use Tk::JPEG;

  use Games::Sudoku::Component::TkPlayer::Splashscreen;
  use Games::Sudoku::Component::TkPlayer::Selector;

  sub new {
    my $class = shift;

    my %options = ref $_[0] ? %{ $_[0] } : @_;

    my $this = bless {
      mw  => $options{mw},
      sdk => $options{sdk},
      cmd => $options{cmd},
      ver => $options{ver},
      wgt => {},
    }, (ref $class || $class);
  }

  sub create {
    my $this = shift;
    my $mw   = $this->{mw};
    my $cmd  = $this->{cmd};
    my $ver  = $this->{ver};

    $mw->title("Sudoku Player $ver");

    $this->create_menu;
    $this->create_progressbar;
    $this->create_board;
    $this->create_sideboard;
    $this->create_selector;
    $mw->focus;
  }

  sub create_menu {
    my $this = shift;
    my $mw   = $this->{mw};

    $mw->configure(-menu => my $menu = $mw->Menu);

    $menu->cascade(
      -label     => '~Game',
      -menuitems => $this->create_menu_file,
      -tearoff   => 0,
    );

    $menu->cascade(
      -label     => '~Hint',
      -menuitems => $this->create_menu_hint,
      -tearoff   => 0,
    );
  }

  sub create_menu_file {
    my $this = shift;
    my $mw   = $this->{mw};
    my $cmd  = $this->{cmd};
    my $sdk  = $this->{sdk};
    my $wgt  = $this->{wgt};

    [
      [
        'command', '~New',
        -command => [ 'new_game', $cmd, $mw, $sdk, $wgt ],
      ],
      [
        'command', '~Load',
        -command => [ 'load_game', $cmd, $mw, $sdk, $wgt ],
      ],
      [
        'command', '~Save',
        -command => [ 'save_game', $cmd, $mw, $sdk, $wgt ],
      ],
      '',
      [
        'command', 'Loc~k',
        -command => [ 'lock', $cmd, $mw, $sdk, $wgt ],
      ],
      [
        'command', '~Unlock',
        -command => [ 'unlock', $cmd, $mw, $sdk, $wgt ],
      ],
      '',
      [
        'command', '~Rewind all',
        -command => [ 'rewind_all', $cmd, $mw, $sdk, $wgt ],
      ],
      [
        'command', '~Clear',
        -command => [ 'clear', $cmd, $mw, $sdk, $wgt ],
      ],
      '',
      [
        'command', '~Quit',
        -command => [ 'quit', $cmd, $mw ],
      ],
    ];
  }

  sub create_menu_hint {
    my $this = shift;
    my $mw   = $this->{mw};
    my $cmd  = $this->{cmd};
    my $sdk  = $this->{sdk};
    my $wgt  = $this->{wgt};

    my ($check_tmp, $allowed_only);
    $cmd->{check_tmp}    = sub { @_ ? $check_tmp = shift : $check_tmp };
    $cmd->{allowed_only} = sub { @_ ? $allowed_only = shift : $allowed_only };
    [
      [
        'checkbutton', q{Tell me if I'm ~wrong},
        -onvalue  => 1,
        -offvalue => 0,
        -variable => \$check_tmp,
        -command => [ 'find_tmpvalue', $cmd, $sdk, $wgt ],
      ],
      [
        'checkbutton', q{~Allowed value only},
        -onvalue  => 1,
        -offvalue => 0,
        -variable => \$allowed_only,
#        -command => [ 'allowed_only', $cmd, $sdk, $wgt ],
      ],
      '',
      [
        'command', q{What should I do ~next},
        -command => [ 'find_next', $cmd, $mw, $sdk, $wgt ],
      ],
      [
        'command', q{~Help me a step},
        -command => [ 'do_next', $cmd, $mw, $sdk, $wgt ],
      ],
      [
        'command', q{~Solve all},
        -command => [ 'solve', $cmd, $mw, $sdk, $wgt ],
      ],
    ];
  }

  sub create_progressbar {
    my $this = shift;
    my $mw   = $this->{mw};
    my $wgt  = $this->{wgt};

    $wgt->{splash} = $mw->Splashscreen;
  }

  sub create_selector {
    my $this = shift;
    my $mw   = $this->{mw};
    my $wgt  = $this->{wgt};
    my $sdk  = $this->{sdk};

    $wgt->{selector} = $mw->Selector;

    $wgt->{selector}->setsize($sdk->table->size);
  }

  sub create_board {
    my $this = shift;
    my $mw   = $this->{mw};
    my $cmd  = $this->{cmd};
    my $sdk  = $this->{sdk};
    my $wgt  = $this->{wgt};

    my $frame = $mw->Frame;
    my $size  = $sdk->table->size;
    foreach my $row (1..$size) {
      foreach my $col (1..$size) {
        my $value = $sdk->table->cell($row,$col)->value;
        my $id    = ($row - 1) * $size + ($col - 1);
        $wgt->{buttons}->[$id] = $mw->Button(
          -text    => ' ',
          -command => [
            'push_button', $cmd, $sdk, $wgt, $row, $col
          ],
        )->grid(
          -in     => $frame,
          -row    => $row - 1,
          -column => $col - 1,
        );
        $cmd->configure_button_color($wgt, $id, 'gray');
        $cmd->configure_button($wgt, $id);
      }
    }
    $frame->pack(-side => 'left');
  }

  sub create_sideboard {
    my $this = shift;
    my $mw   = $this->{mw};
    my $cmd  = $this->{cmd};
    my $sdk  = $this->{sdk};
    my $wgt  = $this->{wgt};

#    my $image = $mw->Photo(-file => 'resources/charsbar.jpg');
    my $image = $mw->Photo;
    my $frame = $mw->Frame;
    $wgt->{image} = $frame->Label(-image => $image)->pack(-side => 'right');
    my $message;
    $wgt->{mbox}  = $frame->Label(
      -textvariable => \$message,
      -font => [
        -family => 'helvetica',
        -size   => 12,
        -weight => 'bold',
      ],
      -background => '#ffffff',
      -height => 10,
      -width  => 18,
      -justify => 'left',
      -anchor => 'nw',
    )->pack(
      -side => 'left'
    );
    $frame->pack(-side => 'right');

    $cmd->{message} = sub { $message = shift };
  }
}

1;

__END__

=head1 NAME

Games::Sudoku::Component::TkPlayer::View - handles puzzle board

=head1 SYNOPSIS

    use Games::Sudoku::Component::TkPlayer::View;
    my $view = Games::Sudoku::Component::TkPlayer::View->new;
    $view->create;

=head1 DESCRIPTION

This is an internal class.

=head1 METHODS

=over 4

=item new

creates an instance.

=item create

creates a puzzle board.

=item create_menu
=item create_menu_file
=item create_menu_hint
=item create_progressbar
=item create_selector
=item create_board
=item create_sideboard

prepare appropriate widgets.

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
