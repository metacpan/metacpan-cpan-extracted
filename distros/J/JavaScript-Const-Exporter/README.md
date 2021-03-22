# NAME

JavaScript::Const::Exporter - Convert exported Perl constants to JavaScript

# VERSION

version v0.1.6

# SYNOPSIS

Support a project has a module that defines constants for export:

```perl
package MyApp::Const;

use Exporter qw/ import /;

our @EXPORT_OK = qw/ A B /;

use constant A => 123;
use constant B => "Hello";
```

Then you can export these constants to JavaScript for use with a
web-application's front-end:

```perl
use JavaScript::Const::Exporter;

my $exporter = JavaScript::Const::Exporter->new(
    module    => 'MyApp::Const',
    constants => [qw/ A B /],
);

my $js = $exporter->process
```

This will return a string with the JavaScript code:

```
const A = 123;
const B = "Hello";
```

# DESCRIPTION

This module allows you to extract a list of exported constants from a
Perl module and generate JavaScript that can be included in a web
application, thus allowing you to share constants between Perl and
JavaScript.

# ATTRIBUTES

## use\_var

When true, these will be defined as "var" variables instead of "const"
values.

## module

This is the (required) name of the Perl module to include.

## constants

This is an array reference of symbols or export tags in the
["module"](#module)'s namespace to export.

If it is omitted (not recommened), then it will look at the modules
`@EXPORT_OK` list an export all modules.

Any subroutine can be included, however if the subroutine is not not a
coderef constant, e.g. created by [constant](https://metacpan.org/pod/constant), then it will emit a
warning.

You must include sigils of constants. However, the exported JavaScript
will omit them, e.g. `$NAME` will export JavaScript that specifies a
constant called `NAME`.

## has\_constants

True if there are ["constants"](#constants).

## include

This is an array reference of paths to add to your `@INC`, when the
["module"](#module) is not in the default path.

## has\_include

True if there are included paths.

## pretty

When true, pretty-print any arrays or objects.

## stash

This is a [Package::Stash](https://metacpan.org/pod/Package::Stash) for the namespace. This is intended for
internal use.

## tags

This is the content of the module's `%EXPORT_TAGS`. This is intended
for internal use.

## json

This is the JSON encoder. This is intended for internal use.

# METHODS

## process

This method attempts to retrieve the symbols from the module and
generate the JavaScript.

On success, it will return a string containing the JavaScript.

# KNOWN ISSUES

## Support for older Perl versions

This module requires Perl v5.10 or newer.

Pull requests to support older versions of Perl are welcome. See
["SOURCE"](#source).

## Const::Fast::Exporter

When using with [Const::Fast::Exporter](https://metacpan.org/pod/Const::Fast::Exporter)-based modules, you must
explicitly list all of the constants to be exported, as that doesn't
provide an `@EXPORT_OK` variable that can be queried.

## Const::Exporter

Exporting constant subs from [Const::Exporter](https://metacpan.org/pod/Const::Exporter) v1.0.0 or earlier will
emit warnings about the subs not being constant subs. The issue has
been fixed in v1.1.0.

# SEE ALSO

[Const::Exporter](https://metacpan.org/pod/Const::Exporter)

# SOURCE

The development version is on github at [https://github.com/robrwo/JavaScript-Const-Exporter](https://github.com/robrwo/JavaScript-Const-Exporter)
and may be cloned from [git://github.com/robrwo/JavaScript-Const-Exporter.git](git://github.com/robrwo/JavaScript-Const-Exporter.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/JavaScript-Const-Exporter/issues](https://github.com/robrwo/JavaScript-Const-Exporter/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2021 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
