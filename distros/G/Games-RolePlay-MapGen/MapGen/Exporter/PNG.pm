# vi:set filetype=perl:

package Games::RolePlay::MapGen::Exporter::PNG;

use common::sense;
use Carp;
use GD;
use Math::Trig qw(deg2rad);

1;

# new {{{
sub new {
    my $class = shift;
    my $this  = bless {o => {@_}}, $class;

    return $this;
}
# }}}
# go {{{
sub go {
    my $this = shift;
    my $opts = {@_};

    for my $k (keys %{ $this->{o} }) {
        $opts->{$k} = $this->{o}{$k} if not exists $opts->{$k};
    }

    croak "ERROR: fname is a required option for " . ref($this) . "::go()" unless $opts->{fname};
    croak "ERROR: _the_map is a required option for " . ref($this) . "::go()" unless ref($opts->{_the_map});

    my $map = $this->genmap($opts);
    unless( $opts->{fname} eq "-retonly" ) {
        open _MAP_OUT, ">$opts->{fname}" or die "ERROR: couldn't open $opts->{fname} for write: $!";
        print _MAP_OUT $map->png; # the format should really be an option... at some point
        close _MAP_OUT;
    }

    return $map;
}
# }}}

# gen_cell_size {{{
sub gen_cell_size {
    my $this = shift;
    my $opts = shift;

    if( $opts->{cell_size} ) {
        die "ERROR: illegal cell size '$opts->{cell_size}'" unless $opts->{cell_size} =~ m/^(\d+)x(\d+)/;
        $opts->{x_size} = $1;
        $opts->{y_size} = $2;
    }
}
# }}}
# genmap {{{
sub genmap {
    my $this = shift;
    my $opts = shift;
    my $map  = $opts->{_the_map};

    $this->gen_cell_size($opts);

    my $gd     = new GD::Image(1+($opts->{x_size} * @{$map->[0]}), 1+($opts->{y_size} * @$map));

    my $white  = $gd->colorAllocate(0xff, 0xff, 0xff);
    my $black  = $gd->colorAllocate(0x00, 0x00, 0x00);
    my $elgrey = $gd->colorAllocate(0xf5, 0xf5, 0xf5); # extremely light grey
    my $vlgrey = $gd->colorAllocate(0xe5, 0xe5, 0xe5); # very light grey
    my $lgrey  = $gd->colorAllocate(0xcc, 0xcc, 0xcc);
    my $dgrey  = $gd->colorAllocate(0x60, 0x60, 0x60);
    my $grey   = $gd->colorAllocate(0x90, 0x90, 0x90);
    my $blue   = $gd->colorAllocate(0x00, 0x00, 0xbb);
    my $red    = $gd->colorAllocate(0xbb, 0x00, 0x00);
    my $green  = $gd->colorAllocate(0x00, 0xbb, 0x00);
    my $purple = $gd->colorAllocate(0xff, 0x00, 0xff);
    my $brown  = $gd->colorAllocate(0xaa, 0x90, 0x00);

    my $door_arc_color     = $lgrey;
    my $door_color         = $brown;
    my $wall_color         = $black;
    my $fog_tile_color     = $lgrey;  # fog-tile color
    my $wall_tile_color    = $dgrey;  # wall-tile color
    my $corridor_color     = $white;  # corridor-tile color
    my $open_color1        = $elgrey; # tile edges
    my $open_color2        = $vlgrey; # tile ticks

    my $D     = 5; # the border around debugging marks
    my $B     = 1; # the border around the filled rectangles for empty tiles
    my $L     = 1; # the length of the cell ticks in open borders
       $L++;       # $L is one less than it seems...

    my ($dm, $dM) = (1, 4); # akin to L, but for doors (door minor horrizontal, door minor vertical and door major)
    my ($sm, $sM) = (3, 8); # status mark dimensions
    my ($wx, $wy) = ( $opts->{x_size}*2-$dM*4, $opts->{y_size}*2-$dM*4 ); # the width and height of the door-arcs (cell size)

    my $am = $dm +1; # the arc displacement is just a little bigger so it doesn't overlap the doors...

    my $oa = 45;  # show doors open by this amount
    my $do = $oa; # show doors the same amount? or a little bit different?
       $do -= 10; # this looks kinda neat.

    my $or = deg2rad( $do );
    my $sr = sin( $or ); # we'll be using this, kthx...

    GRID: {
        my $x = @{$map->[0]}*$opts->{x_size};
        my $y;

        for my $i (0 .. @$map) {
            $y = $i*$opts->{y_size};

            $gd->line( (0, $y) => ($x, $y) => $wall_color );
        }

        $y = @$map*$opts->{y_size};
        for my $i (0 .. @{$map->[0]}) {
            $x = $i*$opts->{x_size};

            my $r = $gd->line( ($x, 0) => ($x, $y) => $wall_color );
        }
    }

    for my $i (0 .. $#$map) {
        my $jend = $#{$map->[$i]};

        for my $j (0 .. $jend) {
            my $t  = $map->[$i][$j];
            my $xp = $j  * $opts->{x_size}; # min x
            my $yp = $i  * $opts->{y_size}; # min y
            my $Xp = $xp + $opts->{x_size}; # max x
            my $Yp = $yp + $opts->{y_size}; # max y

            my $ns_l = (($Xp-$dM) - ($xp+$dM));  # for the doors...
            my $ew_l = (($Yp-$dM) - ($yp+$dM));
            my $ns_h = int ($ns_l * $sr);
            my $ew_h = int ($ew_l * $sr);
            my $ns_b = int( sqrt( $ns_l ** 2 - $ns_h ** 2 ) );
            my $ew_b = int( sqrt( $ew_l ** 2 - $ew_h ** 2 ) );

            $opts->{t_cb}->() if exists $opts->{t_cb};

            $gd->line( $xp+$L, $yp     => $Xp-$L, $yp,    $open_color1 ) if $t->{od}{n} == 1; # == 1 doesn't match doors...
            $gd->line( $xp,    $yp+$L, => $xp,    $Yp-$L, $open_color1 ) if $t->{od}{w} == 1;

            if( $t->{od}{n} == 1 and $t->{od}{w} == 1 ) { # == 1 doesn't match doors
                if( $t->{nb}{n}{od}{w} == 1 and $t->{nb}{w}{od}{n} == 1 ) {
                    $gd->line( $xp-$L, $yp    => $xp+$L, $yp,    $open_color2 );
                    $gd->line( $xp,    $yp-$L => $xp,    $yp+$L, $open_color2 );
                }
            }

            if( not $t->{type} ) {
                $gd->filledRectangle( $xp+$B, $yp+$B => $Xp-$B, $Yp-$B, $wall_tile_color );

            } elsif( $t->{type} eq "fog" ) {
                my ($_xm, $_ym) = (0,0);
                my ($_Xm, $_Ym) = (0,0);

                $_xm -- if (my $wf = ($t->{nb}{w}{type} and $t->{nb}{w}{type} eq "fog"));
                $_ym -- if (my $nf = ($t->{nb}{n}{type} and $t->{nb}{n}{type} eq "fog"));
                            my $ef = ($t->{nb}{e}{type} and $t->{nb}{e}{type} eq "fog");
                            my $sf = ($t->{nb}{s}{type} and $t->{nb}{s}{type} eq "fog");

                $_xm += 3 if not $wf and $t->{od}{w};
                $_ym += 3 if not $nf and $t->{od}{n};
                $_Xm -= 3 if not $ef and $t->{od}{e};
                $_Ym -= 3 if not $sf and $t->{od}{s};

                $gd->filledRectangle( $xp+$B+$_xm, $yp+$B+$_ym => $Xp-$B+$_Xm, $Yp-$B+$_Ym, $fog_tile_color );

            } elsif( $t->{type} eq "corridor" and $corridor_color != $white ) {
                $gd->filledRectangle( $xp+$B, $yp+$B => $Xp-$B, $Yp-$B, $corridor_color );
            }

            # NOTE: we never need to draw s and e doors, that just duplicates efforts
            for my $dir (qw(n w)) {
                if( ref(my $door = $t->{od}{$dir}) ) {
                    my @q1 = ( $dir eq "n" ? ($xp+$dM, $yp-$dm) : ($xp-$dm, $yp+$dM) );
                    my @q2 = ( $dir eq "n" ? ($Xp-$dM, $yp+$dm) : ($xp+$dm, $Yp-$dM) );

                    if( not $door->{secret} and not $door->{'open'} ) {
                        # Regular old unlocked, open, unstock, unhidden doors are these cute little rectangles.

                        $gd->filledRectangle( @q1 => @q2, $door_color );
                    }

                    if( $door->{'open'} ) {
                        $gd->filledRectangle( @q1 => @q2, $white );
                    }

                    # Here, we draw the diagonal line and arc indicating how the door opens.
                    my $oi = "$dir$door->{open_dir}{major}$door->{open_dir}{minor}";

                    # draw the door line/arcs ... sadly, this is a 8 part if-else block {{{
                    if( $oi eq "nne" ) {  # same as above, but $Yp changes to $yp
                        $gd->arc(  $Xp-$dM, $yp-$am, $wx, $wy, 180, 180+$oa, $door_arc_color );
                        my @l = (  $Xp-$dM, $yp-$am => ($Xp-$dM)-$ns_b, $yp-$am-$ns_h  );
                        if( $door->{'open'} and not $door->{secret} ) {
                            $gd->line(@l, $door_color); $l[1]+=1; $l[3]+=1;
                            $gd->line(@l, $door_color); $l[1]-=2; $l[3]-=2;
                            $gd->line(@l, $door_color);

                        } else {
                            $gd->line(@l, $door_arc_color);
                        }

                    } elsif( $oi eq "nse" ) {  # same as above, but $Yp to $yp
                        $gd->arc(  $Xp-$dM, $yp+$am, $wx, $wy, 180-$oa, 180, $door_arc_color );
                        my @l = (  $Xp-$dM, $yp+$am => ($Xp-$dM)-$ns_b, $yp+$am+$ns_h  );
                        if( $door->{'open'} and not $door->{secret} ) {
                            $gd->line(@l, $door_color); $l[1]+=1; $l[3]+=1;
                            $gd->line(@l, $door_color); $l[1]-=2; $l[3]-=2;
                            $gd->line(@l, $door_color);

                        } else {
                            $gd->line(@l, $door_arc_color);
                        }

                    } elsif( $oi eq "nnw" ) { # same as above, but $yp
                        $gd->arc(  $xp+$dM, $yp-$am, $wx, $wy, 360-$oa, 360, $door_arc_color );
                        my @l = (  $xp+$dM, $yp-$am => ($xp+$dM)+$ns_b, $yp-$am-$ns_h  );
                        if( $door->{'open'} and not $door->{secret} ) {
                            $gd->line(@l, $door_color); $l[1]+=1; $l[3]+=1;
                            $gd->line(@l, $door_color); $l[1]-=2; $l[3]-=2;
                            $gd->line(@l, $door_color);

                        } else {
                            $gd->line(@l, $door_arc_color);
                        }

                    } elsif( $oi eq "nsw" ) { # same as above, but $yp
                        $gd->arc(  $xp+$dM, $yp+$am, $wx, $wy, 360, 360+$oa, $door_arc_color );
                        my @l = (  $xp+$dM, $yp+$am => ($xp+$dM)+$ns_b, $yp+$am+$ns_h  );
                        if( $door->{'open'} and not $door->{secret} ) {
                            $gd->line(@l, $door_color); $l[1]+=1; $l[3]+=1;
                            $gd->line(@l, $door_color); $l[1]-=2; $l[3]-=2;
                            $gd->line(@l, $door_color);

                        } else {
                            $gd->line(@l, $door_arc_color);
                        }

                    } elsif( $oi eq "wen" ) { # same as above but $Xp to $xp
                        $gd->arc(  $xp+$am, $yp+$dM, $wx, $wy, 90-$oa, 90, $door_arc_color );
                        my @l = (  $xp+$am, $yp+$dM => $xp+$am+$ew_h, ($yp+$dM)+$ew_b  );
                        if( $door->{'open'} and not $door->{secret} ) {
                            $gd->line(@l, $door_color); $l[1]+=1; $l[3]+=1;
                            $gd->line(@l, $door_color); $l[1]-=2; $l[3]-=2;
                            $gd->line(@l, $door_color);

                        } else {
                            $gd->line(@l, $door_arc_color);
                        }

                    } elsif( $oi eq "wwn" ) { # same as above but $Xp to $xp
                        $gd->arc(  $xp-$am, $yp+$dM, $wx, $wy, 90, 90+$oa, $door_arc_color );
                        my @l = (  $xp-$am, $yp+$dM => $xp-$am-$ew_h, ($yp+$dM)+$ew_b  );
                        if( $door->{'open'} and not $door->{secret} ) {
                            $gd->line(@l, $door_color); $l[1]+=1; $l[3]+=1;
                            $gd->line(@l, $door_color); $l[1]-=2; $l[3]-=2;
                            $gd->line(@l, $door_color);

                        } else {
                            $gd->line(@l, $door_arc_color);
                        }

                    } elsif( $oi eq "wes" ) { # same as above, but $xp
                        $gd->arc(  $xp+$am, $Yp-$dM, $wx, $wy, 270, 270+$oa, $door_arc_color );
                        my @l = (  $xp+$am, $Yp-$dM => $xp+$am+$ew_h, ($Yp-$dM)-$ew_b  );
                        if( $door->{'open'} and not $door->{secret} ) {
                            $gd->line(@l, $door_color); $l[1]+=1; $l[3]+=1;
                            $gd->line(@l, $door_color); $l[1]-=2; $l[3]-=2;
                            $gd->line(@l, $door_color);

                        } else {
                            $gd->line(@l, $door_arc_color);
                        }

                    } elsif( $oi eq "wws" ) { # same as above, but $xp
                        $gd->arc(  $xp-$am, $Yp-$dM, $wx, $wy, 270-$oa, 270, $door_arc_color );
                        my @l = (  $xp-$am, $Yp-$dM => $xp-$am-$ew_h, ($Yp-$dM)-$ew_b  );
                        if( $door->{'open'} and not $door->{secret} ) {
                            $gd->line(@l, $door_color); $l[1]+=1; $l[3]+=1;
                            $gd->line(@l, $door_color); $l[1]-=2; $l[3]-=2;
                            $gd->line(@l, $door_color);

                        } else {
                            $gd->line(@l, $door_arc_color);
                        }

                    }
                    # }}}

                    unless( $door->{'open'} ) {
                        if( $door->{locked} ) {
                            my @l1 = ( $dir eq "n" ? ($xp+$sM, $yp-$sm) : ($xp-$sm, $yp+$sM) );
                            my @l2 = ( $dir eq "n" ? ($xp+$sM, $yp+$sm) : ($xp+$sm, $yp+$sM) );

                            $gd->line( @l1 => @l2 => $red );
                        }

                        if( $door->{stuck} ) {
                            my @l1 = ( $dir eq "n" ? ($Xp-$sM, $yp-$sm) : ($xp-$sm, $Yp-$sM) );
                            my @l2 = ( $dir eq "n" ? ($Xp-$sM, $yp+$sm) : ($xp+$sm, $Yp-$sM) );

                            $gd->line( @l1 => @l2 => $blue );
                        }
                    }
                }
            }

            if( $t->{DEBUG_red_mark} ) {
                $gd->filledRectangle( $xp+$D, $yp+$D => $Xp-$D, $Yp-$D, $red );
            }

            if( $t->{DEBUG_blue_mark} ) {
                $gd->filledRectangle( $xp+$D, $yp+$D => $Xp-$D, $Yp-$D, $blue );
            }

            if( $t->{DEBUG_green_mark} ) {
                $gd->filledRectangle( $xp+$D, $yp+$D => $Xp-$D, $Yp-$D, $green );
            }

            if( $t->{DEBUG_purple_mark} ) {
                $gd->filledRectangle( $xp+$D, $yp+$D => $Xp-$D, $Yp-$D, $purple );
            }
        }
    }

    for my $t (map(@$_, @$map)) {
        for my $d (keys %{ $t->{od} }) {
            if( ref( my $door = $t->{od}{$d} ) ) {
                delete $door->{_drawn};
            }
        }
    }

    return $gd;
}
# }}}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::Exporter::PNG - A pure text mapgen exporter.

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    my $map = new Games::RolePlay::MapGen;

=head1 SEE ALSO

Games::RolePlay::MapGen

=cut
