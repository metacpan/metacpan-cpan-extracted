# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen::GeneratorPlugin::BasicDoors;

use common::sense;
use Carp;
use Games::RolePlay::MapGen::Tools qw( roll _door choice );

$Games::RolePlay::MapGen::known_opts{       "open_room_corridor_door_percent" } = { door => 95, secret =>  2, stuck => 25, locked => 50 };
$Games::RolePlay::MapGen::known_opts{     "closed_room_corridor_door_percent" } = { door =>  5, secret => 95, stuck => 10, locked => 30 };
$Games::RolePlay::MapGen::known_opts{   "open_corridor_corridor_door_percent" } = { door =>  1, secret => 10, stuck => 25, locked => 50 };
$Games::RolePlay::MapGen::known_opts{ "closed_corridor_corridor_door_percent" } = { door =>  1, secret => 95, stuck => 10, locked => 30 };
$Games::RolePlay::MapGen::known_opts{ "max_span"                              } = 50;

1;

# new {{{
sub new {
    my $class = shift;
    my $this  = [qw(door)]; # you have to be the types of things you hook

    return bless $this, $class;
}
# }}}
# doorgen {{{
sub doorgen {
    my $this   = shift;
    my $opts   = shift;
    my $map    = shift;
    my $groups = shift;

    my $minor_dirs = {
        n => [qw(e w)],
        s => [qw(e w)],

        e => [qw(n s)],
        w => [qw(n s)],
    };

    my $max_span = $opts->{max_span} / ($opts->{tile_size} || 1);
       $max_span = 1 unless $max_span > 0;

     # warn "max_span=$max_span";

    for my $i ( 0 .. $#$map ) {
        my $jend = $#{ $map->[$i] };

        for my $j ( 0 .. $jend ) {
            my $t = $map->[$i][$j];

            if( $t->{type} ) {
                for my $dir (qw(n e s w)) { my $opp = $Games::RolePlay::MapGen::opp{$dir};
                    my $n = $t->{nb}{$dir};
                    next unless $n and $n->{type};

                    unless( $t->{_bchkt}{$dir} ) {
                        my ($ttype, $ntype) = ($t->{type}, $n->{type});

                        if( $ttype eq "room" and $ntype eq "room" ) {
                            if( $t->{group}{name} eq $n->{group}{name} ) {
                                next;

                            } else {
                                $ntype = "corridor";
                            }
                        }

                        my $tkey  = ( $t->{od}{$dir} ? "open" : "closed" );
                           $tkey .= "_" . join("_", reverse sort( $ttype, $ntype ));
                           $tkey .= "_door_percent";

                        my $chances = $opts->{$tkey};
                        die "chances error for $tkey" unless defined $chances;

                        if( (my $r = roll(1, 10000)) <= (my $c = $chances->{door}*100) ) {
                            my ($span, $nspn) = $this->_find_span($dir=>$opp, $t=>$n);

                            $_->{_bchkt}{$dir} = 1 for @$span;
                            $_->{_bchkt}{$opp} = 1 for @$nspn;

                            next unless @$span <= $max_span;

                            $_->{od}{$dir} = 0 for @$span;
                            $_->{od}{$opp} = 0 for @$nspn;

                            $t = choice(@$span);
                            $n = $t->{nb}{$dir};

                            my $d1 = sprintf("%40s: (%5d, %5d)", $tkey, $r, $c);
                            my $d2 = sprintf("(%2d, %2d, $dir)", $j, $i);

                            $t->{od}{$dir} = $n->{od}{$opp} = &_door(

                                (map {$_ => ((roll(1, 10000) <= $chances->{$_}*100) ? 1:0) } qw(locked stuck secret)),

                                open_dir => {
                                    major => &choice( $dir, $opp ),
                                    minor => &choice( @{$minor_dirs->{$dir}} ),
                                },
                            );
                        }

                        # $t->{_bchkt}{$dir} = 1; # handled above in the span now
                    }
                }
            }
        }
    }

    delete $_->{_bchkt} for map(@$_, @$map); # btw, bchkt stands for: basic doors checked tile [direction]
}
# }}}
# _find_span {{{
sub _find_span {
    my $this = shift;
    my $dir  = shift;
    my $opp  = shift;
    my $t    = shift;
    my $n    = shift;
    my $span = [$t];
    my $nspn = [$n];

    warn "WARNING: something is fishy $t->{x},$t->{y}:$dir nb!> $n->{x},$n->{y}:$opp" unless $t->{nb}{$dir} == $n;
    warn "WARNING: something is fishy $t->{x},$t->{y}:$dir <!nb $n->{x},$n->{y}:$opp" unless $n->{nb}{$opp} == $t;

    my ($ud, $pd) = (qw(n s));
       ($ud, $pd) = (qw(e w)) if $dir eq "n" or $dir eq "s";

    my $ls = 0;
    while( $ls != int @$span ) { $ls = int @$span;
        $t = $span->[0];
        $n = $nspn->[0]; warn "WARNING: something is fishy" unless $n->{nb}{$opp} == $t and $t->{nb}{$dir} == $n;
        if( $t->{od}{$ud} == 1 and (my $c = $t->{nb}{$ud}) ) {
            if( $n->{od}{$ud} == 1 and (my $d = $n->{nb}{$ud}) ) {
                if( $c->{od}{$dir} == 1 ) {
                    unshift @$span, $c;
                    unshift @$nspn, $d;
                }
            }
        }

        $t = $span->[$#{ $span }];
        $n = $nspn->[$#{ $nspn }]; warn "WARNING: something is fishy" unless $n->{nb}{$opp} == $t and $t->{nb}{$dir} == $n;
        if( $t->{od}{$pd} == 1 and (my $c = $t->{nb}{$pd}) ) {
            if( $n->{od}{$pd} == 1 and (my $d = $n->{nb}{$pd}) ) {
                if( $c->{od}{$dir} == 1 ) {
                    push @$span, $c;
                    push @$nspn, $d;
                }
            }
        }
    }

    return ($span, $nspn);
}
# }}}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::GeneratorPlugin::BasicDoors - The basic generator for simple doors.

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    my $map = new Games::RolePlay::MapGen;
    
    $map->add_generator_plugin( "BasicDoors" );

=head1 DESCRIPTION

This module inserts doors all over the map.

It takes the following options (defaults shown):

=head2 The Percentages

      open_room_corridor_door_percent     => { door =>  95, secret =>  2, stuck => 25, locked => 50 },
    closed_room_corridor_door_percent     => { door =>   5, secret => 95, stuck => 10, locked => 30 },
      open_corridor_corridor_door_percent => { door => 0.1, secret => 10, stuck => 25, locked => 50 },
    closed_corridor_corridor_door_percent => { door =>   1, secret => 95, stuck => 10, locked => 30 },
                                                       
Here I would enumerate the precise meaning of each option, but it seems pretty
clear to me.  Here's an example instead. The default options listed above state
that there's a 95.00% chance that a door would be placed on a room/corridor
boundary (without a wall) and that it'd be stuck about 25.00% of the time.

OK, another?  There would be a 0.10% chance of finding a door in the middle of
an open corridor and said door would be hidden 10.00% of the time.

=head2 The Special Case

Notice that there are no room_room settings.  If any two tiles are both
room type tiles, then the tile is skipped unless the tiles are in different
rooms.  If they _are_ in different rooms, then the opening is treated as if
it were a room_corridor opening (whether open or closed).

=head2 max_span

In order to put a door somewhere, and have it make sense, the BasicDoors plugin
builds walls around the door to complete a span and close something off.  It
will not do this for a span larger than max_span.

=head1 SEE ALSO

Games::RolePlay::MapGen

=cut
