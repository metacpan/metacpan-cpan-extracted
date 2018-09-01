package Math::Geometry::Delaunay;

use 5.008;
use warnings;
use strict;
use Carp qw(carp);;
use Exporter();

our @ISA = qw(Exporter);
our $VERSION;

BEGIN {
    use XSLoader;
    $VERSION = '0.21';
    XSLoader::load('Math::Geometry::Delaunay');
    exactinit();
    }

use constant {
    TRI_CONSTRAINED  => 'Y',
    TRI_CONFORMING   => 'Dq0',
    TRI_CCDT         => 'q',
    TRI_VORONOI      => 'v',
    };

our @EXPORT_OK = qw(TRI_CONSTRAINED TRI_CONFORMING TRI_CCDT TRI_VORONOI);
our @EXPORT = qw();

my $pi = atan2(1,1)*4;

sub new {
    my $class = shift;
    my $self = {};
    $self->{in}     = Math::Geometry::Delaunay::Triangulateio->new();
    $self->{out}    = undef;
    $self->{vorout} = undef;
    $self->{poly}   = {
    regions      => [],
    holes        => [],
    polylines    => [],
    points       => [],
    segments     => [],
    outnodes     => [], #for cache, first time C output arrays are imported
    voutnodes    => [], #for cache
    segptrefs    => {}, #used to avoid dups of points added with addSegments
    };

    $self->{optstr} = '';
    # Triangle switches
    # prq__a__uAcDjevngBPNEIOXzo_YS__iFlsCQVh
    # where __ is an optional number
    $self->{a} = -1; # max tri area
    $self->{q} = -1; # quality min angle
    $self->{e} = 0; # produce edges switch
    $self->{v} = 0; # voronoi switch
    $self->{n} = 0; # neighbors switch
    $self->{N} = 0; # suppress node output
    $self->{E} = 0; # suppress element output
    $self->{O} = 0; # suppress holes - ignore input holes
    $self->{o2}= 0; # subparametric switch (for 6 pts/tri)
    $self->{Q} = 1; # quiet - switch for Triangle's printed output    
    $self->{V} = 0; # verbose - from 0 to 3 for increasing verbosity

    bless $self, $class;
    return $self;
    }

sub reset {
    my $self = shift;
    # clear input
    $self->{poly}->{$_} = [] for qw(regions holes polylines points segments);
    $self->{poly}->{segptrefs} = {};
    # clear any previous output
    $self->{poly}->{$_} = [] for qw(outnodes voutnodes);
    }

# triangulatio interfaces
sub in     {return $_[0]->{in};}
sub out    {return $_[0]->{out};}
sub vorout {return $_[0]->{vorout};}

# getter/setters for the triangulate switches that take numbers

sub area_constraint { # -1 for disabled
    if (@_>1) {$_[0]->{a}=$_[1];}
    return $_[0]->{a};
    }
sub minimum_angle { # "q" switch, in degrees, -1 for disabled
    if (@_>1) {$_[0]->{q}=$_[1];}
    return $_[0]->{q};
    }
sub subparametric {
    if (@_>1) {$_[0]->{o2}=$_[1]?1:0;}
    return $_[0]->{o2};
    }
sub doEdges {
    if (@_>1) {$_[0]->{e}=$_[1]?1:0;}
    return $_[0]->{e};
    }
sub doVoronoi {
    if (@_>1) {$_[0]->{v}=$_[1]?1:0;}
    return $_[0]->{v};
    }
sub doNeighbors {
    if (@_>1) {$_[0]->{n}=$_[1]?1:0;}
    return $_[0]->{n};
    }
sub quiet {
    if (@_>1) {$_[0]->{Q}=$_[1]?1:0;}
    return $_[0]->{Q};
    }
sub verbose { # 0 to 3
    if (@_>1) {$_[0]->{V}=$_[1]?1:0;}
    return $_[0]->{V};
    }

# everything to add input geometry

sub addRegion {
    my $self = shift;
    my $poly = shift;
    my $attribute = @_ ? shift : undef;
    my $area = @_ ? shift:undef;
    my $point_inside = @_ ? shift : undef; # not expected, but we'll use it

    if (@{$poly}==1) {
        carp "first arg to addRegion should be a polygon, or point";
        return;
        }
    elsif (@{$poly}==2 && !ref($poly->[0])) { # a region identifying point
        $point_inside = $poly;
        }
    else {
        $self->addPolygon($poly);
        }

    my $ray; # return ray used for $point_inside calc for debugging, for now

    if (!$point_inside) {
        ($point_inside, $ray) = get_point_in_polygon($poly);
        }
    if (defined $point_inside) {
        push @{$self->{poly}->{regions}}, [ $point_inside, $attribute, ($area && $area > 0) ? $area : -1 ];
        }
    return $point_inside, $ray;
    }

sub addHole {
    my $self = shift;
    my $poly = shift;
    my $point_inside = @_ ? shift : undef; # not expected, but we'll use it if available

    if (@{$poly}==1) {
        carp "first arg to addHole should be a polygon, or point";
        return;
        }
    elsif (@{$poly}==2 && !ref($poly->[0])) { # it's really the hole identifying point
        $point_inside = $poly;
        }
    else {
        $self->addPolygon($poly);
        }

    my $ray; # return ray used for $point_inside calc for debugging, for now

    if (!$point_inside) {
        ($point_inside, $ray) = get_point_in_polygon($poly);
        }
    if (defined $point_inside) {
        push @{$self->{poly}->{holes}}, $point_inside;
        }
    return $point_inside, $ray;
    }

sub addPolygon {
    my $self = shift;
    my $poly = shift;
    if    (@{$poly} == 1 ) {return $self->addPoints([$poly->[0]]);}
    push @{$self->{poly}->{polylines}}, ['polygon',$poly];
    return;
    }

sub addPolyline {
    my $self = shift;
    my $poly = shift;
    if    (@{$poly} == 1 ) {return $self->addPoints([$poly->[0]]);}
    push @{$self->{poly}->{polylines}}, ['polyline',$poly];
    return;
    }

sub addSegments {
    my $self = shift;
    my $segments = shift;
    push @{$self->{poly}->{segments}}, @{$segments};
    return;
    }

sub addPoints { # points unaffiliated with PLSG segments
    my $self = shift;
    my $points = shift;
    push @{$self->{poly}->{points}}, @{$points};
    return;
    }

# compile all the input geometry in to Triangle-format lists
# set up option strings
# and initialize output lists

sub prepPoly {
    my $self = shift;
    my $optstr = shift;
    $self->{optstr} = '';
    # option string options:
    # prq__a__uAcDjevngBPNEIOXzo_YS__iFlsCQVh
    # where __ is an optional number
    $self->{optstr} .= ''.
                       $optstr.
                       ($self->{q} > -1?'q'.$self->{q}:'').
                       ($self->{a} > -1?'a'.$self->{a}:'').
                       ($self->{e}     ?'e':'').
                       ($self->{v}     ?'v':'').
                       ($self->{n}     ?'n':'').
                       'z'. # always number everything starting with zero
                       ($self->{o2}    ?'o2':'').
                       ($self->{Q}     ?'Q':'').
                       ($self->{V} >  0?(($self->{V} > 2) ? 'VVV' : ($self->{V} x 'V')) : '')
                       ;
    my @allpts;
    my @allsegs;

    if (@{$self->{poly}->{segments}}) {

        # The list of segments is the most likely to have duplicate points.
        # Some algorithms in this space result in lists of segments,
        # perhaps listing subsegments of intersecting segments,
        # or representing a boundary or polygon with out-of-order,
        # non-contiguous segment lists, where shared vertices are
        # repeated in each segment's record.

        # addSegments() is meant for that kind of data
        # and this is where we boil the duplicate points down,
        # so Triangle doesn't have to.

        # We look both for duplicate point references and duplicate coordinates.
        # The coordinate check could collapse points that are topologically
        # unique, or it could fail to merge points that should be considered
        # duplicates - but we hope most of the time it does the best thing.

        foreach my $seg (@{$self->{poly}->{segments}}) {
            if (   !defined($self->{segptrefs}->{$seg->[0]}) 
                && !defined($self->{segptrefs}->{$seg->[0]->[0].','.$seg->[0]->[1]})
                ) {
                push @allpts, $seg->[0];
                $self->{segptrefs}->{$seg->[0]} = $#allpts;
                $self->{segptrefs}->{$seg->[0]->[0].','.$seg->[0]->[1]} = $#allpts;
                }
            push @allsegs, defined($self->{segptrefs}->{$seg->[0]})
                           ? $self->{segptrefs}->{$seg->[0]}
                           : $self->{segptrefs}->{$seg->[0]->[0].','.$seg->[0]->[1]};
            if (   !defined($self->{segptrefs}->{$seg->[1]}) 
                && !defined($self->{segptrefs}->{$seg->[1]->[0].','.$seg->[1]->[1]})
                ) {
                push @allpts, $seg->[1];
                $self->{segptrefs}->{$seg->[1]} = $#allpts;
                $self->{segptrefs}->{$seg->[1]->[0].','.$seg->[1]->[1]} = $#allpts;
                }
            push @allsegs, defined($self->{segptrefs}->{$seg->[1]})
                           ? $self->{segptrefs}->{$seg->[1]}
                           : $self->{segptrefs}->{$seg->[1]->[0].','.$seg->[1]->[1]};
            }
        }
    $self->{segptrefs} = {};

    if (@{$self->{poly}->{polylines}} || @allsegs) {
        # doing PSLG - add poly flag to options
        $self->{optstr} = 'p'.$self->{optstr};
        #set up points and segments lists for each polygon and polyline
        foreach my $polycont (@{$self->{poly}->{polylines}}) {
            my $poly = $polycont->[1];
            push @allpts, $poly->[0];
            my $startind=$#allpts;
            foreach my $thispt (@{$poly}[1..@{$poly}-1]) {
                push(@allsegs, $#allpts, $#allpts + 1);
                push(@allpts, $thispt);
                }
            if ($polycont->[0] eq 'polygon') { # add segment to close it
                push(@allsegs, $#allpts, $startind);                
                }

            }
        # add segments to C struct
        my $segs_added_count = $self->in->segmentlist(@allsegs);

        # Add region mark points and any attributes and area constraints to C struct
        if (@{$self->{poly}->{regions}}) {
            my $regions_added_count = $self->in->regionlist(map {grep defined, @{$_->[0]},$_->[1],$_->[2]} @{$self->{poly}->{regions}});
            }
        # Add hole mark points to C struct
        if (@{$self->{poly}->{holes}}) {
            my $holes_added_count = $self->in->holelist(map {@{$_}} @{$self->{poly}->{holes}});
            }
        }

    # add all points from PSLG, (possibly none)
    # and then any other points (not associated with segments)
    # into the C struct
    my $points_added_count = $self->in->pointlist(map {$_->[0],$_->[1]} (@allpts, @{$self->{poly}->{points}}));

    # set up attribute array if any points have more than 2 items (the coordinates) in list
    my $coords_plus_attrs = 2; # 2 for the coords - we'll skip over them when it's time
    foreach my $point (@allpts, @{$self->{poly}->{points}}) {
        if ($coords_plus_attrs < @{$point}) {$coords_plus_attrs = @{$point}}
        }
    if ($coords_plus_attrs > 2) {
        # Extend / fill in the attribute lists for any points 
        # that don't have the full set of attributes defined.
        # Set missing/undefined attributes to zero.
        foreach my $point (@allpts, @{$self->{poly}->{points}}) {
            if (@{$point} < $coords_plus_attrs) {
                foreach (2 .. $coords_plus_attrs - 1) {
                    if (!defined($point->[$_])) {$point->[$_]=0;}
                    }
                }
            }
        # put attributes into C struct
        $self->in->numberofpointattributes($coords_plus_attrs - 2);
        my $attributes_added_count = $self->in->pointattributelist(
            map {@{$_}[2 .. $coords_plus_attrs - 1]} (@allpts, @{$self->{poly}->{points}}));
        }

    # discard intermediate data now that it's been loaded into C arrays
    $self->reset();

    # set up new triangulateio C structs to receive output
    $self->{out}    = Math::Geometry::Delaunay::Triangulateio->new();
    $self->{vorout} = Math::Geometry::Delaunay::Triangulateio->new();

    return;
    }


sub triangulate() {
    my $self = shift;
    my $dotopo = defined wantarray && !wantarray; # scalar or array return context 
    my $optstr = @_ ? join('',@_):'';
    $self->prepPoly($optstr);
    Math::Geometry::Delaunay::_triangulate($self->{optstr},$self->in->to_ptr,$self->out->to_ptr,$self->vorout->to_ptr);
    if (defined wantarray) { # else don't do expensive topology stuff if undef/void context
        if (wantarray && index($self->{optstr},'v') != -1) {
            return topology($self->out), topology($self->vorout);
            }
        return topology($self->out);
        }
    return;
    }

# This probably performs well, but it does show up high enough in profiler
# reports that it's worth looking into speed-up. Consider something with unpack maybe.
sub ltolol {($#_<$_[0])?():map [@_[$_*$_[0]+1..$_*$_[0]+$_[0]]],0..$#_/$_[0]-1}#perl.

sub nodes {
    my $self  = shift;
    my $fromVouty = @_ ? shift : 0;
    my $triio = $fromVouty ? $self->vorout : $self->out;
    my $cachetarg = $fromVouty ? 'voutnodes' : 'outnodes';
    if (@{$self->{poly}->{$cachetarg}} == 0) {
        my @nodeattributes;
        if ($triio->numberofpointattributes) {
            @nodeattributes = ltolol($triio->numberofpointattributes,$triio->pointattributelist);
            }
        @{$self->{poly}->{$cachetarg}} = ltolol(2,$triio->pointlist);
        for (my $i=0;$i<@nodeattributes;$i++) {
            push @{$self->{poly}->{$cachetarg}->[$i]}, @{$nodeattributes[$i]};
            } 
        if (!$fromVouty) {
            my @nodemarkers = $triio->pointmarkerlist;
            for (my $i=0;$i<@nodemarkers;$i++) {
                push @{$self->{poly}->{$cachetarg}->[$i]}, $nodemarkers[$i];
                }
            }
        }
    return $self->{poly}->{$cachetarg};
    }

sub elements {
    my $self = shift;
    my $triio = $self->out;
    my $nodes = $self->nodes;
    my @outelements;
    my @triangleattributes;
    if ($triio->numberoftriangleattributes) {
        @triangleattributes = ltolol($triio->numberoftriangleattributes,$triio->triangleattributelist);
        }
    @outelements = map {[map {$nodes->[$_]} @{$_}]} ltolol($triio->numberofcorners,$triio->trianglelist);
    for (my $i=0;$i<@triangleattributes;$i++) {
        push @{$outelements[$i]}, @{$triangleattributes[$i]};
        } 
    return \@outelements;
    }

sub segments {
    my $self = shift;
    my $triio = $self->out;
    my $nodes = $self->nodes;
    my @outsegments;
    my @segmentmarkers = $triio->segmentmarkerlist;
    @outsegments = map {[$nodes->[$_->[0]],$nodes->[$_->[1]]]} ltolol(2,$triio->segmentlist);
    for (my $i=0;$i<@segmentmarkers;$i++) {
        push @{$outsegments[$i]}, $segmentmarkers[$i];
        } 
    return \@outsegments;
    }
 
sub edges {
    my $self = shift;
    my $fromVouty = @_ ? shift : 0;
    my $triio = $fromVouty ? $self->vorout : $self->out;
    my $nodes = $self->nodes($fromVouty);
    my @outedges;
    @outedges = map {[map { $_==-1?0:$nodes->[$_]} @{$_}]} ltolol(2,$triio->edgelist);
    if (!$fromVouty) {
        my @edgemarkers = $triio->edgemarkerlist;
        for (my $i=0;$i<@edgemarkers;$i++) {
            push @{$outedges[$i]}, $edgemarkers[$i];
            }
        } 
    return \@outedges;
    }

sub vnodes {return $_[0]->nodes(1);}

sub vedges {
    my $self = shift;
    my $vedges = $self->edges(1);
    my $triio = $self->vorout;
    my @outrays;
    @outrays = ltolol(2,$triio->normlist);
    for (my $i=0;$i<@{$vedges};$i++) {
        # if one end was a ray (missing node ref)
        # look up the direction vector and use that as missing point
        # and set third element in edge array to true
        # as a flag to identify this edge as a ray 
        if (!$vedges->[$i]->[0]) {
            $vedges->[$i]->[0] = $outrays[$i];
            $vedges->[$i]->[2] = 1;
            }
        elsif (!$vedges->[$i]->[1]) {
            $vedges->[$i]->[1] = $outrays[$i];
            $vedges->[$i]->[2] = 2;
            }
        else {
            $vedges->[$i]->[2] = 0;
            }
        }
    return $vedges;
    }

sub topology {
    my $triio = shift;

    my $isVoronoi = 0; # we'll detect this when reading edges

    my $pcnt = 0; # In Voronoi diagram node index corresponds to dual Delaunay element.
    my @nodes = map {{ point => $_, attributes => [], marker => undef, elements => [], edges => [] , segments => [], index => $pcnt++}} ltolol(2,$triio->pointlist);
    my $tcnt = 0; # In Delaunay triangulation element index corresponds to dual Voronoi node.
    my @eles  = map {my $ele={ nodes=>[map {$nodes[$_]}              @{$_}], marker => undef, edges => [], neighbors => [], attributes => [], index => $tcnt++ }; foreach (@{$ele->{nodes}}) {push(@{$_->{elements}},$ele)};$ele} ltolol($triio->numberofcorners,$triio->trianglelist);
    my $ecnt = 0; # Corresponding edges in the Delaunay and Voronoi topologies will have the same index.
    my @edges = map {my $edg={ nodes=>[map {$nodes[$_]} grep {$_>-1} @{$_}], marker => undef, elements => [], vector => undef,                index => $ecnt++};  foreach (@{$edg->{nodes}}) {push @{$_->{edges}   },$edg};if (!$isVoronoi && ($_->[0] == -1 || $_->[1] == -1)) {$isVoronoi = 1};$edg} ltolol(2,$triio->edgelist);
    my @segs  = map {my $edg={ nodes=>[map {$nodes[$_]}              @{$_}], marker => undef, elements => []                                                  };  foreach (@{$edg->{nodes}}) {push @{$_->{segments}},$edg};                                                                      $edg} ltolol(2,$triio->segmentlist);

    my @elementattributes;
    if ($triio->numberoftriangleattributes) {
        @elementattributes = ltolol($triio->numberoftriangleattributes,$triio->triangleattributelist);
        }
    for (my $i=0;$i<@elementattributes;$i++) {
        $eles[$i]->{attributes} = $elementattributes[$i];
        }
    my @nodeattributes;
    if ($triio->numberofpointattributes) {
        @nodeattributes = ltolol($triio->numberofpointattributes,$triio->pointattributelist);
        }
    my @nodemarkers = $triio->pointmarkerlist; # always there for pslg, unlike attributes
    for (my $i=0;$i<@nodemarkers;$i++) {
        if ($triio->numberofpointattributes) {
            $nodes[$i]->{attributes} = $nodeattributes[$i];
            }
        $nodes[$i]->{marker} = $nodemarkers[$i];
        }
    my @edgemarkers = $triio->edgemarkerlist;
    for (my $i=0;$i<@edgemarkers;$i++) {
        $edges[$i]->{marker} = $edgemarkers[$i];
        }
    my @segmentmarkers = $triio->segmentmarkerlist; # because some can be internal to boundaries
    for (my $i=0;$i<@segmentmarkers;$i++) {
        $segs[$i]->{marker} = $segmentmarkers[$i];
        }
    my @neighs = ltolol(3,$triio->neighborlist);
    for (my $i=0;$i<@neighs;$i++) {
        $eles[$i]->{neighbors} = [map {$eles[$_]} grep {$_ != -1} @{$neighs[$i]}];
        }
    if ($isVoronoi) {
        my @edgevectors = ltolol(2,$triio->normlist); # voronoi ray vectors
        for (my $i=0;$i<@edgevectors;$i++) {
            $edges[$i]->{vector} = $edgevectors[$i];
            }
        }

    # cross reference elements and edges
    if (@edges) { # but only if edges were generated
        foreach my $ele (@eles) {
            for (my $i=-1;$i<@{$ele->{nodes}}-1;$i++) {
                foreach my $edge (@{$ele->{nodes}->[$i]->{edges}}) {
                    if ($ele->{nodes}->[$i+1] == $edge->{nodes}->[0] || $ele->{nodes}->[$i+1] == $edge->{nodes}->[1]) {
                        push @{$ele->{edges}}, $edge;
                        push @{$edge->{elements}}, $ele;
                        last;
                        }
                    }
                }
            }
        }

    my $ret = {
        nodes    => \@nodes,
        edges    => \@edges,
        segments => \@segs,
        elements => \@eles
        };
    bless $ret, 'mgd_topo'; # gives the hash a DESTROY method that helps with garbage collection
    return $ret;
    }

sub get_point_in_polygon {
    my $poly = shift;
    my $point_inside;

    my $bottom_left_index=0;
    my $maxy = $poly->[$bottom_left_index]->[1];
    for (my $i=1;$i<@{$poly};$i++) {
        if ($poly->[$i]->[1] <= $poly->[$bottom_left_index]->[1]) {
            if ($poly->[$i]->[1] < $poly->[$bottom_left_index]->[1] ||
                $poly->[$i]->[0] <  $poly->[$bottom_left_index]->[0]
               ) {
                $bottom_left_index = $i;
                }
            }
        if ($maxy < $poly->[$i]->[1]) { $maxy = $poly->[$i]->[1] }
        }
    my $prev_index = $bottom_left_index;
    my $next_index = -1 * @{$poly} + $bottom_left_index;
    --$prev_index 
        while ($poly->[$prev_index]->[0] == $poly->[$bottom_left_index]->[0] &&
               $poly->[$prev_index]->[1] == $poly->[$bottom_left_index]->[1]
              );
    ++$next_index
        while ($poly->[$next_index]->[0] == $poly->[$bottom_left_index]->[0] &&
               $poly->[$next_index]->[1] == $poly->[$bottom_left_index]->[1]
              );

    my @vec1 = ($poly->[$bottom_left_index]->[0] - $poly->[$prev_index]->[0],
                $poly->[$bottom_left_index]->[1] - $poly->[$prev_index]->[1]);
    my @vec2 = ($poly->[$next_index]->[0] - $poly->[$bottom_left_index]->[0],
                $poly->[$next_index]->[1] - $poly->[$bottom_left_index]->[1]);
    my $orient = (($vec1[0]*$vec2[1] - $vec2[0]*$vec1[1])>=0) ? 1:0;
    
    my $angle1 = atan2($poly->[$prev_index]->[1] - $poly->[$bottom_left_index]->[1], $poly->[$prev_index]->[0] - $poly->[$bottom_left_index]->[0]);
    my $angle2 = atan2($poly->[$next_index]->[1] - $poly->[$bottom_left_index]->[1], $poly->[$next_index]->[0] - $poly->[$bottom_left_index]->[0]);
    my $angle;        
    if ($orient) {$angle = $angle2 + ($angle1 - $angle2)/2;}
    else         {$angle = $angle1 + ($angle2 - $angle1)/2;}
    my $cosangle = cos($angle);
    my $sinangle = sin($angle);
    my $tanangle = $sinangle/$cosangle;

    my $adequate_distance = 1.1 * ($maxy - $poly->[$bottom_left_index]->[1]) *
                            ((abs($cosangle) < 0.00000001) ? 1 : 1/$sinangle);
    my $point_wayout = [$poly->[$bottom_left_index]->[0] + $adequate_distance * $cosangle, 
                        $poly->[$bottom_left_index]->[1] + $adequate_distance * $sinangle];

    my @intersections = sort {$a->[2] <=> $b->[2]} ray_from_index_poly_intersections($bottom_left_index,$point_wayout,$poly,1);

    if (!@intersections) { 
        print "Warning: Failed to calculate hole or region indicator point."; 
        }
    elsif ($#intersections % 2 != 0) { 
        print "Warning: Calculated hole or region indicator point is not inside its polygon."; 
        }
    else {
        my $closest_intersection = $intersections[0];
        $point_inside = [($poly->[$bottom_left_index]->[0] + $closest_intersection->[0])/2,
                         ($poly->[$bottom_left_index]->[1] + $closest_intersection->[1])/2];
        }
    return $point_inside;
    }

sub ray_from_index_poly_intersections {
    my $vertind = shift;
    my $raypt = shift;
    my $poly = shift;
    my $doDists = @_ ? shift : 0;

    my $seg1 = [$poly->[$vertind],$raypt];
    my $x1= $seg1->[0]->[0];
    my $y1= $seg1->[0]->[1];
    my $x2= $seg1->[1]->[0];
    my $y2= $seg1->[1]->[1];
    my @lowhix=($x2>$x1)?($x1,$x2):($x2,$x1);
    my @lowhiy=($y2>$y1)?($y1,$y2):($y2,$y1);

    my @intersections;

    for (my $i = -1; $i < $#$poly; $i++) {

        # skip the segs on either side of the ray base point
        next if $i == $vertind || ($i + 1) == $vertind || ($vertind == $#$poly && $i == -1);

        my $seg2 = [$poly->[$i],$poly->[$i+1]];
        my @segsegret;

        my $u1= $seg2->[0]->[0];
        my $v1= $seg2->[0]->[1];
        my $u2= $seg2->[1]->[0];
        my $v2= $seg2->[1]->[1];

        ##to maybe optimize for the case where segments are
        ##expected NOT to intersect most of the time
        #my @lowhix=($x2>$x1)?($x1,$x2):($x2,$x1);
        #my @lowhiu=($u2>$u1)?($u1,$u2):($u2,$u1);
        #if (
        #   $lowhix[0]>$lowhiu[1]
        #   ||
        #   $lowhix[1]<$lowhiu[0]   
        #   ) {
        #   return;
        #   }
        #my @lowhiy=($y2>$y1)?($y1,$y2):($y2,$y1);
        #my @lowhiv=($v2>$v1)?($v1,$v2):($v2,$v1);
        #if (
        #   $lowhiy[0]>$lowhiv[1]
        #   ||
        #   $lowhiy[1]<$lowhiv[0]   
        #   ) {
        #   return;
        #   }

        my $m1 = ($x2 eq $x1)?'Inf':($y2 - $y1)/($x2 - $x1);
        my $m2 = ($u2 eq $u1)?'Inf':($v2 - $v1)/($u2 - $u1);

        my $b1;
        my $b2;
        my $xi;

        # Arranged like this to avoid m1-m2 with infinity involved, which works
        # in other contexts, but can trigger a floating point exception here.
        # Turns out the exception happens when we let Triangle set the FPU
        # control word, but not when we use XPFPA.h to take care of that, but
        # leaving it this as it is in case that doesn't fix that everywhere.
        my $dm;
        if ($m1 != 'Inf' && $m2 != 'Inf') {$dm = $m1 - $m2;}
        elsif ($m1 == 'Inf' && $m2 == 'Inf') {return;}
        else {$dm='Inf';}
        if    ($m1 == 'Inf' && $m2 != 'Inf') {$xi = $x1;$b2 = $v1 - ($m2 * $u1);}
        elsif ($m2 == 'Inf' && $m1 != 'Inf') {$xi = $u1;$b1 = $y1 - ($m1 * $x1);}
        elsif (abs($dm) > 0.000000000001) {
            $b1 = $y1 - ($m1 * $x1);
            $b2 = $v1 - ($m2 * $u1);    
            $xi=($b2-$b1)/$dm;
            }
        my @lowhiu=($u2>$u1)?($u1,$u2):($u2,$u1);
        if ($m1 != 'Inf') {
            if ($m2 == 'Inf' &&   ($u2<$lowhix[0] || $u2>$lowhix[1]) ) {
                next;
                }
            if (
                defined $xi &&
                ($xi < $lowhix[1] || $xi eq $lowhix[1]) && 
                ($xi > $lowhix[0] || $xi eq $lowhix[0]) &&
                ($xi < $lowhiu[1] || $xi eq $lowhiu[1]) && 
                ($xi > $lowhiu[0] || $xi eq $lowhiu[0])
                ) {
                my $y=($m1*$xi)+$b1;
                my @lowhiv=($v2>$v1)?($v1,$v2):($v2,$v1);
                if ($m2 == 'Inf' &&
                    ($y<$lowhiv[0] || $y>$lowhiv[1])
                    ) {
                    next;
                    }
                else {
                    push(@intersections,[$xi,$y]);
                    if ($y eq $v1 || $y eq $v2) {
                        $i++; # avoid duplicates at endpoints
                        }
                    }
                }
            }
        elsif ($m2 != 'Inf') {#so $m1 is Inf
            if (($x1 < $lowhiu[0] || $x1 > $lowhiu[1]) && ! ($x1 eq $lowhiu[0] || $x1 eq $lowhiu[1])) {
                next;
                }
            my @lowhiv=($v2>$v1)?($v1,$v2):($v2,$v1);
            my $yi = ($m2*$xi)+$b2;
            if (($yi || $yi eq 0) &&
                ($yi < $lowhiy[1] || $yi eq $lowhiy[1]) && 
                ($yi > $lowhiy[0] || $yi eq $lowhiy[0]) &&
                ($yi < $lowhiv[1] || $yi eq $lowhiv[1]) && 
                ($yi > $lowhiv[0] || $yi eq $lowhiv[0])
                ) {
                push(@intersections,[$xi,$yi]);
                if ($xi eq $u1 || $xi eq $u2) {
                    $i++; # avoid duplicates at endpoints
                    }
                }
            }
        }
    if ($doDists) {
        foreach my $int (@intersections) {
            push(@{$int}, sqrt( ($int->[0]-$seg1->[0]->[0])**2 + ($int->[1]-$seg1->[0]->[1])**2 ) );
            }
        }
    return @intersections;
    }

# Adjust location of nodes in voronoi diagram so they become 
# centers of maximum inscribed circles, and store MIC radius in each node.
# This is a first step towards a better medial axis approximation.
# It straightens out the initial MA approx. derived from the Voronoi diagram.

sub mic_adjust {
    my $topo = shift;
    my $vtopo = shift;

    my @new_vnode_points; # voronoi vertices moved to MIC center points
    my @new_vnode_radii;  # will be calculated and added to node data
    my @new_vnode_tangents;  # where the MIC touches the boundary PSLG

    my $vnc=-1; # will use to look up triangle that corresponds to the voronoi node
    # $vnc can probably be replaced with $vnode->{index}

    foreach my $vnode (@{$vtopo->{nodes}}) {
        $vnc++;

        push(@new_vnode_points,$vnode->{point});
        push(@new_vnode_radii,undef);
        push(@new_vnode_tangents,[]);

        my $boundary_edge;

        if (@{$vnode->{edges}} == 3) {
            my @all_edges = map {$topo->{edges}->[$_->{index}]} @{$vnode->{edges}};
            my @boundary_edges = grep {$_->{marker}} @all_edges;

            my @opposite_boundary_edges;
            my @opposite_boundary_feet;

            my $branch_node_edge_index1;
            my $branch_node_edge_index2;
            my $branch_node_third_tan;

            # BRANCH NODE
            # The corresponding Delaunay triangle has no edges on the PSLG boundary,
            # but touches the boundary at its vertices. This corresponds to a
            # node with three edges in the medial axis approximation.
            if (@boundary_edges == 0) {
                $vnode->{isbranchnode} = 1;

                # Orient nodes in edges emanating from this branch node so that
                # the first node is always the branch node.
                # The notion is that direction is always outward from a branch node.
                # This will be a problem if two branch nodes link to each other.
                $_->{nodes} = [$vnode,$_->{nodes}->[0]!=$vnode?$_->{nodes}->[0]:$_->{nodes}->[1]] for @{$vnode->{edges}};

                # Make sure corners are sorted so they are opposite the Voronoi edges in order.
                # They may have already been that way, but couldn't determine from Triangle docs.
                my @corners;
                for (my $i=0;$i<@{$vnode->{edges}};$i++) {
                    push @corners, +(grep $_ != $topo->{edges}->[$vnode->{edges}->[$i]->{index}]->{nodes}->[0]
                                       && $_ != $topo->{edges}->[$vnode->{edges}->[$i]->{index}]->{nodes}->[1], 
                                       @{$topo->{elements}->[$vnc]->{nodes}}
                                    )[0];
                    }

                my @corner_boundary_edges = grep $_->{marker}, map @{$_->{edges}}, @corners;
                my @corner_boundary_feet = map {getFoot([$_->{nodes}->[0]->{point},$_->{nodes}->[1]->{point}],$vnode->{point}->[0],$vnode->{point}->[1])} @corner_boundary_edges;

                # Handle the case where the three corners are probably the three MIC tangents.
                if (! grep $_, @corner_boundary_feet) {
                    $new_vnode_radii[-1] = dist2d($vnode->{point},$topo->{edges}->[$vnode->{edges}->[0]->{index}]->{nodes}->[0]->{point});
                    $new_vnode_tangents[-1] = [[$corners[2]->{point},
                                                $corners[1]->{point}],
                                               [$corners[0]->{point},
                                                $corners[2]->{point}],
                                               [$corners[1]->{point},
                                                $corners[0]->{point}]];
                    next;
                    }

                # Otherwise, set up a case similar to the non-branch node case
                # by designating feet, a boundary edge, and an opposite edge.
                my @boundary_feet_edges;
                for (my $i=0;$i<@corner_boundary_feet;$i+=2) {
                    my $foot;
                    my $edge;
                    # if no foot was found on the two edges meeting at
                    # one of the triangle's vertices, make the vertex a "fake foot"
                    if (!$corner_boundary_feet[$i] && !$corner_boundary_feet[$i+1]) {
                        my $foot = (   $corner_boundary_edges[$i]->{nodes}->[0] == $corner_boundary_edges[$i+1]->{nodes}->[0]
                                    || $corner_boundary_edges[$i]->{nodes}->[0] == $corner_boundary_edges[$i+1]->{nodes}->[1] )
                                   ? $corner_boundary_edges[$i]->{nodes}->[0]->{point}
                                   : $corner_boundary_edges[$i]->{nodes}->[1]->{point};
                        # edge evaluates to "false" to signal this case
                        push @boundary_feet_edges, [$foot,undef,$i/2];
                        }
                    # otherwise keep foot and edge ref
                    else {
                        if ($corner_boundary_feet[$i]  ) {push @boundary_feet_edges, [$corner_boundary_feet[$i],  $corner_boundary_edges[$i]  ,$i/2];}
                        if ($corner_boundary_feet[$i+1]
                            && ( !$corner_boundary_feet[$i] || 
                                # screen out duplicates
                                (  $corner_boundary_feet[$i+1]->[0] ne $corner_boundary_feet[$i]->[0]
                                && $corner_boundary_feet[$i+1]->[1] ne $corner_boundary_feet[$i]->[1]
                                )
                               )
                           ) {push @boundary_feet_edges, [$corner_boundary_feet[$i+1],$corner_boundary_edges[$i+1],$i/2];}
                        }
                    }

                @boundary_feet_edges = sort {dist2d($a->[0],$vnode->{point}) <=> dist2d($b->[0],$vnode->{point})} @boundary_feet_edges;

                # closest edge treated as boundary edge, similar to non-branch node handling
                my $first_with_edge = +(grep {$_->[1]} @boundary_feet_edges)[0];

                $boundary_edge = {nodes=>[$first_with_edge->[1]->{nodes}->[0],$first_with_edge->[1]->{nodes}->[1]]};

                # next closest edge treated as opposite boundary edge, similar to non-branch node handling
                #   (that is, next closest that's also not connected to the same
                #   corner as the closest)
                my $first_not_first_with_edge = +(grep {$_ != $first_with_edge && $_->[2] != $first_with_edge->[2]} @boundary_feet_edges)[0];

                $opposite_boundary_feet[0]  = $first_not_first_with_edge->[0];
                $opposite_boundary_edges[0] = $first_not_first_with_edge->[1];

                # Use these later to match up tangent point pairs with Voronoi edges.
                $branch_node_edge_index1 = $first_with_edge->[2];
                $branch_node_edge_index2 = $first_not_first_with_edge->[2];

                my @threst = grep {   $_ != $first_with_edge 
                                   && $_ != $first_not_first_with_edge 
                                   && $_->[2] != $first_with_edge->[2]
                                   && $_->[2] != $first_not_first_with_edge->[2]
                                   } @boundary_feet_edges;
                # Not completely thought out, but results look good so far -
                # This "tangent point" is not (generally) touched by the approximate 
                # MIC, but it might be worth trying to shift the approx MIC in
                # a later step to come closer to this, when possible.
                # Even without that extra shift attempt, it's useful to have 
                # this when reconstructing a polygon from the approximate 
                # medial axis enabled by mic_adjust(). 
                $branch_node_third_tan = $threst[0]->[0];
                }

            # NON-BRANCH NODE
            # The corresponding Delaunay triangle has one or two edges 
            # on the PSLG boundary.  This corresponds to a node with two edges 
            # in the medial axis approximation.
            if (@boundary_edges == 1 || @boundary_edges == 2) {

                $boundary_edge = $boundary_edges[0];

                my $bef = getFoot([$boundary_edge->{nodes}->[0]->{point},$boundary_edge->{nodes}->[1]->{point}],$vnode->{point}->[0],$vnode->{point}->[1]);
                my $ber = sqrt(($vnode->{point}->[0]-$bef->[0])**2 + ($vnode->{point}->[1]-$bef->[1])**2);

                if (@boundary_edges == 2) {
                    # If the other boundary edge is closer, make that the boundary edge.
                    my $obef = getFoot([$boundary_edges[1]->{nodes}->[0]->{point},$boundary_edges[1]->{nodes}->[1]->{point}],$vnode->{point}->[0],$vnode->{point}->[1]);
                    next if (!$obef);
                    my $ober = sqrt(($vnode->{point}->[0]-$obef->[0])**2 + ($vnode->{point}->[1]-$obef->[1])**2);
                    if ($ober < $ber) {
                        $boundary_edge = $boundary_edges[1];
                        $bef=$obef;
                        $ber=$ober;
                        }
                    }

                my @other_edges = grep $_ != $boundary_edge, map $topo->{edges}->[$_->{index}], @{$vnode->{edges}};
                my $opposite_node = +(grep {$_ != $boundary_edge->{nodes}->[0] && $_ != $boundary_edge->{nodes}->[1]} @{$other_edges[1]->{nodes}})[0];
                @opposite_boundary_edges = grep {$_->{marker}} @{$opposite_node->{edges}};
                @opposite_boundary_feet = map {getFoot([$_->{nodes}->[0]->{point},$_->{nodes}->[1]->{point}],$vnode->{point}->[0],$vnode->{point}->[1])} @opposite_boundary_edges;

                if (@boundary_edges == 1
                    # || @boundary_edges == 2
                    ) { # should apply to ==2 too, maybe, but should screen out the "opposite" that is also "adjacent" in that case
                    my @adjacent_boundary_edges = grep {$_->{marker} && $_ != $boundary_edge} map @{$_->{edges}}, @{$boundary_edge->{nodes}};
                    my @adjacent_boundary_feet = map {getFoot([$_->{nodes}->[0]->{point},$_->{nodes}->[1]->{point}],$vnode->{point}->[0],$vnode->{point}->[1])} @adjacent_boundary_edges;
                    # if any adjacent bounds closer, replace $boundary_edge with closest
                    for (my $i = 0; $i < @adjacent_boundary_feet; $i++) {
                        next if (!$adjacent_boundary_feet[$i]);
                        my $newfootdist = sqrt(($vnode->{point}->[0] - $adjacent_boundary_feet[$i]->[0])**2 + ($vnode->{point}->[1]-$adjacent_boundary_feet[$i]->[1])**2);
                        if ($newfootdist < $ber) {
                            $boundary_edge = $adjacent_boundary_edges[$i];
                            $bef = $adjacent_boundary_feet[$i];
                            $ber = $newfootdist;
                            }
                        }
                    }

                if (grep $_, @opposite_boundary_feet) {
                    my @sortind = sort {dist2d($vnode->{point},$opposite_boundary_feet[$a]) <=> dist2d($vnode->{point},$opposite_boundary_feet[$b])} grep {$opposite_boundary_feet[$_]} (0..$#opposite_boundary_feet);
                    @opposite_boundary_feet = map $opposite_boundary_feet[$_], @sortind;
                    @opposite_boundary_edges = map $opposite_boundary_edges[$_], @sortind;
                    @opposite_boundary_feet = ($opposite_boundary_feet[0]);
                    @opposite_boundary_edges = ($opposite_boundary_edges[0]);
                    my $obr = dist2d($opposite_boundary_feet[0],$vnode->{point});
                    if ($ber>$obr) {
                        my $tmp = $opposite_boundary_edges[0];
                        $opposite_boundary_edges[0] = $boundary_edge;
                        $boundary_edge = $tmp;
                        $opposite_boundary_feet[0] = $bef;
                        }
                    }

                if (!grep $_, @opposite_boundary_feet) {
                    # make the foot just the opposite point
                    @opposite_boundary_feet = ($opposite_node->{point});
                    # make edge eval to false to signal this fake foot case
                    @opposite_boundary_edges = map {0} @opposite_boundary_edges;
                    }

                }

            # FIND THE TWO TANGENT POINTS, RADIUS, AND SHIFT POINT TO MIC CENTER
            
            # Only one defined unique foot should be in @opposite_boundary_feet
            # at this point, though that wasn't always the case in the past.
            # When we're satisfied that it will be the case in the future, we'll
            # remove the for loop.

            for (my $i = 0; $i < @opposite_boundary_feet; $i++) {
                next if !$opposite_boundary_feet[$i];
                my $foot = $opposite_boundary_feet[$i];
                my $opp_edge = $opposite_boundary_edges[$i];

                my $a1;
                if ($opp_edge) {
                    $a1 = atan2($opp_edge->{nodes}->[0]->{point}->[1] - $opp_edge->{nodes}->[1]->{point}->[1],
                                $opp_edge->{nodes}->[0]->{point}->[0] - $opp_edge->{nodes}->[1]->{point}->[0]);
                    }
                else { # the "fake foot" case, where opposite edge is just a point
                    $a1 = atan2($foot->[1] - $vnode->{point}->[1],
                                $foot->[0] - $vnode->{point}->[0]);
                    $a1 -= $pi / 2;
                    }

                my $a2 = atan2($boundary_edge->{nodes}->[1]->{point}->[1] - $boundary_edge->{nodes}->[0]->{point}->[1],
                               $boundary_edge->{nodes}->[1]->{point}->[0] - $boundary_edge->{nodes}->[0]->{point}->[0]);

                $a1 = angle_reduce_pi($a1);

                my $amid = ($a1 + $a2) / 2;
                my $amidnorm = $amid + $pi / 2;

                my $boundtanpt = line_line_intersection(
                      [ $boundary_edge->{nodes}->[0]->{point}, $boundary_edge->{nodes}->[1]->{point} ],
                      [ $foot, [$foot->[0] + 100 * cos($amidnorm), $foot->[1] + (100 * sin($amidnorm))] ],
                      );

                if ($boundtanpt) {
                    my $midpt=[($foot->[0]+$boundtanpt->[0])/2,($foot->[1]+$boundtanpt->[1])/2];
                    my $nother_mid_pt=[$midpt->[0]-100*cos($amid),$midpt->[1]-100*sin($amid)];
                    my $center = line_line_intersection([$vnode->{point},$foot],[$midpt,$nother_mid_pt]);
                    if ($center) {
                        $new_vnode_points[-1] = $center;
                        $new_vnode_radii[-1] = dist2d($center,$foot);
                        # assign the three tangent pairs to a branch node
                        if (defined $branch_node_edge_index1) {
                            my $gets_both_found = +(grep $_ != $branch_node_edge_index1 && $_ != $branch_node_edge_index2, (0..2))[0];
                            $new_vnode_tangents[-1]->[( $gets_both_found         ) % 3] = [$foot, $boundtanpt];
                            $new_vnode_tangents[-1]->[( $branch_node_edge_index1 ) % 3] = [$branch_node_third_tan, $foot];
                            $new_vnode_tangents[-1]->[( $branch_node_edge_index2 ) % 3] = [$boundtanpt, $branch_node_third_tan];
                            }
                        # assign the two tangent pairs for non-branch nodes
                        else {
                            foreach my $edge (@{$vnode->{edges}}) {
                                next if defined($edge->{vector}) && ($edge->{vector}->[0] != 0 || $edge->{vector}->[1] != 0); # a ray
                                push @{$new_vnode_tangents[-1]}, [$foot, $boundtanpt];
                                }
                            }
                        }
                    }
                }
            }

        if (!defined $new_vnode_radii[-1]) {
            # This would be a branch node that had feet, but didn't end up
            # getting adjusted. This is either an okay edge case or a failure.
            # Let's watch for a while and see if we end up here.
            $new_vnode_radii[-1] = dist2d($vnode->{point},$topo->{edges}->[$vnode->{edges}->[0]->{index}]->{nodes}->[0]->{point});
            print "\nFailure to find radius in Math::Geometery::Delaunay::mic_adjust().\nThe developer would like to know if you come across this.\n";
            }

        }

    # Can probably integrate the node point, radius, and tangents assignments
    # directly into the above section, and get rid of this temp array stuff.
    # On the other hand, if we move this toward using matched index lists (more
    # like Triangle's native output) might just export the lists we made, and not
    # update the crossref'ed hash structure.
    for (my $i = 0; $i < @{$vtopo->{nodes}}; $i++) {
        $vtopo->{nodes}->[$i]->{point} = $new_vnode_points[$i];
        $vtopo->{nodes}->[$i]->{radius} = $new_vnode_radii[$i];
        $vtopo->{nodes}->[$i]->{tangents} = $new_vnode_tangents[$i];
        }

    # Fixup left-right ordering of tangent points, now that
    # vnodes and their edges should all be nicely centered between them. 

    for (my $i = 0; $i < @{$vtopo->{nodes}}; $i++) {
        my $vnode = $vtopo->{nodes}->[$i];

        # first pass -  could you do iswithin for vnode in its corresponding triangle
        # and if not,  shift toward next/previous vnode until it is within
        # like to intersection of line between tri apex and bound edge
        # and line between point and next/prev point... or is there trajectory
        # based on two (usually) boundary edges where the tangents are?
        # 

        my @fixtangents;
        my @edges = grep !defined($_->{vector}) || ($_->{vector}->[0] == 0 && $_->{vector}->[1] == 0), @{$vnode->{edges}};

        for (my $j = 0; $j < @edges; $j++) {
            my $edge = $edges[$j];

            my $tangents = $vnode->{tangents}->[$j]; # tangent pairs correspond to non-ray edges, in order
            my $other_node = ($edge->{nodes}->[0] != $vnode) ? $edge->{nodes}->[0] : $edge->{nodes}->[1];
            my $start_node = $vnode;

            # Duplicate node points can happen for common reasons, so go out
            # to the next node if we got a duplicate. (Three-in-a-row duplicates
            # shouldn't happen.)
            if ($vnode->{point}->[0] eq $other_node->{point}->[0] && $vnode->{point}->[1] eq $other_node->{point}->[1]) {
                my $other_edge = +(grep $_ != $edge && !(defined $_->{vector} && ($_->{vector}->[0] != 0 || $_->{vector}->[1] != 0)), @{$other_node->{edges}})[0];
                if ($other_edge) {
                    $other_node = $other_edge->{nodes}->[0] != $other_node ? $other_edge->{nodes}->[0] : $other_edge->{nodes}->[1];
                    }
                else { 
                    # Well, then, if this is a non-branch node, set up a test line 
                    # using the previous node, heading into this one.
                    if (@{$vnode->{tangents}} == 2) {
                        my $other_edge = $edges[$j == 0 ? 1 : 0];
                        $start_node = ($other_edge->{nodes}->[0] != $vnode) ? $other_edge->{nodes}->[0] : $other_edge->{nodes}->[1];
                        $other_node = $vnode;
                        }
                    #else { die "Couldn't get other edge in duplicate point case\n\n;" }
                    }
                }

            # Heading out from the start node to the other node, the first tangent associated 
            # with this edge should be on the left (a counterclockwise turn), and the
            # other tangent on the right. We've got Triangle's adaptave robust
            # orientation code backing up counterclockwise(), for the really close cases.
            my $ccwl = counterclockwise($start_node->{point}, $other_node->{point}, $tangents->[0]);
            my $ccwr = counterclockwise($start_node->{point}, $other_node->{point}, $tangents->[1]);

            if ($ccwl < 0) { # first tangent wasn't on the left
                if ($ccwr > 0) { # but the second was, so we just need to swap them
                    @{$tangents} = reverse @{$tangents};
                    }
                else { # But if both were on the right, something's wrong.
                    # If this is a branch node, and the other two tangent pairs 
                    # don't have the same problem, we can fix up the bad one later.
                    #push @fixtangents, $j;
                    $vnode->{fixtangents} = [] if !defined $vnode->{fixtangents};
                    push @{$vnode->{fixtangents}}, $j;
                    }
                }
            elsif ($ccwr > 0) { # Both were on the left. Maybe fix up later.
                #push @fixtangents, $j;
                $vnode->{fixtangents} = [] if !defined $vnode->{fixtangents};
                push @{$vnode->{fixtangents}}, $j;
                }
            #elsif ($ccwl eq 0) { die "zero" } # Shouldn't happen. Leave it alone if it does.
            }
        }
    for (my $i = 0; $i < @{$vtopo->{nodes}}; $i++) {
        if (@{$vtopo->{nodes}->[$i]->{tangents}} == 3 && defined $vtopo->{nodes}->[$i]->{fixtangents} && @{$vtopo->{nodes}->[$i]->{fixtangents}} == 1) {
            #print "FIXUP TANGENT PAIR FOR ONE BRANCH AT BRANCH NODE\n";
            #$vtopo->{nodes}->[$i]->{color} = 'orange';
            # one bad tangent pair out of three for a branch node
            # infer that it just needs to be reversed if other two pairs were good

            # debug stuff
            #my @edges = grep !defined($_->{vector}) || ($_->{vector}->[0] == 0 && $_->{vector}->[1] == 0), @{$vtopo->{nodes}->[$i]->{edges}};
            #my $reconsider_edge = $edges[$vtopo->{nodes}->[$i]->{fixtangents}->[0]];
            #my $reconsider_node = $reconsider_edge->{nodes}->[0] != $vtopo->{nodes}->[$i] ? $reconsider_edge->{nodes}->[0]:$reconsider_edge->{nodes}->[1];
            #$reconsider_node->{color} = 'green';

            $vtopo->{nodes}->[$i]->{tangents}->[$vtopo->{nodes}->[$i]->{fixtangents}->[0]] = 
                  [$vtopo->{nodes}->[$i]->{tangents}->[($vtopo->{nodes}->[$i]->{fixtangents}->[0] + 1) % 3]->[1],
                   $vtopo->{nodes}->[$i]->{tangents}->[($vtopo->{nodes}->[$i]->{fixtangents}->[0] - 1)    ]->[0]];

            }
        #if (@{$vtopo->{nodes}->[$i]->{tangents}} == 3 && defined $vtopo->{nodes}->[$i]->{fixtangents} && @{$vtopo->{nodes}->[$i]->{fixtangents}} != 1) {
            #print "  MORE NEEDED FIXUP: ",scalar(@{$vtopo->{nodes}->[$i]->{fixtangents}}),"\n";
            # if more than one branch had tangents mixed up...
            # maybe the other one or two wrong ones are really right?
            # ambiguous.
        #    $vtopo->{nodes}->[$i]->{color} = 'orange';
        #    }
        if (   @{$vtopo->{nodes}->[$i]->{tangents}} == 2
            && $vtopo->{nodes}->[$i]->{tangents}->[0]->[0] == $vtopo->{nodes}->[$i]->{tangents}->[1]->[0]
           ) {
            #print "non-branch maybe needs fixup.\n";
            # not sure if this a good way to approach this -
            # doesn't definitively capture all that can go
            # wrong with non-branch node orientations.
            $vtopo->{nodes}->[$i]->{color} = 'green';
            if (defined $vtopo->{nodes}->[$i]->{fixtangents} && @{$vtopo->{nodes}->[$i]->{fixtangents}} == 1) {
                $vtopo->{nodes}->[$i]->{tangents}->[$vtopo->{nodes}->[$i]->{fixtangents}->[0]] =
                    [$vtopo->{nodes}->[$i]->{tangents}->[$vtopo->{nodes}->[$i]->{fixtangents}->[0] - 1]->[1],
                     $vtopo->{nodes}->[$i]->{tangents}->[$vtopo->{nodes}->[$i]->{fixtangents}->[0] - 1]->[0]];
                }
            }
        }
    }

sub getFoot {
    my $seg = shift;
    my $x = shift;
    my $y = shift;
    my $foot;
    my $m  = ($seg->[1]->[0] - $seg->[0]->[0] == 0) ? 'inf' : ($seg->[1]->[1] - $seg->[0]->[1])/($seg->[1]->[0] - $seg->[0]->[0]);
    my @sortx = $seg->[0]->[0] < $seg->[1]->[0] ? ($seg->[0]->[0], $seg->[1]->[0]) : ($seg->[1]->[0], $seg->[0]->[0]);
    my @sorty = $seg->[0]->[1] < $seg->[1]->[1] ? ($seg->[0]->[1], $seg->[1]->[1]) : ($seg->[1]->[1], $seg->[0]->[1]);
    if ($m == 0) {
        if ($x >= $sortx[0] && $x <= $sortx[1]) {$foot=[$x, $seg->[0]->[1]];}
        }
    elsif ($m == 'inf') {
        if ($y >= $sorty[0] && $y <= $sorty[1]) {$foot=[$seg->[0]->[0], $y];}
        }
    else {
        my $intersect_x = (($m*$seg->[0]->[0])-($seg->[0]->[1])+((1/$m)*$x)+($y))/($m+(1/$m));
        if ($intersect_x >= $sortx[0] && $intersect_x <= $sortx[1]) {
            my $intersect_y = -($seg->[0]->[0] - $intersect_x) * $m + $seg->[0]->[1];
            if ($intersect_y >= $sorty[0] && $intersect_y <= $sorty[1]) {
                $foot = [$intersect_x, $intersect_y];
                }
            }
        }
    return $foot;
    }

sub angle_reduce {
    my $a=shift;
    while($a >   $pi / 2) { $a -= $pi; }
    while($a <= -$pi / 2) { $a += $pi; }
    return $a;
    }

sub angle_reduce_pi {
    my $a=shift;
    while($a >   $pi) { $a -= $pi * 2; }
    while($a <= -$pi) { $a += $pi * 2; }
    return $a;
    }

sub seg_seg_intersection {
    my $seg1 = shift;
    my $seg2 = shift;
    my $int;

    my $x1= $seg1->[0]->[0]; my $y1= $seg1->[0]->[1];
    my $x2= $seg1->[1]->[0]; my $y2= $seg1->[1]->[1];
    my $u1= $seg2->[0]->[0]; my $v1= $seg2->[0]->[1];
    my $u2= $seg2->[1]->[0]; my $v2= $seg2->[1]->[1];

    my $m1 = ($x2 eq $x1)?'Inf':($y2 - $y1)/($x2 - $x1);
    my $m2 = ($u2 eq $u1)?'Inf':($v2 - $v1)/($u2 - $u1);

    my $b1;
    my $b2;
    my $xi;

    # Arranged like this to avoid m1-m2 with infinity involved, which works
    # in other contexts, but can trigger a floating point exception here.
    my $dm;
    if ($m1 != 'Inf' && $m2 != 'Inf') {$dm = $m1 - $m2;}
    elsif ($m1 == 'Inf' && $m2 == 'Inf') {return;}
    else {$dm='Inf';}

    if    ($m1 == 'Inf' && $m2 != 'Inf') {$xi = $x1;$b2 = $v1 - ($m2 * $u1);}
    elsif ($m2 == 'Inf' && $m1 != 'Inf') {$xi = $u1;$b1 = $y1 - ($m1 * $x1);}
    elsif (abs($dm) > 0.000000000001) {
        $b1 = $y1 - ($m1 * $x1);
        $b2 = $v1 - ($m2 * $u1);    
        $xi=($b2-$b1)/$dm;
        }
    my @lowhiu=($u2>$u1)?($u1,$u2):($u2,$u1);
    if ($m1 != 'Inf') {
        my @lowhix=($x2>$x1)?($x1,$x2):($x2,$x1);
        if ($m2 == 'Inf' &&   ($u2<$lowhix[0] || $u2>$lowhix[1]) ) {
            return;
            }
        if (
            ($xi || $xi eq 0) &&
            ($xi < $lowhix[1] || $xi eq $lowhix[1]) && 
            ($xi > $lowhix[0] || $xi eq $lowhix[0]) &&
            ($xi < $lowhiu[1] || $xi eq $lowhiu[1]) && 
            ($xi > $lowhiu[0] || $xi eq $lowhiu[0])
            ) {
            my $y=($m1*$xi)+$b1;
            my @lowhiv=($v2>$v1)?($v1,$v2):($v2,$v1);
            if ($m2 == 'Inf' &&
                ($y<$lowhiv[0] || $y>$lowhiv[1])
                ) {
                return;
                }
            else {
                $int = [$xi,$y];
                }
            }
        }
    elsif ($m2 != 'Inf') { #so $m1 is Inf

        if ($x1 < $lowhiu[0] || $x1 > $lowhiu[1] && ! ($x1 eq $lowhiu[0] || $x1 eq $lowhiu[1])) {
            return;
            }
        my @lowhiy=($y2>$y1)?($y1,$y2):($y2,$y1);
        my @lowhiv=($v2>$v1)?($v1,$v2):($v2,$v1);
        my $yi = ($m2*$xi)+$b2;
        if (($yi || $yi eq 0) &&
            ($yi < $lowhiy[1] || $yi eq $lowhiy[1]) && 
            ($yi > $lowhiy[0] || $yi eq $lowhiy[0]) &&
            ($yi < $lowhiv[1] || $yi eq $lowhiv[1]) && 
            ($yi > $lowhiv[0] || $yi eq $lowhiv[0])
            ) {
            $int = [$xi,$yi];
            }
        }
    return $int;
    }

sub line_line_intersection {
    my $seg1 = shift;
    my $seg2 = shift;
    my $int;

    my $x1= $seg1->[0]->[0]; my $y1= $seg1->[0]->[1];
    my $x2= $seg1->[1]->[0]; my $y2= $seg1->[1]->[1];
    my $u1= $seg2->[0]->[0]; my $v1= $seg2->[0]->[1];
    my $u2= $seg2->[1]->[0]; my $v2= $seg2->[1]->[1];

    my $m1 = ($x2 eq $x1)?'Inf':($y2 - $y1)/($x2 - $x1);
    my $m2 = ($u2 eq $u1)?'Inf':($v2 - $v1)/($u2 - $u1);

    my $b1;
    my $b2;

    my  $xi;

    # Arranged like this to avoid m1-m2 with infinity involved, which works
    # in other contexts, but can trigger a floating point exception here.
    my $dm;
    if ($m1 != 'Inf' && $m2 != 'Inf') {$dm = $m1 - $m2;}
    elsif ($m1 == 'Inf' && $m2 == 'Inf') {return;}
    else {$dm='Inf';}

    if    ($m1 == 'Inf' && $m2 != 'Inf') {$xi = $x1;$b2 = $v1 - ($m2 * $u1);}
    elsif ($m2 == 'Inf' && $m1 != 'Inf') {$xi = $u1;$b1 = $y1 - ($m1 * $x1);}
    elsif (abs($dm) > 0.000000000001) {
        $b1 = $y1 - ($m1 * $x1);
        $b2 = $v1 - ($m2 * $u1);    
        $xi=($b2-$b1)/$dm;
        }
    if ($m1 != 'Inf') {
        if (defined $xi) {
            my $y=($m1*$xi)+$b1;
            $int = [$xi,$y];
            }
        }
    elsif ($m2 != 'Inf') { # so $m1 is Inf
        my $yi = ($m2*$xi)+$b2;
        if ($yi || $yi eq 0) {
            $int = [$xi,$yi];
            }
        }
    return $int;
    }

sub to_svg {
    my %spec = @_;
    my $triios = [defined($spec{topo}) ? delete $spec{topo} : undef, defined($spec{vtopo}) ? delete $spec{vtopo} : undef];
    my $fn = defined($spec{file}) ? delete $spec{file} : '-';
    my $dispsize = defined($spec{size}) ? delete $spec{size} : [800, 600];
    my $triio = $triios->[0];
    my $vorio = @{$triios}?$triios->[1]:undef;
    my @edges;
    my @segs;
    my @pts;
    my @vpts;
    my @vedges;
    my @vrays;
    my @circles;
    my @elements;
    my $maxx;
    my $maxy;
    my $minx;
    my $miny;
    if (!$triio) {carp "no geometry provided";return;}
    foreach my $key ( keys %spec ) { if (ref($spec{$key}) !~ /ARRAY/) { carp("style config for '$key' should be a reference to an array"); return; } } 

    # make copies of points, because we'll be moving and scaling them

    if (ref($triio) =~ /HASH|mgd_topo/ && defined $triio->{nodes}) {
        push @pts, map [$_,defined $spec{nodes}  ? @{$spec{nodes}} : undef], map [@{$_->{point}}], @{$triio->{nodes}};
        }
    else {
        push @pts, map [[@{$_}],defined $spec{nodes}  ? @{$spec{nodes}} : undef], ltolol(2,$triio->pointlist);
        }
    if ($vorio) {
        if (ref($vorio) =~ /HASH|mgd_topo/ && defined $vorio->{nodes}) {
            push @vpts, map [$_,defined $spec{vnodes} ?  @{$spec{vnodes}} : undef], map [@{$_->{point}}], @{$vorio->{nodes}};
            }
        else {
            push @vpts, map [[@{$_}],defined $spec{vnodes} ?  @{$spec{vnodes}} : undef], ltolol(2,$vorio->pointlist);
            }
        }

    $maxx = $pts[0]->[0]->[0];
    $minx = $pts[0]->[0]->[0];
    $maxy = $pts[0]->[0]->[1];
    $miny = $pts[0]->[0]->[1];
    foreach my $pt (@pts,@vpts) {
        if ($maxx < $pt->[0]->[0]) {$maxx = $pt->[0]->[0]}
        if ($maxy < $pt->[0]->[1]) {$maxy = $pt->[0]->[1]}
        if ($minx > $pt->[0]->[0]) {$minx = $pt->[0]->[0]}
        if ($miny > $pt->[0]->[1]) {$miny = $pt->[0]->[1]}
        }

    # offset and scale to avoid limitations of svg renderers

    my $dispsizex = '640';
    my $dispsizey = '480';
    
    if (ref($dispsize) =~ /ARRAY/ && @{$dispsize} > 1) {
        $dispsizex = $dispsize->[0];
        $dispsizey = $dispsize->[1];
        }
    
    # used to scale lines and point circle radii
    # so they stay visible in different viewports dimensions
    my $scale=(sqrt($dispsizex**2+$dispsizey**2))/sqrt(($maxx-$minx)**2+($maxy-$miny)**2);

    foreach (@pts,@vpts) {
        $_->[0]->[0] -= $minx;
        $_->[0]->[0] *= $scale;
        $_->[0]->[1] -= $miny;
        $_->[0]->[1] *= $scale;
        }

    my $scaled_maxx = ($maxx - $minx) * $scale;
    my $scaled_maxy = ($maxy - $miny) * $scale;
    my $scaled_minx = 0;
    my $scaled_miny = 0;

    if (ref($triio) =~ /HASH|mgd_topo/ && defined $triio->{nodes}) {
        if ($spec{edges})    {push @edges, map {[$_,@{$spec{edges}}]}    map [$pts[$_->{nodes}->[0]->{index}]->[0],$pts[$_->{nodes}->[1]->{index}]->[0]], @{$triio->{edges}};}
        if ($spec{segments}) {push @segs,  map {[$_,@{$spec{segments}}]} map [$pts[$_->{nodes}->[0]->{index}]->[0],$pts[$_->{nodes}->[1]->{index}]->[0]], @{$triio->{segments}};}
        #ignoring any subparametric points for elements
        if ($spec{elements}) {push @elements,  map [[map $pts[$_->{index}]->[0], @{$_->{nodes}}[0..2]], (ref($spec{elements}->[0]) =~ /CODE/ ? &{$spec{elements}->[0]}($_) : $spec{elements}->[0]), defined($spec{elements}->[1]) ? $spec{elements}->[1] : ''], @{$triio->{elements}};} #/
        }
    else {
        if ($spec{edges})    {push @edges, map {[[$pts[$_->[0]]->[0],$pts[$_->[1]]->[0]],@{$spec{edges}}]}    ltolol(2,$triio->edgelist);}
        if ($spec{segments}) {push @segs,  map {[[$pts[$_->[0]]->[0],$pts[$_->[1]]->[0]],@{$spec{segments}}]} ltolol(2,$triio->segmentlist);}
        #ignoring any subparametric points for elements
        if ($spec{elements}) {
            push @elements,  map {[[$pts[$_->[0]]->[0],$pts[$_->[1]]->[0],$pts[$_->[2]]->[0]],$spec{elements}->[0], defined($spec{elements}->[1]) ? $spec{elements}->[1] : '']} ltolol($triio->numberofcorners,$triio->trianglelist); #/
            #read triangle attribute list, so at least those are available for choosing fill color in this case
            if (ref($spec{elements}->[0]) =~ /CODE/ && $triio->numberoftriangleattributes > 0 && $triio->numberofregions > 0) {
                my @eleattrs = ltolol($triio->numberoftriangleattributes,$triio->triangleattributes);
                for (my $i=0;$i<@elements;$i++) {
                    # topologically-linked triangle not available here
                    # but we'll fake it at least for the attributes list
                    # so the color callback can still color according to region id
                    # or whatever is in the triangle attribute list
                    $elements[$i]->[1] = &{$spec{elements}->[0]}({attributes=>$eleattrs[$i]});
                    }
                }
            }
        }

    if ($vorio) {
        if (ref($vorio) =~ /HASH|mgd_topo/ && defined $vorio->{nodes}) {
            # circles only available in this case
            if (defined $spec{circles}) {
                push @circles, map {
                                   [
                                    [ # this is point and radius: [x,y,r]
                                     @{$vpts[$_->{index}]->[0]},
                                     defined $_->{radius} 
                                         ? $_->{radius} * $scale
                                         : dist2d($vpts[$_->{index}]->[0],$edges[$_->{edges}->[0]->{index}]->[0]->[0])
                                    ],
                                    @{$spec{circles}}
                                   ]
                                   } @{$vorio->{nodes}};
                }
            if ($spec{vedges}) {
                @vedges = map [[$vpts[$_->{nodes}->[0]->{index}]->[0],$vpts[$_->{nodes}->[1]->{index}]->[0]],@{$spec{vedges}}], grep $_->{vector}->[0] eq 0 && $_->{vector}->[1] eq 0, @{$vorio->{edges}};
                }
            if (defined $spec{vrays}) {
                @vrays  = map [[$vpts[$_->{nodes}->[0]->{index}]->[0],[@{$_->{vector}}]],(defined($spec{vrays}) ? @{$spec{vrays}} : @{$spec{vedges}})], grep $_->{vector}->[0] ne 0 || $_->{vector}->[1] ne 0, @{$vorio->{edges}};
                foreach my $ray (@vrays) {
                    $ray->[0]->[1]->[0] *= $scale;
                    $ray->[0]->[1]->[1] *= $scale;
                    $ray->[0]->[1]->[0] += $ray->[0]->[0]->[0];
                    $ray->[0]->[1]->[1] += $ray->[0]->[0]->[1];
                    }
                }
            }
        else {
            if ($spec{vedges})    {
                my @ves   =ltolol(2,$vorio->edgelist);
                my @vnorms=ltolol(2,$vorio->normlist);
                for (my $i=0;$i<@ves;$i++) {
                    if ($ves[$i]->[0] > -1 && $ves[$i]->[1] > -1) {
                        push @vedges, [[$vpts[$ves[$i]->[0]]->[0],$vpts[$ves[$i]->[1]]->[0]],@{$spec{vedges}}];
                        }
                    elsif (defined $spec{vrays}) {
                        my $baseidx = ($ves[$i]->[0] != -1)?0:1;
                        my $basept = $vpts[$ves[$i]->[$baseidx]]->[0];
                        my $vec = $vnorms[$i];
                        my $h = sqrt($vec->[0]**2 + $vec->[1]**2);
                        $vec = [$vec->[0]/$h,$vec->[1]/$h];
                        push @vrays, [
                            [$basept,[$basept->[0]+$vec->[0]*$maxx,$basept->[1]+$vec->[1]*$maxx]],
                            (defined($spec{vrays}) ? @{$spec{vrays}} : @{$spec{vedges}})];
                        }
                    }
                }
            if ($spec{circles}) {
                for (my $i=0;$i<@vpts;$i++) {
                    push @circles, [[@{$vpts[$i]->[0]},dist2d($vpts[$i]->[0],$elements[$i]->[0])],@{$spec{circles}}];
                    }
                }
            }
        }

    my $margin_x_hi = 5;
    my $margin_x_lo = 5;
    my $margin_y_hi = 5;
    my $margin_y_lo = 5;

    # extend margins to account for the radius of any circles or points
    my @round_things = (@circles, (map {[[$_->[0]->[0], $_->[0]->[1], $_->[2]]]} ( ($spec{nodes} ? @pts : () ), ($spec{vnodes} ? @vpts : () ))));
    if (scalar(@round_things) > 0) {
        my $cir_maxx = $round_things[0]->[0]->[0] + $round_things[0]->[0]->[2];
        my $cir_maxy = $round_things[0]->[0]->[1] + $round_things[0]->[0]->[2];
        my $cir_minx = $round_things[0]->[0]->[0] - $round_things[0]->[0]->[2];
        my $cir_miny = $round_things[0]->[0]->[1] - $round_things[0]->[0]->[2];
        foreach my $cir (@round_things) {
            if ($cir_maxx < $cir->[0]->[0] + $cir->[0]->[2]) {$cir_maxx = $cir->[0]->[0] + $cir->[0]->[2]}
            if ($cir_maxy < $cir->[0]->[1] + $cir->[0]->[2]) {$cir_maxy = $cir->[0]->[1] + $cir->[0]->[2]}
            if ($cir_minx > $cir->[0]->[0] - $cir->[0]->[2]) {$cir_minx = $cir->[0]->[0] - $cir->[0]->[2]}
            if ($cir_miny > $cir->[0]->[1] - $cir->[0]->[2]) {$cir_miny = $cir->[0]->[1] - $cir->[0]->[2]}
            }
        if ($cir_maxx-$scaled_maxx > $margin_x_hi) {$margin_x_hi = ($cir_maxx - $scaled_maxx) + 5;}
        if ($scaled_minx-$cir_minx > $margin_x_lo) {$margin_x_lo = ($scaled_minx - $cir_minx) + 5;}
        if ($cir_maxy-$scaled_maxy > $margin_y_hi) {$margin_y_hi = ($cir_maxy - $scaled_maxy) + 5;}
        if ($scaled_miny-$cir_miny > $margin_y_lo) {$margin_y_lo = ($scaled_miny - $cir_miny) + 5;}
        }

    open(SVGO,'>'.$fn);
    print SVGO sprintf <<"EOS", $dispsizex, $dispsizey, -$margin_x_lo, -$margin_y_hi, $scaled_maxx + ($margin_x_lo + $margin_x_hi), $scaled_maxy + ($margin_y_lo + $margin_y_hi), $scaled_maxy;
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg width="%s" height="%s" viewBox="%s %s %s %s" preserveAspectRatio="xMinYMin meet" xmlns="http://www.w3.org/2000/svg">
<g transform="scale(1,-1) translate(0,-%s)">
EOS

    if ($spec{elements}) {print SVGO "\n<!-- elements -->\n";}
    foreach my $ele (@elements) {
        print SVGO '<path d="M',join('L',map $_->[0].','.$_->[1], @{$ele->[0]}),'" style="fill:',(defined($ele->[1]) ? $ele->[1] : 'none'),';',(defined($ele->[2])?$ele->[2]:''),'"/>',"\n"
        }
    if ($spec{edges}) {print SVGO "\n<!-- edges -->\n";}
    foreach my $edge (@edges) {
        print SVGO '<line x1="',$edge->[0]->[0]->[0],'" y1="',$edge->[0]->[0]->[1],'" x2="',$edge->[0]->[1]->[0],'" y2="',$edge->[0]->[1]->[1],'" style="stroke:',$edge->[1],';stroke-width:',$edge->[2],';',(defined($edge->[3])?$edge->[3]:''),'"/>',"\n"
        }
    if ($spec{segments}) {print SVGO "\n<!-- segments -->\n";}
    foreach my $edge (@segs) {
        print SVGO '<line x1="',$edge->[0]->[0]->[0],'" y1="',$edge->[0]->[0]->[1],'" x2="',$edge->[0]->[1]->[0],'" y2="',$edge->[0]->[1]->[1],'" style="stroke:',$edge->[1],';stroke-width:',$edge->[2],';',(defined($edge->[3])?$edge->[3]:''),'"/>',"\n"
        }
    if ($spec{vedges} && $vorio) {print SVGO "\n<!-- vor edges -->\n";}
    foreach my $edge (@vedges) {
        print SVGO '<line x1="',$edge->[0]->[0]->[0],'" y1="',$edge->[0]->[0]->[1],'" x2="',$edge->[0]->[1]->[0],'" y2="',$edge->[0]->[1]->[1],'" style="stroke:',$edge->[1],';stroke-width:',$edge->[2],';',(defined($edge->[3])?$edge->[3]:''),'"/>',"\n"
        }
    if ($spec{vrays} && $vorio) {print SVGO "\n<!-- vor rays -->\n";}
    foreach my $edge (@vrays) {
        print SVGO '<line x1="',$edge->[0]->[0]->[0],'" y1="',$edge->[0]->[0]->[1],'" x2="',$edge->[0]->[1]->[0],'" y2="',$edge->[0]->[1]->[1],'" style="stroke:',$edge->[1],';stroke-width:',$edge->[2],';',(defined($edge->[3])?$edge->[3]:''),'"/>',"\n"
        }
    if ($spec{nodes}) {
        print SVGO "\n<!-- pts -->\n";
        foreach my $pt (@pts) {
            print SVGO '<circle cx="',$pt->[0]->[0],'" cy="',$pt->[0]->[1],'" r="', $pt->[2] ,'" style="fill:',$pt->[1],';',(defined($pt->[3])?$pt->[3]:''),'"/>',"\n"
            }
        }
    if ($spec{vnodes} && $vorio) {
        print SVGO "\n<!-- vor pts -->\n";
        foreach my $pt (@vpts) {
            print SVGO '<circle cx="',$pt->[0]->[0],'" cy="',$pt->[0]->[1],'" r="', $pt->[2] ,'" style="fill:',$pt->[1],';',(defined($pt->[3])?$pt->[3]:''),'"/>',"\n"
            }
        }
    if ($spec{circles}) {print SVGO "\n<!-- circles -->\n";}
    foreach my $circle (@circles) {
         print SVGO '<circle cx="',$circle->[0]->[0],'" cy="',$circle->[0]->[1],'" r="', $circle->[0]->[2] ,'" style="stroke-width:',$circle->[2],';stroke:',$circle->[1],';fill:none;',(defined($circle->[3])?$circle->[3]:''),'"/>',"\n"
        }

    if ($spec{raw}) {
        print SVGO "\n<!-- raw svg -->\n";
        print SVGO join("\n",map { s/ (c?x[12]?)="([0-9\.eE\-]+)"/' '.$1.'="'.(($2-$minx)*$scale).'"'/ge; 
                                   s/ (c?y[12]?)="([0-9\.eE\-]+)"/' '.$1.'="'.(($2-$miny)*$scale).'"'/ge;
                                   $_;
                                 } @{$spec{raw}});
        }
    print SVGO "\n</g></svg>";
    close(SVGO);
    }

sub dist2d {sqrt(($_[0]->[0]-$_[1]->[0])**2+($_[0]->[1]-$_[1]->[1])**2)}

sub counterclockwise {
    my ($pa, $pb, $pc) = @_;
    return _counterclockwise($pa->[0],$pa->[1],$pb->[0],$pb->[1],$pc->[0],$pc->[1]);
    }

package mgd_topo;

sub DESTROY {
    # circular references in the topology data seem to thwart garbage collection
    # so we'll undo some of the cross references to help with that
    my $self = shift;
    if (exists $self->{elements}) { undef $_->{nodes} for @{$self->{elements}};}
    if (exists $self->{edges})    { undef $_->{nodes} for @{$self->{edges}};   }
    if (exists $self->{segments}) { undef $_->{nodes} for @{$self->{segments}};}
    }

=head1 NAME

Math::Geometry::Delaunay - Quality Mesh Generator and Delaunay Triangulator

=head1 VERSION

Version 0.21

=cut

=head1 SYNOPSIS

=for html <div style="width:30%;float:right;display:inline-block;text-align:center;">
<svg viewBox="0 0 8 6" height="75px" preserveAspectRatio="xMinYMin meet" xmlns="http://www.w3.org/2000/svg" version="1.1">
<g transform="scale(1,-1) translate(0,-6)">
<circle r="0.15" cx="1" cy="1" style="fill:blue"/>
<circle r="0.15" cx="7" cy="1" style="fill:blue"/>
<circle r="0.15" cx="7" cy="3" style="fill:blue"/>
<circle r="0.15" cx="3" cy="3" style="fill:blue"/>
<circle r="0.15" cx="3" cy="5" style="fill:blue"/>
<circle r="0.15" cx="1" cy="5" style="fill:blue"/>
</g></svg><br/>
<br/><small>input vertices</small><br/>
<svg viewBox="0 0 8 6" height="75px" preservAspectRatio="minXminY meet" xmlns="http://www.w3.org/2000/svg" version="1.1">
<g transform="scale(1,-1) translate(0,-6)">
<line x1="1" y1="1" x2="3" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3" y1="3" x2="1" y2="5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="5" x2="1" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="1" x2="7" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="7" y1="1" x2="3" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3" y1="3" x2="3" y2="5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3" y1="5" x2="1" y2="5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3" y1="3" x2="7" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="7" y1="3" x2="3" y2="5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="7" y1="1" x2="7" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<circle cx="1" cy="1" r="0.150" style="fill:blue;"/>
<circle cx="7" cy="1" r="0.150" style="fill:blue;"/>
<circle cx="7" cy="3" r="0.150" style="fill:blue;"/>
<circle cx="3" cy="3" r="0.150" style="fill:blue;"/>
<circle cx="3" cy="5" r="0.150" style="fill:blue;"/>
<circle cx="1" cy="5" r="0.150" style="fill:blue;"/>
</g></svg>
<br/><small>Delaunay triangulation</small><br/>
<svg viewBox="0 0 8 6" height="75px" preservAspectRatio="minXminY meet" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:slic3r="http://slic3r.org/namespaces/slic3r">
<g transform="scale(1,-1) translate(0,-5)">
<line x1="1" y1="3" x2="4" y2="0" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="3" x2="2" y2="4" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4" y1="0" x2="5" y2="2" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2" y1="4" x2="5" y2="4" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5" y1="4" x2="5" y2="2" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="3" x2="-139" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4" y1="0" x2="4" y2="-210" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2" y1="4" x2="2" y2="74" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5" y1="4" x2="75" y2="144" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5" y1="2" x2="75" y2="2" style="stroke:gray;stroke-width:0.1;"/>
<circle cx="1" cy="3" r="0.15" style="fill:blue;"/>
<circle cx="4" cy="0" r="0.15" style="fill:blue;"/>
<circle cx="2" cy="4" r="0.15" style="fill:blue;"/>
<circle cx="5" cy="4" r="0.15" style="fill:blue;"/>
<circle cx="5" cy="2" r="0.15" style="fill:blue;"/>
</g></svg>
<br/><small>Voronoi diagram</small>
</div>

    use Math::Geometry::Delaunay qw(TRI_CCDT);

    # generate Delaunay triangulation
    # and Voronoi diagram for a point set

    my $point_set = [ [1,1], [7,1], [7,3],
                      [3,3], [3,5], [1,5] ];

    my $tri = new Math::Geometry::Delaunay();
    $tri->addPoints($point_set);
    $tri->doEdges(1);
    $tri->doVoronoi(1);
    
    # called in void context
    $tri->triangulate();
    # populates the following lists

    $tri->elements(); # triangles
    $tri->nodes();    # points
    $tri->edges();    # triangle edges
    $tri->vnodes();   # Voronoi diagram points
    $tri->vedges();   # Voronoi edges and rays


=for html <br clear="all"/><div style="margin-top:30px;width:30%;float:right;display:inline-block;text-align:center;">
<svg viewBox="0 0 8 6" height="75px" preserveAspectRatio="xMinYMin meet" xmlns="http://www.w3.org/2000/svg" version="1.1">
<g transform="scale(1,-1) translate(0,-6)">
<line x1="7" y1="1" x2="1" y2="1" style="stroke:blue;stroke-width:0.1;"/>
<line x1="7" y1="3" x2="7" y2="1" style="stroke:blue;stroke-width:0.1;"/>
<line x1="3" y1="3" x2="7" y2="3" style="stroke:blue;stroke-width:0.1;"/>
<line x1="3" y1="3" x2="3" y2="5" style="stroke:blue;stroke-width:0.1;"/>
<line x1="1" y1="5" x2="3" y2="5" style="stroke:blue;stroke-width:0.1;"/>
<line x1="1" y1="1" x2="1" y2="5" style="stroke:blue;stroke-width:0.1;"/>
<circle cx="1" cy="1" r="0.15" style="fill:black;"/>
<circle cx="7" cy="1" r="0.15" style="fill:black;"/>
<circle cx="7" cy="3" r="0.15" style="fill:black;"/>
<circle cx="3" cy="3" r="0.15" style="fill:black;"/>
<circle cx="3" cy="5" r="0.15" style="fill:black;"/>
<circle cx="1" cy="5" r="0.15" style="fill:black;"/>
</g></svg>
<br/><small>input PSLG</small><br/>
<svg viewBox="0 0 8 6" height="75px" preserveAspectRatio="xMinYMin meet" style="margin-top:23px;" xmlns="http://www.w3.org/2000/svg" version="1.1">
<g transform="scale(1,-1) translate(0,-6)">
<line x1="1.55" y1="2.5" x2="1" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="3" x2="1" y2="2" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="2" x2="1.55" y2="2.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4.75" y1="1.72322767215881" x2="4" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4" y1="1" x2="5.5" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5.5" y1="1" x2="4.75" y2="1.72322767215881" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3" y1="5" x2="2" y2="5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2" y1="5" x2="2.25" y2="4.25" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.25" y1="4.25" x2="3" y2="5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3" y1="4" x2="2.25" y2="4.25" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.25" y1="4.25" x2="2" y2="3.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2" y1="3.5" x2="3" y2="4" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.25" y1="2.75" x2="3" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3" y1="3" x2="2" y2="3.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2" y1="3.5" x2="2.25" y2="2.75" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.93181818181818" y1="1.95454545454545" x2="3.71892953370153" y2="1.8730674509337" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3.71892953370153" y1="1.8730674509337" x2="3.5" y2="2.52618854085072" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3.5" y1="2.52618854085072" x2="2.93181818181818" y2="1.95454545454545" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3" y1="3" x2="3" y2="4" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.25" y1="4.25" x2="1.33333333333333" y2="4.13888888888889" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1.33333333333333" y1="4.13888888888889" x2="2" y2="3.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3" y1="4" x2="3" y2="5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2" y1="5" x2="1.33333333333333" y2="4.13888888888889" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2" y1="5" x2="1" y2="5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="5" x2="1.33333333333333" y2="4.13888888888889" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="5" x2="1" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="3" x2="1.33333333333333" y2="4.13888888888889" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="3" x2="2" y2="3.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.93181818181818" y1="1.95454545454545" x2="1.8375" y2="1.63125" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1.8375" y1="1.63125" x2="2.5" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.5" y1="1" x2="2.93181818181818" y2="1.95454545454545" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.25" y1="2.75" x2="1.8375" y2="1.63125" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.93181818181818" y1="1.95454545454545" x2="2.25" y2="2.75" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.5" y1="1" x2="3.25" y2="1.23566017316017" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3.25" y1="1.23566017316017" x2="2.93181818181818" y2="1.95454545454545" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1.8375" y1="1.63125" x2="1" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="1" x2="2.5" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1.55" y1="2.5" x2="2" y2="3.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.25" y1="2.75" x2="1.55" y2="2.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1.55" y1="2.5" x2="1.8375" y2="1.63125" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1.8375" y1="1.63125" x2="1" y2="2" style="stroke:gray;stroke-width:0.1;"/>
<line x1="1" y1="2" x2="1" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.5" y1="1" x2="4" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4" y1="1" x2="3.25" y2="1.23566017316017" style="stroke:gray;stroke-width:0.1;"/>
<line x1="2.93181818181818" y1="1.95454545454545" x2="3" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3.71892953370153" y1="1.8730674509337" x2="4.75" y2="1.72322767215881" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4.75" y1="1.72322767215881" x2="4.5" y2="2.43504117935408" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4.5" y1="2.43504117935408" x2="3.71892953370153" y2="1.8730674509337" style="stroke:gray;stroke-width:0.1;"/>
<line x1="7" y1="2" x2="6.5096079838992" y2="2.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="6.5096079838992" y1="2.5" x2="6.36316415068211" y2="1.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="6.36316415068211" y1="1.5" x2="7" y2="2" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4" y1="3" x2="3" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3" y1="3" x2="3.5" y2="2.52618854085072" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3.5" y1="2.52618854085072" x2="4" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3.25" y1="1.23566017316017" x2="3.71892953370153" y2="1.8730674509337" style="stroke:gray;stroke-width:0.1;"/>
<line x1="3.71892953370153" y1="1.8730674509337" x2="4" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5" y1="3" x2="4.5" y2="2.43504117935408" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4.5" y1="2.43504117935408" x2="5.42596576190246" y2="1.67372070106296" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5.42596576190246" y1="1.67372070106296" x2="5" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5.42596576190246" y1="1.67372070106296" x2="4.75" y2="1.72322767215881" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5.5" y1="1" x2="5.42596576190246" y2="1.67372070106296" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4" y1="3" x2="4.5" y2="2.43504117935408" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5" y1="3" x2="4" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="4.5" y1="2.43504117935408" x2="3.5" y2="2.52618854085072" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5.5" y1="1" x2="6.36316415068211" y2="1.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="6.36316415068211" y1="1.5" x2="5.42596576190246" y2="1.67372070106296" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5" y1="3" x2="5.89643888151886" y2="2.16160972037971" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5.89643888151886" y1="2.16160972037971" x2="6.5096079838992" y2="2.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="6.5096079838992" y1="2.5" x2="5" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="7" y1="1" x2="7" y2="2" style="stroke:gray;stroke-width:0.1;"/>
<line x1="6.36316415068211" y1="1.5" x2="7" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5.42596576190246" y1="1.67372070106296" x2="5.89643888151886" y2="2.16160972037971" style="stroke:gray;stroke-width:0.1;"/>
<line x1="6.5096079838992" y1="2.5" x2="7" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="7" y1="3" x2="5" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="7" y1="2" x2="7" y2="3" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5.89643888151886" y1="2.16160972037971" x2="6.36316415068211" y2="1.5" style="stroke:gray;stroke-width:0.1;"/>
<line x1="5.5" y1="1" x2="7" y2="1" style="stroke:gray;stroke-width:0.1;"/>
<line x1="7" y1="1" x2="5.5" y2="1" style="stroke:blue;stroke-width:0.1;"/>
<line x1="7" y1="3" x2="7" y2="2" style="stroke:blue;stroke-width:0.1;"/>
<line x1="3" y1="3" x2="4" y2="3" style="stroke:blue;stroke-width:0.1;"/>
<line x1="3" y1="4" x2="3" y2="5" style="stroke:blue;stroke-width:0.1;"/>
<line x1="1" y1="5" x2="2" y2="5" style="stroke:blue;stroke-width:0.1;"/>
<line x1="1" y1="1" x2="1" y2="2" style="stroke:blue;stroke-width:0.1;"/>
<line x1="3" y1="4" x2="3" y2="3" style="stroke:blue;stroke-width:0.1;"/>
<line x1="2" y1="5" x2="3" y2="5" style="stroke:blue;stroke-width:0.1;"/>
<line x1="1" y1="3" x2="1" y2="5" style="stroke:blue;stroke-width:0.1;"/>
<line x1="1" y1="2" x2="1" y2="3" style="stroke:blue;stroke-width:0.1;"/>
<line x1="4" y1="1" x2="2.5" y2="1" style="stroke:blue;stroke-width:0.1;"/>
<line x1="2.5" y1="1" x2="1" y2="1" style="stroke:blue;stroke-width:0.1;"/>
<line x1="5" y1="3" x2="7" y2="3" style="stroke:blue;stroke-width:0.1;"/>
<line x1="4" y1="3" x2="5" y2="3" style="stroke:blue;stroke-width:0.1;"/>
<line x1="5.5" y1="1" x2="4" y2="1" style="stroke:blue;stroke-width:0.1;"/>
<line x1="7" y1="2" x2="7" y2="1" style="stroke:blue;stroke-width:0.1;"/>
<circle cx="1" cy="1" r="0.15" style="fill:black;"/>
<circle cx="7" cy="1" r="0.15" style="fill:black;"/>
<circle cx="7" cy="3" r="0.15" style="fill:black;"/>
<circle cx="3" cy="3" r="0.15" style="fill:black;"/>
<circle cx="3" cy="5" r="0.15" style="fill:black;"/>
<circle cx="1" cy="5" r="0.15" style="fill:black;"/>
<circle cx="1" cy="3" r="0.15" style="fill:black;"/>
<circle cx="3" cy="4" r="0.15" style="fill:black;"/>
<circle cx="2" cy="5" r="0.15" style="fill:black;"/>
<circle cx="2" cy="3.5" r="0.15" style="fill:black;"/>
<circle cx="2.25" cy="4.25" r="0.15" style="fill:black;"/>
<circle cx="1.33" cy="4.138" r="0.15" style="fill:black;"/>
<circle cx="2.9318" cy="1.95" r="0.15" style="fill:black;"/>
<circle cx="4" cy="1" r="0.15" style="fill:black;"/>
<circle cx="2.25" cy="2.75" r="0.15" style="fill:black;"/>
<circle cx="1" cy="2" r="0.15" style="fill:black;"/>
<circle cx="1.55" cy="2.5" r="0.15" style="fill:black;"/>
<circle cx="1.8375" cy="1.63125" r="0.15" style="fill:black;"/>
<circle cx="2.5" cy="1" r="0.15" style="fill:black;"/>
<circle cx="3.25" cy="1.235" r="0.15" style="fill:black;"/>
<circle cx="5.5" cy="1" r="0.15" style="fill:black;"/>
<circle cx="4" cy="3" r="0.15" style="fill:black;"/>
<circle cx="5" cy="3" r="0.15" style="fill:black;"/>
<circle cx="3.7189" cy="1.873" r="0.15" style="fill:black;"/>
<circle cx="4.75" cy="1.723" r="0.15" style="fill:black;"/>
<circle cx="3.5" cy="2.526" r="0.15" style="fill:black;"/>
<circle cx="5.896" cy="2.1616" r="0.15" style="fill:black;"/>
<circle cx="4.5" cy="2.435" r="0.15" style="fill:black;"/>
<circle cx="5.4259" cy="1.6737" r="0.15" style="fill:black;"/>
<circle cx="7" cy="2" r="0.15" style="fill:black;"/>
<circle cx="6.5096" cy="2.5" r="0.15" style="fill:black;"/>
<circle cx="6.36316" cy="1.5" r="0.15" style="fill:black;"/>
</g></svg>
<br/><small>output mesh</small><br/>
<svg viewBox="0 0 8 6" height="75px" preserveAspectRatio="xMinYMin meet" style="margin-top:23px;" xmlns="http://www.w3.org/2000/svg" version="1.1">
<g transform="scale(1,-1) translate(0,-6)">
<g style="fill:black">
<polygon points="1.55,2.5,1,3,1,2"/>
<polygon points="4.75,1.723,4,1,5.5,1"/>
<polygon points="3,5,2,5,2.25,4.25"/>
<polygon points="3,3,3,4,2,3.5"/>
<polygon points="3,5,2.25,4.25,3,4"/>
<polygon points="1.333,4.139,2,5,1,5"/>
<polygon points="1,5,1,3,1.333,4.139"/>
<polygon points="1.837,1.631,1,1,2.5,1"/>
<polygon points="1,1,1.837,1.631,1,2"/>
<polygon points="2.5,1,4,1,3.25,1.236"/>
<polygon points="4,3,3,3,3.5,2.526"/>
<polygon points="4,3,4.5,2.435,5,3"/>
<polygon points="7,1,7,2,6.363,1.5"/>
<polygon points="5,3,6.51,2.5,7,3"/>
<polygon points="7,3,6.51,2.5,7,2"/>
<polygon points="5.5,1,7,1,6.363,1.5"/>
</g>
<g style="fill:gray">
<polygon points="3,4,2.25,4.25,2,3.5"/>
<polygon points="2.25,2.75,3,3,2,3.5"/>
<polygon points="2,5,1.333,4.139,2.25,4.25"/>
<polygon points="1,3,2,3.5,1.333,4.139"/>
<polygon points="2.932,1.955,1.837,1.631,2.5,1"/>
<polygon points="2.5,1,3.25,1.236,2.932,1.955"/>
<polygon points="1.55,2.5,2,3.5,1,3"/>
<polygon points="2.25,2.75,2.932,1.955,3,3"/>
<polygon points="1.55,2.5,1,2,1.837,1.631"/>
<polygon points="7,2,6.51,2.5,6.363,1.5"/>
<polygon points="4,1,4.75,1.723,3.719,1.873"/>
<polygon points="4,1,3.719,1.873,3.25,1.236"/>
<polygon points="5,3,4.5,2.435,5.426,1.674"/>
<polygon points="5.426,1.674,4.75,1.723,5.5,1"/>
<polygon points="2.932,1.955,3.5,2.526,3,3"/>
<polygon points="5.5,1,6.363,1.5,5.426,1.674"/>
<polygon points="5,3,5.896,2.162,6.51,2.5"/>
<polygon points="4.5,2.435,4,3,3.5,2.526"/>
<polygon points="5.426,1.674,5.896,2.162,5,3"/>
</g>
</g></svg>
<br/><small>something interesting<br/>extracted from topology</small>
</div>

    # quality mesh of a planar straight line graph
    # with cross-referenced topological output

    my $tri = new Math::Geometry::Delaunay();
    $tri->addPolygon($point_set);
    $tri->minimum_angle(23);
    $tri->doEdges(1);

    # called in scalar context
    my $mesh_topology = $tri->triangulate(TRI_CCDT);
    # returns cross-referenced topology

    # make two lists of triangles that touch boundary segments

    my @tris_with_boundary_segment;
    my @tris_with_boundary_point;

    foreach my $triangle (@{$mesh_topology->{elements}}) {
            my $nodes_on_boundary_count = ( 
                grep $_->{marker} == 1,
                @{$triangle->{nodes}} 
                );
            if ($nodes_on_boundary_count == 2) {
                push @tris_with_boundary_segment, $triangle;
                }
            elsif ($nodes_on_boundary_count == 1) {
                push @tris_with_boundary_point, $triangle;
                }
            }
            

=for html <br clear="all"/>

=head1 DESCRIPTION

This is a Perl interface to the Jonathan Shewchuk's Triangle library.

"Triangle generates exact Delaunay triangulations, constrained Delaunay 
triangulations, conforming Delaunay triangulations, Voronoi diagrams, and 
high-quality triangular meshes. The latter can be generated with no small or 
large angles, and are thus suitable for finite element analysis." 
-- from L<http://www.cs.cmu.edu/~quake/triangle.html>

=head1 EXPORTS

Triangle has several option switches that can be used in different combinations 
to choose a class of triangulation and then configure options within that class.
To clarify the composition of option strings, or just to give you a head start, 
a few constants are supplied to configure different classes of mesh output.

    TRI_CONSTRAINED  = 'Y'    for "Constrained Delaunay"
    TRI_CONFORMING   = 'Dq0'  for "Conforming Delaunay"
    TRI_CCDT         = 'q'    for "Constrained Conforming Delaunay"
    TRI_VORONOI      = 'v'    to generate the Voronoi diagram

For an illustration of these terms, see: 
L<http://www.cs.cmu.edu/~quake/triangle.defs.html>

=head1 CONSTRUCTOR

=head2 new

The constructor returns a Math::Geometry::Delaunay object.

    my $tri = Math::Geometry::Delaunay->new();

=head1 MESH GENERATION

=head2 triangulate

Run the triangulation with specified options, and either populate the object's
output lists, or return a hash reference giving access to a cross-referenced 
representation of the mesh topology.

Common options can be set prior to calling C<triangulate>. The full range of 
Triangle's options can also be passed to C<triangulate> as a string, or list 
of strings. For example:

    my $tri = Math::Geometry::Delaunay->new('pzq0eQ');

    my $tri = Math::Geometry::Delaunay->new(TRI_CCDT, 'q15', 'a3.5');

Triangle's command line switches are documented here: 
L<http://www.cs.cmu.edu/~quake/triangle.switch.html>

=head3 list output

After triangulate is invoked in void context, the output mesh data can be 
retrieved from the following methods, all of which return a reference to an 
array.

    $tri->triangulate(); # void context - no return value requested
    # output lists now available
    $points  = $tri->nodes();    # array of vertices
    $tris    = $tri->elements(); # array of triangles
    $edges   = $tri->edges();    # all the triangle edges
    $segs    = $tri->segments(); # the PSLG segments
    $vpoints = $tri->vnodes();   # points in the voronoi diagram
    $vedges  = $tri->vedges();   # edges in the voronoi diagram

Data may not be available for all lists, depending on which option switches were
used. By default, nodes and elements are generated, while edges are not.

The members of the lists returned have these formats:

    nodes:    [x, y, < zero or more attributes >, < boundary marker >]

    elements: [[x0, y0], [x1, y1], [x2, y2],
                < another three vertices, if "o2" switch used >,
                < zero or more attributes >
                ]
    edges:    [[x0, y0], [x1, y1], < boundary marker >]

    segments: [[x0, y0], [x1, y1], < boundary marker >]

    vnodes:   [x, y, < zero or more attributes >]

    vedges:   [< vertex or vector >, < vertex or vector >, < ray flag >]

Boundary markers are 1 or 0. An edge or segment with only one end on a boundary 
has boundary marker 0.

The ray flag is 0 if the edge is not a ray, or 1 or 2, to indicate 
which vertex is actually a unit vector indicating the direction of the ray.

Import of the mesh data from the C data structures will be deferred until
actually requested from the list fetching methods above. For speed and 
lower memory footprint, access only what you need, and consider suppressing 
output you don't need with option switches.

=head3 topological output

When triangulate is invoked in scalar or array context, it returns a hash ref 
containing the cross-referenced nodes, elements, edges, and PSLG segments of the
triangulation. In array context, with the "v" switch enabled, the Voronoi
topology is the second item returned.

    my $topology = $tri->triangulate();

    $topology now looks like this:
    
    {
    nodes    => [
                  { # a node
                  point      => [x0, x1],
                  edges      => [edgeref, ...],
                  segments   => [edgeref, ...], # a subset of edges
                  elements   => [elementref, ...],
                  marker     => 1 or 0 or undefined, # boundary marker
                  attributes => [attr0, ...]
                  },
                  ... more nodes like that
                    
                ],
    elements => [
                  { # a triangle
                  nodes      => [noderef0, noderef1, noderef2],
                  edges      => [edgeref0, edgeref1, edgeref2],
                  neighbors  => [neighref0, neighref1, neighref2],
                  attributes => [attrib0, ...]
                  },
                  ... more triangles like that
                ],
    edges    => [
                  {
                  nodes    => [noderef0, noderef1], # only one for a ray
                  elements => [elemref0, elemref1], # one if on boundary
                  vector   => undefined or [x, y],  # ray direction
                  marker   => 1 or 0 or undefined,  # boundary marker
                  index    => <integer> # edge's index in edge list
                  },
                  ... more edges like that
                    
                ],
    segments => [
                  {
                  nodes    => [noderef0, noderef1],
                  elements => [elemref0, elemref1], # one if on boundary
                  marker   => 1 or 0 or undefined   # boundary marker
                  },
                  ... more segments
                ]
    }

=head3 cross-referencing Delaunay and Voronoi

Corresponding Delaunay triangles and Voronoi nodes have the same index number
in their respective lists.

In the topological output, any element in a triangulation has a record of its 
own index number that can by used to look up the corresponding node in the 
Voronoi diagram topology, or vice versa, like so:

    ($topo, $voronoi_topo) = $tri->triangulate('v');

    # get a triangle reference where the index is not obvious
    
    $element = $topo->{nodes}->[-1]->{elements}->[-1];
    
    # this gets a reference to the corresponding node in the Voronoi diagram
    
    $voronoi_node = $voronoi_topo->{nodes}->[$element->{index}];


Corresponding edges in the Delaunay and Voronoi outputs have the same index
number in their respective edge lists. 

In the topological output, any edge in a triangulation has a record of its own 
index number that can by used to look up the corresponding edge in the Voronoi 
diagram topology, or vice versa, like so:

    ($topo, $voronoi_topo) = $tri->triangulate('ev');
    
    # get an edge reference where it's not obvious what the edge's index is
    
    $delaunay_edge = $topo->{nodes}->[-1]->{edges}->[-1];
    
    # this gets a reference to the corresponding edge in the Voronoi diagram
    
    $voronoi_edge = $voronoi_topo->{edges}->[$delaunay_edge->{index}];

=head1 METHODS TO SET SOME Triangle OPTIONS

=head2 area_constraint

Corresponds to the "a" switch.

With one argument, sets the maximum triangle area constraint for the 
triangulation. Returns the value supplied. With no argument, returns the 
current area constraint.

Passing -1 to C<area_constraint()> will disable the global area constraint.

=head2 minimum_angle

Corresponds to the "q" switch.

With one argument, sets the minimum angle allowed for triangles added in the
triangulation. Returns the value supplied. With no argument, returns the
current minimum angle constraint.

Passing -1 to C<minimum_angle()> will cause the "q" switch to be omitted from
the option string.

=head2 doEdges, doVoronoi, doNeighbors

These methods simply add or remove the corresponding letters from the 
option string. Pass in a true or false value to enable or disable.
Invoke with no argument to read the current state.

=head2 quiet, verbose

Triangle prints a basic summary of the meshing operation to STDOUT unless
the "Q" switch is present. This module includes the "Q" switch by default, but
you can override this by passing a false value to C<quiet()>.

If you would like to see even more output regarding the triangulation process,
there are are three levels of verbosity configurable with repeated "V"
switches. Passing a number from 1 to 3 to the C<verbose()> method will enable 
the corresponding level of verbosity.

=head1 METHODS TO ADD VERTICES AND SEGMENTS

=head2 addVertices, addPoints

Takes a reference to an array of vertices, each vertex itself an reference to
an array containing two coordinates and zero or more attributes. Attributes
are floating point numbers.
    
    # vertex format
    # [x, y, < zero or more attributes as floating point numbers >]

    $tri->addPoints([[$x0, $y0], [$x1, $y1], ... ]);

Use addVertices to add vertices that are not part of a PSLG. 
Use addPoints to add points that are not part of a polygon or polyline.
In other words, they do the same thing.

=head2 addSegments

Takes a reference to an array of segments.

    # segment format
    # [[$x0, $y0], [$x1, $y1]]

    $tri->addSegments([ $segment0, $segment1, ... ]);

If your segments are contiguous, it's better to use addPolyline, or addPolygon.

This method is provided because some point and polygon processing algorithms
result in segments that represent polygons, but list the segments in a 
non-contiguous order, and have shared vertices repeated in each segment's record.

The segments added with this method will be checked for duplicate vertices, and 
references to these will be merged.

Triangle can handle duplicate vertices, but we would rather not feed them in on 
purpose.

=head2 addPolyline

Takes a reference to an array of vertices describing a curve. 
Creates PSLG segments for each pair of adjacent vertices. Adds the
new segments and vertices to the triangulation input.

    $tri->addPolyline([$vertex0, $vertex1, $vertex2, ...]);

=head2 addPolygon

Takes a reference to an array of vertices describing a polygon. 
Creates PSLG segments for each pair of adjacent vertices
and creates and additional segment linking the last vertex to
the first,to close the polygon.  Adds the new segments and vertices 
to the triangulation input.

    $tri->addPolygon([$vertex0, $vertex1, $vertex2, ...]);

=head2 addHole

Like addPolygon, but describing a hole or concavity - an area of the output mesh
that should not be triangulated. 

There are two ways to specify a hole. Either provide a list of vertices, like
for addPolygon, or provide a single vertex that lies inside of a polygon, to
identify that polygon as a hole.

    # first way
    $tri->addHole([$vertex0, $vertex1, $vertex2, ...]);

    # second way
    $tri->addPolygon( [ [0,0], [1,0], [1,1], [0,1] ] );
    $tri->addHole( [0.5,0.5] );

Hole marker points can also be used, in combination with the "c" option, to
cause or preserve concavities in a boundary when Triangle would otherwise
enclose a PSLG in a convex hull.

=head2 addRegion

Takes a polygon describing a region, and an attribute or area constraint. With
both the "A" and "a" switches in effect, three arguments allow you to specify
both an attribute and an optional area constraint.

The first argument may alternately be a single vertex that lies inside of 
another polygon, to identify that polygon as a region.

To be used in conjunction with the "A" and "a" switches.

    # with the "A" switch
    $tri->addRegion(\@polygon, < attribute > );
    
    # with the "a" switch
    $tri->addRegion(\@polygon, < area constraint > );

    # with both "Aa"
    $tri->addRegion(\@polygon, < attribute >, < area constraint > );

If the "A" switch is used, each triangle generated within the bounds of a region
will have that region's attribute added to the end of the triangle's 
attributes list, while each triangle not within a region will have a "0" added
to the end of its attribute list.

If the "a" switch is used without a number following, each triangle generated 
within the bounds of a region will be subject to that region's area
constraint.

If the "A" or "a" switches are not in effect, addRegion has the same effect as 
addPolygon.

=head1 METHODS TO ACCESS OUTPUT LISTS

The following methods retrieve the output lists after the triangulate method has
been invoked in void context.

Triangle's output data is not imported from C to Perl until one of these methods
is invoked, and then only what's needed to construct the list requested. So 
there may be a speed or memory advantage to accessing the output in this way - 
only what you need, when you need it.

The methods prefixed with "v" access the Voronoi diagram nodes and edges, if one
was generated.

=head2 nodes

Returns a reference to a list of nodes (vertices or points). 

    my $pointlist = $tri->nodes();    # retrieve nodes/vertices/points
    
The nodes in the list have this structure:

    [x, y, < zero or more attributes >, < boundary marker >]

=head2 elements

Returns a reference to a list of elements.

    $triangles  = $tri->elements(); # retrieve triangle list

The elements in the list have this structure:

    [[x0, y0], [x1, y1], [x2, y2],
     < another three vertices, if "o2" switch used >
     < zero or more attributes >
    ]

=head2 segments

Returns a reference to a list of segments.

    $segs  = $tri->segments(); # retrieve the PSLG segments

The segments in the list have this structure:

    [[x0, y0], [x1, y1], < boundary marker >]

=head2 edges

Returns a reference to a list of edges.

    $edges  = $tri->edges();    # retrieve all the triangle edges

The edges in the list have this structure:

    [[x0, y0], [x1, y1], < boundary marker >]

Note that the edge list is not produced by default. Request that it be generated
by invoking C<doEdges(1)>, or passing the 'e' switch to C<triangulate()>.

=head2 vnodes

Returns a reference to a list of nodes in the Voronoi diagram.

    $vpointlist = $tri->vnodes();   # retrieve Voronoi vertices

The Voronoi diagram nodes in the list have this structure:

    [x, y, < zero or more attributes >]

=head2 vedges

Returns a reference to a list of edges in the Voronoi diagram. Some of these
edges are actually rays.

    $vedges = $tri->vedges();   # retrieve Voronoi diagram edges and rays 

The Voronoi diagram edges in the list have this structure:

    [< vertex or vector >, < vertex or vector >, < ray flag >]

If the edge is a true edge, the ray flag will be 0.
If the edge is actually a ray, the ray flag will either be 1 or 2,
to indicate whether the the first, or second vertex should be interpreted as
a direction vector for the ray.

=head1 UTILITY FUNCTIONS

=head2 to_svg

This function is meant as a development and debugging aid, to "dump" the
geometric data structures specific to this package to a graphical
representation. Takes key-value pairs to specify topology hashes, output file,
image dimensions, and styles for the elements in the various output lists.

The topology hash input for the C<topo> or C<vtopo> keys is just the hash
returned by C<triangulate>. The value for the C<file> key is a file name string.
Omit C<file> to print to STDOUT. For C<size>, provide and array ref with width
and height, in pixels. For output list styles, keys correspond to the output 
list names, and values consist of references to arrays containing style 
configurations, as demonstrated below.

Only geometry that has a style configuration will be displayed. The following
example includes everything. To display a subset, just omit any of the style
configuration key-value pairs.

    ($topo, $vtopo) = $tri->triangulate('ve');

    to_svg( topo  => $topo,
            vtopo => $vtopo,
            
            file => "enchilada.svg",    # omit for STDOUT
            size => [800, 600],         # width, height in pixels
            
            #                     line width or   optional
            #         svg color   point radius    extra CSS
            
            nodes    => ['black'  ,   0.3],
            edges    => ['#CCCCCC',   0.7],
            segments => ['blue'   ,   0.9,     'stroke-dasharray:1 1;'],
            elements => ['pink']  , # string or callback; see below

            # these require Voronoi input (vtopo)

            vnodes   => ['purple' ,   0.3],
            vedges   => ['#FF0000',   0.7],
            vrays    => ['purple' ,   0.6],
            circles  => ['orange' ,   0.6],
            
          );

Note that for display purposes C<vedges> does not include the infinite rays in 
the Voronoi diagram. To see the complete Voronoi diagram, including segments
representing the infinite rays, you should include style configuration for the 
C<vrays> key, as in the example above.

Elements (triangles) only need one style config entry, for color. (An optional
second entry would be a string for additional CSS.) In this case,
the first entry can also be a reference to a callback function. A reference to 
the triangle being processed for display will be passed to the callback 
function. Therefore the callback function can determine a color based on any 
features or relationships of that triangle.

Typically you might color each triangle according to the region it's in, by
using Triangle's 'A' switch, and then reading the region attribute from the
last item in the triangle's attribute list.

    my $region_colors_callback = sub {
        my $tri_ref = shift;
        return ('gray','blue','green')[$tri_ref->{attributes}->[-1]];
        };

But any other data accessible through the triangle reference can be used to 
calculate a color. For instance, the triangle's three nodes can carry any
number of attributes, which are interpolated during mesh generation. You 
might shade each triangle according to the average of a node attribute.

    my $tri_nodes_average_callback = sub {
        my $tri_ref = shift;
        my $sum = 0;
        # calculate average of the eighth attribute in all nodes
        foreach my $node (@{$tri_ref->{nodes}}) {
            $sum += $node->{attributes}->[7];
            }
        return &attrib_val_to_grayscale_hexcode( $sum / 3 );
        };

=head2 mic_adjust

=for html <div style="width:30%;float:right;display:inline-block;text-align:center;">
<svg viewBox="-23 -11 204 165" width="57%" preserveAspectRatio="xMinYMin meet" style="margin-top:15px;" xmlns="http://www.w3.org/2000/svg" version="1.1">
<style type="text/css"> .edge {stroke:gray;stroke-width:2;} .seg  {stroke:black;stroke-width:1;} .vedge {stroke:blue;stroke-width:2;} .vcirc {stroke-width:0.8;stroke:blue;fill:none;opacity:0.7;} </style>
<g transform="scale(1,-1) translate(0,-117.66968108291)">
<line x1="0" y1="0" x2="58.835" y2="58.835" class="edge"/>
<line x1="58.835" y1="58.835" x2="0" y2="58.835" class="edge"/>
<line x1="0" y1="58.835" x2="0" y2="0" class="edge"/>
<line x1="0" y1="0" x2="88.252" y2="0" class="edge"/>
<line x1="88.252" y1="0" x2="58.835" y2="58.835" class="edge"/>
<line x1="58.835" y1="58.835" x2="58.835" y2="88.252" class="edge"/>
<line x1="58.835" y1="88.252" x2="0" y2="58.835" class="edge"/>
<line x1="0" y1="58.835" x2="29.417" y2="117.67" class="edge"/>
<line x1="29.417" y1="117.67" x2="0" y2="117.67" class="edge"/>
<line x1="0" y1="117.67" x2="0" y2="58.835" class="edge"/>
<line x1="58.835" y1="88.252" x2="29.417" y2="117.67" class="edge"/>
<line x1="58.835" y1="88.252" x2="58.835" y2="117.67" class="edge"/>
<line x1="58.835" y1="117.67" x2="29.417" y2="117.67" class="edge"/>
<line x1="88.252" y1="0" x2="176.505" y2="0" class="edge"/>
<line x1="176.505" y1="0" x2="176.505" y2="29.417" class="edge"/>
<line x1="176.505" y1="29.417" x2="88.252" y2="0" class="edge"/>
<line x1="176.505" y1="29.417" x2="117.67" y2="58.835" class="edge"/>
<line x1="117.67" y1="58.835" x2="88.252" y2="0" class="edge"/>
<line x1="176.505" y1="58.835" x2="117.67" y2="58.835" class="edge"/>
<line x1="176.505" y1="29.417" x2="176.505" y2="58.835" class="edge"/>
<line x1="117.67" y1="58.835" x2="58.835" y2="58.835" class="edge"/>
<line x1="0" y1="0" x2="0" y2="58.835" class="seg"/>
<line x1="88.252" y1="0" x2="0" y2="0" class="seg"/>
<line x1="176.505" y1="0" x2="88.252" y2="0" class="seg"/>
<line x1="176.505" y1="29.417" x2="176.505" y2="0" class="seg"/>
<line x1="176.505" y1="58.835" x2="176.505" y2="29.417" class="seg"/>
<line x1="117.67" y1="58.835" x2="176.505" y2="58.835" class="seg"/>
<line x1="58.835" y1="58.835" x2="117.67" y2="58.835" class="seg"/>
<line x1="58.835" y1="58.835" x2="58.835" y2="88.252" class="seg"/>
<line x1="58.835" y1="88.252" x2="58.835" y2="117.67" class="seg"/>
<line x1="29.417" y1="117.67" x2="58.835" y2="117.67" class="seg"/>
<line x1="0" y1="117.67" x2="29.417" y2="117.67" class="seg"/>
<line x1="0" y1="58.835" x2="0" y2="117.67" class="seg"/>
<line x1="29.417" y1="29.417" x2="44.126" y2="14.709" class="vedge"/>
<line x1="29.417" y1="29.417" x2="29.417" y2="73.544" class="vedge"/>
<line x1="44.126" y1="14.709" x2="88.252" y2="36.772" class="vedge"/>
<line x1="29.417" y1="73.544" x2="24.515" y2="83.349" class="vedge"/>
<line x1="14.709" y1="88.252" x2="24.515" y2="83.349" class="vedge"/>
<line x1="24.515" y1="83.349" x2="44.126" y2="102.961" class="vedge"/>
<line x1="132.378" y1="14.709" x2="132.378" y2="14.709" class="vedge"/>
<line x1="132.378" y1="14.709" x2="147.087" y2="44.126" class="vedge"/>
<line x1="132.378" y1="14.709" x2="88.252" y2="36.772" class="vedge"/>
<circle cx="0" cy="58.835" r="3" style="fill:black;"/>
<circle cx="0" cy="0" r="3" style="fill:black;"/>
<circle cx="88.252" cy="0" r="3" style="fill:black;"/>
<circle cx="176.505" cy="0" r="3" style="fill:black;"/>
<circle cx="176.505" cy="29.417" r="3" style="fill:black;"/>
<circle cx="176.505" cy="58.835" r="3" style="fill:black;"/>
<circle cx="117.67" cy="58.835" r="3" style="fill:black;"/>
<circle cx="58.835" cy="58.835" r="3" style="fill:black;"/>
<circle cx="58.835" cy="88.252" r="3" style="fill:black;"/>
<circle cx="58.835" cy="117.67" r="3" style="fill:black;"/>
<circle cx="29.417" cy="117.67" r="3" style="fill:black;"/>
<circle cx="0" cy="117.67" r="3" style="fill:black;"/>
<circle cx="29.417" cy="29.417" r="3" style="fill:blue;"/>
<circle cx="44.126" cy="14.709" r="3" style="fill:blue;"/>
<circle cx="29.417" cy="73.544" r="3" style="fill:blue;"/>
<circle cx="14.709" cy="88.252" r="3" style="fill:blue;"/>
<circle cx="24.515" cy="83.349" r="3" style="fill:blue;"/>
<circle cx="44.126" cy="102.961" r="3" style="fill:blue;"/>
<circle cx="132.378" cy="14.709" r="3" style="fill:blue;"/>
<circle cx="132.378" cy="14.709" r="3" style="fill:blue;"/>
<circle cx="147.087" cy="44.126" r="3" style="fill:blue;"/>
<circle cx="88.252" cy="36.772" r="3" style="fill:blue;"/>
<circle cx="29.417" cy="29.417" r="41.601" class="vcirc"/>
<circle cx="44.126" cy="14.709" r="46.512" class="vcirc"/>
<circle cx="29.417" cy="73.544" r="32.890" class="vcirc"/>
<circle cx="14.709" cy="88.252" r="32.889" class="vcirc"/>
<circle cx="24.515" cy="83.349" r="34.668" class="vcirc"/>
<circle cx="44.126" cy="102.961" r="20.801" class="vcirc"/>
<circle cx="132.378" cy="14.709" r="46.512" class="vcirc"/>
<circle cx="132.378" cy="14.709" r="46.513" class="vcirc"/>
<circle cx="147.087" cy="44.126" r="32.890" class="vcirc"/>
<circle cx="88.252" cy="36.772" r="36.772" class="vcirc"/>
</g></svg>
<br/><small>Voronoi edges (blue)<br/> as a poor medial<br/>axis approximation</small><br/>
<svg viewBox="-5 -5 186 127" width="50%"   preserveAspectRatio="xMinYMin meet" style="margin-top:23px;" xmlns="http://www.w3.org/2000/svg" version="1.1">
<style type="text/css"> .edge {stroke:gray;stroke-width:2;} .seg  {stroke:black;stroke-width:1;} .vedge {stroke:blue;stroke-width:2;} .vcirc {stroke-width:0.8;stroke:blue;fill:none;opacity:0.7;} </style>
<g transform="scale(1,-1) translate(0,-117.66968108291)">
<line x1="0" y1="0" x2="58.835" y2="58.835" class="edge"/>
<line x1="58.835" y1="58.835" x2="0" y2="58.835" class="edge"/>
<line x1="0" y1="58.835" x2="0" y2="0" class="edge"/>
<line x1="0" y1="0" x2="88.252" y2="0" class="edge"/>
<line x1="88.252" y1="0" x2="58.835" y2="58.835" class="edge"/>
<line x1="58.835" y1="58.835" x2="58.835" y2="88.252" class="edge"/>
<line x1="58.835" y1="88.252" x2="0" y2="58.835" class="edge"/>
<line x1="0" y1="58.835" x2="29.417" y2="117.67" class="edge"/>
<line x1="29.417" y1="117.67" x2="0" y2="117.67" class="edge"/>
<line x1="0" y1="117.67" x2="0" y2="58.835" class="edge"/>
<line x1="58.835" y1="88.252" x2="29.417" y2="117.67" class="edge"/>
<line x1="58.835" y1="88.252" x2="58.835" y2="117.67" class="edge"/>
<line x1="58.835" y1="117.67" x2="29.417" y2="117.67" class="edge"/>
<line x1="88.252" y1="0" x2="176.505" y2="0" class="edge"/>
<line x1="176.505" y1="0" x2="176.505" y2="29.417" class="edge"/>
<line x1="176.505" y1="29.417" x2="88.252" y2="0" class="edge"/>
<line x1="176.505" y1="29.417" x2="117.67" y2="58.835" class="edge"/>
<line x1="117.67" y1="58.835" x2="88.252" y2="0" class="edge"/>
<line x1="176.505" y1="58.835" x2="117.67" y2="58.835" class="edge"/>
<line x1="176.505" y1="29.417" x2="176.505" y2="58.835" class="edge"/>
<line x1="117.67" y1="58.835" x2="58.835" y2="58.835" class="edge"/>
<line x1="0" y1="0" x2="0" y2="58.835" class="seg"/>
<line x1="88.252" y1="0" x2="0" y2="0" class="seg"/>
<line x1="176.505" y1="0" x2="88.252" y2="0" class="seg"/>
<line x1="176.505" y1="29.417" x2="176.505" y2="0" class="seg"/>
<line x1="176.505" y1="58.835" x2="176.505" y2="29.417" class="seg"/>
<line x1="117.67" y1="58.835" x2="176.505" y2="58.835" class="seg"/>
<line x1="58.835" y1="58.835" x2="117.67" y2="58.835" class="seg"/>
<line x1="58.835" y1="58.835" x2="58.835" y2="88.252" class="seg"/>
<line x1="58.835" y1="88.252" x2="58.835" y2="117.67" class="seg"/>
<line x1="29.417" y1="117.67" x2="58.835" y2="117.67" class="seg"/>
<line x1="0" y1="117.67" x2="29.417" y2="117.67" class="seg"/>
<line x1="0" y1="58.835" x2="0" y2="117.67" class="seg"/>
<line x1="34.465" y1="34.465" x2="49.287" y2="30.192" class="vedge"/>
<line x1="34.465" y1="34.465" x2="29.417" y2="73.544" class="vedge"/>
<line x1="49.287" y1="30.192" x2="88.252" y2="29.417" class="vedge"/>
<line x1="29.417" y1="73.544" x2="29.417" y2="83.349" class="vedge"/>
<line x1="14.709" y1="102.961" x2="29.417" y2="83.349" class="vedge"/>
<line x1="29.417" y1="83.349" x2="44.126" y2="102.961" class="vedge"/>
<line x1="161.796" y1="14.709" x2="132.378" y2="29.417" class="vedge"/>
<line x1="132.378" y1="29.417" x2="161.796" y2="44.126" class="vedge"/>
<line x1="132.378" y1="29.417" x2="88.252" y2="29.417" class="vedge"/>
<circle cx="0" cy="58.835" r="3" style="fill:black;"/>
<circle cx="0" cy="0" r="3" style="fill:black;"/>
<circle cx="88.252" cy="0" r="3" style="fill:black;"/>
<circle cx="176.505" cy="0" r="3" style="fill:black;"/>
<circle cx="176.505" cy="29.417" r="3" style="fill:black;"/>
<circle cx="176.505" cy="58.835" r="3" style="fill:black;"/>
<circle cx="117.67" cy="58.835" r="3" style="fill:black;"/>
<circle cx="58.835" cy="58.835" r="3" style="fill:black;"/>
<circle cx="58.835" cy="88.252" r="3" style="fill:black;"/>
<circle cx="58.835" cy="117.67" r="3" style="fill:black;"/>
<circle cx="29.417" cy="117.67" r="3" style="fill:black;"/>
<circle cx="0" cy="117.67" r="3" style="fill:black;"/>
<circle cx="34.465" cy="34.465" r="3" style="fill:blue;"/>
<circle cx="49.287" cy="30.192" r="3" style="fill:blue;"/>
<circle cx="29.417" cy="73.544" r="3" style="fill:blue;"/>
<circle cx="14.709" cy="102.961" r="3" style="fill:blue;"/>
<circle cx="29.417" cy="83.349" r="3" style="fill:blue;"/>
<circle cx="44.126" cy="102.961" r="3" style="fill:blue;"/>
<circle cx="161.796" cy="14.709" r="3" style="fill:blue;"/>
<circle cx="132.378" cy="29.417" r="3" style="fill:blue;"/>
<circle cx="161.796" cy="44.126" r="3" style="fill:blue;"/>
<circle cx="88.252" cy="29.417" r="3" style="fill:blue;"/>
<circle cx="34.465" cy="34.465" r="34.464" class="vcirc"/>
<circle cx="49.287" cy="30.192" r="30.192" class="vcirc"/>
<circle cx="29.417" cy="73.544" r="29.417" class="vcirc"/>
<circle cx="14.709" cy="102.961" r="14.708" class="vcirc"/>
<circle cx="29.417" cy="83.349" r="29.417" class="vcirc"/>
<circle cx="44.126" cy="102.961" r="14.708" class="vcirc"/>
<circle cx="161.796" cy="14.709" r="14.708" class="vcirc"/>
<circle cx="132.378" cy="29.417" r="29.417" class="vcirc"/>
<circle cx="161.796" cy="44.126" r="14.708" class="vcirc"/>
<circle cx="88.252" cy="29.417" r="29.417" class="vcirc"/>
</g></svg>
<br/><small>improved approximation<br/>after calling mic_adust()</small><br/>
</div>

Warning: not yet thoroughly tested; may move elsewhere

One use of the Voronoi diagram of a tessellated polygon is to derive an
approximation of the polygon's medial axis by pruning infinite rays and perhaps
trimming or refining remaining branches. The approximation improves as
intervals between sample points on the polygon become shorter. But it's not 
always desirable to multiply the number of polygon points to achieve short
intervals.

At any point on the true medial axis, there is a maximum inscribed circle,
with it's center on the medial axis, and tangent to the polygon in at least
two places.

The C<mic_adjust()> function moves each Voronoi node so that it becomes the 
center of a circle that is tangent to the polygon at two points. In simple 
cases this is a maximum inscribed circle, and the point is on the medial axis.
And when it's not, it still should be a much better approximation than the 
original point location. The radius to the tangent on the polygon is stored 
with the updated Voronoi node.

After calling C<mic_adjust()>, the modified Voronoi topology can be used as a
list of maximum inscribed circles, from which can be derive a straighter, 
better medial axis approximation, without having to increase the number of 
sample points on the polygon.

    ($topo, $voronoi_topo) = $tri->triangulate('e');

    mic_adjust($topo, $voronoi_topo); # modifies $voronoi_topo in place
    
    foreach my $node (@{$voronoi_topo->{nodes}}) {
        $mic_center = $node->{point};
        $mic_radius = $node->{radius};
        ...
        }

Constructing a true medial axis is much more involved - a subject for a 
different module. Until that module appears, running topology through
C<mic_adjust()> and then walking and pruning the Voronoi topology might help 
fill the gap.

=head1 API STATUS

Currently Triangle's option strings are exposed to give more complete access to
its features. More of these options, and perhaps certain common combinations of 
them, will likely be wrapped in method-call getter-setters. I would prefer to 
preserve the ability to use the option strings directly, but it may be better
at some point to hide them completely behind a more descriptive interface.


=head1 AUTHOR

Michael E. Sheldrake, C<< <sheldrake at cpan.org> >>

Triangle's author is Jonathan Richard Shewchuk


=head1 BUGS

Please report any bugs or feature requests to 

C<bug-math-geometry-delaunay at rt.cpan.org>

or through the web interface at 

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Geometry-Delaunay>

I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Geometry::Delaunay


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Geometry-Delaunay>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Geometry-Delaunay/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks go to Far Leaves Tea in Berkeley for providing oolongs and refuge, 
and a place for paths to intersect.


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Micheal E. Sheldrake.

This Perl binding to Triangle is free software; 
you can redistribute it and/or modify it under the terms of either: 
the GNU General Public License as published by the Free Software Foundation; 
or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head2 Triangle license

B<Triangle> by Jonathan Richard Shewchuk, copyright 2005, includes the following
notice in the C source code. Please refer to the C source, included in with this
Perl module distribution, for the full notice.

    This program may be freely redistributed under the condition that the
    copyright notices (including this entire header and the copyright
    notice printed when the `-h' switch is selected) are not removed, and
    no compensation is received.  Private, research, and institutional
    use is free.  You may distribute modified versions of this code UNDER
    THE CONDITION THAT THIS CODE AND ANY MODIFICATIONS MADE TO IT IN THE
    SAME FILE REMAIN UNDER COPYRIGHT OF THE ORIGINAL AUTHOR, BOTH SOURCE
    AND OBJECT CODE ARE MADE FREELY AVAILABLE WITHOUT CHARGE, AND CLEAR
    NOTICE IS GIVEN OF THE MODIFICATIONS.  Distribution of this code as
    part of a commercial system is permissible ONLY BY DIRECT ARRANGEMENT
    WITH THE AUTHOR.  (If you are not directly supplying this code to a
    customer, and you are instead telling them how they can obtain it for
    free, then you are not required to make any arrangement with me.)

=cut

1;
