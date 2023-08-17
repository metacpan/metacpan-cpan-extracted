# NAME

Import::These -  Terse, Prefixed and Multiple Imports with a Single Statement

# SYNOPSIS

Any item ending with :: is a prefix. Any later items in the list will use the
prefix to create the full package name: 

```perl
#Instead of this:
#
use Plack::Middleware::Session;
use Plack::Middleware::Static;
use Plack::Middleware::Lint;
use IO::Compress::Gzip;
use IO::Compress::Gunzip;
use IO::Compress::Deflate;
use IO::Compress::Inflate;


# Do this
use Import::These qw<
  Plack::Middleware:: Session Static Lint
  IO::Compress::      Gzip GunZip Defalte Inflate
>;
```

Any item exactly equal to  :: clears the prefix:

```perl
use Import::These "Prefix::", "Mod", "::", "Prefix::Another";
# Prefix::Mod
# Prefix::Another;
```

A item beginning with :: and ending with :: appends the item to the prefix:

```perl
use Import::These "Plack::", "Test", "::Middleware::", "Lint";
# Plack::Test,
# Plack::Middleware::Lint;
```

Supports default, named/tagged, and no import:

```perl
# Instead of this:
#
# use File::Spec::Functions;
# use File::Spec::Functions "catfile";
# use File::Spec::Functions ();

# Do This:
#
use Import::These "File::Spec::", Functions, 
                                  Functions=>["catfile"],
                                  Functions=>[]
```

Supports Perl Version as first argument to list

```perl
use Import::These qw<v5.36 Plack:: Test ::Middleware:: Lint>;
# use v5.36;
# Plack::Test,
# Plack::Middleware::Lint;
```

Supports Module Version

```perl
use Import::These qw<File::Spec:: Functions 1.3>;
# use File::Spec::Functions 1.3;
#
use Import::These qw<File::Spec:: Functions 1.3>, ["catfile"];
# use File::Spec::Functions 1.3 "catfile";

```

# DESCRIPTION

A tiny module for importing multiple modules in one statement utilising a
prefix. The prefix can be set, cleared, or appended multiple times in a list,
making long lists of imports much easier to type!

It works with any package providing a `import` subroutine (i.e. compatible
with [Exporter](https://metacpan.org/pod/Exporter). It also is compatible with recursive exporters such as
[Export::These](https://metacpan.org/pod/Export%3A%3AThese) manipulating the export levels.

# USAGE

When using this pragma, the list of arguments are interpreted as either a Perl
version, prefix mutation, module name, module version  or  array ref of symbols
to import. The current value of the prefix is applied to module names as they
appear in the list.

- The prefix always starts out as an empty string.
- The first item in the list is optionally a Perl version 
- Module version optionally comes after a module name (prefixed or not)
- Symbols list optionally comes after a module name or module version if used
- The prefix can be set/cleared/appended as many times as needed 

## Prefix Manipulation

The current prefix is used for all module names as they occur. However, changes
to the prefix can be interleaved within module names.

### Set the Prefix

```
Name::

# Prefix equals "Name::"
```

Any item in the list ending in "::" with result in the prefix being set to item (including the ::)

### Append The Prefix

```
 ::Name::

 # Prefix equals "OLDPREFIX::Name::"

```

Any item in the list starting and ending with "::" will result in the prefix
having the item appended to it. The item has the leading "::" removed before
appending.

### Clear the Prefix

```
::

#Prefix is ""

```

Any item in the list equal to "::" exactly will clear the prefix to an empty
string

# EXAMPLES

The following examples make it easier to see the benefits of using this module:

## Simple Prefix

A single prefix used for  multiple packages:

```perl
use Import::These qw<IO::Compress:: Gzip GunZip Defalte Inflate >;

# Equivalent to:
# use IO::Compress::Gzip
# use IO::Compress::GunZip
# use IO::Compress::Deflate
# use IO::Compress::Inflate
```

## Appending Prefix

Prefix is appended along the way:

```perl
use Import::These qw<IO:: File ::Compress:: Gzip GunZip Defalte Inflate >;

# Equivalent to:
# use IO::File
# use IO::Compress::Gzip
# use IO::Compress::GunZip
# use IO::Compress::Deflate
# use IO::Compress::Inflate
```

## Reset Prefix

Completely change (reset) prefix to something else:

```perl
use Import::These qw<File::Spec Functions :: Compress:: Gzip GunZip Defalte Inflate >;

# Equivalent to: 
# use File::Spec::Functions
# use IO::Compress::Gzip
# use IO::Compress::GunZip
# use IO::Compress::Deflate
# use IO::Compress::Inflate
```

## No Default Import

```perl
use Import::These "File::Spec::", "Functions"=>[];

# Equivalent to:
# use File::Spec::Functions ();

```

## Import Names/groups

```perl
use Import::These "File::Spec::", "Functions"=>["catfile"];

# Equivalent to:
# use File::Spec::Functions ("catfile");
```

## With Perl Version

```perl
use Import::These "v5.36", "File::Spec::", "Functions";

# Equivalent to:
# use v5.36;
# use File::Spec::Functions;
```

## With Module Version

```perl
use Import::These "File::Spec::", "Functions", "v1.2";

# Equivalent to:
# use File::Spec::Functions v1.2;
```

## All Together Now

```perl
use Import::These qw<v5.36 File:: IO ::Spec:: Functions v1.2>, ["catfile"],  qw<:: IO::Compress:: Gzip GunZip Deflate Inflate>;

# Equivalent to:
# use v5.36;
# use File::IO;
# use File::Spec::Functions v1.2 "catfile"
# use IO::Compress::Gzip;
# use IO::Compress::GunZip;
# use IO::Compress::Deflate;
# use IO::Compress::Inflate;
```

# COMPARISON TO OTHER MODULES

[Import::Base](https://metacpan.org/pod/Import%3A%3ABase) Performs can perform multiple imports, however requires a
custom package to group the imports and reexport them. Does not support
prefixes.

[use](https://metacpan.org/pod/use) is very similar however does not support prefixes.

[import](https://metacpan.org/pod/import) works by loading ALL packages under a common prefix. Whether you need
them or not.  That could be a lot of disk access and memory usage.

[modules](https://metacpan.org/pod/modules) has automatic module installation using CPAN. However no
prefix support and uses **a lot** of RAM for basic importing

[Importer](https://metacpan.org/pod/Importer) has some nice features but not a 'simple' package prefix. It also
looks like it only handles a single package per invocation

# REPOSITOTY and BUGS

Please report and feature requests or bugs via the github repo:

[https://github.com/drclaw1394/perl-import-these.git](https://github.com/drclaw1394/perl-import-these.git)

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2023 by Ruben Westerberg

Licensed under MIT

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.
