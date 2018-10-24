# NAME

Graphics::ColorNames::HTML - HTML color names and equivalent RGB values

# VERSION

version v3.3.1

# SYNOPSIS

```
require Graphics::ColorNames::HTML;

$NameTable = Graphics::ColorNames::HTML->NamesRgbTable();
$RgbBlack  = $NameTable->{black};
```

# DESCRIPTION

This module defines color names and their associated RGB values from the
HTML 4.0 Specification.

This module is deprecated.You should use [Graphics::ColorNames::WWW](https://metacpan.org/pod/Graphics::ColorNames::WWW)
instead.

# KNOWN ISSUES

In versions prior to 1.1, "fuchsia" was misspelled "fuscia". This
mispelling came from un unidentified HTML specification.  It also
appears to be a common misspelling, so rather than change it, the
proper spelling was added.

# SEE ALSO

[Graphics::ColorNames](https://metacpan.org/pod/Graphics::ColorNames)

# SOURCE

The development version is on github at [https://github.com/robrwo/Graphics-ColorNames-HTML](https://github.com/robrwo/Graphics-ColorNames-HTML)
and may be cloned from [git://github.com/robrwo/Graphics-ColorNames-HTML.git](git://github.com/robrwo/Graphics-ColorNames-HTML.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Graphics-ColorNames-HTML/issues](https://github.com/robrwo/Graphics-ColorNames-HTML/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

Robert Rothenberg has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.
