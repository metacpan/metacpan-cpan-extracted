# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen::Generator::Perfect;

use common::sense;
use Carp;
use parent q(Games::RolePlay::MapGen::Generator);
use Games::RolePlay::MapGen::Tools qw( _group _tile choice roll );

1;

# create_tiles {{{
sub create_tiles {
    my $this = shift;
    my $opts = shift;
    my @map  = ();

    for my $i (0 .. $opts->{y_size}-1) {
        my $a = [];

        for my $j (0 .. $opts->{x_size}-1) {
            $opts->{t_cb}->() if exists $opts->{t_cb};

            push @$a, &_tile(x=>$j, y=>$i);
        }

        push @map, $a;
    }

    return @map;
}
# }}}
# generate_perfect_maze {{{
sub generate_perfect_maze {
    my $this = shift;
    my $opts = shift;
    my $map  = new Games::RolePlay::MapGen::_interconnected_map(shift);
    # This object interconnects the map; but, also ensures that the self-refs are broken when it goes out of scope!

    my @dirs    = (qw(n s e w));
    my $cur     = &choice(map(@$_, @$map));      
    my @togo    = @dirs;
    my $dir     = &choice(@togo);
    my @visited = ( $cur );

    $cur->{type} = "corridor";

    # open DEBUG, ">debug.log" or die $!;

    for(;;) {
        my $nex = $cur->{nb}{$dir};

        my $show = sub { my $n = shift; sprintf '(%2d, %2d)', $n->{x}, $n->{y} };

        $opts->{t_cb}->() if exists $opts->{t_cb};

        # printf DEBUG '@visited=%3d; $cur=%s; $nex=%s;%s', int @visited, $show->($cur), $show->($nex);

        if( $nex and not $nex->{visited} ) {
            # print DEBUG " NEXT";

            $cur->{od}{$dir} = 1;

            $cur = $nex;
            $cur->{visited} = 1;
            push @visited, $cur;

            $cur->{od}{$Games::RolePlay::MapGen::opp{$dir}} = 1;
            $cur->{type} = 'corridor';

            @togo = grep { !$cur->{od}{$_} and !$cur->{_pud}{$_} } @dirs;
            $dir  = &choice(@togo) if &roll(1, 100) > $opts->{same_way_percent};
            # $opts->{same_way_percent} of the time, we won't change the direction

        } elsif( @togo ) {
            # print DEBUG " TOGO";

            $cur->{_pud}{$dir} = 1; # perfect's used dir

            # $opts->{same_node_percent} of the time, we try to use the same node
            if( @visited>1 and (&roll(1, 100) > $opts->{same_node_percent}) ) {
                # print DEBUG " SAME";
                # Pick a new node with a random direction that makes sense.
                $cur  = &choice(@visited);
                @togo = grep { !$cur->{od}{$_} and !$cur->{_pud}{$_} } @dirs;
                $dir  = &choice(@togo); # whenever we switch nodes, we pick a random direction though

            } else {
                # print DEBUG " DIFF";
                # Try a different direction at this same node.
                @togo = grep { !$cur->{od}{$_} and !$cur->{_pud}{$_} } @dirs;
                $dir  = &choice(@togo);
            }

        } else {
            # print DEBUG " DULL";
            # This node is so boring, we don't want to accidentally try it again
            @visited = grep {$_ != $cur} @visited;

            last unless @visited;

            # Pick a new node with a random direction that makes sense.
            $cur  = &choice(@visited);
            @togo = grep { !$cur->{od}{$_} and !$cur->{_pud}{$_} } @dirs;
            $dir  = &choice(@togo);
        }

        # print DEBUG "\n";
    }

    delete $_->{_pud} for (map(@$_, @$map))

}
# }}}

# genmap {{{
sub genmap {
    my $this   = shift;
    my $opts   = shift;
    my @map    = $this->create_tiles( $opts );
    my @groups = ();

    $this->generate_perfect_maze($opts, \@map);

    return (\@map, \@groups);
}
# }}}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::Generator::Perfect - The perfect maze generator

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    my $map = new Games::RolePlay::MapGen;
    
    $map->set_generator( "Games::RolePlay::MapGen::Generator::Perfect" );

    generate $map;

=head1 DESCRIPTION

This is the Perfect Maze portion of Jamis Buck's Dungeon Generator.

http://www.aarg.net/~minam/dungeon_design.html

=head2 Jamis Buck's Dungeon Generator Algorithm

1. Start with a rectangular grid, x units wide and y units tall. Mark each cell in the grid
unvisited.

2. Pick a random cell in the grid and mark it visited. This is the current cell.

3. From the current cell, pick a random direction (north, south, east, or west). If (1) there is no
cell adjacent to the current cell in that direction, or (2) if the adjacent cell in that direction
has been visited, then that direction is invalid, and you must pick a different random direction. If
all directions are invalid, pick a different random visited cell in the grid and start this step
over again.

4. Let's call the cell in the chosen direction C. Create a corridor between the current cell and C,
and then make C the current cell. Mark C visited.

5. Repeat steps 3 and 4 until all cells in the grid have been visited.

=head1 SEE ALSO

Games::RolePlay::MapGen

=cut
