# NAME

Graphics::ColorNames::Netscape - Netscape 1.1 Color Names

# VERSION

version v3.1.3

# SYNOPSIS

```
require Graphics::ColorNames::Netscape;

$NameTable = Graphics::ColorNames::Netscape->NamesRgbTable();
$RgbBlack  = $NameTable->{black};
```

# DESCRIPTION

This module defines color names and their associated RGB values associated
with Netscape 1.1 (I cannot determine whether they were once usable in
Netscape or were arbitrary names for RGB values-- _many of these names are
not recognized by later versions of Netscape_).

This scheme is deprecated, but is provided as a separate release
from [Graphics::ColorNames](https://metacpan.org/pod/Graphics::ColorNames) for backwards compatability.

# SEE ALSO

[Graphics::ColorNames](https://metacpan.org/pod/Graphics::ColorNames)

[Graphics::ColorNames::Mozilla](https://metacpan.org/pod/Graphics::ColorNames::Mozilla)

[Graphics::ColorNames::IE](https://metacpan.org/pod/Graphics::ColorNames::IE)

[Graphics::ColorNames::SVG](https://metacpan.org/pod/Graphics::ColorNames::SVG)

The color names come from
[https://web.archive.org/web/20001211143800/http://home1.netscape.com/home/bg/colorindex.html](https://web.archive.org/web/20001211143800/http://home1.netscape.com/home/bg/colorindex.html).

Corrections to errors in the Netscape spec are due to
[http://www.he.net/info/color/](http://www.he.net/info/color/).

# SOURCE

The development version is on github at [https://github.com/robrwo/Graphics-ColorNames-Netscape](https://github.com/robrwo/Graphics-ColorNames-Netscape)
and may be cloned from [git://github.com/robrwo/Graphics-ColorNames-Netscape.git](git://github.com/robrwo/Graphics-ColorNames-Netscape.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Graphics-ColorNames-Netscape/issues](https://github.com/robrwo/Graphics-ColorNames-Netscape/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTORS

- Magnus Cedergren <magnus@mbox604.swipnet.se>
- Gary Vollink <gary@vollink.com>
- Slaven Rezić <slaven@rezic.de>

# COPYRIGHT AND LICENSE

Robert Rothenberg has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.
