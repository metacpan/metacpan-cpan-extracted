# Font::Selector

select the right font

# Synopsis

```perl
use Font::Selector qw/grep_from_fontnames/;

my @@suitable = grep_from_fontnames( $string, 'Courier New', 'Noto Sans');
```

# Description

This Perl module gives tools to select the most applicable font when used in
rendering situations.

## grep_from_fontnames

```perl
my @@suitable = grep_from_fontnames( $string, 'Courier New', 'Noto Sans');
```

For a given string, this will grep all the fonts from the given font-names list,
that are suitable for rendereing the string, that is, contains all the glyphs.

# Disclaimer

For more information, always check the pod, using `perldoc`. This is just a ...
well, a README, and only documents the module as it initially was conceived.
Things may have turned out a bit differently. And this file may or may not been
updated accordingly.

# LICENSE INFORMATION

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided “as is” and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.
