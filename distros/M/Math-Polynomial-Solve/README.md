# Math::Polynomial::Solve

## version 2.86

---
As foretold (but three quarters of a year late), version 2.85
(released 30 June 2018) warned if you have not set the coefficient order
in your programs. This will continue on even after version 3.00, when the
default coefficient order changes. At some point after that the warning
will be dropped, but when hasn't been determined and it will certainly
remain this way at the least throughout 2020.

---

## Coming changes:

By release 3.00 (scheduled for end of 2019), the default order of the the
coefficients of the polynomials will be changed to an ascending order,
to match that of Math::Polynomial. To help with the change, the function
coefficients() is available.

Currently all functions are called with the polynomials in descending order.
For example if your polynomial is the cubic `x**3 + 3*x**2 + 11* x + 5`, then
by default, you would list the coefficients this way:

```perl
my @cubic = (1, 3, 11, 5);
my @roots = cubic_roots(@cubic);
```

This will work, but you will get a warning about the upcoming change. To
silence the warning, and to make sure your code continues to work in
version 3.00, insert this line at the beginning of your code:

```perl
coefficients order => 'descending';

my @cubic = (1, 3, 11, 5);
my @roots = cubic_roots(@cubic);
```

On the other hand, if you want to get a jump on the change in version
3.00 (or to just have less-confusing code if you're also using
Math::Polynomial), you can use coefficients() now to future-proof
your code:

```perl
coefficients order => 'ascending';      # Same as Math::Polynomial

my @cubic = (5, 11, 3, 1);
my @roots = cubic_roots(@cubic);
```

---

This package provides a set of functions that find the roots of
polynomials up to degree 4 using the classical methods; a function
for solving polynomials of any degree by an implementation of the
QR Hessenberg algorithm; and functions that implement Sturm's
sequence for counting the number of real, unique roots in a range.

These functions can be exported by name or by tag (`:classical`,
`:numeric`, `:sturm`, and `:utility`). The utility tag exports the
functions that are used internally and which previously were private
to the module. See the documentation for more information.

Using the classical methods, the cubic may be solved by the method
described by R. W. D. Nickalls, "A New Approach to solving the cubic:
Cardan's solution revealed," The Mathematical Gazette, 77, 354-359, 1993.
Dr. Nickalls has made his paper available at
(http://www.nickalls.org/dick/papers/maths/cubic1993.pdf), one of his
many publications at (http://www.nickalls.org/dick/papers/rwdnPapers.html)

The solution for the quartic is based on Ferrari's method, as described in the
[Encyclopedia of Mathematics](https://www.encyclopediaofmath.org/index.php/Ferrari_method)

## INSTALLATION

To install this module, run the following commands:

```bash
perl Build.PL
./Build
./Build test
./Build install
```

## COPYRIGHT AND LICENSE

Copyright (c) 2018 John M. Gamble. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.
