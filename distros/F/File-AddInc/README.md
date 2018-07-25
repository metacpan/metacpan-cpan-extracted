[![Build Status](https://travis-ci.org/hkoba/p5-File-AddInc.svg?branch=master)](https://travis-ci.org/hkoba/p5-File-AddInc) [![MetaCPAN Release](https://badge.fury.io/pl/File-AddInc.svg)](https://metacpan.org/release/File-AddInc)
# NAME

File::AddInc - FindBin(+ use lib) alike for \*.pm modulino (instead of \*.pl)

# SYNOPSIS

In file `MyApp/Deep/Runnable/Module.pm`:

    #!/usr/bin/env perl
    package MyApp::Deep::Runnable::Module;

    # use MyApp::Util; # This may fail because @INC can be wrong in many ways.

    # So, use this to modify @INC.
    use File::AddInc;

    # Then perl can find MyApp/Util.pm correctly.
    use MyApp::Util;

    ...

Suppose you have a module like above
and want to make it runnable and symlink it from your `~/bin`
(Yes, I'm sane;-).
In the module, you want to use some other module (`MyApp/Util.pm`)
in the same library tree.
File::AddInc will locate your lib directory and modify @INC for you.

# DESCRIPTION

File::AddInc is a `@INC` tuner for
[Modulino](http://www.drdobbs.com/scripts-as-modules/184416165).

It does similar task of [FindBin](https://metacpan.org/pod/FindBin) + [lib](https://metacpan.org/pod/lib), but for Modules (`*.pm`)
instead of standalone scripts (`*.pl`).

Conceptually, this module locates root of `lib` directory
through following steps.

1. Inspect `__FILE__` (using [caller()](https://metacpan.org/pod/perlfunc#caller)).
2. Resolve symbolic links.
3. Trim `__PACKAGE__` part from it.

Then adds it to `@INC`.

# CLASS METHODS

## `libdir($PACKNAME, $FILEPATH)`


Trims `$PACKNAME` portion from `$FILEPATH`.
When arguments are omitted, results from [caller()](https://metacpan.org/pod/perlfunc#caller) is used.

    my $libdir = File::AddInc->libdir('MyApp::Foobar', "/somewhere/lib/MyApp/Foobar.pm");
    # $libdir == "/somewhere/lib"

    my $libdir = File::AddInc->libdir(caller);

    my $libdir = File::AddInc->libdir;

## Note for MOP4Import users

This module does \*NOT\* rely on [MOP4Import::Declare](https://metacpan.org/pod/MOP4Import::Declare)
but designed to work well with it. Actually,
this module provides `declare_file_inc` method.
So, you can inherit 'File::AddInc' to reuse this pragma.

    package MyExporter;
    use MOP4Import::Declare -as_base, [parent => 'File::AddInc'];

Then you can use `-file_inc` pragma like following:

    use MyExporter -file_inc;

# CAVEATS

Since this module compares `__FILE__` with `__PACKAGE__` in case
sensitive manner, it may not work well with modules which relies case
insensitive filesystems.

# SEE ALSO

[FindBin](https://metacpan.org/pod/FindBin), [lib](https://metacpan.org/pod/lib), [rlib](https://metacpan.org/pod/rlib), [blib](https://metacpan.org/pod/blib)

# LICENSE

Copyright (C) Kobayasi, Hiroaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kobayasi, Hiroaki <buribullet@gmail.com>
