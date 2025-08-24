# Debug::Comments

[![CPAN version](https://badge.fury.io/pl/Debug-Comments.svg)](https://metacpan.org/pod/Debug::Comments)
[![License](https://img.shields.io/cpan/l/Debug-Comments)](https://metacpan.org/pod/Debug::Comments)

Perl source filter which turns comments into debug messages

This module is a minimalist Perl source filter which converts
designated comments into debug trace messages printed via warn().  The
behaviour is normally activated by an environment variable (e.g.
"DEBUG") in a "use if" pragma.  In the absence of the source filter,
the comments are just comments, so using the module does not create a
dependency on it except to the extent you want to run it with debug
output.

## Synopsis

```perl
use if $ENV{DEBUG}, 'Debug::Comments';
#@! This is a debug message. DEBUG=$ENV{DEBUG}
```

## Key Features

- **No cost when disabled** - Without the filter, debug messages are just comments
- **Trace info** - Messages have a standard time/file/line prefix
- **ANSI color** - Prefix is visually distinct if STDERR is a TTY (unless disabled)
- **Configurable** - Env vars for controlling output

## Installation

```bash
cpanm Debug::Comments
```

## Requirements

- Perl 5.10+
- Filter::Util::Call

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## Author

Brett Watson

## See Also

- [Smart::Comments](https://metacpan.org/pod/Smart::Comments) - Feature-rich alternative by Damian Conway
- [Debug::Filter::PrintExpr](https://metacpan.org/pod/Debug::Filter::PrintExpr) - Alternative with a focus on data dumping
