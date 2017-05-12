# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen::Generator::SparseAndLoops;

use common::sense;
use Carp;
use parent 'Games::RolePlay::MapGen::Generator::Perfect';
use Games::RolePlay::MapGen::Tools qw( choice roll );

1;

sub _dirsum       { my $c = 0; for (qw(n s e w)) { $c ++ if $_[0]->{od}{$_} } $c };
sub _endian_tiles { return grep { &_dirsum($_) == 1 } map(@$_, @{ $_[0] }) }

# remove_deadends {{{
sub remove_deadends {
    my $this = shift;
    my $opts = shift;
    my $map  = shift;

    my @dirs = (qw(n s e w));

    for my $tile ( &_endian_tiles( $map ) ) {
        if( &roll(1, 100) <= $opts->{remove_deadend_percent} ) {

            DO_THIS_TILE_ALSO:
            my @togo = grep { !$tile->{od}{$_} } @dirs;
            my $dir  = &choice(@togo);

            TRY_THIS_DIR_INSTEAD: 
            if( my $nex = $tile->{nb}{$dir} ) {

                $tile->{od}{$dir} = $nex->{od}{$Games::RolePlay::MapGen::opp{$dir}} = 1;

                if( $nex->{type} ) {
                    # Excellent, we're done with this tile.

                } else {
                    # Alrightsir, mark nex as a corridor and we'll have to keep going.

                    $tile = $nex;
                    $tile->{type} = 'corridor';

                    if( &roll(1, 100) > $opts->{same_way_percent} ) {
                        @togo = grep { !$tile->{od}{$_} and !$tile->{_bud}{$dir} } @dirs;
                        $dir  = &choice(@togo);
                    }

                    goto DO_THIS_TILE_ALSO;
                }

            } else {
                $tile->{_bud}{$dir} = 1;
                @togo = grep { !$tile->{od}{$_} and !$tile->{_bud}{$_} } @dirs;
                $dir  = &choice(@togo);

                die "FATAL: couldn't figure out how to un-dead this end..." unless $dir;

                goto TRY_THIS_DIR_INSTEAD;
            }
        }
    }
}
# }}}
# sparsify {{{
sub sparsify {
    my $this = shift;
    my $opts = shift;
    my $map  = shift;

    my $sparseness = $opts->{sparseness};

    SPARSIFY: 
    for my $tile ( &_endian_tiles( $map ) ) {
        my($dir)= grep { $tile->{od}{$_} } (qw(n s e w)); # grep returns the resulting list size unless you evaluate in list context
        my $nex = ($tile->{od}{n} ? $map->[$tile->{y}-1][$tile->{x}] :
                   $tile->{od}{s} ? $map->[$tile->{y}+1][$tile->{x}] :
                   $tile->{od}{e} ? $map->[$tile->{y}][$tile->{x}+1] :
                                    $map->[$tile->{y}][$tile->{x}-1] );

        $opts->{t_cb}->() if exists $opts->{t_cb};

        $tile->{od} = {n=>0, s=>0, e=>0, w=>0};
        delete $tile->{type};

        die "incomplete open direction found during sparseness calculation" unless defined $nex;

        $nex->{od}{$Games::RolePlay::MapGen::opp{$dir}} = 0;
    }

    goto SPARSIFY if --$sparseness > 0;
}
# }}}
# genmap {{{
sub genmap {
    my $this = shift;
    my $opts = $this->gen_opts;
    my ($map, $groups) = $this->SUPER::genmap(@_);

    $this->sparsify( $opts, $map );
    $this->remove_deadends( $opts, $map );

    return ($map, $groups);
}
# }}}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::Generator::SparseAndLoops - The basic corridor generator

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    my $map = new Games::RolePlay::MapGen;
    
    $map->set_generator( "Games::RolePlay::MapGen::Generator::SparseAndLoops" );

    generate $map;

=head1 DESCRIPTION

This is the sparseness and looping portion of Jamis Buck's Dungeon Generator.

http://www.aarg.net/~minam/dungeon_design.html

=head2 Jamis Buck's Dungeon Generator Algorithm (continued)

1. Start with Jamis Buck's perfect maze

2. Look at every cell in the maze grid. If the given cell contains a corridor that exits the cell in
only one direction (in otherwords, if the cell is the end of a dead-end hallway), "erase" that cell
by removing the corridor.

3. Repeat step #2 sparseness times (ie, if sparseness is five, repeat step #2 five times).

4. Look at every cell in the maze grid. If the given cell is a dead-end cell
(meaning that a corridor enters but does not exit the cell), it is a candidate
for "dead-end removal."

4a. Roll d% (ie, pick a number between 1 and 100, inclusive). If the result is
less than or equal to the "deadends removed" parameter, this deadend should be
removed (4b). Otherwise, proceed to the next candidate cell.

4b. Remove the dead-end by performing step #3 of Games::RolePlay::MapGen::Generator::Perfect,
above, except that a cell is not considered invalid if it has been visited.
Stop when you intersect an existing corridor.

=head1 SEE ALSO

Games::RolePlay::MapGen, Games::RolePlay::MapGen::Generator::Perfect

=cut
