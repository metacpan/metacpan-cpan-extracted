#!/usr/bin/perl

use strict;
use warnings;

use Games::LMSolve::Plank::Base;

use Test::More tests => 1;

package main;

use File::Temp qw/ tempdir /;
use File::Spec;

my $dir = tempdir( CLEANUP => 1 );
my $board_fn = File::Spec->catfile($dir, 'board.txt');

open my $fh, '>', $board_fn
    or die "Cannot open - $!";
my $WS = ' ';
print {$fh} <<"EOBOARD";
Dims = (7,5)
layout = <<EOF
   XXX$WS
 XX$WS$WS$WS$WS
 X X  G
X X  X$WS
   X X$WS
EOF
Planks = [ ( (0,3) -> (2,3) ),((2,3) -> (5,3)),((4,0) -> (5,0)),((1,1) -> (1,2))]

EOBOARD

close ($fh);

my $self = Games::LMSolve::Plank::Base->new();
my @ret = $self->solve_board($board_fn);

sub my_display_solution
{
    my $buffer = '';
    my $self = shift;

    open my $fh, '>>', \$buffer
        or die "cannot open!";

    my @ret = @_;

    my $state_collection = $self->{'state_collection'};

    my $output_states = $self->{'cmd_line'}->{'output_states'};
    my $to_rle = $self->{'cmd_line'}->{'to_rle'};

    my $echo_state =
        sub {
            my $state = shift;
            return $output_states ?
                ($self->display_state($state) . ": Move = ") :
                "";
        };

    print {$fh} $ret[0], "\n";

    if ($ret[0] eq "solved")
    {
        my $key = $ret[1];
        my $s = $state_collection->{$key};
        my @moves = ();
        my @states = ($key);

        while ($s->{'p'})
        {
            push @moves, $s->{'m'};
            $key = $s->{'p'};
            $s = $state_collection->{$key};
            push @states, $key;
        }
        @moves = reverse(@moves);
        @states = reverse(@states);
        my $num_state;
        if ($to_rle)
        {
            my @moves_rle = _run_length_encoding(@moves);
            my ($m);

            $num_state = 0;
            foreach $m (@moves_rle)
            {
                print {$fh} $echo_state->($states[$num_state]) . $self->render_move($m->[0]) . " * " . $m->[1] . "\n";
                $num_state += $m->[1];
            }
        }
        else
        {
            for($num_state=0;$num_state<scalar(@moves);$num_state++)
            {
                print {$fh} $echo_state->($states[$num_state]) . $self->render_move($moves[$num_state]) . "\n";
            }
        }
        if ($output_states)
        {
            print {$fh} $self->display_state($states[$num_state]), "\n";
        }
    }

    close ($fh);

    return $buffer;
}

# TEST
is_deeply(
    [my_display_solution($self, @ret)],
    [<<'EOF'],
solved
Move the Plank of Length 2 to (2,3) N
Move the Plank of Length 3 to (5,3) N
Move the Plank of Length 1 to (5,3) S
Move the Plank of Length 3 to (5,3) W
Move the Plank of Length 1 to (2,1) W
Move the Plank of Length 1 to (5,3) S
Move the Plank of Length 3 to (5,3) N
Move the Plank of Length 1 to (5,0) W
Move the Plank of Length 3 to (5,3) W
Move the Plank of Length 1 to (5,3) S
Move the Plank of Length 2 to (5,4) W
Move the Plank of Length 3 to (5,3) N
Move the Plank of Length 1 to (4,0) W
Move the Plank of Length 1 to (5,3) S
Move the Plank of Length 2 to (3,4) N
Move the Plank of Length 2 to (3,2) N
Move the Plank of Length 1 to (4,0) E
Move the Plank of Length 1 to (4,0) W
Move the Plank of Length 3 to (3,2) E
EOF
    'Solution is ok.',
);
