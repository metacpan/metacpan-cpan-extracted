# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 8;

use Math::BigRat;

# Reset accuracy and precision.

Math::BigRat -> accuracy(undef);
Math::BigRat -> precision(undef);

# Inf and NaN.

note(qq|\nMath::BigRat -> new("+inf") -> bdstr();\n\n|);
is(Math::BigRat -> new("+inf") -> bdstr(), 'inf');

note(qq|\nMath::BigRat -> new("-inf") -> bdstr();\n\n|);
is(Math::BigRat -> new("-inf") -> bdstr(), '-inf');

note(qq|\nMath::BigRat -> new("NaN") -> bdstr();\n\n|);
is(Math::BigRat -> new("NaN") -> bdstr(), 'NaN');

# Default rounding.

note(qq|\nMath::BigRat -> new("355/113") -> bdstr();\n\n|);
is(Math::BigRat -> new("355/113") -> bdstr(),
   '3.141592920353982300884955752212389380531');

# Accuracy as argument.

note(qq|\nMath::BigRat -> new("355/113") -> bdstr(3);\n\n|);
is(Math::BigRat -> new("355/113") -> bdstr(3), '3.14');

# Precision as argument.

note(qq|\nMath::BigRat -> new("355/113") -> bdstr(undef, -3);\n\n|);
is(Math::BigRat -> new("355/113") -> bdstr(undef, -3), '3.142');

# Accuracy as class variable.

note(qq|\nMath::BigRat -> accuracy(5); Math::BigRat -> new("355/113") -> bdstr();\n\n|);
Math::BigRat -> accuracy(5);
is(Math::BigRat -> new("355/113") -> bdstr(), '3.1416');

# Precision as class variable.

note(qq|\nMath::BigRat -> precision(-5); Math::BigRat -> new("355/113") -> bdstr();\n\n|);
Math::BigRat -> precision(-5);
is(Math::BigRat -> new("355/113") -> bdstr(), '3.14159');
