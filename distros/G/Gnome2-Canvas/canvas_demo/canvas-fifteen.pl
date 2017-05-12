package CanvasFifteen;
use strict;
use Gnome2::Canvas;
use Glib qw(TRUE FALSE);
use constant PIECE_SIZE => 50;


sub test_win {
	my ($window, $board) = @_;

	for (my $i = 0; $i < 15; $i++) {
		if (!$board->[$i] || ($board->[$i]{piece_num} != $i)) {
			return;
		}
	}

	my $dlg = Gtk2::MessageDialog->new ($window, 'destroy-with-parent',
					   'info', 'ok', "You stud, you win!");
	$dlg->signal_connect (response => sub {$_[0]->destroy});
	$dlg->run;
}

sub get_piece_color {
	my ($piece) = @_;

	my $y = $piece / 4;
	my $x = $piece % 4;

	my $r = ((4 - $x) * 255) / 4;
	my $g = ((4 - $y) * 255) / 4;
	my $b = 128;

	return sprintf "#%02x%02x%02x", $r, $g, $b;
}

sub piece_event {
	my ($item, $event) = @_;

	my $board = $item->canvas->{board};
	my $num = $item->{piece_num};
	my $pos = $item->{piece_pos};
	my $text = $item->{text};

	if ($event->type eq 'enter-notify') {
		$text->set (fill_color => "white");

	} elsif ($event->type eq 'leave-notify') {
		$text->set (fill_color => "black");

	} elsif ($event->type eq 'button-press') {
		my $y = int ($pos / 4);
		my $x = int ($pos % 4);

		my ($dx, $dy) = (0.0, 0.0);

		my $move = TRUE;

		if (($y > 0) && (! $board->[($y - 1) * 4 + $x])) {
			$dx = 0.0;
			$dy = -1.0;
			$y--;
		} elsif (($y < 3) && (! $board->[($y + 1) * 4 + $x])) {
			$dx = 0.0;
			$dy = 1.0;
			$y++;
		} elsif (($x > 0) && (! $board->[$y * 4 + $x - 1])) {
			$dx = -1.0;
			$dy = 0.0;
			$x--;
		} elsif (($x < 3) && (! $board->[$y * 4 + $x + 1])) {
			$dx = 1.0;
			$dy = 0.0;
			$x++;
		} else {
			$move = FALSE;
		}

		if ($move) {
			my $newpos = $y * 4 + $x;
			$board->[$pos] = undef;
			$board->[$newpos] = $item;
			$item->{piece_pos} = $newpos;
			$item->move ($dx * PIECE_SIZE, $dy * PIECE_SIZE);
			test_win ($item->canvas->get_toplevel, $board);
		}
	}

	return FALSE;
}

use constant SCRAMBLE_MOVES => 256;

sub scramble {
	my (undef, $canvas) = @_;
	my $board = $canvas->{board};

	# First, find the blank spot

	my $pos;
	for ($pos = 0; $pos < 16; $pos++) {
		last if not defined $board->[$pos];
	}

	# "Move the blank spot" around in order to scramble the pieces

	for (my $i = 0; $i < SCRAMBLE_MOVES; $i++) {
		my ($x, $y) = (0, 0);
		do {
			my $dir = rand (65535) % 4;

			($x, $y) = (0, 0);

			if (($dir == 0) && ($pos > 3)) { # up
				$y = -1;
			} elsif (($dir == 1) && ($pos < 12)) { # down
				$y = 1;
			} elsif (($dir == 2) && (($pos % 4) != 0)) { # left
				$x = -1;
			} elsif (($dir == 3) && (($pos % 4) != 3)) { # right
				$x = 1;
			}
		} while ($x == $y);

		my $oldpos = $pos + $y * 4 + $x;
		$board->[$pos] = $board->[$oldpos];
		$board->[$oldpos] = undef;
		$board->[$pos]{piece_pos} = $pos;
		$board->[$pos]->move (-$x * PIECE_SIZE, -$y * PIECE_SIZE);
		$canvas->update_now;
		$pos = $oldpos;
	}
}

sub create {
	my $vbox = Gtk2::VBox->new (FALSE, 4);
	$vbox->set_border_width (4);
	$vbox->show;

	my $alignment = Gtk2::Alignment->new (0.5, 0.5, 0.0, 0.0);
	$vbox->pack_start ($alignment, TRUE, TRUE, 0);
	$alignment->show;

	my $frame = Gtk2::Frame->new;
	$frame->set_shadow_type ('in');
	$alignment->add ($frame);
	$frame->show;

	# Create the canvas and board

	my $canvas = Gnome2::Canvas->new;
	$canvas->set_size_request (PIECE_SIZE * 4 + 1, PIECE_SIZE * 4 + 1);
	$canvas->set_scroll_region (0, 0, PIECE_SIZE * 4 + 1, PIECE_SIZE * 4 + 1);
	$frame->add ($canvas);
	$canvas->show;

	my @board = ();
	$canvas->{board} = \@board;

	for (my $i = 0; $i < 15; $i++) {
		my $y = int ($i / 4);
		my $x = int ($i % 4);

		$board[$i] = Gnome2::Canvas::Item->new
					($canvas->root,
					 Gnome2::Canvas::Group::,
					 x => $x * PIECE_SIZE,
					 y => $y * PIECE_SIZE);

		Gnome2::Canvas::Item->new ($board[$i],
					 Gnome2::Canvas::Rect::,
					 x1            => 0.0,
					 y1            => 0.0,
					 x2            => PIECE_SIZE,
					 y2            => PIECE_SIZE,
					 fill_color    => get_piece_color ($i),
					 outline_color => "black",
					 width_pixels  => 0);

		my $text = Gnome2::Canvas::Item->new
					($board[$i],
					 Gnome2::Canvas::Text::,
					 text       => sprintf ('%d', $i+1),
					 x          => PIECE_SIZE / 2.0,
					 y          => PIECE_SIZE / 2.0,
					 font       => 'Sans bold 24',
					 anchor     => 'center',
					 fill_color => 'black');

		$board[$i]{piece_num} = $i;
		$board[$i]{piece_pos} = $i;
		$board[$i]{text} = $text;
		$board[$i]->signal_connect (event => \&piece_event);
	}

	$board[15] = undef;

	# Scramble button

	my $button = Gtk2::Button->new_with_label ("Scramble");
	$vbox->pack_start ($button, FALSE, FALSE, 0);
	$button->{board} = \@board;
	$button->signal_connect (clicked => \&scramble, $canvas);
	$button->show;

	return $vbox;
}

1;
