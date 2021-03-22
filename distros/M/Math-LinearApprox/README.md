# NAME

Math::LinearApprox - fast linear approximation of 2D sequential points

# SYNOPSIS

```
use Math::LinearApprox qw( linear_approx linear_approx_str );

# OO style
my @points = ( 0, 4 );
my $la = Math::LinearApprox->new();
my $la = Math::LinearApprox->new(\@points);
$la->add_point( 2, 1 );
$la->add_point( 7, 0 );
print $la->equation_str();
my ($A, $B) = $la->equation();

# Procedural style
my @points = ( 0, 4, 2, 1, 7, 0 );
print linear_approx_str(\@points);
```

# DESCRIPTION

Typically there are several methods of linear approximation in use to
approximate 2D points series, including least squares method.
All of them requires a lot of multiplication operations.

I have invented new numerical method which requires less complex instructions
and much more suitable for approximation of really huge arrays of data.
This method description and comparative analysis will be published in a
separate scientific paper soon.

Currently there is a requirement for all the points to be sorted by X axis.
Also currently this method uses all the points and does not include any
filtering abilities.  Hopefully, they will be added soon.

Each point should be specified by `$x, $y` pair of coordinates.
You can either push the points from anywhere into the model -- they are not
being saved AS-IS -- or populate the model with `@points = ($x, $y, ...)`
reference.

# SUBROUTINES

## add\_point

To fill the model with data one can call `$obj->add_point( $x, $y )`.
This function returns nothing meaningful.
Perl will cast anything illegal passed as `$x, $y` into numbers.
So it is your responsibility to validate your points in advance.

- `$x` is X coordinate of the point.
- `$y` is Y coordinate of the point.

## equation

Since any line that is not perpendicular to X axis could be represented 
in a form of `y = A * x + B`, then `$obj->equation()` returns
`($A, $B)` coefficients.  The method returns undef unless the model could
not be represented in such a form.

## equation\_str

The `$obj->equation_str` returns stringified equation of the model either
in form `"y = A * x + B"`, or `"x = X"` in case all points are vertically
distributed.  The method dies unless the model could not be approximated.
In most cases it is due to absense of points in the model.

## linear\_approx

The `linear_approx( \@points )` is a procedural style alias for
`new( \@points )->equation()`.

## linear\_approx\_str

The `linear_approx_str( \@points )` is a procedural style alias for
`new( \@points )->equation_str()`.

## new

`$obj = Math::LinearApprox->new()` is an object constructor
that will instantiate the approximation model.  The only parameter is 
optional -- reference to array of points: `[$x1, $y1, $x2, $y2, ...]`.

# AUTHOR

Sergei Zhmylev, `<zhmylove@cpan.org>`

# BUGS

Please report any bugs or feature requests to official GitHub page at
[https://github.com/zhmylove/math-linearapprox](https://github.com/zhmylove/math-linearapprox).
You also can use official CPAN bugtracker by reporting to
`bug-math-linearapprox at rt.cpan.org`, or through the web interface at
[https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-LinearApprox](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-LinearApprox).
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

# INSTALLATION

To install this module, run the following commands:

```
$ perl Makefile.PL
$ make
$ make test
$ make install
```

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Sergei Zhmylev.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
