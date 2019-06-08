# NAME

Graphics::ColorNames - defines RGB values for common color names

# VERSION

version v3.5.0

# SYNOPSIS

```perl
use Graphics::ColorNames;
use Graphics::ColorNames::WWW;

$pal = Graphics::ColorNames->new( qw[ X WWW ] );

$rgb = $pal->hex('green');          # returns '00ff00'
$rgb = $pal->hex('green', '0x');    # returns '0x00ff00'
$rgb = $pal->hex('green', '#');     # returns '#00ff00'

$rgb = $pal->rgb('green');          # returns '0,255,0'
@rgb = $pal->rgb('green');          # returns (0, 255, 0)
```

# DESCRIPTION

This module provides a common interface for obtaining the RGB values
of colors by standard names.  The intention is to (1) provide a common
module that authors can use with other modules to specify colors by
name; and (2) free module authors from having to "re-invent the wheel"
whenever they decide to give the users the option of specifying a
color by name rather than RGB value.

# METHODS

## `new`

The constructor is as follows:

```perl
my $pal = Graphics::ColorNames->new( @schemes );
```

where `@schemes` is an array of color schemes (palettes, dictionaries).

A valid color scheme may be the name of a color scheme (such as `X`
or a full module name such as `Graphics::ColorNames::X`), a reference
to a color scheme hash or subroutine, or to the path or open
filehandle for a `rgb.txt` file.

If none are specified, it uses the default `X` color scheme, which
corresponds to the X-Windows `rgb.txt` colors.  For most purposes,
this is good enough.  Since v3.2.0, it was updated to use the
2014-07-06 colors, so includes the standard CSS colors as well.

Other color schemes are available on CPAN,
e.g. [Graphics::ColorNames::WWW](https://metacpan.org/pod/Graphics::ColorNames::WWW).

Since version 2.1002, [Color::Library](https://metacpan.org/pod/Color::Library) dictionaries can be used as
well:

```perl
my $pal = Graphics::ColorNames->new( 'Color::Library::Dictionary::HTML' );
```

## `rgb`

```
@rgb = $pal->rgb($name);

$rgb = $pal->rgb($name, $separator);
```

If called in a list context, returns a triplet.

If called in a scalar context, returns a string separated by an
optional separator (which defauls to a comma).  For example,

```
@rgb = $pal->rgb('blue');      # returns (0, 0, 255)

$rgb = $pal->rgb('blue', ','); # returns "0,0,255"
```

Unknown color names return empty lists or strings, depending on the
context.

Color names are case insensitive, and spaces or punctuation are
ignored. So "Alice Blue" returns the same value as "aliceblue",
"ALICE-BLUE" and "a\*lICEbl-ue".  (If you are using color names based
on user input, you should add additional validation of the color
names.)

The value returned is in the six-digit hexidecimal format used in HTML and
CSS (without the initial '#'). To convert it to separate red, green, and
blue values (between 0 and 255), use the ["hex2tuple"](#hex2tuple) function.

You may also specify an absolute filename as a color scheme, if the file
is in the same format as the standard `rgb.txt` file.

## `hex`

```
$hex = $pal->hex($name, $prefix);
```

Returns a 6-digit hexidecimal RGB code for the color.  If an optional
prefix is specified, it will prefix the code with that string.  For
example,

```
$hex = $pal->hex('blue', '#'); # returns "#0000ff"
```

If the color does not exist, it will return an empty string.

A hexidecimal RGB value in the form of `#RRGGBB`, `0xRRGGBB` or
`RRGGBB` will return itself:

```
$color = $pal->hex('#123abc');         # returns '123abc'
```

## autoloaded color name methods

Autoloaded color name methods were removed in v3.4.0.

## `load_scheme`

```
$pal->load_scheme( $scheme );
```

This dynamically loads a color scheme, which can be either a hash
reference or code reference.

# EXPORTS

## `all_schemes`

```perl
my @schemes = all_schemes();
```

Returns a list of all available color schemes installed on the machine
in the `Graphics::ColorNames` namespace.

The order has no significance.

## `hex2tuple`

Converts a hexidecimal string to a tuple.

## `tuple2hex`

Converts a tuple to a hexidecimal string.

# TIED INTERFACE

The standard interface (prior to version 0.40) was through a tied hash:

```
tie %pal, 'Graphics::ColorNames', qw[ X WWW ];
```

This interface is deprecated, and will be moved to a separate module
in the future.

# CUSTOM COLOR SCHEMES

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
module.

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

# ROADMAP

The following changes are planned in the future:

- The tied interface will be removed, but implemented in a separate
module for users that wish to use it.
- The namespace for color schemes will be moved to the
`Graphics::ColorNames::Schemes` but options will be added to use the
existing scheme.

    This will allow modules to be named like `Graphics::ColorNames::Tied`
    without being confused for color schemes.

- This module will be rewritten to be a [Moo](https://metacpan.org/pod/Moo)-based class.

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
- Andreas J. König <andk@cpan.org>
- Slaven Rezić <slaven@rezic.de>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2001-2019 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
