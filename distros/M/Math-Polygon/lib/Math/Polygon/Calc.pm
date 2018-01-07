# Copyrights 2004-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Math::Polygon.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Math::Polygon::Calc;
use vars '$VERSION';
$VERSION = '1.10';

use base 'Exporter';

use strict;
use warnings;

our @EXPORT = qw/
 polygon_area
 polygon_bbox
 polygon_beautify
 polygon_centroid
 polygon_clockwise
 polygon_contains_point
 polygon_counter_clockwise
 polygon_distance
 polygon_equal
 polygon_is_clockwise
 polygon_is_closed
 polygon_perimeter
 polygon_same
 polygon_start_minxy
 polygon_string
 polygon_format
/;

use List::Util    qw/min max/;
use Carp          qw/croak/;


sub polygon_string(@) { join ', ', map "[$_->[0],$_->[1]]", @_ }


sub polygon_bbox(@)
{
    ( min( map $_->[0], @_ )
    , min( map $_->[1], @_ )
    , max( map $_->[0], @_ )
    , max( map $_->[1], @_ )
    );
}


sub polygon_area(@)
{   my $area    = 0;
    while(@_ >= 2)
    {   $area += $_[0][0]*$_[1][1] - $_[0][1]*$_[1][0];
        shift;
    }

    abs($area)/2;
}


sub polygon_is_clockwise(@)
{   my $area  = 0;

    polygon_is_closed(@_)
       or croak "ERROR: polygon must be closed: begin==end";

    while(@_ >= 2)
    {   $area += $_[0][0]*$_[1][1] - $_[0][1]*$_[1][0];
        shift;
    }

    $area < 0;
}


sub polygon_clockwise(@)
{   polygon_is_clockwise(@_) ? @_ : reverse @_;
}


sub polygon_counter_clockwise(@)
{   polygon_is_clockwise(@_) ? reverse(@_) : @_;
}



sub polygon_perimeter(@)
{   my $l    = 0;

    while(@_ >= 2)
    {   $l += sqrt(($_[0][0]-$_[1][0])**2 + ($_[0][1]-$_[1][1])**2);
        shift;
    }

    $l;
}


sub polygon_start_minxy(@)
{   return @_ if @_ <= 1;
    my $ring  = $_[0][0]==$_[-1][0] && $_[0][1]==$_[-1][1];
    pop @_ if $ring;

    my ($xmin, $ymin) = polygon_bbox @_;

    my $rot   = 0;
    my $dmin_sq = ($_[0][0]-$xmin)**2 + ($_[0][1]-$ymin)**2;

    for(my $i=1; $i<@_; $i++)
    {   next if $_[$i][0] - $xmin > $dmin_sq;

        my $d_sq = ($_[$i][0]-$xmin)**2 + ($_[$i][1]-$ymin)**2;
        if($d_sq < $dmin_sq)
        {   $dmin_sq = $d_sq;
            $rot     = $i;
        }
    }

    $rot==0 ? (@_, ($ring ? $_[0] : ()))
            : (@_[$rot..$#_], @_[0..$rot-1], ($ring ? $_[$rot] : ()));
}


sub polygon_beautify(@)
{   my %opts     = ref $_[0] eq 'HASH' ? %{ (shift) } : ();
    return () unless @_;

    my $despike  = exists $opts{remove_spikes} ? $opts{remove_spikes}  : 0;

    my @res      = @_;
    return () if @res < 4;  # closed triangle = 4 points
    pop @res;               # cyclic: last is first
    my $unchanged= 0;

    while($unchanged < 2*@res)
    {    return () if @res < 3;  # closed triangle = 4 points

         my $this = shift @res;
         push @res, $this;         # recycle
         $unchanged++;

         # remove doubles
         my ($x, $y) = @$this;
         while(@res && $res[0][0]==$x && $res[0][1]==$y)
         {   $unchanged = 0;
             shift @res;
         }

         # remove spike
         if($despike && @res >= 2)
         {   # any spike
             if($res[1][0]==$x && $res[1][1]==$y)
             {   $unchanged = 0;
                 shift @res;
             }

             # x-spike
             if($y==$res[0][1] && $y==$res[1][1]
                && (   ($res[0][0] < $x && $x < $res[1][0])
                    || ($res[0][0] > $x && $x > $res[1][0])))
             {   $unchanged = 0;
                 shift @res;
             }

             # y-spike
             if(   $x==$res[0][0] && $x==$res[1][0]
                && (   ($res[0][1] < $y && $y < $res[1][1])
                    || ($res[0][1] > $y && $y > $res[1][1])))
             {   $unchanged = 0;
                 shift @res;
             }
        }

        # remove intermediate
        if(   @res >= 2
           && $res[0][0]==$x && $res[1][0]==$x
           && (   ($y < $res[0][1] && $res[0][1] < $res[1][1])
               || ($y > $res[0][1] && $res[0][1] > $res[1][1])))
        {   $unchanged = 0;
            shift @res;
        }

        if(   @res >= 2
           && $res[0][1]==$y && $res[1][1]==$y
           && (   ($x < $res[0][0] && $res[0][0] < $res[1][0])
               || ($x > $res[0][0] && $res[0][0] > $res[1][0])))
        {   $unchanged = 0;
            shift @res;
        }

        # remove 2 out-of order between two which stay
        if(@res >= 3
           && $x==$res[0][0] && $x==$res[1][0] && $x==$res[2][0]
           && ($y < $res[0][1] && $y < $res[1][1]
               && $res[0][1] < $res[2][1] && $res[1][1] < $res[2][1]))
        {   $unchanged = 0;
            splice @res, 0, 2;
        }

        if(@res >= 3
           && $y==$res[0][1] && $y==$res[1][1] && $y==$res[2][1]
           && ($x < $res[0][0] && $x < $res[1][0]
               && $res[0][0] < $res[2][0] && $res[1][0] < $res[2][0]))
        {   $unchanged = 0;
            splice @res, 0, 2;
        }
    }

    @res ? (@res, $res[0]) : ();
}


sub polygon_equal($$;$)
{   my  ($f,$s, $tolerance) = @_;
    return 0 if @$f != @$s;
    my @f = @$f;
    my @s = @$s;

    if(defined $tolerance)
    {    while(@f)
         {    return 0 if abs($f[0][0]-$s[0][0]) > $tolerance
                       || abs($f[0][1]-$s[0][1]) > $tolerance;
              shift @f; shift @s;
         }
         return 1;
    }

    while(@f)
    {    return 0 if $f[0][0] != $s[0][0] || $f[0][1] != $s[0][1];
         shift @f; shift @s;
    }

    1;
}


sub polygon_same($$;$)
{   return 0 if @{$_[0]} != @{$_[1]};
    my @f = polygon_start_minxy @{ (shift) };
    my @s = polygon_start_minxy @{ (shift) };
    polygon_equal \@f, \@s, @_;
}


# Algorithms can be found at
# http://www.eecs.umich.edu/courses/eecs380/HANDOUTS/PROJ2/InsidePoly.html
# p1 = polygon[0];
# for (i=1;i<=N;i++) {
#   p2 = polygon[i % N];
#   if (p.y > MIN(p1.y,p2.y)) {
#     if (p.y <= MAX(p1.y,p2.y)) {
#       if (p.x <= MAX(p1.x,p2.x)) {
#         if (p1.y != p2.y) {
#           xinters = (p.y-p1.y)*(p2.x-p1.x)/(p2.y-p1.y)+p1.x;
#           if (p1.x == p2.x || p.x <= xinters)
#             counter++;
#         }
#       }
#     }
#   }
#   p1 = p2;
# }
# inside = counter % 2;

sub polygon_contains_point($@)
{   my $point = shift;
    return 0 if @_ < 3;

    my ($x, $y) = @$point;
    my $inside  = 0;

    polygon_is_closed(@_)
       or croak "ERROR: polygon must be closed: begin==end";

    my ($px, $py) = @{ (shift) };

    while(@_)
    {   my ($nx, $ny) = @{ (shift) };

        # Extra check for exactly on the edge when the axes are
        # horizontal or vertical.
        return 1 if $y==$py && $py==$ny
                 && ($x >= $px || $x >= $nx)
                 && ($x <= $px || $x <= $nx);

        return 1 if $x==$px && $px==$nx
                 && ($y >= $py || $y >= $ny)
                 && ($y <= $py || $y <= $ny);

        if(   $py == $ny
           || ($y <= $py && $y <= $ny)
           || ($y >  $py && $y >  $ny)
           || ($x >  $px && $x >  $nx)
          )
        {
            ($px, $py) = ($nx, $ny);
            next;
        }

        # side wrt diagonal
        my $xinters = ($y-$py)*($nx-$px)/($ny-$py)+$px;
        $inside = !$inside
            if $px==$nx || $x <= $xinters;

        ($px, $py) = ($nx, $ny);
    }

    $inside;
}


sub polygon_centroid(@)
{
    polygon_is_closed(@_)
        or croak "ERROR: polygon must be closed: begin==end";

    my ($cx, $cy, $a) = (0, 0, 0);
    foreach my $i (0..@_-2)
    {    my $ap = $_[$i][0]*$_[$i+1][1] - $_[$i+1][0]*$_[$i][1];
         $cx   += ($_[$i][0]+$_[$i+1][0]) * $ap;
         $cy   += ($_[$i][1]+$_[$i+1][1]) * $ap;
         $a    += $ap;
    }
    my $c = 3*$a; # 6*$a/2;
    [ $cx/$c, $cy/$c ];
}


sub polygon_is_closed(@)
{   @_ or croak "ERROR: empty polygon is neither closed nor open";

    my ($first, $last) = @_[0,-1];
    $first->[0]==$last->[0] && $first->[1]==$last->[1];
}


# Contributed by Andreas Koenig for 1.05
# http://stackoverflow.com/questions/10983872/distance-from-a-point-to-a-polygon#10984080
# with correction from
# http://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
sub polygon_distance($%)
{   my $p = shift;

    my ($x, $y) = @$p;
    my $minDist;

    @_ or return undef;

    my ($x1, $y1) = @{ (shift) };
    unless(@_)
    {   my ($dx, $dy) = ($x1 - $x, $y1 - $y);
        return sqrt($dx * $dx + $dy * $dy);
    }

    while(@_)
    {   my ($x2, $y2) = @{ (shift) };   # closed poly!
        my $A =  $x - $x1;
        my $B =  $y - $y1;
        my $C = $x2 - $x1;
        my $D = $y2 - $y1;

        # closest point to the line segment
        my $dot    = $A * $C + $B * $D;
        my $len_sq = $C * $C + $D * $D;
        my $angle  = $len_sq==0 ? -1 : $dot / $len_sq;
 
        my ($xx, $yy)
         = $angle < 0 ? ($x1, $y1)   # perpendicular line crosses off segment
         : $angle > 1 ? ($x2, $y2)
         :              ($x1 + $angle * $C, $y1 + $angle * $D);

        my $dx = $x - $xx;
        my $dy = $y - $yy;
        my $dist = sqrt($dx * $dx + $dy * $dy);
        $minDist = $dist unless defined $minDist;
        $minDist = $dist if $dist < $minDist;

        ($x1, $y1) = ($x2, $y2);
    }

    $minDist;
}



sub polygon_format($@)
{   my $format = shift;
    my $call   = ref $format eq 'CODE' ? $format
      : sub { sprintf $format, $_[0] };

    map [ $call->($_->[0]), $call->($_->[1]) ], @_;
}

1;
