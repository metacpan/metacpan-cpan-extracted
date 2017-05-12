# NAME

Devel::CheckCompiler - Check the compiler's availability

# SYNOPSIS

    use Devel::CheckCompiler;

    check_c99_or_exit();

# DESCRIPTION

Devel::CheckCompiler is checker for compiler's availability.

# FUNCTIONS

- `check_c99()`

    Returns true if the current system has a working C99 compiler, false otherwise.

- `check_c99_or_exit()`

    Check the current system has a working C99 compiler, if it's not available, exit by 0.

- `check_compile($src: Str, %options)`

    Compile `$src` as C code. Return 1 if it's available, 0 otherwise.

    Possible options are:

    - executable :Bool = false

        Check to see if generating executable is possible if this parameter is true.

    - extra\_linker\_flags : Str | ArrayRef\[Str\]

        Any additional flags you wish to pass to the linker. This option is used
        only when `executable` option specified.

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

[ExtUtils::CBuilder](https://metacpan.org/pod/ExtUtils::CBuilder)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
