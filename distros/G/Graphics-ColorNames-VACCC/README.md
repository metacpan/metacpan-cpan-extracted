# NAME

Graphics::ColorNames::VACCC - VisiBone Anglo-Centric Color Codes

# VERSION

version 1.03

# SYNOPSIS

```
require Graphics::ColorNames::VACCC;

$NameTable = Graphics::ColorNames::VACCC->NamesRgbTable();
$RgbColor  = $NameTable->{paledullred};
```

# DESCRIPTION

This module defines color names and their associated RGB values for
the VisiBone Anglo-Centric Color Code.  This is intended for use with
the [Graphics::ColorNames](https://metacpan.org/pod/Graphics%3A%3AColorNames) package.

# SEE ALSO

A description of this color scheme can be found at
[http://www.visibone.com/vaccc/](http://www.visibone.com/vaccc/).

# SOURCE

The development version is on github at [https://github.com/robrwo/Graphics-ColorNames-VACCC](https://github.com/robrwo/Graphics-ColorNames-VACCC)
and may be cloned from [git://github.com/robrwo/Graphics-ColorNames-VACCC.git](git://github.com/robrwo/Graphics-ColorNames-VACCC.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Graphics-ColorNames-VACCC/issues](https://github.com/robrwo/Graphics-ColorNames-VACCC/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTOR

Spoon Reloaded <spoon.reloaded@gmail.com>

## Acknowledgements

A while back I had received a request from somebody to implement this
as part of the [Graphics::ColorNames](https://metacpan.org/pod/Graphics%3A%3AColorNames) distribution.  The request
included source code for the module.  I had suggested to this person
that they upload a separate module to CPAN, but heard no reply.

Afterwards I had lost the original E-mail.

This version of the module was implemented separately.

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2004,2022 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
