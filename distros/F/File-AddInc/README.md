[![Build Status](https://travis-ci.org/hkoba/p5-File-AddInc.svg?branch=master)](https://travis-ci.org/hkoba/p5-File-AddInc) [![MetaCPAN Release](https://badge.fury.io/pl/File-AddInc.svg)](https://metacpan.org/release/File-AddInc)
# NAME

File::AddInc - a reliable shorthand of `use lib dirname($FindBin::Bin)` for Modulino

# SYNOPSIS

Assume you have a Modulino at `$DIR/lib/MyApp.pm`,
and you want to use `$DIR/lib/MyApp/Util.pm` from it. Then:

    #!/usr/bin/env perl
    package MyApp;

    # This manipulates @INC for you!
    use File::AddInc;

    # So perl can find MyApp/Util.pm from the same module tree correctly.
    use MyApp::Util;

    ...

You can use `File::AddInc` to add `$DIR/lib` to `@INC`.

# DESCRIPTION

File::AddInc manipulates `@INC` for Modulino (a module which is also runnable as a command). If you don't know much about the usefulness of Modulino, See these fine articles
[\[1\]](http://www.drdobbs.com/scripts-as-modules/184416165) [\[2\]](https://perlmaven.com/modulino-both-script-and-module).

Unfortunately, there is an annoying complexity to write Modulino: `@INC` manipulation.
Generally, it is responsible for top-level scripts (`*.pl`, `*.psgi`)
to manipulate `@INC` to be able to load all modules correctly.
But in programming with Modulino, the Modulino itself is the top-level.
To run such Modulino, you must give `-Mlib` to perl like below:

    perl -Mlib=$PWD ModX.pm ...

Above is disappointingly long, especially for Perl newbies.
Instead, imagine if it can be called as a command file like `./ModX.pm`, like the following:

    ./ModX.pm ...

With the above, they can use shell's filename completion and can run
it less than a second. To achieve above, you usually need to add
following `BEGIN {}` block to every Modulinos. (Note. You may want to
name your Modulino like `ModX::SomeCategory::SomeFunc`):

    package ModX;
    ...
    BEGIN {
      my ($pack) = __PACKAGE__;
      my $libdir = $FindBin::RealBin;
      my $depth = (split "::", $pack) - 1;
      $libdir = dirname($libdir) while --$depth >= 0;
      require lib;
      lib->import($libdir);
    }

With File::AddInc, you can replace the above block with one line:

    use File::AddInc;

Conceptually, this module locates the root of `lib` directory
through the following steps.

1. Inspect `__FILE__` (using [caller()](https://metacpan.org/pod/perlfunc#caller)).
2. Resolve symbolic links.
3. Trim `__PACKAGE__` part from it.

Then adds it to `@INC`.

Also, File::AddInc can be used to find the library's root directory reliably.
FindBin is enough to manipulate `@INC` but not work well to locate
something other than `use`-ed Perl modules.
For example, assume you have a Modulino `$DIR/lib/ModY.pm`,
and it uses some assets under `$DIR/assets`.
You may write `ModY` with `FindBin` like following:

    package ModY;
    ...
    use lib (my $app_dir = dirname(FindBin::RealBin));

    our $assets_dir = "$app_dir/assets";

Unfortunately, the above code doesn't work as expected, because
FindBin relies on `$0` and varies what top-level program uses this `ModY`.
In such a case, we should use `__FILE__` instead of `$0`.

    package ModY;
    ...
    use lib (my $app_dir = dirname(File::Spec->rel2abs(__FILE__)));

    our $assets_dir = "$app_dir/assets";

Unfortunately again, this won't work if `ModY.pm` is symlinked to somewhere.
With File::AddInc, you can rewrite it and can handle symlinks correctly:

    package ModY;
    ...
    use File::AddInc;
    my $app_dir = dirname(File::AddInc->libdir);

    our $assets_dir = "$app_dir/assets";

# SUB-PRAGMAS

If you give some arguments to this module, it will treat them as _subpragma_s.
This module invokes corresponding class methods for each subpragmas
as the specified order. You can specify any number of subpragmas.
If you give no subpragmas, a subpragma `-file_inc` is assumed.
There are three forms of subpragmas in this module. That is
`-PRAGMA`, `[PRAGMA => @ARGS]` and `qw($var)`.

For example, following code:

    use File::AddInc -file_inc
     , [libdir_var => qw($libdir)]
     , qw($libdir2);

is a shorthand of below:

    BEGIN {
      require File::AddInc;

      my $opts = File::AddInc->Opts->new(caller => [caller]);

      File::AddInc->declare_file_inc($opts);

      File::AddInc->declare_libdir_var($opts, qw($libdir));

      File::AddInc->declare_libdir_var($opts, qw($libdir2));
    }

## `-file_inc`

This finds libdir from caller and add it to `@INC` by ["add\_inc\_if\_necessary"](#add_inc_if_necessary).
This is the default behavior of this module. In other words,

    use File::AddInc;

is a shorthand form of below:

    use File::AddInc -file_inc;

## `-local_lib`

This also adds `$DIR/local/lib/perl5` to `@INC` (assumes your module is under `$DIR/lib`). This subpragma is now implemented in ["these\_libdirs"](#these_libdirs) subpragma.
In other words,

    use File::AddInc -local_lib;

is a shorthand form of below:

    use File::AddInc [these_libdirs => '', [dirname => "local/lib/perl5"]];

## `qw($var)`


This finds libdir from caller and set it to given scalar variable.
This subpragma is now implemented in ["libdir\_var"](#libdir_var) subpragma.
In other words,

    use File::AddInc qw($foo);

is a shorthand form of below:

    use File::AddInc [libdir_var => qw($foo)];

## `[libdir_var => qw($libdir)]`


This finds libdir from caller and set it to given scalar variable.

    use File::AddInc [libdir_var => qw($foo)];

is an equivalent of the folloing:

    use File::AddInc ();
    our $foo; BEGIN { $foo = File::AddInc->libdir };

## `[these_libdirs => @dirSpec]`


This finds libdir from caller, generate a list of directories from given `@dirSpec` and prepend them to `@INC` by ["add\_inc\_if\_necessary"](#add_inc_if_necessary).

For example, following code:

    use File::AddInc [these_libdirs => 'etc', '', [dirname => "local/lib/perl5"]];

adds `$libdir/etc`, `$libdir` and `dirname($libdir)."/local/lib/perl5")` to `@INC`.

Each item of `@dirSpec` can be one of following two forms:

- STRING

    In this case, `$libdir."/STRING"` will be added.

- \[dirname => STRING\]


    In this case, `dirname($libdir)."/STRING"` will be added.

# CLASS METHODS

## `->libdir($PACKNAME, $FILEPATH)`


Trims `$PACKNAME` portion from `$FILEPATH`.
When arguments are omitted, results from [caller()](https://metacpan.org/pod/perlfunc#caller) is used.

    my $libdir = File::AddInc->libdir('MyApp::Foobar', "/somewhere/lib/MyApp/Foobar.pm");
    # $libdir == "/somewhere/lib"

    my $libdir = File::AddInc->libdir(caller);

    my $libdir = File::AddInc->libdir;

## `->add_inc_if_necessary(@libdir)`


This method prepends `@libdir` to `@INC` unless it is already listed in there.
Note: this comparison is done through exact match.

# MISC

## How to inherit and extend

You can inherit this module to implement custom `@INC` modifier.
For example, you can write your own exporter to invoke
`declare_these_libdirs` to give traditional pragma usage like following:

    use MyExporter 'etc', '', 'perl5';

Such `MyExporter.pm` could be written like folloing:

    package MyExporter;
    use strict;
    use warnings;
    use parent qw/File::AddInc/;
    
    sub import {
      my ($pack, @args) = @_;
    
      my $opts = $pack->Opts->new(caller => [caller]);
    
      $pack->declare_these_libdirs($opts, @args);
    }
    
    1;

## Note for MOP4Import users

This module does \*NOT\* rely on [MOP4Import::Declare](https://metacpan.org/pod/MOP4Import%3A%3ADeclare)
but designed to work well with it. Actually,
this module provides `declare_file_inc` method.
So, you can inherit 'File::AddInc' to reuse this pragma.

    package MyExporter;
    use MOP4Import::Declare -as_base, [parent => 'File::AddInc'];

Then you can use `-file_inc` pragma like following:

    use MyExporter -file_inc;

# CAVEATS

Since this module compares `__FILE__` with `__PACKAGE__` in a case
sensitive manner, it may not work well with modules which rely on case
insensitive filesystems.

# SEE ALSO

[FindBin](https://metacpan.org/pod/FindBin), [lib](https://metacpan.org/pod/lib), [rlib](https://metacpan.org/pod/rlib), [blib](https://metacpan.org/pod/blib)

# LICENSE

Copyright (C) Kobayasi, Hiroaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kobayasi, Hiroaki <buribullet@gmail.com>
