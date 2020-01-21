# Font::Fontconfig

List, search or match fonts, managed by fontconfig

# Synopsis

```perl
use Font::Fontconfig;

my @font_patterns = Font::Fontconfig->list('Noteworthy');

warn "Can't use font for printing"
    unless $font_patterns[0]->contains_codepoint( ord $char );
```

# Description

This Perl module provides much of the functionality that `fontconfig` gives.

The class methods will generate 1 or a list of `Font::Fontconfig::Pattern`
objects. These object have their own instance methods.

## list

```perl
my @font_patterns = Font::Fontconfig->list($name);
```
or
```perl
my @installed = Font::Fontconfig->list( )
```
Lists fonts that match the name, or all installed if non given

## LICENSE INFORMATION

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
