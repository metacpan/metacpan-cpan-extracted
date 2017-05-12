package Math::Vec;
our $VERSION   = '1.01';

=pod

=head1 NAME

Math::Vec - Object-Oriented Vector Math Methods in Perl

=head1 SYNOPSIS

  use Math::Vec;
  $v = Math::Vec->new(0,1,2);

  or

  use Math::Vec qw(NewVec);
  $v = NewVec(0,1,2);
  @res = $v->Cross([1,2.5,0]);
  $p = NewVec(@res);
  $q = $p->Dot([0,1,0]);

  or

  use Math::Vec qw(:terse);
  $v = V(0,1,2);
  $q = ($v x [1,2.5,0]) * [0,1,0];

=head1 NOTICE

This module is still somewhat incomplete.  If a function does nothing,
there is likely a really good reason.  Please have a look at the code
if you are trying to use this in a production environment.

=head1 AUTHOR

Eric L. Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com

=head1 DESCRIPTION

This module was adapted from Math::Vector, written by Wayne M. Syvinski.

It uses most of the same algorithms, and currently preserves the same
names as the original functions, though some aliases have been added to
make the interface more natural (at least to the way I think.)

The "object" for the object oriented calling style is a blessed array
reference which contains a vector of the form [x,y,z].  Methods will
typically return a list.

=head1 COPYRIGHT NOTICE

Copyright (C) 2003-2006 Eric Wilhelm

portions Copyright 2003 Wayne M. Syvinski

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.
In case of loss, neither Wayne M. Syvinski, Eric Wilhelm, nor anyone
else, owes you anything whatseover.  You have been warned.

Note that this includes NO GUARANTEE of MATHEMATICAL CORRECTNESS.  If
you are going to use this code in a production environment, it is YOUR
RESPONSIBILITY to verify that the methods return the correct values. 

=head1 LICENSE

You may use this software under one of the following licenses:

  (1) GNU General Public License 
    (found at http://www.gnu.org/copyleft/gpl.html) 
  (2) Artistic License 
    (found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 SEE ALSO

  Math::Vector

=cut

########################################################################

use strict;
use warnings;
use Carp;

{
package Math::Vec::Support;
# Dropping the usage of Math::Complex acos() because we don't want any
# complex numbers to happen due to errors in the whee bits.
sub acos {
	my ($z) = @_;

	my $abs = abs($z);
	if($abs > 1) {
		# just a little sanity checking
		(($abs - 1) > 2**-16) and die "bad input to acos($z)";
		# make it safe
		$z = ($z > 0) ? 1 : -1;
	}

	return CORE::atan2(CORE::sqrt(1-$z*$z), $z);
}
}

BEGIN {
use Exporter;
*{import} = \&Exporter::import;
}
our @EXPORT = ();
our @EXPORT_OK = qw(
	NewVec
	);
our @terse_exp = qw(
	V
	U
	X
	Y
	Z
	);
our %EXPORT_TAGS = (
	terse => [@terse_exp],
	);
Exporter::export_ok_tags(keys(%EXPORT_TAGS));


########################################################################

=head1 Constructor

=head2 new

Returns a blessed array reference to cartesian point ($x, $y, $z),
where $z is optional.  Note the feed-me-list, get-back-reference syntax
here.  This is the opposite of the rest of the methods for a good
reason (it allows nesting of function calls.)

The z value is optional, (and so are x and y.)  Undefined values are
silently translated into zeros upon construction.

  $vec = Math::Vec->new($x, $y, $z);

=cut
sub new {
	my $caller = shift;
	my $class = ref($caller) || $caller;
	my $self = [map({defined($_) ? $_ : 0} @_[0,1,2])];
	bless($self, $class);
	return($self);
} # end subroutine new definition
########################################################################

=head2 NewVec

This is simply a shortcut to Math::Vec->new($x, $y, $z) for those of
you who don't want to type so much so often.  This also makes it easier
to nest / chain your function calls.  Note that methods will typically
output lists (e.g. the answer to your question.)  While you can simply
[bracket] the answer to make an array reference, you need that to be
blessed in order to use the $object->method(@args) syntax.  This
function does that blessing.

This function is exported as an option.  To use it, simply use
Math::Vec qw(NewVec); at the start of your code.

  use Math::Vec qw(NewVec);
  $vec = NewVec($x, $y, $z);
  $diff = NewVec($vec->Minus([$ovec->ScalarMult(0.5)]));

=cut
sub NewVec {
	return(Math::Vec->new(@_));
} # end subroutine NewVec definition
########################################################################

=head1 Terse Functions

These are all one-letter shortcuts which are imported to your namespace
with the :terse flag.

  use Math::Vec qw(:terse);

=head2 V

This is the same as Math::Vec->new($x,$y,$z).

  $vec = V($x, $y, $z);

=cut
sub V {
	return(Math::Vec->new(@_));
} # end subroutine V definition
########################################################################

=head2 U

Shortcut to V($x,$y,$z)->UnitVector()

  $unit = U($x, $y, $z);

This will also work if called with a vector object:

  $unit = U($vector);

=cut
sub U {
	my $v;
	if(ref($_[0])) {
		$v = _vec_check($_[0]);
	}
	else {
		$v = V(@_);
	}
	return(V($v->UnitVector()));
} # end subroutine U definition
########################################################################

=head2 X

Returns an x-axis unit vector.

  $xvec = X();

=cut
sub X {
	V(1,0,0);
} # end subroutine X definition
########################################################################

=head2 Y

Returns a y-axis unit vector.

  $yvec = Y();

=cut
sub Y {
	V(0,1,0);
} # end subroutine Y definition
########################################################################

=head2 Z

Returns a z-axis unit vector.

  $zvec = Z();

=cut
sub Z {
	V(0,0,1);
} # end subroutine Z definition
########################################################################

=head1 Overloading

Best used with the :terse functions, the Overloading scheme introduces
an interface which is unique from the Methods interface.  Where the
methods take references and return lists, the overloaded operators will
return references.  This allows vector arithmetic to be chained together
more easily.  Of course, you can easily dereference these with @{$vec}.

The following sections contain equivelant expressions from the longhand
and terse interfaces, respectively.

=head2 Negation:

  @a = NewVec->(0,1,1)->ScalarMult(-1);
  @a = @{-V(0,1,1)};

=head2 Stringification:

This also performs concatenation and other string operations.

  print join(", ", 0,1,1), "\n";

  print V(0,1,1), "\n";

  $v = V(0,1,1);
  print "$v\n";
  print "$v" . "\n";
  print $v, "\n";

=head2 Addition:

  @a = NewVec(0,1,1)->Plus([2,2]);

  @a = @{V(0,1,1) + V(2,2)};

  # only one argument needs to be blessed:
  @a = @{V(0,1,1) + [2,2]};

  # and which one is blessed doesn't matter:
  @a = @{[0,1,1] + V(2,2)};

=head2 Subtraction:

  @a = NewVec(0,1,1)->Minus([2,2]);

  @a = @{[0,1,1] - V(2,2)};

=head2 Scalar Multiplication:

  @a = NewVec(0,1,1)->ScalarMult(2);

  @a = @{V(0,1,1) * 2};

  @a = @{2 * V(0,1,1)};

=head2 Scalar Division:

  @a = NewVec(0,1,1)->ScalarMult(1/2);

  # order matters!
  @a = @{V(0,1,1) / 2};

=head2 Cross Product:

  @a = NewVec(0,1,1)->Cross([0,1]);

  @a = @{V(0,1,1) x [0,1]};

  @a = @{[0,1,1] x V(0,1)};

=head2 Dot Product:

Also known as the "Scalar Product".

  $a = NewVec(0,1,1)->Dot([0,1]);

  $a = V(0,1,1) * [0,1];

Note:  Not using the '.' operator here makes everything more efficient.
I know, the * is not a dot, but at least it's a mathematical operator
(perl does some implied string concatenation somewhere which drove me to
avoid the dot.)

=head2 Comparison:

The == and != operators will compare vectors for equal direction and
magnitude.  No attempt is made to apply tolerance to this equality.

=head2 Length:

  $a = NewVec(0,1,1)->Length();

  $a = abs(V(0,1,1));

=head2 Vector Projection:

This one is a little different.  Where the method is written
$a->Proj($b) to give the projection of $b onto $a, this reads like you
would say it (b projected onto a):  $b>>$a.

  @a = NewVec(0,1,1)->Proj([0,0,1]);

  @a = @{V(0,0,1)>>[0,1,1]};

=head1 Chaining Operations

The above examples simply show how to go from the method interface to
the overloaded interface, but where the overloading really shines is in
chaining multiple operations together.  Because the return values from
the overloaded operators are all references, you dereference them only
when you are done.

=head2 Unit Vector left of a line

This comes from the CAD::Calc::line_to_rectangle() function.

  use Math::Vec qw(:terse);
  @line = ([0,1],[1,0]);
  my ($a, $b) = map({V(@$_)} @line);
  $unit = U($b - $a);
  $left = $unit x -Z();

=head2 Length of a cross product

  $length = abs($va x $vb);

=head2 Vectors as coordinate axes

This is useful in drawing eliptical arcs using dxf data.

  $val = 3.14159;                             # the 'start parameter'
  @c = (14.15973317961194, 6.29684276451746); # codes 10, 20, 30
  @e = (6.146127847120538, 0);                # codes 11, 21, 31
  @ep = @{V(@c) + \@e};                       # that's the axis endpoint
  $ux = U(@e);                                # unit on our x' axis
  $uy = U($ux x -Z());                       # y' is left of x'
  $center = V(@c);
  # autodesk gives you this:
  @pt = ($a * cos($val), $b * sin($val));
  # but they don't tell you about the major/minor axis issue:
  @pt = @{$center + $ux * $pt[0] + $uy * $pt[1]};;

=head1 Precedence

The operator precedence is going to be whatever perl wants it to be.  I
have not yet investigated this to see if it matches standard vector
arithmetic notation.  If in doubt, use parentheses.

One item of note here is that the 'x' and '*' operators have the same
precedence, so the leftmost wins.  In the following example, you can get
away without parentheses if you have the cross-product first.

  # dot product of a cross product:
  $v1 x $v2 * $v3
  ($v1 x $v2) * $v3

  # scalar crossed with a vector (illegal!)
  $v3 * $v1 x $v2

=cut

use overload
	'neg' => sub {
		return(V($_[0]->ScalarMult(-1)));
	},
	'""' => sub {
		return(join(",", @{$_[0]}));
	},
	'+' => sub {
		my ($v, $arg) = @_;
		$arg = _vec_check($arg);
		return(V($v->Plus($arg)));
	},
	'-' => sub {
		my ($v, $arg, $flip) = @_;
		$arg = _vec_check($arg);
		$flip and (($v, $arg) = ($arg, $v));
		return(V($v->Minus($arg)));
	},
	'*' => sub {
		my($v, $arg) = @_;
		ref($arg) and
			return($v->Dot($arg));
		return(V($v->ScalarMult($arg)));
	},
	'/' => sub {
		my($v, $arg, $flip) =  @_;
		$flip and croak("cannot divide by vector");
		$arg or croak("cannot divide vector by zero");
		return(V($v->ScalarMult(1 / $arg)));
	},
	'x' => sub {
		my ($v, $arg, $flip) = @_;
		$arg = _vec_check($arg);
		$flip and (($v, $arg) = ($arg, $v));
		return(V($v->Cross($arg)));
	},
	'==' => sub {
		my ($v, $arg) = @_;
		$arg = _vec_check($arg);
		for(my $i = 0; $i < 3; $i++) {
			($v->[$i] == $arg->[$i]) or return(0);
		}
		return(1);
	},
	'!=' => sub {
		my ($v, $arg) = @_;
		return(! ($v == $arg));
	},
	'abs' => sub {
		return($_[0]->Length());
	},
	'>>' => sub {
		my ($v, $arg, $flip) = @_;
		$arg = _vec_check($arg);
		$flip and (($v, $arg) = ($arg, $v));
		return(V($arg->Proj($v)));
	},
	;

# Check and return a vector (or array reference turns into a vector.)
# also serves to initialize Z-coordinate.
sub _vec_check {
	my $arg = shift;
	if(ref($arg)) {
		if(ref($arg) eq "ARRAY") {
			$arg = V(@$arg);
		}
		else {
			eval{$arg->isa('Math::Vec')};
			$@ and 
				croak("cannot use $arg as a vector");
		}
	}
	else {
		croak("cannot use $arg as a vector");
	}
	return($arg);
} # end subroutine _vec_check definition
########################################################################

=head1 Methods

The typical theme is that methods require array references and return
lists.  This means that you can choose whether to create an anonymous
array ref for use in feeding back into another function call, or you
can simply use the list as-is.  Methods which return a scalar or list
of scalars (in the mathematical sense, not the Perl SV sense) are
exempt from this theme, but methods which return what could become one
vector will return it as a list.

If you want to chain calls together, either use the NewVec constructor,
or enclose the call in square brackets to make an anonymous array out
of the result.

  my $vec = NewVec(@pt);
  my $doubled = NewVec($vec->ScalarMult(0.5));
  my $other = NewVec($vec->Plus([0,2,1], [4,2,3]));
  my @result = $other->Minus($doubled);
  $unit = NewVec(NewVec(@result)->UnitVector());

The vector objects are simply blessed array references.  This makes for
a fairly limited amount of manipulation, but vector math is not
complicated stuff.  Hopefully, you can save at least two lines of code
per calculation using this module.

=head2 Dot

Returns the dot product of $vec 'dot' $othervec.

  $vec->Dot($othervec);

=cut
sub Dot {
	my $self = shift;
	my ($operand) = @_;
	$operand = _vec_check($operand);
	my @r = map( {$self->[$_] * $operand->[$_]} 0,1,2);
	return( $r[0] + $r[1] + $r[2]);
} # end subroutine Dot definition
########################################################################

=head2 DotProduct

Alias to Dot()

  $number = $vec->DotProduct($othervec);

=cut
sub DotProduct {
	my $self = shift;
	return($self->Dot(@_));
} # end subroutine DotProduct definition
########################################################################

=head2 Cross

Returns $vec x $other_vec

  @list = $vec->Cross($other_vec);
  # or, to use the result as a vec:
  $cvec = NewVec($vec->Cross($other_vec));

=cut
sub Cross {
	my $a = shift;
	my $b = shift;
	$b = _vec_check($b);
	my $x = (($a->[1] * $b->[2]) - ($a->[2] * $b->[1]));
	my $y = (($a->[2] * $b->[0]) - ($a->[0] * $b->[2]));
	my $z = (($a->[0] * $b->[1]) - ($a->[1] * $b->[0]));
	return($x, $y, $z);
} # end subroutine Cross definition
########################################################################

=head2 CrossProduct

Alias to Cross() (should really strip out all of this clunkiness and go
to operator overloading, but that gets into other hairiness.)

  $vec->CrossProduct();

=cut
sub CrossProduct {
	my $self = shift;
	return($self->Cross(@_));
} # end subroutine CrossProduct definition
########################################################################

=head2 Length

Returns the length of $vec

  $length = $vec->Length();

=cut
sub Length {
	my Math::Vec $self = shift;
	my $sum;
	map( {$sum+=$_**2} @$self );
	return(sqrt($sum));
} # end subroutine Length definition
########################################################################

=head2 Magnitude

  $vec->Magnitude();

=cut
sub Magnitude {
	my Math::Vec $self = shift;
	return($self->Length());
} # end subroutine Magnitude definition
########################################################################

=head2 UnitVector

  $vec->UnitVector();

=cut
sub UnitVector {
	my Math::Vec $self = shift;
	my $mag = $self->Length();
	$mag || croak("zero-length vector (@$self) has no unit vector");
	return(map({$_ / $mag} @$self) );
} # end subroutine UnitVector definition
########################################################################

=head2 ScalarMult

Factors each element of $vec by $factor.

  @new = $vec->ScalarMult($factor);

=cut
sub ScalarMult {
	my Math::Vec $self = shift;
	my($factor) = @_;
	return(map( {$_ * $factor} @{$self}));
} # end subroutine ScalarMult definition
########################################################################

=head2 Minus

Subtracts an arbitrary number of vectors.

  @result = $vec->Minus($other_vec, $another_vec?);

This would be equivelant to:

  @result = $vec->Minus([$other_vec->Plus(@list_of_vectors)]);

=cut
sub Minus {
	my Math::Vec $self = shift;
	my @list = @_;
	my @result = @$self;
	foreach my $vec (@list) {
		@result = map( {$result[$_] - $vec->[$_]} 0..$#$vec);
		}
	return(@result);
} # end subroutine Minus definition
########################################################################

=head2 VecSub

Alias to Minus()

  $vec->VecSub();

=cut
sub VecSub {
	my Math::Vec $self = shift;
	return($self->Minus(@_));
} # end subroutine VecSub definition
########################################################################

=head2 InnerAngle

Returns the acute angle (in radians) in the plane defined by the two
vectors.

  $vec->InnerAngle($other_vec);

=cut
sub InnerAngle {
	my $A = shift;
	my $B = shift;
	my $dot_prod = $A->Dot($B);
	my $m_A = $A->Length();
	my $m_B = $B->Length();
	# NOTE occasionally returned an answer with a very small imaginary
	# part (for d/(A*B) values very slightly under -1 or very slightly
	# over 1.)  Large imaginary results are not possible with vector 
	# inputs, so we can just drop the imaginary bit.
	return(Math::Vec::Support::acos($dot_prod / ($m_A * $m_B)) );
} # end subroutine InnerAngle definition
########################################################################

=head2 DirAngles

  $vec->DirAngles();

=cut
sub DirAngles {
	my Math::Vec $self = shift;
	my @unit = $self->UnitVector();
	return( map( {acos($_)} @unit) );
} # end subroutine DirAngles definition
########################################################################

=head2 Plus

Adds an arbitrary number of vectors.

  @result = $vec->Plus($other_vec, $another_vec);

=cut
sub Plus {
	my Math::Vec $self = shift;
	my @list = @_;
	my @result = @$self;
	foreach my $vec (@list) {
		@result = map( {$result[$_] + $vec->[$_]} 0..$#$vec);
	}
	return(@result);
} # end subroutine Plus definition
########################################################################

=head2 PlanarAngles

If called in list context, returns the angle of the vector in each of
the primary planes.  If called in scalar context, returns only the
angle in the xy plane.  Angles are returned in radians
counter-clockwise from the primary axis (the one listed first in the
pairs below.)

  ($xy_ang, $xz_ang, $yz_ang) = $vec->PlanarAngles();

=cut
sub PlanarAngles {
	my $self = shift;
	my $xy = atan2($self->[1], $self->[0]);
	wantarray || return($xy);
	my $xz = atan2($self->[2], $self->[0]);
	my $yz = atan2($self->[2], $self->[1]);
	return($xy, $xz, $yz);
} # end subroutine PlanarAngles definition
########################################################################

=head2 Ang

A simpler alias to PlanarAngles() which eliminates the concerns about
context and simply returns the angle in the xy plane.

  $xy_ang = $vec->Ang();

=cut
sub Ang {
	my $self = shift;
	my ($xy) = $self->PlanarAngles();
	return($xy);
} # end subroutine Ang definition
########################################################################

=head2 VecAdd

  $vec->VecAdd();

=cut
sub VecAdd {
	my Math::Vec $self = shift;
	return($self->Plus(@_));
} # end subroutine VecAdd definition
########################################################################

=head2 UnitVectorPoints

Returns a unit vector which points from $A to $B.

  $A->UnitVectorPoints($B);

=cut
sub UnitVectorPoints {
	my $A = shift;
	my $B = shift;
	$B = NewVec(@$B); # because we cannot guarantee that it was blessed
	return(NewVec($B->Minus($A))->UnitVector());
} # end subroutine UnitVectorPoints definition
########################################################################

=head2 InnerAnglePoints

Returns the InnerAngle() between the three points.  $Vert is the vertex
of the points.

  $Vert->InnerAnglePoints($endA, $endB);

=cut
sub InnerAnglePoints {
	my $v = shift;
	my ($A, $B) = @_;
	my $lead = NewVec($v->UnitVectorPoints($A));
	my $tail = NewVec($v->UnitVectorPoints($B));
	return($lead->InnerAngle($tail));
} # end subroutine InnerAnglePoints definition
########################################################################

=head2 PlaneUnitNormal

Returns a unit vector normal to the plane described by the three
points.  The sense of this vector is according to the right-hand rule
and the order of the given points.  The $Vert vector is taken as the
vertex of the three points.  e.g. if $Vert is the origin of a
coordinate system where the x-axis is $A and the y-axis is $B, then the
return value would be a unit vector along the positive z-axis.

  $Vert->PlaneUnitNormal($A, $B);

=cut
sub PlaneUnitNormal {
	my $v = shift;
	my ($A, $B) = @_;
	$A = NewVec(@$A);
	$B = NewVec(@$B);
	my $lead = NewVec($A->Minus($v));
	my $tail = NewVec($B->Minus($v));
	return(NewVec($lead->Cross($tail))->UnitVector);
} # end subroutine PlaneUnitNormal definition
########################################################################

=head2 TriAreaPoints

Returns the angle of the triangle formed by the three points.

  $A->TriAreaPoints($B, $C);

=cut
sub TriAreaPoints {
	my $A = shift;
	my ($B, $C) = @_;
	$B = NewVec(@$B);
	$C = NewVec(@$C);
	my $lead = NewVec($A->Minus($B));
	my $tail = NewVec($A->Minus($C));
	return(NewVec($lead->Cross($tail))->Length() / 2);
} # end subroutine TriAreaPoints definition
########################################################################

=head2 Comp

Returns the scalar projection of $B onto $A (also called the component
of $B along $A.)

  $A->Comp($B);

=cut
sub Comp {
	my $self = shift;
	my $B = _vec_check(shift);
	my $length = $self->Length();
	$length || croak("cannot Comp() vector without length");
	return($self->Dot($B) / $length);
} # end subroutine Comp definition
########################################################################

=head2 Proj

Returns the vector projection of $B onto $A.

  $A->Proj($B);

=cut
sub Proj {
	my $self = shift;
	my $B = shift;
	return(NewVec($self->UnitVector())->ScalarMult($self->Comp($B)));
} # end subroutine Proj definition
########################################################################

=head2 PerpFoot

Returns a point on line $A,$B which is as close to $pt as possible (and
therefore perpendicular to the line.)

  $pt->PerpFoot($A, $B);

=cut
sub PerpFoot {
	my $pt = shift;
	my ($A, $B) = @_;
	$pt = NewVec($pt->Minus($A));
	$B = NewVec(NewVec(@$B)->Minus($A));
	my $proj = NewVec($B->Proj($pt));
	return($proj->Plus($A));
} # end subroutine PerpFoot definition
########################################################################

=head1 Incomplete Methods

The following have yet to be translated into this interface.  They are
shown here simply because I intended to fully preserve the function
names from the original Math::Vector module written by Wayne M.
Syvinski.

=head2 TripleProduct

  $vec->TripleProduct();

=cut
sub TripleProduct {
	die("not written");
} # end subroutine TripleProduct definition
########################################################################

=head2 IJK

  $vec->IJK();

=cut
sub IJK {
	die("not written");

} # end subroutine IJK definition
########################################################################

=head2 OrdTrip

  $vec->OrdTrip();

=cut
sub OrdTrip {
	die("not written");

} # end subroutine OrdTrip definition
########################################################################

=head2 STV

  $vec->STV();

=cut
sub STV {
	die("not written");

} # end subroutine STV definition
########################################################################

=head2 Equil

  $vec->Equil();

=cut
sub Equil {
	die("not written");

} # end subroutine Equil definition
########################################################################

1;
# vim:ts=4:sw=4:noet
