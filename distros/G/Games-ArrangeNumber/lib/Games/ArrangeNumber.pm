package Games::ArrangeNumber;

our $DATE = '2015-01-03'; # DATE
our $VERSION = '0.05'; # VERSION

use Color::ANSI::Util qw(ansibg ansifg);
use List::Util qw(shuffle);
use Term::ReadKey;
use Time::HiRes qw(sleep);

use 5.010001;
use Mo qw(build default);

has frame_rate   => (is => 'rw', default=>15);
has board_size   => (is => 'rw', default=>4);
has needs_redraw => (is => 'rw', default=>1);
has num_moves    => (is => 'rw');
has start_time   => (is => 'rw');
has board        => (is => 'rw'); # a 2-d matrix of numbers

my %color_themes = (
    default => {
        border     => [      "", "a0a0a0"],
        blank_tile => [      "", "202020"],
        odd_tile   => ["d0d0d0", "306e2e"],
        even_tile  => ["d0d040", "407e33"],
    },
);
my $color_theme = $color_themes{default};

sub _col {
    my $self = shift;
    my $item = shift;
    my $ci = $color_theme->{$item};
    join(
        "",
        (length($ci->[0]) ? ansifg($ci->[0]) : ""),
        (length($ci->[1]) ? ansibg($ci->[1]) : ""),
        @_,
        "\e[0m",
    );
}

sub draw_board {
    my $self = shift;
    state $drawn = 0;
    state $buf = "";

    return unless $self->needs_redraw;

    # move up to original row position
    if ($drawn) {
        # count the number of newlines
        my $num_nls = 0;
        $num_nls++ while $buf =~ /\n/g;
        printf "\e[%dA", $num_nls;
    }

    my $s = $self->board_size;
    my $w = $s > 3 ? 2 : 1; # width of number
    $buf = "";
    $buf .= "How to play: press arrow keys to arrange the numbers.\n";
    $buf .= "  Press R to restart. Q to quit.\n";
    $buf .= "\n";
    $buf .= sprintf("Moves: %-4d | Time: %-5d\n", $self->num_moves,
                    time-$self->start_time);
    $buf .= $self->_col("border", "  ", (" " x ($s*(4+$w))), "  ");
    $buf .= "\n";
    my $board = $self->board;
    for my $row (@$board) {
        for my $i (1..3) {
            $buf .= $self->_col("border", "  ");
            for my $cell (@$row) {
                my $item = $cell == 0 ? "blank_tile" :
                    $cell % 2 ? "odd_tile" : "even_tile";
                $buf .= $self->_col(
                    $item, sprintf("  %${w}s  ", $i==2 && $cell ? $cell : ""));
            }
            $buf .= $self->_col("border", "  ");
            $buf .= "\n";
        }
    }
    $buf .= $self->_col("border", "  ", (" " x ($s*(4+$w))), "  ");
    $buf .= "\n";
    print $buf;
    $drawn++;
    $self->needs_redraw(0);
}

# borrowed from Games::2048
sub read_key {
    my $self = shift;
    state @keys;

    if (@keys) {
        return shift @keys;
    }

    my $char;
    my $packet = '';
    while (defined($char = ReadKey -1)) {
        $packet .= $char;
    }

    while ($packet =~ m(
                           \G(
                               \e \[          # CSI
                               [\x30-\x3f]*   # Parameter Bytes
                               [\x20-\x2f]*   # Intermediate Bytes
                               [\x40-\x7e]    # Final Byte
                           |
                               .              # Otherwise just any character
                           )
                   )gsx) {
        push @keys, $1;
    }

    return shift @keys;
}

sub has_won {
    my $self = shift;
    join(",", map { @$_ } @{$self->board}) eq
        join(",", 1 .. ($self->board_size ** 2 -1), 0);
}

sub new_game {
    my $self = shift;

    my $s = $self->board_size;
    die "Board size must be between 3 and 7 \n" unless ($s >= 3 && $s <= 7)
        || $ENV{DEBUG};

    my $board;
    while (1) {
        my @num0 = (1 .. ($s ** 2 -1), 0);
        my @num  = shuffle @num0;
        redo if join(",",@num0) eq join(",",@num);
        $board = [];
        while (@num) {
            push @$board, [splice @num, 0, $s];
        }
        last;
    }
    $self->board($board);
    $self->num_moves(0);
    $self->start_time(time());

    $self->needs_redraw(1);
    $self->draw_board;
}

sub init {
    my $self = shift;
    $SIG{INT}     = sub { $self->cleanup; exit 1 };
    $SIG{__DIE__} = sub { warn shift; $self->cleanup; exit 1 };
    ReadMode "cbreak";

    # pick color depth
    if ($ENV{KONSOLE_DBUS_SERVICE}) {
        $ENV{COLOR_DEPTH} //= 2**24;
    } else {
        $ENV{COLOR_DEPTH} //= 16;
    }
}

sub cleanup {
    my $self = shift;
    ReadMode "normal";
}

# move the blank tile
sub move {
    my ($self, $dir) = @_;

    my $board = $self->board;
    # find the current position of the blank tile
    my ($curx, $cury);
  FIND:
    for my $y (0..@$board-1) {
        my $row = $board->[$y];
        for my $x (0..@$row-1) {
            if ($row->[$x] == 0) {
                $curx = $x;
                $cury = $y;
                last FIND;
            }
        }
    }

    my $s = $self->board_size;
    if ($dir eq 'up') {
        return unless $cury > 0;
        $board->[$cury  ][$curx  ] = $board->[$cury-1][$curx  ];
        $board->[$cury-1][$curx  ] = 0;
    } elsif ($dir eq 'down') {
        return unless $cury < $s-1;
        $board->[$cury  ][$curx  ] = $board->[$cury+1][$curx  ];
        $board->[$cury+1][$curx  ] = 0;
    } elsif ($dir eq 'left') {
        return unless $curx > 0;
        $board->[$cury  ][$curx  ] = $board->[$cury  ][$curx-1];
        $board->[$cury  ][$curx-1] = 0;
    } elsif ($dir eq 'right') {
        return unless $curx < $s-1;
        $board->[$cury  ][$curx  ] = $board->[$cury  ][$curx+1];
        $board->[$cury  ][$curx+1] = 0;
    } else {
        die "BUG: Unknown direction '$dir'";
    }

    $self->num_moves($self->num_moves+1);
    $self->needs_redraw(1);
}

sub run {
    my $self = shift;

    $self->init;
    $self->new_game;
    my $ticks = 0;
  GAME:
    while (1) {
        while (defined(my $key = $self->read_key)) {
            if ($key eq 'q' || $key eq 'Q') {
                last GAME;
            } elsif ($key eq 'r' || $key eq 'R') {
                $self->new_game;
            } elsif ($key eq "\e[D") { # left arrow
                $self->move("right");
            } elsif ($key eq "\e[A") { # up arrow
                $self->move("down");
            } elsif ($key eq "\e[C") { # right arrow
                $self->move("left");
            } elsif ($key eq "\e[B") { # down arrow
                $self->move("up");
            }
        }
        $self->draw_board;
        if ($self->has_won) {
            say "You won!";
            last;
        }
        sleep 1/$self->frame_rate;
        $ticks++;
        $self->needs_redraw(1) if $ticks % $self->frame_rate == 0
    }
    $self->cleanup;
}

# ABSTRACT: Arrange number game

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::ArrangeNumber - Arrange number game

=head1 VERSION

This document describes version 0.05 of Games::ArrangeNumber (from Perl distribution Games-ArrangeNumber), released on 2015-01-03.

=head1 SYNOPSIS

 % arrange-number

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<arrange-number>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Games-ArrangeNumber>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Games-ArrangeNumber>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-ArrangeNumber>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
