package Games::Sudoku::Component::TkPlayer::Controller;
{
  use strict;
  use warnings;
  use Carp;

  sub new {
    my $class = shift;
    my $this  = bless {}, (ref $class || $class);

    $this;
  }

  sub new_game {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    $sdk->clear;

    my $max   = $sdk->table->size ** 2;
    my $blank = int($max * .65);

    my $splash = $wgt->{splash};

    $splash->Show(-max => $max);
    until($sdk->status->is_finished) {
      $sdk->next;
      $splash->progress($sdk->table->num_of_finished);
      $splash->update;
    }
    $splash->progress($max);
    $sdk->make_blank($blank);
    $splash->Hide;

    my $size = $sdk->table->size;

    my $check = $this->{check_tmp}->();
    $this->{check_tmp}->(0);
    foreach my $row (1..$size) {
      foreach my $col (1..$size) {
        $this->_set_button($sdk, $wgt, $row, $col);
      }
    }
    $this->{check_tmp}->($check);
    $this->{message}->(q{Solve this!});

    $mw->Unbusy;
  }

  sub load_game {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    my $file = $mw->getOpenFile;

    if (defined $file && -f $file) {
      $sdk->clear;

      $sdk->load(file => $file);

      my $size = $sdk->table->size;

      my $check = $this->{check_tmp}->();
      $this->{check_tmp}->(0);
      foreach my $row (1..$size) {
        foreach my $col (1..$size) {
          $this->_set_button($sdk, $wgt, $row, $col);
        }
      }
      $this->{check_tmp}->($check);
      $this->{message}->(q{Loaded!});
    }
    $mw->Unbusy;
  }

  sub save_game {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    my $file = $mw->getSaveFile;

    if (defined $file and open my $fh, '>', $file) {
      print $fh $sdk->table->as_string;
      close $fh;

      $this->{message}->(q{Saved!});
    }

    $mw->Unbusy;
  }

  sub lock {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    $sdk->table->lock_all;
    $this->_update_lock_status($mw, $sdk, $wgt);
    $this->{message}->(q{Locked});

    $mw->Unbusy;
  }

  sub clear {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    $sdk->clear;
    $this->unlock($mw, $sdk, $wgt);

    my $size = $sdk->table->size;

    my $check = $this->{check_tmp}->();
    $this->{check_tmp}->(0);
    foreach my $row (1..$size) {
      foreach my $col (1..$size) {
        $this->_set_button($sdk, $wgt, $row, $col);
      }
    }
    $this->{check_tmp}->($check);
    $this->{message}->(q{Cleared});

    $mw->Unbusy;
  }

  sub unlock {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    $sdk->table->unlock_all;
    $this->_update_lock_status($mw, $sdk, $wgt);
    $this->{message}->(q{Unlocked});

    $mw->Unbusy;
  }

  sub rewind_all {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    $sdk->rewind_all;
    $sdk->status->turn_to_ok;

    my $size = $sdk->table->size;

    my $check = $this->{check_tmp}->();
    $this->{check_tmp}->(0);
    foreach my $row (1..$size) {
      foreach my $col (1..$size) {
        $this->_set_button($sdk, $wgt, $row, $col);
      }
    }
    $this->{check_tmp}->($check);
    $this->{message}->(q{Rewinded});

    $mw->Unbusy;
  }

  sub _update_lock_status {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    my $table = $sdk->table;
    my $size  = $table->size;

    my $check = $this->{check_tmp}->();
    $this->{check_tmp}->(0);
    foreach my $row (1..$size) {
      foreach my $col (1..$size) {
        my $id = ($row - 1) * $size + ($col - 1);
        $this->configure_button($wgt, $id, 
          $table->cell($row, $col)->is_locked
        );
      }
    }
    $this->{check_tmp}->($check);

    $mw->Unbusy;
  }

  sub _set_button {
    my ($this, $sdk, $wgt, $row, $col) = @_;

    my $value  = $sdk->table->cell($row,$col)->value;
    my $locked = $sdk->table->cell($row,$col)->is_locked;
    my $size   = $sdk->table->size;
    my $id     = ($row - 1) * $size + ($col - 1);

    $wgt->{buttons}->[$id]->configure(
      -text => $value ? $value : ' ',
    );
    $this->configure_button($wgt, $id, $locked);

    if ( $this->{check_tmp}->() ) {
      if ( $sdk->table->cell($row,$col)->tmpvalue ) {
        $this->configure_button_color($wgt, $id, 'red');
        $this->{message}->(q{might be wrong...});
      }
      else {
        $this->configure_button_color($wgt, $id, 'gray');
        $this->{message}->(q{hmm...});
        $this->find_tmpvalue($sdk, $wgt);
      }
    }
    else {
      $this->configure_button_color($wgt, $id, 'gray');
      $this->{message}->(q{hm...});
    }
  }

  sub find_tmpvalue {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    my $size = $sdk->table->size;

    $sdk->table->check_tmpvalue;

    my $check_on = $this->{check_tmp}->();
    foreach my $row (1..$size) {
      foreach my $col (1..$size) {
        my $id = ($row - 1) * $size + ($col - 1);
        $this->configure_button_color($wgt, $id, 
          $check_on && $sdk->table->cell($row,$col)->tmpvalue ?
            'red' : 'gray',
        );
      }
    }
    $mw->Unbusy;
  }

  sub find_next {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    my $next = $sdk->table->find_next;

    if ($next) {
      my $size = $sdk->table->size;
      my $row  = $next->row;
      my $col  = $next->col;
      my $id   = ($row - 1) * $size + ($col - 1);
      $this->configure_button_color($wgt, $id, 'yellow');
      $this->{message}->(q{Try this.})
    }
    else {
      $this->{message}->(q{I have no idea. Try some.})
    }
    $mw->Unbusy;
  }

  sub configure_button {
    my ($this, $wgt, $id, $locked) = @_;

    $wgt->{buttons}->[$id]->configure(
      -font => [
        -weight => $locked ? 'bold' : 'normal',
        -family => 'courier',
        -size   => 25,
      ],
      -width => 2,
      -height => 1,
    );
  }

  sub configure_button_color {
    my ($this, $wgt, $id, $color) = @_;

    if ($color eq 'yellow') {
      $wgt->{buttons}->[$id]->configure(
        -activebackground => 'lightyellow',
        -background       => 'yellow',
      );
    }
    if ($color eq 'red') {
      $wgt->{buttons}->[$id]->configure(
        -activebackground => 'orange',
        -background       => 'red',
      );
    }
    if ($color eq 'gray') {
      $wgt->{buttons}->[$id]->configure(
        -activebackground => 'gray',
        -background       => 'darkgray',
      );
    }
  }

  sub solve {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    my $status = $sdk->status;
    $status->clear;

    until($status->is_finished) {
      $this->_do_next($mw, $sdk, $wgt, 1);
      $mw->update;
    }
    if ($status->is_solved) {
      $this->{message}->(q{OK, here you are!});
    }
    if ($status->is_giveup) {
      $this->{message}->(q{Sorry I can't solve!});
    }
    $mw->Unbusy;
  }

  sub do_next {
    my ($this, $mw, $sdk, $wgt) = @_;

    $mw->Busy(-recurse => 1);

    $this->_do_next($mw, $sdk, $wgt, 0);

    $mw->Unbusy;
  }

  sub _do_next {
    my ($this, $mw, $sdk, $wgt, $silent) = @_;

    my $item   = $sdk->next;
    my $status = $sdk->status;

    if ($status->is_ok) {
      $this->_set_button($sdk, $wgt, $item->row, $item->col) if $item;
      $this->{message}->(q{Your turn...}) unless $silent;
    }
    if ($status->is_rewind) {
      $this->_set_button($sdk, $wgt, $item->row, $item->col) if $item;
      $this->{message}->(q{mmm, we should rewind some...}) unless $silent;
    }
    if ($status->is_giveup) {
      $this->{message}->(q{Sorry I can't solve!}) unless $silent;
    }
    if ($sdk->table->is_finished) {
      $this->{message}->(q{OK, here you are!}) unless $silent;
    }
  }

  sub push_button {
    my ($this, $sdk, $wgt, $row, $col) = @_;

    return if $sdk->table->cell($row,$col)->is_locked;

    my @allowed = $sdk->table->cell($row,$col)->allowed;

    my $allowed_only = $this->{allowed_only}->();

    $wgt->{selector}->set_allowed($allowed_only, @allowed);

    my $value = $wgt->{selector}->Show;

    $sdk->table->cell($row,$col)->value($value);

    $this->_set_button($sdk, $wgt, $row, $col);

    $this->{message}->('Conguratulations!') if $sdk->table->is_finished;
  }

  sub quit {
    my ($this, $mw) = @_;

    $mw->destroy;
  }
}

1;

__END__

=head1 NAME

Games::Sudoku::Component::TkPlayer::Controller - controls Tk Widgets and Sudoku Components

=head1 SYNOPSIS

    use Games::Sudoku::Component::TkPlayer::Controller;
    my $ctrl = Games::Sudoku::Component::TkPlayer::Controller->new;

=head1 DESCRIPTION

This is an internal class but may show you how to use Games::Sudoku::Component.

=head1 METHODS

=over 4

=item new

creates an instance

=item new_game

erases an existing puzzle if any and creates a new one.

=item load_game

erases an existing puzzle if any and loads a new one.

=item save_game

saves a puzzle to a file.

=item lock

locks a puzzle, so you can roll back the changes you make
afterwards. Generated and loaded puzzles are locked by default.

=item unlock

unlocks a puzzle, so you can change an existing puzzle.

=item clear

clears an existing puzzle.

=item rewind_all

rolls back all the changes you made.

=item find_tmpvalue

finds values that are wrong and prohibited in fact.

=item find_next

would tell you what cell you should put an answer next.

=item solve

solves a puzzle.

=item do_next

puts an answer to a cell the solver thinks best.

=item configure_button, configure_button_color

configures button/cell appearance (used internally). 

=item push_button

does everything required when you push a button/cell (used internally).

=item quit

quits an application.

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
