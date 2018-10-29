## Lingua::RO::Numbers

Converts numeric values into their Romanian string equivalents and the other way around.

### SYNOPSIS

```perl
use 5.010;
use Lingua::RO::Numbers qw(number_to_ro ro_to_number);

say number_to_ro(315);
  # prints: 'trei sute cincisprezece'

say ro_to_number('trei sute douazeci si cinci virgula doi');
  # prints: 325.2
```

#### OPTIONS

Initializing an object.

```perl
my $obj = Lingua::RO::Numbers->new();
```

is equivalent with:

```perl
my $obj = Lingua::RO::Numbers->new(
                  diacritics          => 1,
                  invalid_number      => undef,
                  negative_sign       => 'minus',
                  decimal_point       => 'virgulă',
                  thousands_separator => '',
                  infinity            => 'infinit',
                  not_a_number        => 'NaN',
          );
```

#### `number_to_ro($number)`

Converts a number to its Romanian string representation.

```perl
# Functional oriented usage
$string = number_to_ro($number);
$string = number_to_ro($number, %opts);

# Object oriented usage
my $obj = Lingua::RO::Numbers->new(%opts);
$string = $obj->number_to_ro($number);

# Example:
print number_to_ro(98_765, thousands_separator => q{,});
  # says: 'nouăzeci și opt de mii, șapte sute șaizeci și cinci'
```

#### `ro_to_number($text)`

Converts a Romanian text into its numeric value.

```perl
# Functional oriented usage
$number = ro_to_number($text);
$number = ro_to_number($text, %opts);

# Object oriented usage
my $obj = Lingua::RO::Numbers->new(%opts);
$number = $obj->ro_to_number($text);

# Example:
print ro_to_number('patruzeci si doi');  # says: 42
```

### INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

### SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Lingua::RO::Numbers

### LICENSE AND COPYRIGHT

Copyright (C) 2013-2018 Daniel "Trizen" Șuteu

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
