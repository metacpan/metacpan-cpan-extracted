# vi:filetype=perl:

package Games::RolePlay::MapGen::MapQueue;

use common::sense;
use Carp;
use Exporter;
use Math::Trig;
use Math::Round;
use List::Util qw(min max);
use Storable qw(freeze thaw);
use constant {
    LOS_NO              => 0,
    LOS_YES             => 1,

    LOS_NO_COVER        => 0,
    LOS_COVER           => 1,
    LOS_DOUBLE_COVER    => 2,
};

our @ISA = qw(Exporter);
our @EXPORT = qw(LOS_NO LOS_YES LOS_NO_COVER LOS_IGNORABLE_COVER LOS_COVER LOS_DOUBLE_COVER);

our $LOS_CREATURE_RADIUS = 0.19; # used for double-cover check
our $LOS_LHS_BONUS       = 0.05_777; # slight advantage for being closer to obstruction
our $EXTRUDE_POINTS      =    4;
our $CLOS_MIN_ANGLE      = deg2rad(9); # the minimum angle between our LOS and the closure where we can still tell if there's a door on that wall

*_line_of_sight         = *_line_of_sight_xs;
*_tight_line_of_sight   = *_tight_line_of_sight_xs;
*_ranged_cover          = *_ranged_cover_xs;
*_melee_cover           = *_melee_cover_xs;
*_closure_line_of_sight = *_closure_line_of_sight_xs;

use Memoize qw(memoize flush_cache);
  memoize( _line_of_sight                        => NORMALIZER => sub { "$_[0] @{$_[1]} @{$_[2]}" } );
  memoize( _tight_line_of_sight                  => NORMALIZER => sub { "$_[0] @{$_[1]} @{$_[2]}" } );
  memoize( _ranged_cover                         => NORMALIZER => sub { "$_[0] @{$_[1]} @{$_[2]}" } );
  memoize( _melee_cover                          => NORMALIZER => sub { "$_[0] @{$_[1]} @{$_[2]}" } );
  memoize( _ignorable_cover                      => NORMALIZER => sub { "$_[0] @{$_[1]} @{$_[2]}" } );
  memoize( _locations_in_line_of_sight           => NORMALIZER => sub { "$_[0] @{$_[1]}"          } );
  memoize( _locations_in_range_and_line_of_sight => NORMALIZER => sub { "$_[0] @{$_[1]} $_[2]"    } );
  memoize( _locations_in_path                    => NORMALIZER => sub { "$_[0] @{$_[1]} @{$_[2]}" } );
  memoize( _closure_line_of_sight                => NORMALIZER => sub { "$_[0] @{$_[1]} @{$_[2]}" } );

our @toflush = qw( _line_of_sight _tight_line_of_sight _ranged_cover _melee_cover _ignorable_cover
    _locations_in_line_of_sight _locations_in_range_and_line_of_sight
    _locations_in_path _closure_line_of_sight );

use Games::RolePlay::MapGen;
require XSLoader; XSLoader::load('Games::RolePlay::MapGen', $Games::RolePlay::MapGen::VERSION);

# new {{{
sub new {
    my $class = shift;
    my $the_m = shift;
    my $this = bless { o=>{}, c=>[] }, $class;

    croak "where is _the_map?" unless ref $the_m;
    $the_m = $the_m->{_the_map};
    $this->{_the_map} = $the_m;

    $this->{ym} = $#{ $the_m };
    $this->{xm} = $#{ $the_m->[0] };

    return $this;
}
# }}}
# retag {{{
sub retag {
    my $this = shift;

    my $tags = {};
    for my $row ( 0 .. $this->{ym} ) {
        for my $col ( 0 .. $this->{xm} ) {
            my $rhs = [ $col, $row ];

            for my $o (@{ $this->{c}[ $rhs->[1] ][ $rhs->[0] ] || [] }) {
                $tags->{"$o"} = $rhs;
            }
        }
    }

    $this->{l} = $tags;
}
# }}}
# flush {{{
sub flush {
    flush_cache($_) for @toflush
}
# }}}

# _check_loc {{{
sub _check_loc {
    my $this = shift;
    my $loc  = shift;

    return 0 if @$loc != 2;
    return 0 if $loc->[0] < 0;
    return 0 if $loc->[1] < 0;
    return 0 if $loc->[0] > $this->{xm};
    return 0 if $loc->[1] > $this->{ym};

    my $type = $this->{_the_map}[ $loc->[1] ][ $loc->[0] ]{type};
    return 0 unless $type; # the wall type is <undef>

    return $loc;
}
# }}}
# _od_segments {{{
sub _od_segments {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    ## DEBUG ## warn "SET\n<@$lhs> <@$rhs>\n";

    my @X = sort {$a<=>$b} ($lhs->[0], $rhs->[0]); @X = ($X[0] .. $X[1]);
    my @Y = sort {$a<=>$b} ($lhs->[1], $rhs->[1]); @Y = ($Y[0] .. $Y[1]);

    my $x_dir = ($lhs->[0] < $rhs->[0] ? "e" : "w");
    my $y_dir = ($lhs->[1] < $rhs->[1] ? "s" : "n");

    my @od_segments = (); # the solid line segments we might have to pass through
    for my $x (@X[0 .. $#X]) {
        for my $y (@Y[0 .. $#Y]) {
            my $x_od = $this->{_the_map}[ $y ][ $x ]{od}{ $x_dir };
            my $y_od = $this->{_the_map}[ $y ][ $x ]{od}{ $y_dir };

            for( $x_od, $y_od ) {
                $_ = $_->{'open'} if ref $_;
            }

            unless( $x_od or $x == ($x_dir eq "e" ? $X[$#X]:$X[0]) ) {
                if( $x_dir eq "e" ) { push @od_segments, [[ $x+1, $y ] => [$x+1, $y+1]] }
                else                { push @od_segments, [[ $x,   $y ] => [$x,   $y+1]] }
            }

            unless( $y_od or $y == ($y_dir eq "s" ? $Y[$#Y]:$Y[0]) ) {
                if( $y_dir eq "s" ) { push @od_segments, [[ $x, $y+1 ] => [$x+1, $y+1]] }
                else                { push @od_segments, [[ $x, $y   ] => [$x+1, $y  ]] }
            }
        }
    }

    ## DEBUG ## warn "(@{$_->[0]})->(@{$_->[1]})\n" for @od_segments;
    ## DEBUG ## warn "DONE\n";

    return @od_segments;
}
# }}}
# _extrude_point {{{
sub _extrude_point {
    # extrude a point into a tile or a sub-tile
    my $this    = shift;
    my $point   = shift;
    my $use_ocr = shift; # use our creature radius
    my $use_lhs = shift; # use our lhs bonus

    die "EXTRUDE_POINTS=$EXTRUDE_POINTS must be an even integer" unless $EXTRUDE_POINTS >= 2 and not $EXTRUDE_POINTS =~ m/\./
                                                                 and not $EXTRUDE_POINTS & 1; # needed for closure_line_of_sight

    my $s = ($use_ocr ? 0.50-$LOS_CREATURE_RADIUS-($use_lhs ? $LOS_LHS_BONUS : 0) : 0.0001);
    my $e = ($use_ocr ? 0.50+$LOS_CREATURE_RADIUS+($use_lhs ? $LOS_LHS_BONUS : 0) : 0.9999);
    my $i = ( abs($s-$e) / ($EXTRUDE_POINTS-1) );

    my @r = (
        [$point->[0] + $s, $point->[1] + $s],
        [$point->[0] + $e, $point->[1] + $s],
        [$point->[0] + $s, $point->[1] + $e],
        [$point->[0] + $e, $point->[1] + $e],
    );

    ## DEBUG ## return @r; # psh> require "MapGen/MapQueue.pm"; d[ Games::RolePlay::MapGen::MapQueue->_extrude_point([5,5]) ]

    my $c = $s+$i;
    while( $c < $e ) {
        push @r, 
            [$point->[0] + $c, $point->[1] + $s],
            [$point->[0] + $s, $point->[1] + $c],
            [$point->[0] + $c, $point->[1] + $e],
            [$point->[0] + $e, $point->[1] + $c],
        ;$c += $i;
    }

    # use Data::Dumper; $Data::Dumper::Indent = $Data::Dumper::Sortkeys = 0;
    # warn Dumper([$s, $e, $i, \@r]);

    my %h;
    return grep {my $x = not $h{"@$_"}; $h{"@$_"}=1; $x} @r;
}
# }}}
# _tight_line_of_sight_xs {{{
sub _tight_line_of_sight_xs {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    return LOS_YES if "@$lhs" eq "@$rhs";

    my @ods = $this->_od_segments(@_);
    my @lhs = $this->_extrude_point( $lhs, 1,1 ); # ocr,lhs
    my @rhs = $this->_extrude_point( $rhs, 1,0 );

    return LOS_YES if &Games::RolePlay::MapGen::MapQueue::any_any_los_loop(\@lhs, \@rhs, \@ods);
    return LOS_NO;
}
# }}}
# _tight_line_of_sight_pl {{{
sub _tight_line_of_sight_pl {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    return LOS_YES if "@$lhs" eq "@$rhs";

    my @od_segments = $this->_od_segments(@_);

    my @lhs = $this->_extrude_point( $lhs, 1,1 ); # ocr,lhs
    my @rhs = $this->_extrude_point( $rhs, 1,0 );

    ##---------------- LOS CALC
    my $line = 0;

    ## DEBUG ## warn "SET\n";
    ## DEBUG ## warn "\@target: <@$rhs>\n";
    ## DEBUG ## warn "wall: (@{$_->[0]})->(@{$_->[1]})\n" for @od_segments;
    LOS_CHECK:
    for my $l (@lhs) {
    for my $r (@rhs) {
        my $this_line = 1;

        OD_CHECK:
        for my $od_segment (@od_segments) {
            if( $this->_line_segments_intersect( (map {@$_} @$od_segment) => (@$l=>@$r) ) ) {
                $this_line = 0;

                last OD_CHECK;
            }
        }

        if( $this_line ) {
            ## DEBUG ## warn "LOS: (@$l)->(@$r)\n";
            $line = 1;
            last LOS_CHECK;
        }
    }}
    ## DEBUG ## warn "DONE\n";

    return LOS_NO unless $line;
    return LOS_YES; # cover needs to be double checked
}
# }}}
# _line_of_sight_xs {{{
sub _line_of_sight_xs {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    return LOS_YES if "@$lhs" eq "@$rhs";

    my @ods = $this->_od_segments(@_);
    my @lhs = $this->_extrude_point( $lhs, 0,0 ); # ocr,lhs
    my @rhs = $this->_extrude_point( $rhs, 0,0 );

    return LOS_YES if &Games::RolePlay::MapGen::MapQueue::any_any_los_loop(\@lhs, \@rhs, \@ods);
    return LOS_NO;
}
# }}}
# _line_of_sight_pl {{{
sub _line_of_sight_pl {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    return LOS_YES if "@$lhs" eq "@$rhs";

    my @od_segments = $this->_od_segments(@_);

    my @lhs = $this->_extrude_point( $lhs, 0,0 ); # ocr,lhs
    my @rhs = $this->_extrude_point( $rhs, 0,0 );

    # warn "LHS: " . join(" ", map(sprintf('<%9.6f, %9.6f>', @$_), @lhs));
    # warn "RHS: " . join(" ", map(sprintf('[%9.6f, %9.6f]', @$_), @rhs));
    # warn "ODS: " . join(" ", map(sprintf('(%9.6f, %9.6f)->(%9.6f, %9.6f)', @{$_->[0]}, @{$_->[1]}), @od_segments));

    my $line = 0;

    ## DEBUG ## warn "---------- LOS @$lhs => @$rhs\n";

    LOS_CHECK:
    for my $l (@lhs) {
    for my $r (@rhs) {
        my $this_line = 1;

        OD_CHECK:
        for my $od_segment (@od_segments) {
            if( $this->_line_segments_intersect( (map {@$_} @$od_segment) => (@$l=>@$r) ) ) {
                $this_line = 0;

                last OD_CHECK;
            }
        }

        if( $this_line ) {
            ## DEBUG ## warn "\tfound: (@$l)->(@$r)\n";
            $line = 1;
            last LOS_CHECK;
        }
        ## DEBUG ## else { warn "\treject: (@$l)->(@$r)\n"; }
    }}

    return LOS_NO unless $line;
    return LOS_YES; # cover needs to be double checked
}
# }}}
# _ranged_cover_pl {{{
sub _ranged_cover_pl {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    return LOS_NO_COVER if "@$lhs" eq "@$rhs";

    my @od_segments = $this->_od_segments(@_);

    my @lhs = $this->_extrude_point( $lhs, 0,0 ); # ocr,lhs
    my @rhs = $this->_extrude_point( $rhs, 0,0 );
    
    for my $l (@lhs) {
        my $cover = 0;

        ## DEBUG ## warn "SET\n";
        ## DEBUG ## warn "<@$lhs> <@$rhs>\n";

        RCRHS: for my $r (@rhs) {
            for my $od_segment (@od_segments) {
                if( $this->_line_segments_intersect( (map {@$_} @$od_segment) => (@$l=>@$r) ) ) {
                    ## DEBUG ## warn "SET\n<@$lhs> <@$rhs>\n";
                    ## DEBUG ## warn "(@{$od_segment->[0]})->(@{$od_segment->[1]}) (@$l)->(@$r)\n";
                    ## DEBUG ## warn "DONE\n";
                    $cover = 1;
                    last RCRHS;
                }
            }
        }

        ## DEBUG ## warn "DONE\n";

        # for ranged cover, if we can find even one lhs corner that can see all the rhs corners
        # then we return LOS_NO_COVER;
        unless( $cover ) {
            ## DEBUG ## warn "\e[32m here(@$l) \e[m";
            # NOTE: this cover-upgrade _not_ d20 rules:
            return LOS_COVER unless $this->_tight_line_of_sight( $lhs => $rhs );
            return LOS_NO_COVER;
        }
    }

    ## DEBUG ## warn "\e[32m here(---) \e[m";

    # NOTE: this cover-upgrade is _not_ d20 rules:
    return LOS_DOUBLE_COVER unless $this->_tight_line_of_sight( $lhs => $rhs );
    return LOS_COVER;
}
# }}}
# _ranged_cover_xs {{{
sub _ranged_cover_xs {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    return LOS_NO_COVER if "@$lhs" eq "@$rhs";

    my @ods = $this->_od_segments(@_);
    my @lhs = $this->_extrude_point( $lhs, 0,0 ); # ocr,lhs
    my @rhs = $this->_extrude_point( $rhs, 0,0 );

    if( &Games::RolePlay::MapGen::MapQueue::any_all_los_loop(\@lhs, \@rhs, \@ods) ) {
        ## DEBUG ## warn "\e[31m here(@@@) \e[m";
        return LOS_COVER unless $this->_tight_line_of_sight( $lhs => $rhs );
        return LOS_NO_COVER;
    }

    ## DEBUG ## warn "\e[31m here(---) \e[m";

    return LOS_DOUBLE_COVER unless $this->_tight_line_of_sight( $lhs => $rhs );
    return LOS_COVER;
}
# }}}
# _melee_cover_pl {{{
sub _melee_cover_pl {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    # NOTE: Let the caller figure this out?  Different creatures have different
    # reach and reach weapons should be using ranged_cover() anyway.  On the
    # other hand, this map-logic doesn't even begin to consider creatures that
    # take up more than one tile...

    return LOS_NO_COVER if abs($lhs->[0]-$rhs->[0]) > 1;
    return LOS_NO_COVER if abs($lhs->[1]-$rhs->[1]) > 1;

    # end_NOTE

    my @od_segments = $this->_od_segments(@_);

    my @lhs = $this->_extrude_point( $lhs, 0,0 ); # ocr,lhs
    my @rhs = $this->_extrude_point( $rhs, 0,0 );
    
    for my $l (@lhs) {
    for my $r (@rhs) {
        my $cover = 0;

        for my $od_segment (@od_segments) {
            if( $this->_line_segments_intersect( (map {@$_} @$od_segment) => (@$l=>@$r) ) ) {
                # This short circuits quickly half the time (on average).  If
                # there's cover from any corner it counds as melee cover!
                return LOS_COVER;
            }
        }
    }}

    return LOS_NO_COVER;
}
# }}}
# _melee_cover_xs {{{
sub _melee_cover_xs {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    return LOS_NO_COVER if abs($lhs->[0]-$rhs->[0]) > 1;
    return LOS_NO_COVER if abs($lhs->[1]-$rhs->[1]) > 1;

    my @ods = $this->_od_segments(@_);
    my @lhs = $this->_extrude_point( $lhs, 0,0 ); # ocr,lhs
    my @rhs = $this->_extrude_point( $rhs, 0,0 );

    return LOS_COVER
        if &Games::RolePlay::MapGen::MapQueue::any_any_intersect_loop(\@lhs, \@rhs, \@ods);

    return LOS_NO_COVER;
}
# }}}
# _closure_line_of_sight_pl {{{
sub _closure_line_of_sight_pl {
    my $this = shift;
    my $lhs  = shift;
    my $rhsd = shift;

    my $s = (0.0001);
    my $e = (0.9999);
    my $i = (abs($s-$e) / ($EXTRUDE_POINTS-1));

    # NOTE: We build a row of points just "this side" of the door using (@c,$b)
    # for n/s doors or ($b,@c) for e/w ones.  When we're done, there's a row of
    # points in the @rhs, built from @c and $b.

    my @c = ($s); $c[@c] = $c[$#c] + $i while $c[$#c] < $e;
    my $b;

       if( $rhsd->[2] eq "n" ) { $b = $rhsd->[1] + ($lhs->[1]>=$rhsd->[1] ? 0.01 : -0.01) } # slightly more or less than 0
    elsif( $rhsd->[2] eq "s" ) { $b = $rhsd->[1] + ($lhs->[1]<=$rhsd->[1] ? 0.99 :  1.01) } # slightly more or less than 1
    elsif( $rhsd->[2] eq "e" ) { $b = $rhsd->[0] + ($lhs->[0]<=$rhsd->[0] ? 0.99 :  1.01) }
    elsif( $rhsd->[2] eq "w" ) { $b = $rhsd->[0] + ($lhs->[0]>=$rhsd->[0] ? 0.01 : -0.01) }

    my @rhs;
       if( $rhsd->[2] eq "n" ) { @rhs = map {[ $rhsd->[0]+$_, $b ]} @c }
    elsif( $rhsd->[2] eq "s" ) { @rhs = map {[ $rhsd->[0]+$_, $b ]} @c }
    elsif( $rhsd->[2] eq "e" ) { @rhs = map {[ $b, $rhsd->[1]+$_ ]} @c }
    elsif( $rhsd->[2] eq "w" ) { @rhs = map {[ $b, $rhsd->[1]+$_ ]} @c }

    my $v  = [ $rhs[-1][0]-$rhs[0][0], $rhs[-1][1]-$rhs[0][1] ]; # vector @origin describing the line-segment named @rhs
    my $mv = sqrt( $v->[0]**2 + $v->[1]**2 );
       $v  = [ map { $_/$mv } @$v ]; # unit vector describing the line-segment named @rhs

    my $c = [ $rhsd->[0] + $v->[0]/2, $rhsd->[1] + $v->[1]/2 ]; # center of the line-segment named $rhsd
       $c->[0] ++ if $rhsd->[2] eq "e"; # which does require some minor correction
       $c->[1] ++ if $rhsd->[2] eq "s";

    my @od_segments = $this->_od_segments($lhs, [$rhs[0][0],$rhs[0][1]]); # line segments possibly in the way

    my @lhs =
        grep {
            my $l = $_;
            my $ok = 1;
            for my $r (@rhs) {
                for my $od_segment (@od_segments) {
                    if( my @i = $this->_line_segments_intersect( (map {@$_} @$od_segment) => (@$l=>@$r) ) ) {
                        $ok = 0;
                        last;
                    }
                }
            }

            $ok

        } grep {
            my $ab;
            my $od = $this->{_the_map}[ $rhsd->[1] ][ $rhsd->[0] ]{od}{ $rhsd->[2] };
            my $rf = ref $od;
            if( ($od and not $rf) or ($rf and $od->{'open'}) ) {
                $ab = 360;

            } else {
                my $u  = [ $c->[0]-$_->[0], $c->[1]-$_->[1] ]; # the line-segment from the $_ to the center of the closure
                my $mu = sqrt( $u->[0]**2 + $u->[1]**2 );
                   $u  = [ map { abs $_/$mu } @$u ]; # unit vector of $u -- er, the totally positive version anyway

                # We wish to exclude points that are within a certain arc.
                # Anything within $CLOS_MIN_ANGLE degrees of the wall plane
                # we're searching is defined to be an akward search angle

                my $cab = $v->[0]*$u->[0] + $v->[1]*$u->[1];

                $ab = acos( $cab );
            }

            # $ab, hopefully, contains the angle between the vectors
            $ab >= $CLOS_MIN_ANGLE;
        }

        # All the points around the edge of the source tile.  We do not need to
        # worry about any lhs being in the same line segment as the rhs since
        # none of them should be $c and all of them will have too small of an
        # angle between -- this assumes EXTRUDE_POINTS is even, which is now
        # enforced in _ex_p

        ($this->_extrude_point( $lhs, 0,0 ), [$lhs->[0]+0.5,$lhs->[1]+0.5]);

    my $min = (@lhs ? min map { my $l = $_; (max map { sqrt(($l->[0]-$_->[0])**2 + ($l->[1]-$_->[1])**2) } @rhs) } @lhs : 0);
    return $min;
}
# }}}
# _closure_line_of_sight_xs {{{
sub _closure_line_of_sight_xs {
    my $this = shift;
    my $lhs  = shift;
    my $rhsd = shift;

    my $s = (0.0001);
    my $e = (0.9999);
    my $i = (abs($s-$e) / ($EXTRUDE_POINTS-1));

    # NOTE: We build a row of points just "this side" of the door using (@c,$b)
    # for n/s doors or ($b,@c) for e/w ones.  When we're done, there's a row of
    # points in the @rhs, built from @c and $b.

    my @c = ($s); $c[@c] = $c[$#c] + $i while $c[$#c] < $e;
    my $b;

       if( $rhsd->[2] eq "n" ) { $b = $rhsd->[1] + ($lhs->[1]>=$rhsd->[1] ? 0.01 : -0.01) } # slightly more or less than 0
    elsif( $rhsd->[2] eq "s" ) { $b = $rhsd->[1] + ($lhs->[1]<=$rhsd->[1] ? 0.99 :  1.01) } # slightly more or less than 1
    elsif( $rhsd->[2] eq "e" ) { $b = $rhsd->[0] + ($lhs->[0]<=$rhsd->[0] ? 0.99 :  1.01) }
    elsif( $rhsd->[2] eq "w" ) { $b = $rhsd->[0] + ($lhs->[0]>=$rhsd->[0] ? 0.01 : -0.01) }

    my @rhs; # we don't know what the rhs is until we figure out where the door is in relation to the $lhs
       if( $rhsd->[2] eq "n" ) { @rhs = map {[ $rhsd->[0]+$_, $b ]} @c }
    elsif( $rhsd->[2] eq "s" ) { @rhs = map {[ $rhsd->[0]+$_, $b ]} @c }
    elsif( $rhsd->[2] eq "e" ) { @rhs = map {[ $b, $rhsd->[1]+$_ ]} @c }
    elsif( $rhsd->[2] eq "w" ) { @rhs = map {[ $b, $rhsd->[1]+$_ ]} @c }

    my $v  = [ $rhs[-1][0]-$rhs[0][0], $rhs[-1][1]-$rhs[0][1] ]; # vector @origin describing the line-segment named @rhs
    my $mv = sqrt( $v->[0]**2 + $v->[1]**2 );
       $v  = [ map { $_/$mv } @$v ]; # unit vector describing the line-segment named @rhs

    my $c = [ $rhsd->[0] + $v->[0]/2, $rhsd->[1] + $v->[1]/2 ]; # center of the line-segment named $rhsd
       $c->[0] ++ if $rhsd->[2] eq "e"; # which does require some minor correction
       $c->[1] ++ if $rhsd->[2] eq "s";

    my @ods = $this->_od_segments($lhs, [$rhs[0][0],$rhs[0][1]]); # line segments possibly in the way

    my @lhs = grep { &Games::RolePlay::MapGen::MapQueue::any_all_los_loop([$_], \@rhs, \@ods) }
        grep {
            my $ab;
            my $od = $this->{_the_map}[ $rhsd->[1] ][ $rhsd->[0] ]{od}{ $rhsd->[2] };
            my $rf = ref $od;
            if( ($od and not $rf) or ($rf and $od->{'open'}) ) {
                $ab = 360;

            } else {
                my $u  = [ $c->[0]-$_->[0], $c->[1]-$_->[1] ]; # the line-segment from the $_ to the center of the closure
                my $mu = sqrt( $u->[0]**2 + $u->[1]**2 );
                   $u  = [ map { abs $_/$mu } @$u ]; # unit vector of $u -- er, the totally positive version anyway

                # We wish to exclude points that are within a certain arc.
                # Anything within $CLOS_MIN_ANGLE degrees of the wall plane
                # we're searching is defined to be an akward search angle

                my $cab = $v->[0]*$u->[0] + $v->[1]*$u->[1];

                $ab = acos( $cab );
            }

            # $ab, hopefully, contains the angle between the vectors
            $ab >= $CLOS_MIN_ANGLE;
        }

        # All the points around the edge of the source tile.  We do not need to
        # worry about any lhs being in the same line segment as the rhs since
        # none of them should be $c and all of them will have too small of an
        # angle between -- this assumes EXTRUDE_POINTS is even, which is now
        # enforced in _ex_p

        ($this->_extrude_point( $lhs, 0,0 ), [$lhs->[0]+0.5,$lhs->[1]+0.5]);

    my $min = (@lhs ? min map { my $l = $_; (max map { sqrt(($l->[0]-$_->[0])**2 + ($l->[1]-$_->[1])**2) } @rhs) } @lhs : 0);
    return $min;
}
# }}}
# _mxb_of_sight (returns m and b of y=mx+b fame) {{{
sub _mxb_of_sight {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    return if "@$lhs" eq "@$rhs";

    ## DEBUG ## warn "---------- MXB @$lhs => @$rhs\n";

    my @od_segments = $this->_od_segments(@_);

    my @lhs = $this->_extrude_point( $lhs, 0,0 ); # ocr,lh
    my @rhs = $this->_extrude_point( $rhs, 0,0 );

    for my $l (sort { $this->_ldistance($a=>$rhs) <=> $this->_ldistance($b=>$rhs) } @lhs) {
    for my $r (sort { $this->_ldistance($a=>$l)   <=> $this->_ldistance($b=>$l)   } @rhs) {
        my $this_line = 1;

        OD_CHECK:
        for my $od_segment (@od_segments) {
            if( $this->_line_segments_intersect( (map {@$_} @$od_segment) => (@$l=>@$r) ) ) {
                $this_line = 0;

                last OD_CHECK;
            }
        }

        if( $this_line ) {
            my $d = ($r->[0]-$l->[0]);
            my $m = ($d != 0 ? ( ($r->[1]-$l->[1]) / $d ) : undef );
            my $b = (defined $m ? ($l->[1] - ($m*$l->[0])) : 0);

            ## DEBUG ## warn "\tfound: (@$l)->(@$r)\n";

            return ($m, $b, $l, $r);
        }
        ## DEBUG ## else { warn "\treject: (@$l)->(@$r)\n"; }
    }}

    return;
}
# }}}
# _ignorable_cover {{{
sub _ignorable_cover {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    warn "ignorable cover isn't actually calculated";

    return 0;
}
# }}}
# _ldistance {{{
sub _ldistance {
    my $this = shift;
    my ($lhs, $rhs) = @_;

    return sqrt ( (($lhs->[0]-$rhs->[0]) ** 2) + (($lhs->[1]-$rhs->[1]) ** 2) );
}
# }}}
# _locations_in_line_of_sight {{{
sub _locations_in_line_of_sight {
    my $this = shift;
    my $init = shift;
    my @loc  = ();
    my @new  = ($init);

    my %checked = ( "@$init" => 1 );
    while( @new ) {
        my @very_new = ();

        for my $i (@new) {
            for my $j ( [$i->[0]+1, $i->[1]], [$i->[0]-1, $i->[1]], [$i->[0], $i->[1]+1], [$i->[0], $i->[1]-1] ) {
                next if $checked{"@$j"}; $checked{"@$j"} = 1;
                next unless $this->_check_loc($j);

                push @very_new, $j if $this->_line_of_sight( $init => $j );
            }
        }

        push @loc, @new;
        @new = @very_new;
    }

    return @loc;
}
# }}}
# _locations_in_range_and_line_of_sight {{{
sub _locations_in_range_and_line_of_sight {
    my $this  = shift;
    my $init  = shift;
    my $range = shift;
    my @loc   = ();
    my @new   = ($init);

    my %checked = ( "@$init" => 1 );
    while( @new ) {
        my @very_new = ();

        for my $i (@new) {
            for my $j ( [$i->[0]+1, $i->[1]], [$i->[0]-1, $i->[1]], [$i->[0], $i->[1]+1], [$i->[0], $i->[1]-1] ) {
                next if $checked{"@$j"}; $checked{"@$j"} = 1;
                next unless $this->_check_loc($j);
                next unless sqrt( ($init->[0]-$j->[0])**2 + ($init->[1]-$j->[1])**2) <= $range;

                push @very_new, $j if $this->_line_of_sight( $init => $j );
            }
        }

        push @loc, @new;
        @new = @very_new;
    }

    return @loc;
}
# }}}
# _objs_at_location {{{
sub _objs_at_location {
    my $this = shift;
    my $loc  = shift;
    my @itm  = @{ $this->{c}[ $loc->[1] ][ $loc->[0] ] || [] };

    return @itm; # this is a copy, so it's silly to use wantarray...
}
# }}}
# _locations_in_path {{{
sub _locations_in_path {
    my $this = shift;
    my $lhs  = shift;
    my $rhs  = shift;
    my @path = ();

    return ([@$lhs],[@$rhs]) if "@$lhs" eq "@$rhs";

    my ($m, $b, $p0, $p1) = $this->_mxb_of_sight($lhs => $rhs);

    ## DEBUG ## warn "m=$m; b=$b; p0=(@$p0); p1=(@$p1)";

    my $ranger = sub {
        my ($l, $r) = @_;

        return ( $l<$r ? ($l+1 .. $r-1) : (reverse ($r+1 .. $l-1)) );
    };

    push @path, [@$lhs];

    if( not defined $m ) { 
        for my $y ( $ranger->($lhs->[1] => $rhs->[1]) ) {
            my $x = $lhs->[0]; # == $rhs->[0]

            push @path, [$x,$y];
        }

    } elsif( (abs $m) > 1 ) {
        for my $y ( $ranger->($lhs->[1] => $rhs->[1]) ) {
            my $z = (($y+0.5)-$b)/$m;
            my $x = round($z-0.5);

            push @path, [$x,$y];
        }
    } elsif( $m == 0 ) {
        for my $x ( $ranger->($lhs->[0] => $rhs->[0]) ) {
            my $y = round($b);

            push @path, [$x,$y];
        }

    } else {
        for my $x ( $ranger->($lhs->[0] => $rhs->[0]) ) {
            my $z = ($m * ($x+0.5)) + $b;
            my $y = round($z-0.5);

            push @path, [$x,$y];
        }
    }

    push @path, [@$rhs];

    for my $list ([+1, reverse 0 .. $#path-1], [-1, 1 .. $#path]) { my $ni = shift @$list; 
    for my $i (@$list) {
        my $changes = 0;

        for my $j (0,1) {
            my $A = $path[$i][$j];
            my $d = $path[$i+$ni][$j] - $A;
            my $md = abs $d;
            if( $md > 1 ) {
                $A += $d/$md;

                ## DEBUG ## warn (($j==0 ? "X":"Y") . "-CHANGE($i,$j)::(@{$path[$i]})[$j] = $A\n");

                $path[$i][$j] = $A;
                $changes ++;
            }

            ## DEBUG ## else { warn (($j==0 ? "X":"Y") . "-!NO!CHANGE($i,$j)::(@{$path[$i]})[$j] = $A; md=$md; d=$d\n"); }
        }

        last unless $changes;
    }}

    DIAG_ORDEAL: {
        my $map = $this->{_the_map};
        for my $i ( 0 .. $#path-1 ) {
            my $j = $i + 1;
            my ($lhs, $rhs) = ($path[$i], $path[$j]);

            if( $lhs->[0] != $rhs->[0] and $lhs->[1] != $rhs->[1] ) {
                # NOTE: a diagonal move is illegal if there's a "corner" in the way phb p. 147

                LHS_DIAG_VIOLATION: {
                    my $lod  = $map->[ $lhs->[1] ][ $lhs->[0] ]{od};
                    my $xdir = ($lhs->[0]<$rhs->[0] ? 'e':'w'); my $xo = $lod->{$xdir}; $xo = 1 if ref $xo and $xo->{'open'};
                    my $ydir = ($lhs->[1]<$rhs->[1] ? 's':'n'); my $yo = $lod->{$ydir}; $yo = 1 if ref $yo and $yo->{'open'};

                    if( not $yo ) {
                        if( $i == 0 or ($path[$i-1][0] != $lhs->[0]) ) {
                            splice @path, $j, 0, [ $rhs->[0], $lhs->[1] ]; # 0-width inserts at $j
                            redo DIAG_ORDEAL;

                        } else {
                            $lhs->[0] = $rhs->[0];
                        }

                    } elsif( not $xo ) {
                        if( $i == 0 or ($path[$i-1][1] != $lhs->[1]) ) {
                            splice @path, $j, 0, [ $lhs->[0], $rhs->[1] ]; # 0-width inserts at $j
                            redo DIAG_ORDEAL;

                        } else {
                            $lhs->[1] = $rhs->[1];
                        }
                    }
                }

                RHS_DIAG_VIOLATION: {
                    my $lod  = $map->[ $rhs->[1] ][ $rhs->[0] ]{od};
                    my $xdir = ($lhs->[0]<$rhs->[0] ? 'w':'e'); my $xo = $lod->{$xdir}; $xo = 1 if ref $xo and $xo->{'open'};
                    my $ydir = ($lhs->[1]<$rhs->[1] ? 'n':'s'); my $yo = $lod->{$ydir}; $yo = 1 if ref $yo and $yo->{'open'};

                    if( not $yo ) {
                        if( $j == $#path or ($path[$j+1][0] != $rhs->[0] ) ) {
                            splice @path, $j, 0, [ $lhs->[0], $rhs->[1] ]; # 0-width inserts at $j
                            redo DIAG_ORDEAL;

                        } else {
                            $rhs->[0] = $lhs->[0];
                        }

                    } elsif( not $xo ) {
                        if( $j == $#path or ($path[$j+1][1] != $rhs->[1] ) ) {
                            splice @path, $j, 0, [ $rhs->[0], $lhs->[1] ]; # 0-width inserts at $j
                            redo DIAG_ORDEAL;

                        } else {
                            $rhs->[1] = $lhs->[1];
                        }
                    }
                }
            }
        }
    }

    return @path;
}
# }}}
# _door {{{
sub _door {
    my $this = shift;
    my $door = shift; return unless ref $door;

    for my $y ( 0 .. $this->{ym} ) {
        for my $x ( 0 .. $this->{xm} ) {
            my $tile = $this->{_the_map}[$y][$x];

            for my $d (qw(n e s w)) {
                if( $door == $tile->{od}{$d} ) {
                    my $nb = $tile->{nb}{$d};

                    return [$x,$y,$d];
                }
            }
        }
    }

    return;
}
# }}}
 
# _line_segments_intersect {{{
sub _line_segments_intersect {
    my $this = shift;
    # this is http://perlmonks.org/?node_id=253983

    my ( $ax,$ay, $bx,$by, $cx,$cy, $dx,$dy ) = @_;
    # printf STDERR "[pl] A(%9.6f,%9.6f) B(%9.6f,%9.6f) C(%9.6f,%9.6f) D(%9.6f,%9.6f)", $ax,$ay, $bx,$by, $cx,$cy, $dx,$dy;

    # P = p*A + (1-p)*B
    # Q = q*C + (1-q)*D

    # for p=0, P=A, and for p=1, P=B
    # for 0<=p<=1, P is on the line segment between A and B

    # find p,q such than P=Q
    # (... lengthy derivation ...)

    my $d = ($ax-$bx)*($cy-$dy) - ($ay-$by)*($cx-$dx);
    # printf STDERR " d=$d";

    if( $cx == $dx and $cy == $dy ) {
        # 6/25/7 we're a point on the rhs ... apparently this happens when you remove the extrude shortcutting

        if( $ay == $by and $cy == $ay ) {
            return ($cx, $cy) if $ax <= $cx and $cx <= $bx;

        } elsif( $ax == $bx and $cx == $ax ) {
            return ($cx, $cy) if $ay <= $cy and $cy <= $by;
        }

        die "probably a bug";
    }

    if( $d == 0 ) {
        # d=0 when len(C->D)==0 !!
        for my $l ([$ax,$ay], [$bx, $by]) {
        for my $r ([$cx,$cy], [$dx, $dy]) {
            return (@$l) if $l->[0] == $r->[0] and $l->[1] == $r->[1];
        }}

        # NOTE: another huge bug from 6/23/7 !! This vertical overlap was totally overlooked before.
        # This is arguably not the most efficient way to check it, but it's literally better than *nothing*
        if( abs($ax-$bx)<0.0001 and abs($bx-$cx)<0.0001 and abs($cx-$dx)<0.0001 ) {
            return ($cx,$cy) if $ay <= $cy and $cy <= $by;
            return ($dx,$dy) if $ay <= $dy and $dy <= $by;

        # 6/25/7 -- sorta the same deal as above, but horizontal
        } elsif( abs($ay-$by)<0.0001 and abs($by-$cy)<0.0001 and abs($cy-$dy)<0.0001 ) {
            return ($cx,$cy) if $ax <= $cx and $cx <= $bx;
            return ($dx,$dy) if $ax <= $dx and $dx <= $bx;
        }

        ## DEBUG ## warn "\t\tlsi p=||\n";
        return; # probably parallel
    }

    my $p = ( ($by-$dy)*($cx-$dx) - ($bx-$dx)*($cy-$dy) ) / $d;
    # printf STDERR " p=$p";

    ## NOTE: this was an effin hard bug to find...
    ## my @w = ( ( ($p <= 1) ? 1:0 ), ( ($p == 1) ? 1:0 ), ( ($p != 1) ? 1:0 ), ( ($p  - 1) ),);
    ## warn "\t\tlsi p=$p (@w)\n";
    ## lsi p-1 = 2.22044604925031e-16 = 1?  No, not actually, sometimes...

    $p = 0 if abs($p)   < 0.00001; # fixed 6/23/7
    $p = 1 if abs($p-1) < 0.00001;

    # printf STDERR " p=$p\n";

    ## DEBUG ## warn "\t\tlsi p=$p\n";

    # we probably don't need to find q because we already restricted the domain/range above
    return unless $p >= 0 and $p <= 1;

    my $px = $p*$ax + (1-$p)*$bx;
    my $py = $p*$ay + (1-$p)*$by;

    return ($px, $py);
}

# NOTE: simply uncomment these to get verbose LSI results
## DEBUG ## *debug_lsi = *_line_segments_intersect;
## DEBUG ## sub replacer { my @ret = &debug_lsi(@_); warn "\t\tLSI(@ret)\n"; return @ret; }
## DEBUG ## *_line_segments_intersect = *replacer;

# }}}

# location {{{
sub location {
    my $this = shift;
    my $that = shift;

    croak "that object/tag ($that) isn't on the map" unless exists $this->{l}{$that};

    my $l = $this->{l}{$that};
    return (wantarray ? @$l : $l);
}
# }}}
# lline_of_sight {{{
sub lline_of_sight {
    my $this = shift;

    croak "you should provide 4 arguments to line_of_sight()" unless @_ == 4;

    my @lhs = @_[0 .. 1];
    my @rhs = @_[2 .. 3];

    croak "the first two arguments to lline_of_sight() do not appear to form a sane map location" unless $this->_check_loc(\@lhs);
    croak "the last two arguments to lline_of_sight() do not appear to form a sane map location"  unless $this->_check_loc(\@rhs);

    return $this->_line_of_sight(\@lhs, \@rhs); 
}
# }}}
# ldistance {{{
sub ldistance {
    my $this = shift;

    croak "you should provide 4 arguments to ldistance()" unless @_ == 4;

    my @lhs = @_[0 .. 1];
    my @rhs = @_[2 .. 3];

    croak "the first two arguments to ldistance() do not appear to form a sane map location" unless $this->_check_loc(\@lhs);
    croak "the last two arguments to ldistance() do not appear to form a sane map location"  unless $this->_check_loc(\@rhs);

    if( $_[4] ) {
        my @r = ($this->_ldistance(\@lhs, \@rhs), $this->_line_of_sight(\@lhs, \@rhs));
        return (wantarray ? @r : \@r);
    }

    return undef unless $this->_line_of_sight(\@lhs => \@rhs);
    return $this->_ldistance(\@lhs => \@rhs);
}
# }}}
# distance {{{
sub distance {
    my $this = shift;
    my $lhs  = shift; croak "the lhs=$lhs isn't on the map" unless exists $this->{l}{$lhs};
    my $rhs  = shift; croak "the rhs=$rhs isn't on the map" unless exists $this->{l}{$rhs};
    my $los  = shift;

    $lhs = $this->{l}{$lhs};
    $rhs = $this->{l}{$rhs};

    if( $los ) {
        my @r = ($this->_ldistance($lhs, $rhs), $this->_line_of_sight($lhs, $rhs));
        return (wantarray ? @r : \@r);
    }

    return undef unless $this->_line_of_sight($lhs, $rhs);
    return $this->_ldistance($lhs, $rhs);
}
# }}}
# line_of_sight {{{
sub line_of_sight {
    my $this = shift;

    croak "you should provide 2 arguments to line_of_sight()" unless @_ == 2;

    my $lhs = shift; $lhs = "$lhs";
    my $rhs = shift; $rhs = "$rhs";

    croak "the first argument to line_of_sight() does not appear to be on the map" unless ($lhs = $this->{l}{$lhs});
    croak "the last argument to line_of_sight() does not appear to be on the map"  unless ($rhs = $this->{l}{$rhs});

    return $this->_line_of_sight($lhs, $rhs); 
}
# }}}
# closure_line_of_sight {{{
sub closure_line_of_sight {
    my $this = shift;

    croak "you should provide 2 arguments to closure_line_of_sight()" unless @_ == 2;

    my $lhs = shift; $lhs = "$lhs";
    my $rhs = shift;

    croak "the first argument to closure_line_of_sight() does not appear to be on the map" unless ($lhs = $this->{l}{$lhs});
    croak "the last argument to closure_line_of_sight() does not appear to be a door"      unless ($rhs = $this->_door($rhs));
    # it definitely does have to be a door so we can get the direction! ... for arbitrary closures you must use
    # closure_lline_of_sight. :(

    return $this->_closure_line_of_sight($lhs, $rhs); 
}
# }}}
# closure_lline_of_sight {{{
sub closure_lline_of_sight {
    my $this = shift;

    croak "you should provide 5 arguments to closure_lline_of_sight()" unless @_ == 5;

    my @lhs = @_[0 .. 1];
    my @rhs = @_[2 .. 3];
    my $dir = $_[4];

    croak "the first two arguments to closeure_lline_of_sight() do not appear to form a sane map location" unless $this->_check_loc(\@lhs);
    croak "the second two arguments to closeure_lline_of_sight() do not appear to form a sane map location"  unless $this->_check_loc(\@rhs);
    croak "the fifth argument to closure_lline_of_sight() should be a map direction (ie, n s e w)" unless $dir =~ m/^[nsew]\z/;

    return $this->_closure_line_of_sight(\@lhs, [@rhs, $dir]); 
}
# }}}

# {{{ sub build_queue_from_hash

##################
# XXX: experimental, undocumented, crazy thing, do not use, may change
######

sub build_queue_from_hash {
    my $this = shift;
    my $that = @_==1 && ref($_[0])eq"HASH" ? $_[0] : { @_ };

    delete $this->{l};
    delete $this->{c};

    for my $k (keys %$that) {
        $this->{l} = $k;
        my $loc = $that->{$k}{l};
        my $itm = $that->{$k}{i};

        push @{$this->{c}[ $loc->[1] ][ $loc->[0] ]}, $itm;
    }
}

# }}}

# add {{{
sub add {
    my $this = shift;
    my $that = shift or croak "place what?"; my $tag = "$that";
    my @loc  = @_;

    croak "that object/tag ($tag) appears to already be on the map" if exists $this->{l}{$tag};
    croak "that location (@loc) makes no sense" unless $this->_check_loc(\@loc);

    $this->{l}{$tag} = \@loc;
    push @{ $this->{c}[ $loc[1] ][ $loc[0] ] }, $that;
}
# }}}
# remove {{{
sub remove {
    my $this = shift;
    my $that = shift; my $tag = "$that";

    croak "that object/tag ($tag) isn't on the map" unless exists $this->{l}{$tag};

    my @loc = @{ delete $this->{l}{$tag} };
    my $itm = $this->{c}[ $loc[1] ][ $loc[0] ];

    @$itm = ( grep {$_ ne $tag} @$itm );
}
# }}}
# replace {{{
sub replace {
    my $this = shift;
    my $that = shift; my $tag = "$that";
    my @loc  = @_;

    croak "that location (@loc) makes no sense" unless $this->_check_loc(\@loc);

    $this->remove($tag) if exists $this->{l}{$tag};
    $this->add($that => @loc);
}
# }}}
# {{{ is_on_map
sub is_on_map {
    my $this = shift;
    my $that = shift;

    return exists($this->{l}{$that}) ? 1:0;
}

# }}}

# objs_at_location {{{
sub objs_at_location {
    my $this = shift;
    my $loc  = $this->_check_loc(\@_) or croak "that location (@_) makes no sense";

    return $this->_objs_at_location( $loc );
}
*objects_at_location = *objs_at_location;
# }}}
# objs_in_line_of_sight {{{
sub objs_in_line_of_sight {
    my $this = shift;
    my $loc  = $this->_check_loc(\@_) or croak "that location (@_) makes no sense";
    my @ret  = ();

    for my $l ($this->_locations_in_line_of_sight($loc)) {
        push @ret, @{ $this->{c}[ $l->[1] ][ $l->[0] ] || [] };
    }

    return @ret;
}
*objects_in_line_of_sight = *objs_in_line_of_sight;
# }}}
# objs {{{
sub objs {
    my $this = shift;
    my @ret  = ();

    for my $row ( 0 .. $this->{ym} ) {
        for my $col ( 0 .. $this->{xm} ) {

            push @ret, @{ $this->{c}[ $row ][ $col ] || [] };
        }
    }

    return @ret;
}
*objects = *objs;
# }}}
# objs_with_locations {{{
sub objs_with_locations {
    my $this = shift;
    my @ret  = ();

    for my $row ( 0 .. $this->{ym} ) {
        for my $col ( 0 .. $this->{xm} ) {
            my $loc = [ $col, $row ];

            my @junk = @{ $this->{c}[ $loc->[1] ][ $loc->[0] ] || [] };

            push @ret, [ $loc => \@junk ] if @junk;
        }
    }

    return @ret;
}
*objects_with_locations = *objs_with_locations;
# }}}

# random_open_location {{{
sub random_open_location {
    my $this = shift;
    my @l    = $this->all_open_locations;
    my $i    = int rand int @l;

    return unless @l;
    return (wantarray ? @{$l[$i]}:$l[$i]);
}
# }}}
# all_open_locations {{{
sub all_open_locations {
    my $this = shift;
    my ($X, $Y) = ($this->{xm}+1, $this->{ym}+1);
    my @ret = ();

    for my $x ( 0 .. $this->{xm} ) {
    for my $y ( 0 .. $this->{ym} ) {
        push @ret, [$x, $y] if defined $this->{_the_map}[ $y ][ $x ]{type}; # the wall type is <undef>
    }}

    return (wantarray ? @ret:\@ret);
}
# }}}
# locations_in_line_of_sight {{{
sub locations_in_line_of_sight {
    my $this = shift;
    my @init = @_; $this->_check_loc(\@init) or croak "that location (@_) doesn't make any sense";

    return $this->_locations_in_line_of_sight(\@init);
}
# }}}
# locations_in_range_and_line_of_sight {{{
sub locations_in_range_and_line_of_sight {
    my $this  = shift;
    my @init  = splice @_,0,2; $this->_check_loc(\@init) or croak "that location (@_) doesn't make any sense";
    my $range = shift || 0;

    croak "range should be greater than 0" unless $range > 0;

    return $this->_locations_in_range_and_line_of_sight(\@init, $range);
}
# }}}
# locations_in_path {{{
sub locations_in_path {
    my $this = shift; croak "you should provide 4 arguments to locations_in_path()" unless @_ == 4;
    my @lhs = @_[0 .. 1]; $this->_check_loc(\@lhs) or croak "the first two arguments to locations_in_path() (@_) don't make any sense";
    my @rhs = @_[2 .. 3]; $this->_check_loc(\@rhs) or croak "the second two arguments to locations_in_path() (@_) don't make any sense";

    croak "the target location doesn't appear to be visible from the source"
        unless $this->_line_of_sight(\@lhs => \@rhs);

    return $this->_locations_in_path(\@lhs => \@rhs);
}
# }}}

# ranged_cover {{{
sub ranged_cover {
    my $this = shift;
    my @l    = @_[0 .. 1]; $this->_check_loc(\@l) or croak "the left location (@l) doesn't make any sense";
    my @r    = @_[2 .. 3]; $this->_check_loc(\@r) or croak "the right location (@r) doesn't make any sense";

    return $this->_ranged_cover(\@l=>\@r);
}
# }}}
# melee_cover {{{
sub melee_cover {
    my $this = shift;
    my @l    = @_[0 .. 1]; $this->_check_loc(\@l) or croak "the left location (@l) doesn't make any sense";
    my @r    = @_[2 .. 3]; $this->_check_loc(\@r) or croak "the right location (@r) doesn't make any sense";

    return $this->_melee_cover(\@r=>\@l);
}
# }}}
# ignorable_cover {{{
sub ignorable_cover {
    my $this = shift;
    my @l    = @_[0 .. 1]; $this->_check_loc(\@l) or croak "the left location (@l) doesn't make any sense";
    my @r    = @_[2 .. 3]; $this->_check_loc(\@r) or croak "the right location (@r) doesn't make any sense";

    return $this->_ignorable_cover(\@r=>\@l);
}
# }}}

# is_open {{{
sub is_open {
    my $this = shift;
    my @loc  = @_[0 .. 1];

    return $this->_check_loc(\@loc);
}
# }}}
# is_door_open {{{
sub is_door_open {
    my $this = shift;
    my @loc  = @_[0 .. 1];
    my $dir  = lc $_[2]; $dir = $1 if $dir =~ m/^([nsew])./i;
    my $door;

    croak "that location doesn't make sense" unless $this->_check_loc(\@loc);
    croak "there isn't a door there" unless ref ($door = $this->{_the_map}[ $loc[1] ][ $loc[0] ]{od}{$dir});

    return $door->{'open'};
}
# }}}
# is_door {{{
sub is_door {
    my $this = shift;
    my @loc  = @_[0 .. 1];
    my $dir  = lc $_[2]; $dir = $1 if $dir =~ m/^([nsew])./i;

    croak "that location doesn't make sense" unless $this->_check_loc(\@loc);
    return 1 if ref $this->{_the_map}[ $loc[1] ][ $loc[0] ]{od}{ $dir };
    return 0;
}
# }}}
# open_door {{{
sub open_door {
    my $this = shift;
    my @loc  = @_[0 .. 1];
    my $dir  = lc $_[2]; $dir = $1 if $dir =~ m/^([nsew])./i;
    my $door;

    croak "that location doesn't make sense" unless $this->_check_loc(\@loc);
    croak "there isn't a door there" unless ref ($door = $this->{_the_map}[ $loc[1] ][ $loc[0] ]{od}{$dir});
    croak "that door is already open" if $door->{'open'};

    $door->{'open'} = 1;
    $this->flush;
}
# }}}
# close_door {{{
sub close_door {
    my $this = shift;
    my @loc  = @_[0 .. 1];
    my $dir  = lc $_[2]; $dir = $1 if $dir =~ m/^([nsew])./i;
    my $door;

    croak "that location doesn't make sense" unless $this->_check_loc(\@loc);
    croak "there isn't a door there" unless ref ($door = $this->{_the_map}[ $loc[1] ][ $loc[0] ]{od}{$dir});
    croak "that door isn't open"     unless $door->{'open'};

    $door->{'open'} = 0;
    $this->flush;
}
# }}}
# map_range {{{
sub map_range {
    my $this = shift;

    return ( 0 .. $this->{xm} ) if wantarray;
    return $this->{xm};
}
# }}}
# map_domain {{{
sub map_domain {
    my $this = shift;

    return ( 0 .. $this->{ym} ) if wantarray;
    return $this->{ym};
}
# }}}

# {{{ FREEZE_THAW_HOOKS
FREEZE_THAW_HOOKS: {
    my $going;
    sub STORABLE_freeze {
        return if $going;
        my $this = shift;
        $going = 1;
        my $str = freeze($this);
        $going = 0;
        return $str;
    }

    sub STORABLE_thaw {
        my $this = shift;
        %$this = %{ thaw($_[1]) };
        $this->retag;
    }
}

# }}}

1;
