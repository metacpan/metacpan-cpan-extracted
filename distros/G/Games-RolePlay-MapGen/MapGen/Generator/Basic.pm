# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen::Generator::Basic;

use common::sense;
use Carp;
use parent q(Games::RolePlay::MapGen::Generator::SparseAndLoops);
use Games::RolePlay::MapGen::Tools qw( choice roll _group irange str_eval );

1;

# gen_room_size {{{
sub gen_room_size {
    my $this = shift;
    my $opts = shift;
     
    my ($xm, $ym) = split /x/, $opts->{min_room_size};
    my ($xM, $yM) = split /x/, $opts->{max_room_size};

    my $x = irange($xm, $xM);
    my $y = irange($ym, $yM);

    die "ERROR: problem generating room size from '$opts->{min_room_size} - $opts->{max_room_size}'" unless $x>0 and $y>0;

    return ($x, $y);
}
# }}}

# mark_things_as_pseudo_rooms {{{
sub mark_things_as_pseudo_rooms {
    my $this   = shift;
    my $map    = shift;
    my $groups = shift;

    # This function assumes all defined {type}s are corridoors and that all {od} are un-broken.

    for my $tile ( map(@$_, @$map) ) {
        if( $tile->{type} ) {

            # Look for those 2x2 corridor-loops starting with familiar upper left corner tiles.
            if( $tile->{od}{e} and $tile->{od}{s} ) {
                my $ul = $tile;
                my $ur = $tile->{nb}{e};
                my $ll = $tile->{nb}{s};

                if( $ur->{od}{s} and $ll->{od}{e} ) {
                    my $lr = $ur->{nb}{s};

                    my $group = &_group;
                       $group->type("pseudo");
                       $group->add_rectangle([$ul->{x}, $ul->{y}], [2,2]);

                    for( $ul, $ur, $ll, $lr) {
                        # $_->{DEBUG_red_mark} = 1;
                        $_->{group} = $group;
                        $_->{type}  = $group->{type};
                    }

                } elsif( (my $um = $ur)->{od}{e} and $ll->{od}{e} ) {
                       $ur = $um->{nb}{e};
                    my $lm = $ll->{nb}{e};

                    if( $lm->{od}{e} and $ur->{od}{s} ) {
                        my $lr = $lm->{nb}{e};

                        my $group = &_group;
                           $group->type("pseudo");
                           $group->add_rectangle([$ul->{x}, $ul->{y}], [3,2]);

                        for( $ul, $um, $ur,
                             $ll, $lm, $lr ) {

                            # $_->{DEBUG_blue_mark} = 1;
                            $_->{group} = $group;
                            $_->{type}  = $group->{type};
                        }

                    }

                } elsif( (my $ml = $ll)->{od}{s} and $ur->{od}{s} ) {
                       $ll = $ml->{nb}{s};
                    my $mr = $ur->{nb}{s};

                    if( $ll->{od}{e} and $mr->{od}{s} ) {
                        my $lr = $ll->{nb}{e};

                        my $group = &_group;
                           $group->type("pseudo");
                           $group->add_rectangle([$ul->{x}, $ul->{y}], [2,3]);

                        for( $ul, $ur,
                             $ml, $mr,
                             $ll, $lr ) {

                            # $_->{DEBUG_blue_mark} = 1;
                            $_->{group} = $group;
                            $_->{type}  = $group->{type};
                        }

                    }
                }
            }
        }
    }

    push @$groups, map($_->{group}, grep {$_->{group}} map(@$_, @$map));
    for my $g (@$groups) {
        $g->{lsize} = $g->enumerate_tiles;
    }
}
# }}}
# drop_rooms {{{
sub drop_rooms {
    my $this   = shift;
    my $opts   = shift;
    my $map    = shift;
    my $groups = shift;

    $opts->{y_size} = $#$map;
    $opts->{x_size} = $#{ $map->[0] };

    for my $rn (1 .. str_eval( $opts->{num_rooms} )) {
        my @size    = $this->gen_room_size( $opts );
           $size[0] = $opts->{x_size} if $size[0] > $opts->{x_size};
           $size[1] = $opts->{y_size} if $size[1] > $opts->{y_size};

        my @possible_locs = (); # [ $j, $i, $score ]
        my $lowest_score  = undef;

        $opts->{t_cb}->() if exists $opts->{t_cb};

        for my $i (0 .. $#$map - $size[1]) {
           my $jend = $#{ $map->[$i] };

           for my $j (0 .. $jend - $size[0]) {

               my $score  = 0;
               my $pseudo = 0;
               for my $x (0 .. $size[0]-1) {
                   for my $y (0 .. $size[1]-1) {
                       my $tile = $map->[$i+$y][$j+$x];

                       if( exists $tile->{type} ) {
                           goto LONGJUMP_PAST_SCORING if $tile->{type} eq "room";

                           if( $tile->{type} eq "corridor" ) {
                               $score += 1.07;

                           } elsif( $tile->{type} eq "pseudo" ) {
                               $tile->{group}{_rd_all} ++;

                               $pseudo = 1;
                           }
                       }
                   }
               }

               if( $pseudo ) {
                   for my $g (grep { $_->{type} eq "pseudo" } @$groups) {
                       if( exists $g->{_rd_all} ) {

                           if( $g->{_rd_all} == $g->{lsize} ) {
                               $score += ( $g->{lsize} == 6 ? 1.01 : 1.03 );

                           } elsif( $g->{lsize} == 6 and $g->{_rd_all} == 4 ) {
                               $score += 1.05;

                           } else {
                               $score += 1.07 * 4;

                           }

                           delete $g->{_rd_all};
                           $pseudo = 0;
                       } 
                   }
               }

               if( $score > 0 ) {
                   if( not defined $lowest_score or $score < $lowest_score ) {
                       $lowest_score = $score;
                       @possible_locs = grep { $_->[2] <= $lowest_score } @possible_locs;
                   }

                   push @possible_locs, [ $j, $i, $score ] if $score <= $lowest_score;
               }

               LONGJUMP_PAST_SCORING: 
               # This is a way of short-cutting much looping when we're not
               # going to be putting the room there anyway.
           }
        }

        if( my $loc = choice( @possible_locs ) ) {
            my @corridors = ();

            pop @$loc; # ditch the score.

            my $group = &_group;
               $group->name( "Room #$rn" );
               $group->type( "room" );
               $group->add_rectangle( [@$loc], [@size] );

            my @tiles = $group->enumerate_tiles;
            my ($xmin, $ymin, $xmax, $ymax) = $group->enumerate_extents;

            for my $tl ( @tiles ) {
                my ($x,$y) = @$tl;
                my $tile = $map->[ $y ][ $x ];

                if( exists $tile->{type} ) {
                    if( $tile->{type} eq "corridor" or $tile->{type} eq "pseudo" ) {
                        push @corridors, [ w => $tile ] if $x == $xmin and $tile->{od}{w};
                        push @corridors, [ n => $tile ] if $y == $ymin and $tile->{od}{n};
                        push @corridors, [ e => $tile ] if $x == $xmax and $tile->{od}{e};
                        push @corridors, [ s => $tile ] if $y == $ymax and $tile->{od}{s};
                    }
                }

                $tile->{type}  = "room";
                $tile->{group} = $group;
                for my $dir (qw(n e s w)) {
                    $tile->{od}{$dir} = 1; # open every direction... close edges below

                    if( my $n = $tile->{nb}{$dir} ) {
                        $n->{od}{$Games::RolePlay::MapGen::opp{$dir}} = 1;
                    }
                }
                # $tile->{DEBUG_green_mark} = 1;
            }

            for my $y ($ymin .. $ymax) {
                (my $west = $map->[$y][ $xmin ])->{od}{w} = 0;
                (my $east = $map->[$y][ $xmax ])->{od}{e} = 0;

                if( my $west_n = $west->{nb}{w} ) {
                    $west_n->{od}{e} = 0;
                }

                if( my $east_n = $east->{nb}{e} ) {
                    $east_n->{od}{w} = 0;
                }
            }

            for my $x ($xmin .. $xmax) {
                (my $north = $map->[ $ymin ][$x])->{od}{n} = 0;
                (my $south = $map->[ $ymax ][$x])->{od}{s} = 0;

                if( my $north_n = $north->{nb}{n} ) {
                    $north_n->{od}{s} = 0;
                }

                if( my $south_n = $south->{nb}{s} ) {
                    $south_n->{od}{n} = 0;
                }
            }

            # By default, tiles will be open between the new rooms and the corridors they stomped
            for my $a (@corridors) {
                my $t = $a->[1];
                my $n = $t->{nb}{$a->[0]};

                $t->{od}{$a->[0]} = $n->{od}{$Games::RolePlay::MapGen::opp{$a->[0]}} = 1;
            }

            push @$groups, $group;
        }

    }
}
# }}}
# cleanup_pseudo_rooms {{{
sub cleanup_pseudo_rooms {
    my $this   = shift;
    my $map    = shift;
    my $groups = shift;
    my @pseudo = ();

    @$groups = grep { my $r = 1; if( $_->{type} eq "pseudo" ) { push @pseudo, $_; $r = 0 } $r } @$groups;

    for my $group (@pseudo) {

        my $intact = 1;
        my @tofix  = ();
        for my $tl ($group->enumerate_tiles) {
            my $tile = $map->[$tl->[1]][$tl->[0]];

            # $tile->{DEBUG_red_mark} = 1;

            if( $tile->{type} eq "pseudo" ) {
                $tile->{type} = "corridor";
                push @tofix, $tile;

            } else {
                $intact = 0;
            }
        }

        my ($xmin, $ymin, $xmax, $ymax) = $group->enumerate_extents;
        if( $intact ) {
            for my $tile (@tofix) {
                $tile->{od}{n} = 1 if $tile->{y} > $ymin;
                $tile->{od}{s} = 1 if $tile->{y} < $ymax;
                $tile->{od}{e} = 1 if $tile->{x} < $xmax;
                $tile->{od}{w} = 1 if $tile->{x} > $xmin;
            }
        }
    }

    for my $tile (grep {$_->{group}} map {@$_} @$map) {
        delete $tile->{group}
            if $tile->{group}{type} eq "pseudo";
    }
}
# }}}

# genmap {{{
sub genmap {
    my $this = shift;
    my $opts = $this->gen_opts(%{ $_[0] });
    my ($map, $groups) = $this->SUPER::genmap(@_);

    # There are a few types of random corridors that look enough like rooms
    # That I didn't think they should count against the room drop score below.
    # In fact, we'd really rather cover them up if possible.
    $this->mark_things_as_pseudo_rooms( $map, $groups );
    $this->drop_rooms( $opts, $map, $groups );
    $this->cleanup_pseudo_rooms( $map, $groups );

    return ($map, $groups);
}
# }}}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::Generator::Basic - The basic random bounded dungeon generator

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    my $map = new Games::RolePlay::MapGen;
    
    $map->set_generator( "Games::RolePlay::MapGen::Generator::Basic" );

    generate $map;

=head1 DESCRIPTION

This module really just drops rooms onto Jamis Buck's fantastic maze generator.

=head1 SEE ALSO

Games::RolePlay::MapGen, Games::RolePlay::MapGen::Generator::Perfect, Games::RolePlay::MapGen::Generator::SparseAndLoops

=cut
