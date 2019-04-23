package Geo::OGC::Service::Filter;

use Modern::Perl;
use Carp;
use Data::Dumper;
use Geo::OGC::Service;
use vars qw(@ISA);
push @ISA, qw(Geo::OGC::Service::Common);

require Exporter;
push @ISA, qw(Exporter);
our @EXPORT_OK = qw(filter2sql node2sql parse_tag parse_name strip get_integer latest_version);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our %gml_geometry_type = (
    Envelope => 1,
    Point => 1,
    MultiPoint => 1,
    LineString => 1,
    MultiLineString => 1,
    Polygon => 1,
    MultiPolygon => 1,
    MultiGeometry => 1,
    );

our %spatial2op = ( 
    Disjoint => 1,
    Equals => 1,
    Touches => 1,
    Within => 1,
    Overlaps => 1,
    Crosses => 1,
    Intersects => 1,
    Contains => 1
    ); # there are more in PostGIS

our %temporal_operators = (
    After => 1,
    Before => 1,
    Begins => 1,
    BegunBy => 1,
    TContains => 1,
    During => 1,
    TEquals => 1,
    TOverlaps => 1,
    Meets => 1,
    OverlappedBy => 1,
    MetBy => 1,
    EndedBy => 1
    );

my %functions = (
    abs => ['xs:int', [[int => 'xs:int']]],
    acos => ['xs:double', [[value => 'xs:double']]],
    Area => ['xs:double', [[geometry => 'gml:AbstractGeometryType']]],
    within => ['xs:boolean', [[geometry => 'gml:AbstractGeometryType'], [geometry => 'gml:AbstractGeometryType']]]
    ); # lots missing

sub Filter_Capabilities  {
    my ($self, $writer) = @_;
    my $ns = $self->{version} eq '2.0.0' ? 'fes' : 'ogc';
    $writer->open_element($ns.':Filter_Capabilities');

    # Conformance
    my %Constraints = ( 
        ImplementsQuery => [['ows:NoValues'], ['ows:DefaultValue' => 'TRUE']],
        ImplementsAdHocQuery => [['ows:NoValues'], ['ows:DefaultValue' => 'TRUE']],
        ImplementsFunctions => [['ows:NoValues'], ['ows:DefaultValue' => 'TRUE']],
        ImplementsMinStandardFilter => [['ows:NoValues'], ['ows:DefaultValue' => 'TRUE']],
        ImplementsStandardFilter => [['ows:NoValues'], ['ows:DefaultValue' => 'FALSE']],
        ImplementsMinSpatialFilter => [['ows:NoValues'], ['ows:DefaultValue' => 'TRUE']],
        ImplementsSpatialFilter => [['ows:NoValues'], ['ows:DefaultValue' => 'FALSE']],
        ImplementsMinTemporalFilter => [['ows:NoValues'], ['ows:DefaultValue' => 'TRUE']],
        ImplementsTemporalFilter => [['ows:NoValues'], ['ows:DefaultValue' => 'TRUE']],
        ImplementsVersionNav => [['ows:NoValues'], ['ows:DefaultValue' => 'FALSE']],
        ImplementsSorting => [['ows:AllowedValues' => [['ows:Value' => 'ASC'], ['ows:Value' => 'DESC']]], 
                              ['ows:DefaultValue' => 'ASC']],
        ImplementsExtendedOperators => [['ows:NoValues'], ['ows:DefaultValue' => 'FALSE']],
        );
    my @c;
    for my $key (keys %Constraints) {
        push @c, [$ns.':Constraint', {name=>$key}, $Constraints{$key}];
    }
    $writer->element($ns.':Conformance', \@c);

    my @ids;
    if ($ns eq 'ogc') {
        @ids = ([$ns.':FID']);
    } else {
        @ids = (['fes:ResourceIdentifier', {name => 'fes:ResourceId'}]);
    }
    $writer->element($ns.':Id_Capabilities', \@ids);

    my @operators = ();    
    for my $o (qw/LessThan GreaterThan LessThanOrEqualTo GreaterThanOrEqualTo EqualTo NotEqualTo Like Between Null/) {
        if ($ns eq 'ogc') {
            push @operators, [$ns.':ComparisonOperator', 'PropertyIs'.$o];
        } else {
            push @operators, [$ns.':ComparisonOperator', { name => 'PropertyIs'.$o}];
        }
    }
    $writer->element($ns.':Scalar_Capabilities', 
                [[$ns.':LogicalOperators'], # empty ?
                 [$ns.':ComparisonOperators', \@operators]]);

    my @operands = ();
    for my $o (keys %gml_geometry_type) {
        if ($ns eq 'ogc') {
            push @operands, [$ns.':GeometryOperand', 'gml:'.$o];
        } else {
            push @operands, [$ns.':GeometryOperand', { name => 'gml:'.$o }];
        }
    }
    @operators = ();
    my @op = keys %spatial2op;
    push @op, (qw/DWithin BBOX/);
    for my $o (@op) {
        push @operators, [$ns.':SpatialOperator', { name => $o }];
    }
    $writer->element($ns.':Spatial_Capabilities', 
                [[$ns.':GeometryOperands', \@operands],
                 [$ns.':SpatialOperators', \@operators]]);

    # Temporal_Capabilities

    @operands = ();
    for my $o (qw/TimeInstant TimePeriod/) {
        if ($ns eq 'ogc') {
            push @operands, [$ns.':GeometryOperand', 'gml:'.$o];
        } else {
            push @operands, [$ns.':GeometryOperand', { name => 'gml:'.$o }];
        }
    }
    @operators = ();
    @op = keys %temporal_operators;
    for my $o (@op) {
        push @operators, [$ns.':TemporalOperator', { name => $o }];
    }
    $writer->element($ns.':Temporal_Capabilities', 
                     [[$ns.':TemporalOperands', \@operands],
                      [$ns.':TemporalOperators', \@operators]]);

    # Functions
    
    my @functions;
    for my $f (sort keys %functions) {
        my @args = ();
        my $args = $functions{$f}[1];
        for my $arg (@$args) {
            push @args, [$ns.':Argument', { name => $arg->[0]}, [$ns.':Type' => $arg->[1]]];
        }
        push @functions, [$ns.':Function', { name => $f }, 
                          [[$ns.':Returns' => $functions{$f}[0]] ,[$ns.':Arguments' => \@args]]];
    }
    $writer->element($ns.':Functions', \@functions);
    
    $writer->close_element;
}

sub error {
    my ($self, $msg, $headers) = @_;
    if (!$msg->{debug}) {
        Geo::OGC::Service::error($self->{responder}, $msg, $headers);
    } else {
        print STDERR Dumper $msg;
    }
}

sub log {
    my ($self, $msg) = @_;
    say STDERR Dumper($msg);
}

# convert OGC Filter XML to SQL
sub filter2sql {
    my ($node, $type) = @_;
    if (!$node) {
        return "";
    }
    my ($ns, $name) = parse_tag($node);

    if ($name eq 'Literal') {
        my $child = $node->firstChild;
        my $data = $child ? $child->data : '';
        return "'".$data."'";

    } elsif ($name eq 'PropertyName') {
        my $ref = strip($node->textContent);
        $ref = $type->{GeometryColumn} if $ref eq 'geometryProperty';
        return '"'.$ref.'"';

    } elsif ($name eq 'ValueReference') {
        my $ref = strip($node->textContent);
        $ref =~ s/^\w+://;
        $ref = $type->{GeometryColumn} if $ref eq 'geometryProperty';
        return '"'.$ref.'"';

    } elsif ($name eq 'ResourceId') {
        my $id = $node->getAttribute('rid');
        return $type->{'gml:id'}." = '$id'";

    } elsif ($name eq 'FeatureId') {
        my $id = $node->getAttribute('fid');
        return $type->{'gml:id'}." = '$id'";

    } elsif ($name eq 'GmlObjectId') {
        my $id = $node->getAttribute('gml:id');
        return $type->{'gml:id'}." = '$id'";

    } elsif ($name eq 'PropertyIsEqualTo') {
        $node = $node->firstChild;
        return '('.filter2sql($node, $type).' = '.filter2sql($node->nextSibling, $type).')';

    } elsif ($name eq 'PropertyIsNotEqualTo') {
        $node = $node->firstChild;
        return '('.filter2sql($node, $type).' != '.filter2sql($node->nextSibling, $type).')';

    } elsif ($name eq 'PropertyIsLessThan') {
        $node = $node->firstChild;
        return '('.filter2sql($node, $type).' < '.filter2sql($node->nextSibling, $type).')';

    } elsif ($name eq 'PropertyIsGreaterThan') {
        $node = $node->firstChild;
        return '('.filter2sql($node, $type).' > '.filter2sql($node->nextSibling, $type).')';

    } elsif ($name eq 'PropertyIsLessThanOrEqualTo') {
        $node = $node->firstChild;
        return '('.filter2sql($node, $type).' <= '.filter2sql($node->nextSibling, $type).')';

    } elsif ($name eq 'PropertyIsGreaterThanOrEqualTo') {
        $node = $node->firstChild;
        return '('.filter2sql($node, $type).' >= '.filter2sql($node->nextSibling, $type).')';

    } elsif ($name eq 'PropertyIsBetween') {
        $node = $node->firstChild;
        my $property = filter2sql($node->firstChild, $type);
        $node = $node->nextSibling;
        return '('.$property.' >= '.filter2sql($node, $type).' AND '.$property.'<='.filter2sql($node->nextSibling).')';

    } elsif ($name eq 'PropertyIsLike') {
        $node = $node->firstChild;
        return '('.filter2sql($node, $type).' ~ '.filter2sql($node->nextSibling, $type).')';

    } elsif ($name eq 'PropertyIsNull') {
        return '('.filter2sql($node->firstChild, $type).' ISNULL)';

    } elsif ($name eq 'And') {
        $node = $node->firstChild;
        my $p = '('.filter2sql($node, $type);
        while ($node = $node->nextSibling) {
            $p .= ' AND '.filter2sql($node, $type);
        }
        return $p.')';

    } elsif ($name eq 'Or') {
        $node = $node->firstChild;
        my $p = '('.filter2sql($node, $type);
        while ($node = $node->nextSibling) {
            $p .= ' OR '.filter2sql($node, $type);
        }
        return $p.')';
    } elsif ($name eq 'Not') {
        return '(NOT '.filter2sql($node->firstChild, $type).')';

    } elsif ($ns eq 'gml' and $gml_geometry_type{$name}) {
        return node2sql($node);

    } elsif ($name eq 'BBOX') {
        $node = $node->firstChild;
        my ($ns, $n) = parse_tag($node);
        my $property;
        if ($n eq 'Envelope') {
            $property = 'GeometryColumn';
        } else {
            $property = filter2sql($node, $type);
            $node = $node->nextSibling;
        }
        my $envelope = filter2sql($node, $type);
        $envelope = "ST_Transform($envelope,$type->{SRID})";
        return "($property && $envelope)";
        
    } elsif ($spatial2op{$name}) {
        $node = $node->firstChild;
        my $geom1 = filter2sql($node, $type);
        $node = $node->nextSibling;
        my $geom2 = filter2sql($node, $type);
        return "ST_$name($geom1, $geom2)";

    } elsif ($name eq 'DWithin') {
        $node = $node->firstChild;
        my $geom1 = filter2sql($node, $type);
        $node = $node->nextSibling;
        my $geom2 = filter2sql($node, $type);
        $node = $node->nextSibling;
        my $dist = filter2sql($node, $type);
        return "ST_$name($geom1, $geom2, $dist)";

    # temporal filter missing

    # functions missing

    } elsif ($name eq 'Filter') {
        my %id = ( ResourceId => 1,
                   FeatureId => 1,
                   GmlObjectId => 1 );
        $node = $node->firstChild;
        my ($ns2, $name2) = parse_tag($node);
        if ($id{$name2}) {
            my $where = '';
            for (my $id = $node; $id; $id = $id->nextSibling) {
                $where .= filter2sql($id, $type).' OR ';
            }
            $where =~ s/ OR $//;
            return $where;
        } else {
            return filter2sql($node, $type);
        }
    }
}

sub node2sql {
    my ($node) = @_;
    my $srs = get_integer($node->getAttribute('srsName')) // '4326';
    $srs = ",$srs" if $srs ne '';
    my ($ns, $name) = parse_tag($node);
    my $wkt;

    # should use Geo::OGC::Geometry

    if ($name eq 'Box') {
        my $env = strip($node->firstChild->textContent);
        $env =~ s/ /,/;
        return "ST_MakeEnvelope($env$srs)";
    } elsif ($name eq 'Envelope') {
        $node = $node->firstChild;
        my $lc = strip($node->textContent); # gml:lowerCorner
        $lc =~ s/ /,/;
        $node = $node->nextSibling;
        my $uc = strip($node->textContent); # gml:upperCorner
        $uc =~ s/ /,/;
        return "ST_MakeEnvelope($lc,$uc$srs)";
    } elsif ($name eq 'Point') {
        my $pos = $node->firstChild->firstChild->data;
        $pos =~ s/,/ /;
        $wkt = "POINT ($pos)";
    } elsif ($name eq 'MultiPoint') { # not ok
        my $pos = $node->firstChild->firstChild->data;
        $pos =~ s/,/ /;
        $wkt = "MULTIPOINT ($pos)";
    } elsif ($name eq 'LineString') {
        my @tmp = split /\s+/, $node->firstChild->firstChild->data;
        my @pos;
        for (my $i = 0; $i < @tmp; $i+=2) {
            push @pos, $tmp[$i].' '.$tmp[$i+1];
        }
        $wkt = "LINESTRING (".join(', ',@pos).")";
    } elsif ($name eq 'MultiLineString') { # not ok
        my @tmp = split / /, $node->firstChild->firstChild->data;
        my @pos;
        for (my $i = 0; $i < @tmp; $i+=2) {
            push @pos, $tmp[$i].' '.$tmp[$i+1];
        }
        $wkt = "MULTILINESTRING (".join(', ',@pos).")";
    } elsif ($name eq 'Polygon') {
        # Polygon.exterior.LinearRing.posList
        my @tmp = split /\s+/, $node->firstChild->firstChild->firstChild->textContent;
        my @pos;
        for (my $i = 0; $i < @tmp; $i+=2) {
            push @pos, strip($tmp[$i]).' '.strip($tmp[$i+1]);
        }
        $wkt = "POLYGON ((".join(', ',@pos)."))";
    } elsif ($name eq 'MultiPolygon') { # not ok
        my @tmp = split / /, $node->firstChild->firstChild->firstChild->data;
        my @pos;
        for (my $i = 0; $i < @tmp; $i+=2) {
            push @pos, $tmp[$i].' '.$tmp[$i+1];
        }
        $wkt = "MULTIPOLYGON ((".join(', ',@pos)."))";
    } elsif ($name eq 'MultiGeometry') { # not ok
        my @tmp = split / /, $node->firstChild->firstChild->firstChild->data;
        my @pos;
        for (my $i = 0; $i < @tmp; $i+=2) {
            push @pos, $tmp[$i].' '.$tmp[$i+1];
        }
        $wkt = "MULTIGEOMETRY ((".join(', ',@pos)."))";
    }
    
    return "ST_GeometryFromText('$wkt'$srs)";
}

sub latest_version {
    my $versions = shift;
    return undef unless defined $versions;
    my @versions = split /\s*,\s*/, $versions;
    for (@versions) {
        my ($a,$b,$c) = split /\./;
        $_ = $a*10000+$b*100+$c;
    }
    @versions = sort {$b <=> $a} @versions;
    my ($a,$b,$c) = $versions[0] =~ /^(\d+)(\d\d)(\d\d)$/;
    for ($a,$b,$c) {
        $_ = int($_);
    }
    return "$a.$b.$c";
}

sub get_integer {
    my $s = shift;
    if (not defined $s) {
        if (@_) {
            return get_integer(shift);
        } else {
            return undef;
        }
    }
    if ($s =~ /(\d+)/) {
        return $1;
    }
    return undef;
}

sub parse_tag {
    my $node = shift;
    return parse_name($node->nodeName);
}

sub parse_name {
    my $name = shift;
    my $ns = '';
    ($ns, $name) = split /:/, $name if $name =~ /:/;
    return ($ns, $name);
}

sub strip {
    my $s = shift;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return $s;
}
    
1;
