# NAME

Graphics::ColorNames - defines RGB values for common color names

# VERSION

version v3.2.1

# SYNOPSIS

```perl
use Graphics::ColorNames 2.10;

$po = Graphics::ColorNames->new( qw[ X ] );

$rgb = $po->hex('green');          # returns '00ff00'
$rgb = $po->hex('green', '0x');    # returns '0x00ff00'
$rgb = $po->hex('green', '#');     # returns '#00ff00'

$rgb = $po->rgb('green');          # returns '0,255,0'
@rgb = $po->rgb('green');          # returns (0, 255, 0)

$rgb = $po->green;                 # same as $po->hex('green');

tie %ph, 'Graphics::ColorNames', (qw[ X ]);

$rgb = $ph{green};                 # same as $po->hex('green');
```

# DESCRIPTION

This module provides a common interface for obtaining the RGB values
of colors by standard names.  The intention is to (1) provide a common
module that authors can use with other modules to specify colors by
name; and (2) free module authors from having to "re-invent the wheel"
whenever they decide to give the users the option of specifying a
color by name rather than RGB value.

For example,

```perl
use Graphics::ColorNames 2.10;

use GD;

$pal = Graphics::ColorNames->new;

$img = new GD::Image(100, 100);

$bgColor = $img->colorAllocate( $pal->rgb('CadetBlue3') );
```

Although this is a little "bureaucratic", the meaning of this code is clear:
`$bgColor` (or background color) is 'CadetBlue3' (which is easier to for one
to understand than `0x7A, 0xC5, 0xCD`). The variable is named for its
function, not form (ie, `$CadetBlue3`) so that if the author later changes
the background color, the variable name need not be changed.

You can also define ["Custom Color Schemes"](#custom-color-schemes) for specialised palettes
for websites or institutional publications:

```
$color = $pal->hex('MenuBackground');
```

As an added feature, a hexidecimal RGB value in the form of #RRGGBB,
0xRRGGBB or RRGGBB will return itself:

```
$color = $pal->hex('#123abc');         # returns '123abc'
```

## Tied Interface

The standard interface (prior to version 0.40) is through a tied hash:

```
tie %pal, 'Graphics::ColorNames', @schemes;
```

where `%pal` is the tied hash and `@schemes` is a list of
[color schemes](#color-schemes).

A valid color scheme may be the name of a color scheme (such as `X`
or a full module name such as `Graphics::ColorNames::X`), a reference
to a color scheme hash or subroutine, or to the path or open
filehandle for a `rgb.txt` file.

As of version 2.1002, one can also use [Color::Library](https://metacpan.org/pod/Color::Library) dictionaries:

```
tie %pal, 'Graphics::ColorNames', qw(Color::Library::Dictionary::HTML);
```

This is an experimental feature which may change in later versions (see
["SEE ALSO"](#see-also) for a discussion of the differences between modules).

Multiple schemes can be used:

```
tie %pal, 'Graphics::ColorNames', qw(HTML X);
```

In this case, if the name is not a valid HTML color, the X-windows
name will be used.

One can load all available schemes in the Graphics::ColorNames namespace
(as of version 2.0):

```perl
use Graphics::ColorNames 2.0, 'all_schemes';
tie %NameTable, 'Graphics::ColorNames', all_schemes();
```

When multiple color schemes define the same name, then the earlier one
listed has priority (however, hash-based color schemes always have
priority over code-based color schemes).

When no color scheme is specified, the X-Windows scheme is assumed.

Color names are case insensitive, and spaces or punctuation
are ignored.  So "Alice Blue" returns the same
value as "aliceblue", "ALICE-BLUE" and "a\*lICEbl-ue".  (If you are
using color names based on user input, you may want to add additional
validation of the color names.)

The value returned is in the six-digit hexidecimal format used in HTML and
CSS (without the initial '#'). To convert it to separate red, green, and
blue values (between 0 and 255), use the ["hex2tuple"](#hex2tuple) function.

You may also specify an absolute filename as a color scheme, if the file
is in the same format as the standard `rgb.txt` file.

## Object-Oriented Interface

If you prefer, an object-oriented interface is available:

```perl
use Graphics::ColorNames 0.40;

$obj = Graphics::ColorNames->new('/etc/rgb.txt');

$hex = $obj->hex('skyblue'); # returns "87ceeb"
@rgb = $obj->rgb('skyblue'); # returns (0x87, 0xce, 0xeb)
```

The interface is similar to the [Color::Rgb](https://metacpan.org/pod/Color::Rgb) module:

- new

    ```
    $obj = Graphics::ColorNames->new( @SCHEMES );
    ```

    Creates the object, using the default [color schemes](#color-schemes).
    If none are specified, it uses the `X` scheme.

- load\_scheme

    ```
    $obj->load_scheme( $scheme );
    ```

    Loads a scheme dynamically.  The scheme may be any hash or code reference.

- hex

    ```
    $hex = $obj->hex($name, $prefix);
    ```

    Returns a 6-digit hexidecimal RGB code for the color.  If an optional
    prefix is specified, it will prefix the code with that string.  For
    example,

    ```
    $hex = $obj->hex('blue', '#'); # returns "#0000ff"
    ```

- rgb

    ```
    @rgb = $obj->rgb($name);

    $rgb = $obj->rgb($name, $separator);
    ```

    If called in a list context, returns a triplet.

    If called in a scalar context, returns a string separated by an
    optional separator (which defauls to a comma).  For example,

    ```
    @rgb = $obj->rgb('blue');      # returns (0, 0, 255)

    $rgb = $obj->rgb('blue', ','); # returns "0,0,255"
    ```

Since version 2.10\_02, the interface will assume method names
are color names and return the hex value,

```
$obj->black eq $obj->hex("black")
```

Method names are case-insensitive, and underscores are ignored.

## Utility Functions

These functions are not exported by default, so much be specified to
be used:

```perl
use Graphics::ColorNames qw( all_schemes hex2tuple tuple2hex );
```

- all\_schemes

    ```
    @schemes = all_schemes();
    ```

    Returns a list of all available color schemes installed on the machine
    in the `Graphics::ColorNames` namespace.

    The order has no significance.

- hex2tuple

    ```
    ($red, $green, $blue) = hex2tuple( $colors{'AliceBlue'});
    ```

- tuple2hex

    ```
    $rgb = tuple2hex( $red, $green, $blue );
    ```

## Color Schemes

The following schemes are available by default:

- X

    About 750 color names used in X-Windows (although about 90+ of them are
    duplicate names with spaces).

- HTML

    16 common color names defined in the HTML 4.0 specification. These
    names are also used with older CSS and SVG specifications. (You may
    want to see [Graphics::ColorNames::SVG](https://metacpan.org/pod/Graphics::ColorNames::SVG) for a complete list.)

- Windows

    16 commom color names used with Microsoft Windows and related
    products.  These are actually the same colors as the ["HTML"](#html) scheme,
    although with different names.

Note that the [Graphics::ColorNames::Netscape](https://metacpan.org/pod/Graphics::ColorNames::Netscape) scheme is no longer
included with this distribution. If you need it, you should install it
separately.

Rather than a color scheme, the path or open filehandle for a
`rgb.txt` file may be specified.

Additional color schemes are available on CPAN.

## Custom Color Schemes

You can add naming scheme files by creating a Perl module is the name
`Graphics::ColorNames::SCHEMENAME` which has a subroutine named
`NamesRgbTable` that returns a hash of color names and RGB values.
(Schemes with a different base namespace will require the fill namespace
to be given.)

The color names must be in all lower-case, and the RGB values must be
24-bit numbers containing the red, green, and blue values in most- significant
to least- significant byte order.

An example naming schema is below:

```perl
package Graphics::ColorNames::Metallic;

sub NamesRgbTable() {
  use integer;
  return {
    copper => 0xb87333,
    gold   => 0xcd7f32,
    silver => 0xe6e8fa,
  };
}
```

You would use the above schema as follows:

```
tie %colors, 'Graphics::ColorNames', 'Metallic';
```

The behavior of specifying multiple keys with the same name is undefined
as to which one takes precedence.

As of version 2.10, case, spaces and punctuation are ignored in color
names. So a name like "Willy's Favorite Shade-of-Blue" is treated the
same as "willysfavoroteshadeofblue".  (If your scheme does not include
duplicate entrieswith spaces and punctuation, then the minimum
version of [Graphics::ColorNames](https://metacpan.org/pod/Graphics::ColorNames) should be 2.10 in your requirements.)

An example of an additional module is the [Graphics::ColorNames::Mozilla](https://metacpan.org/pod/Graphics::ColorNames::Mozilla)
module by Steve Pomeroy.

Since version 1.03, `NamesRgbTable` may also return a code reference:

```perl
package Graphics::ColorNames::Orange;

sub NamesRgbTable() {
  return sub {
    my $name = shift;
    return 0xffa500;
  };
}
```

See [Graphics::ColorNames::GrayScale](https://metacpan.org/pod/Graphics::ColorNames::GrayScale) for an example.

# SEE ALSO

[Color::Library](https://metacpan.org/pod/Color::Library) provides an extensive library of color schemes. A notable
difference is that it supports more complex schemes which contain additional
information about individual colors and map multiple colors to a single name.

[Color::Rgb](https://metacpan.org/pod/Color::Rgb) has a similar function to this module, but parses an
`rgb.txt` file.

[Graphics::ColorObject](https://metacpan.org/pod/Graphics::ColorObject) can convert between RGB and other color space
types.

[Graphics::ColorUtils](https://metacpan.org/pod/Graphics::ColorUtils) can also convert betweeb RGB and other color
space types, and supports RGB from names in various color schemes.

[Acme::AutoColor](https://metacpan.org/pod/Acme::AutoColor) provides subroutines corresponding to color names.

# SOURCE

The development version is on github at [https://github.com/robrwo/Graphics-ColorNames](https://github.com/robrwo/Graphics-ColorNames)
and may be cloned from [git://github.com/robrwo/Graphics-ColorNames.git](git://github.com/robrwo/Graphics-ColorNames.git)

The SourceForge project for this module at
[http://sourceforge.net/projects/colornames/](http://sourceforge.net/projects/colornames/) is no longer
maintained.

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNames](https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNames) or
by email to
[bug-Graphics-ColorNames@rt.cpan.org](mailto:bug-Graphics-ColorNames@rt.cpan.org).

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTORS

- Alan D. Salewski <alans@cji.com>
- Steve Pomeroy <xavier@cpan.org>
- "chemboy" <chemboy@perlmonk.org>
- Magnus Cedergren <magnus@mbox604.swipnet.se>
- Gary Vollink <gary@vollink.com>
- Claus Färber <cfaerber@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2001-2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
