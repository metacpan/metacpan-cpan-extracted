# NAME

Filesys::Restrict - Restrict filesystem access

# SYNOPSIS

    {
        my $check = Filesys::Restrict::create(
            sub {
                my ($op, $path) = @_;

                return 1 if $path =~ m<^/safe/place/>;

                # Deny access to anything else:
                return 0;
            },
        );

        # In this block, most Perl code will throw if it tries
        # to access anything outside of /safe/place.
    }

    # No more filesystem checks here.

# DESCRIPTION

This module is a reasonable-best-effort at preventing Perl code from
accessing files you don’t want to allow. One potential application of
this is to restrict filesystem access to `/tmp` in tests.

# **THIS** **IS** **NOT** **A** **SECURITY** **TOOL!**

This module cannot prevent all unintended filesystem access.
The following are some known ways to circumvent it:

- Use XS modules (e.g., [POSIX](https://metacpan.org/pod/POSIX)).
- Use one of `open()`’s more esoteric forms.
This module tries to parse typical `open()` arguments but doesn’t
“bend over backward”. The 2- and 3-argument forms are assumed to be
valid if there’s an unrecognized format, and we ignore the 1-argument
form entirely.
- Call `system()`, `do()`, or `require()`.

    We _could_ actually restrict `do()` and `require()`.
    These, though, are a bit different from other built-ins because they
    don’t facilitate reading arbitrary data off the filesystem; rather,
    they’re narrowly-scoped to bringing in additional Perl code.

    If you have a use case where it’s useful to restrict these,
    file a feature request.

# SEE ALSO

[Test::MockFile](https://metacpan.org/pod/Test%3A%3AMockFile) can achieve a similar effect to this module but
has some compatibility problems with some Perl syntax.

Linux’s [fanotify(7)](http://man.he.net/man7/fanotify) provides a method of real-time access control
via the kernel. See [Linux::Fanotify](https://metacpan.org/pod/Linux%3A%3AFanotify) and [Linux::Perl](https://metacpan.org/pod/Linux%3A%3APerl) for Perl
implementations.

# FUNCTIONS

## $obj = create( sub { .. } )

Creates an opaque object that installs an access-control callback.
Any existing access-control callback is saved and restored whenever
$obj is DESTROYed.

The access-control callback is called with two arguments:

- The name of the Perl op that requests filesystem access.
The names come from `PL_op_desc` in Perl’s [opcode.h](https://metacpan.org/pod/opcode.h) header file;
they should correlate to the actual built-in called.
- The filesystem path in question.

The callback can end in one of three ways:

- Return truthy to confirm access to the path.
- Return falsy to cause a [Filesys::Restrict::X::Forbidden](https://metacpan.org/pod/Filesys%3A%3ARestrict%3A%3AX%3A%3AForbidden)
instance to be thrown.
- Throw a custom exception.

# LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

This library is licensed under the same terms as Perl itself.
See [perlartistic](https://metacpan.org/pod/perlartistic).

This library was originally a research project at
[cPanel, L.L.C.](https://cpanel.net).
