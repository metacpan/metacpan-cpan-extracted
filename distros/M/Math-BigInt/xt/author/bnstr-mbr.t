# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 8;

use Math::BigRat;

# Reset accuracy and precision.

Math::BigRat -> accuracy(undef);
Math::BigRat -> precision(undef);

# Inf and NaN.

note(qq|\nMath::BigRat -> new("+inf") -> bnstr();\n\n|);
is(Math::BigRat -> new("+inf") -> bnstr(), 'inf');

note(qq|\nMath::BigRat -> new("-inf") -> bnstr();\n\n|);
is(Math::BigRat -> new("-inf") -> bnstr(), '-inf');

note(qq|\nMath::BigRat -> new("NaN") -> bnstr();\n\n|);
is(Math::BigRat -> new("NaN") -> bnstr(), 'NaN');

# Default rounding.

note(qq|\nMath::BigRat -> new("355/113") -> bnstr();\n\n|);
is(Math::BigRat -> new("355/113") -> bnstr(),
   '3.141592920353982300884955752212389380531e+0');

# Accuracy as argument.

note(qq|\nMath::BigRat -> new("355/113") -> bnstr(3);\n\n|);
is(Math::BigRat -> new("355/113") -> bnstr(3), '3.14e+0');

# Precision as argument.

note(qq|\nMath::BigRat -> new("355/113") -> bnstr(undef, -3);\n\n|);
is(Math::BigRat -> new("355/113") -> bnstr(undef, -3), '3.142e+0');

# Accuracy as class variable.

note(qq|\nMath::BigRat -> accuracy(5); Math::BigRat -> new("355/113") -> bnstr();\n\n|);
Math::BigRat -> accuracy(5);
is(Math::BigRat -> new("355/113") -> bnstr(), '3.1416e+0');

# Precision as class variable.

note(qq|\nMath::BigRat -> precision(-5); Math::BigRat -> new("355/113") -> bnstr();\n\n|);
Math::BigRat -> precision(-5);
is(Math::BigRat -> new("355/113") -> bnstr(), '3.14159e+0');
