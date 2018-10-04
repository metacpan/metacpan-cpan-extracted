# NAME

Graphics::ColorNames::Werner - RGB codes for Werner's Nomenclature of Colours

# VERSION

version v1.0.2

# SYNOPSIS

```
require Graphics::ColorNames::Werner;

$NameTable = Graphics::ColorNames::Werner->NamesRgbTable();
$RgbBlack  = $NameTable->{asparagusgreen};
```

# DESCRIPTION

This module defines color names and their associated RGB values
from the online version of
[Werner's Nomenclature of Colors](https://www.c82.net/werner/).
It is intended as a plugin for [Graphics::ColorNames](https://metacpan.org/pod/Graphics::ColorNames).

Note that the color names have been normalized to lower case,
without and punctuation. However, they will use the original
spelling, e.g. "colour" instead of "color".

# SOURCE

The development version is on github at [https://github.com/robrwo/Graphics-ColorNames-Werner](https://github.com/robrwo/Graphics-ColorNames-Werner)
and may be cloned from [git://github.com/robrwo/Graphics-ColorNames-Werner.git](git://github.com/robrwo/Graphics-ColorNames-Werner.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Graphics-ColorNames-Werner/issues](https://github.com/robrwo/Graphics-ColorNames-Werner/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTOR

Slaven Rezić <slaven@rezic.de>

# COPYRIGHT AND LICENSE

Robert Rothenberg has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.
