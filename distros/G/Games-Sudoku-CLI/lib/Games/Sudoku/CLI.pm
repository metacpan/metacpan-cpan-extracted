package Games::Sudoku::CLI;
use strict;
use warnings;
use 5.010;

use Games::Sudoku::Component::Controller;

our $VERSION = '0.02';

sub new {
    my ($class) = @_;

    return bless {}, $class;
}

sub play {
    my ($self) = @_;

    $self->msg("Welcome to CLI Sudoku version $VERSION");

    while (1) {
        $self->start_game or return;

        while (1) {
            $self->print_as_grid;
            while (1) {
                $self->prompt('Enter your choice (row, col, value) or [q-quit game, x-exit app, h-hint]: ');
                $self->get_input();
                $self->{input} = lc $self->{input};
                last if $self->verify_input();
            }

            if ($self->{input} eq 'h') {
                for my $item ($self->{ctrl}->find_hints) {
                    $self->msg(sprintf "%s, %s, %s", $item->row, $item->col, $item->allowed);
                }
                next;
            }
            if ($self->{input} eq 'x') {
                $self->msg('BYE');
                return;
            }
            if ($self->{input} eq 'q') {
                $self->msg('quit game');
                last;
            }
            $self->{ctrl}->set(@{ $self->{step} });

            if ($self->{ctrl}->table->is_finished) {
                $self->print_as_grid;
                $self->msg('DONE');
                last;
            }
        }
    }
    return;
}

sub start_game {
    my ($self) = @_;

    while (1) {
        $self->msg('Would you like to start a new game, load saved game, or exit?');
        $self->msg('Type in "n NUMBER" to start a new game with NUMBER empty slots');
        $self->msg('Type in "l FILENAME" to load the file called FILENAME');
        $self->msg('Type x to exit');
        $self->get_input();
        if ($self->{input} eq 'x') {
            $self->msg('BYE BYE');
            return;
        }
        if ($self->{input} =~ /^n\s+(\d+)$/) {
            my $blank = $1;
            $self->{ctrl} = Games::Sudoku::Component::Controller->new(size => 9);
            $self->{ctrl}->solve;
            $self->{ctrl}->make_blank($blank);
            last;
        }
        if ($self->{input} =~ /^l\s+(\S+)$/) {
            my $filename = $1;
            $self->{ctrl} = Games::Sudoku::Component::Controller->new(size => 9);
            $self->{ctrl}->load(filename => $filename);
        }
        last;
    }

    return 1;
}

sub get_input {
    my ($self) = @_;
    $self->{input} = <STDIN>;
    chomp $self->{input};

    return;
}

sub verify_input {
    my ($self) = @_;

    if ($self->{input} =~ /^[xqh]$/) {
        return 1;
    }

    (my $spaceless_input = $self->{input}) =~ s/\s+//g;
    my ($row, $col, $value) = $spaceless_input =~ /^(\d+),(\d+),(\d+)$/;
    if (not defined $value) {
        $self->msg("Invalid format: '$self->{input}'");
        return;
    }
    if ($row > 9 or $col > 9 or $value > 9) {
        $self->msg("Invalid values in: '$self->{input}'");
        return;
    }
    if (not $self->{ctrl}->table->cell($row,$col)->is_allowed($value)) {
        $self->msg("Value $value is not allowed in ($row, $col)");
        return;
    }

    $self->{step} = [$row, $col, $value];

    return 1;
}

sub print_as_grid {
    my ($self) = @_;

    my $table =  $self->{ctrl}->table;

    my $size   = $table->{size};
    my $digit  = int(log($size) / log(10)) + 1;

    print "    ";
    for my $c (1 .. $size) {
        print " $c ";
        if ($c % 3 == 0 and $c < 9) {
            print ' | ';
        }
    }
    print "\n";
    say '   |' . '-' x 33;

    foreach my $row (1..$size) {
        print " $row |";
        foreach my $col (1..$size) {
            my $value = $table->cell($row, $col)->value;
            print $value ? " $value " : '   ';
            if ($col % 3 == 0 and $col < 9) {
                print ' | ';
            }
        }
        print "\n";
        if ($row % 3 == 0 and $row < 9) {
            say '   |' . '-' x 33;
        }
    }
    return;
}

sub msg {
    my ($self, $msg) = @_;
    say $msg;
    return;
}

sub prompt {
    my ($self, $msg) = @_;
    print $msg;
    return;
}


1;

=pod

=head1 NAME

Games::Sudoku::CLI - play Sudoku on the command line

=cut


