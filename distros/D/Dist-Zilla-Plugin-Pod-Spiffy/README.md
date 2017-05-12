# NAME

Dist::Zilla::Plugin::Pod::Spiffy - make your documentation look spiffy as HTML

# SYNOPSIS

In your POD:

    =head2 C<my_super_function>

    =for pod_spiffy in no args | out error undef or list|out hashref

    This function takes two arguments, one of them is mandatory. On
    error it returns either undef or an empty list, depending on the
    context. On success, it returns a hashref.

    ...

    =head1 REPOSITORY

    =for pod_spiffy start github section

    Fork this module on https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy

    =for pod_spiffy end github section

    ...

    =head1 AUTHORS

    =for pod_spiffy authors ZOFFIX JOE SHMOE

    =head1 CONTRIBUTORS

    =for pod_spiffy authors SOME CONTRIBUTOR



In your `dist.ini`:

    [Pod::Spiffy]

# DESCRIPTION

This [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugin lets you make your documentation look
spiffy as HTML, by adding meaningful icons. If you're viewing this document
as HTML, you can see available icons below.

The main idea behind this module isn't so much the looks, however, but
the provision of visual hints and clues about various sections of your
documentation, and more importantly the arguments and return values
of the methods/functions.

# HISTORY

I was impressed by [ETHER](http://metacpan.org/author/ETHER)'s work on
[Acme::CPANAuthors::Nonhuman](https://metacpan.org/pod/Acme::CPANAuthors::Nonhuman) (the including author avatars in the docs
part) and appreciated the added value HTML content can bring to
the POD in my [Acme::Dump::And::Dumper](https://metacpan.org/pod/Acme::Dump::And::Dumper).

While working on the implementation of the horribly inconsistent
[WWW::Goodreads](https://github.com/zoffixznet/WWW-Goodreads),
I wanted my users to not have to remember the
type of return values for 74+ methods. That's when I thought up the idea
of including icons to give hints of the return types.

# THEME

The current theme is hardcoded to use
`http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/` However,
since most icons are size-unbound, themeing should be extremely
easy in the future, and configuration option will be provided very soon.

# NOTE ON SCALARS

I realize that hashrefs, subrefs, arrayrefs, and the ilk are all scalars,
but this documentation and the icons by scalars mean the
plain, non-reference types; i.e. strings and numbers (`42`, `"foo"`, etc.)

# IN YOUR POD

To spiffy-up your POD, use the `=for` POD command, followed by
`pod_spiffy`, followed by codes (see [SYNOPSIS](https://metacpan.org/pod/SYNOPSIS) for examples).
For icons, you can specify multiple icon codes separated with a
pipe character (`|`). For example:

    =for pod_spiffy in no args

    =for pod_spiffy in no args | out error undef list

You can have any amount of whitespace between individual
words of the codes (but
you must have at least some whitespace). Whitespace around the
`|` separator is irrelevant.

The following codes are currently available:

## INPUT ARGUMENTS ICONS

These icons provide hints on what your sub/method takes as an argument.

### `in no args`

    =for pod_spiffy in no args

Use this icon to indicate your sub/method does not take any arguments.

### `in scalar`

    =for pod_spiffy in scalar

Use this icon to indicate your sub/method takes a plain
scalar as an argument.

### `in scalar scalar optional`

    =for pod_spiffy in scalar scalar optional

Use this icon to indicate your sub/method takes as arguments one
mandatory and one optional arguments, both of which are plain
scalars.

### `in arrayref`

    =for pod_spiffy in arrayref

Use this icon to indicate your sub/method takes an arrayref as an argument.

### `in hashref`

    =for pod_spiffy in hashref

Use this icon to indicate your sub/method takes an hashref as an argument.

### `in key value`

    =for pod_spiffy in key value

Use this icon to indicate your sub/method takes a list of
key/value pairs as an argument
(e.g. `->method( foo => 'bar', ber => 'biz' );`.

### `in list`

    =for pod_spiffy in list

Use this icon to indicate your sub/method takes a list
of scalars as an argument (e.g. `qw/foo bar baz ber/`)

### `in object`

    =for pod_spiffy in object

Use this icon to indicate your sub/method takes an object as an argument.

### `in scalar optional`

    =for pod_spiffy in scalar optional

Use this icon to indicate your sub/method takes a
single __optional__ argument that is a scalar.

### `in scalar or arrayref`

    =for pod_spiffy in scalar or arrayref

Use this icon to indicate your sub/method takes either
a plain scalar or an arrayref as an argument.

### `in subref`

    =for pod_spiffy in subref

Use this icon to indicate your sub/method takes a subref as an argument.

## OUTPUT ON ERROR ICONS

These icons are to indicate what your sub/method returns if an
error occurs during its execution.

### `out error exception`

    =for pod_spiffy out error exception

Use this icon to indicate your sub/method on error throws an exception.

### `out error undef or list`

    =for pod_spiffy out error undef or list





Use this icon to indicate your sub/method on error returns
either `undef` or an empty list, depending on the context.

### `out error undef`

    =for pod_spiffy out error undef

Use this icon to indicate your sub/method on error returns
`undef` (regardless of the context).

## OUTPUT ICONS

These icons are to indicate what your sub/method returns after
a successful     execution.

### `out scalar`

    =for pod_spiffy out scalar

Use this icon to indicate your sub/method returns a plain scalar.

### `out arrayref`

    =for pod_spiffy out arrayref

Use this icon to indicate your sub/method returns an arrayref.

### `out hashref`

    =for pod_spiffy out hashref

Use this icon to indicate your sub/method returns a hashref.

### `out key value`

    =for pod_spiffy out key value

Use this icon to indicate your sub/method returns a list of
key value pairs (i.e., return is suitable to assign to a hash).

### `out list`

    =for pod_spiffy out list

Use this icon to indicate your sub/method returns a list of
things (i.e., return is suitable to assign to an array).

### `out list or arrayref`

    =for pod_spiffy out list or arrayref

Use this icon to indicate your sub/method returns either a list of
things or an arrayref, depending on the context.

### `out subref`

    =for pod_spiffy out subref

Use this icon to indicate your sub/method returns a subref.

### `out object`

    =for pod_spiffy out object

Use this icon to indicate your sub/method returns a object.

## SECTION ICONS

To use a section icon, you need to indicate both the start of the section
and the end of it, e.g.:

    =for pod_spiffy start github section

    =head3 GITHUB REPO

    Fork this module on github https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy

    =for pod_spiffy end github section

Available icons are:

### Github Repo

    =for pod_spiffy start github section

    Fork this module on GitHub:
    L<https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy>

    =for pod_spiffy end github section

### Authors

    =for pod_spiffy start author section

    Joe Shmoe wrote this module

    =for pod_spiffy end author section

__See also:__ ["CPAN Authors"](#cpan-authors) section below, for a way to include
author avatars.

### Contributors

    =for pod_spiffy start contributors section

        Joe More also contributed to this module

    =for pod_spiffy end contributors section

__See also:__ ["CPAN Authors"](#cpan-authors) section below, for a way to include
author avatars.

### Bugs

    =for pod_spiffy start bugs section

    Report bugs for this module on
    L<https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy/issues>

    =for pod_spiffy end bugs section

### Code

    =for pod_spiffy start code section

        print "Yey\n" for 1..42;

    =for pod_spiffy end code section

I'm unsure of the use for this icon. Originally it was planned to be
used with the SYNOPSIS code. The icon will likely be changed in appearance
and the `code` section might become more versatile, to be used
with all chunks of code.

### Warning

    =for pod_spiffy start warning section

    Warning! If you try this something might explode!

    =for pod_spiffy end warning section

Use this section icon to indicate a warning.

### Experimental

    =for pod_spiffy start experimental section

    This method is still experimental!

    =for pod_spiffy end experimental section

Use this section to hint about the features described being experimental.

## OTHER FEATURES

### CPAN Authors

    =for pod_spiffy author ZOFFIX ETHER MSTROUT

Adds an avatar of the author, and their PAUSE
ID. To use this feature use `authors` code, followed by a
whitespace separated list of PAUSE author IDs, for example:

### Horizontal Rule

    =for pod_spiffy hr

A simple horizontal rule. You can use it, for example, to separate
groups of methods.

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy](https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy/issues](https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy/issues)

If you can't access GitHub, you can email your request
to `bug-Dist-Zilla-Plugin-Pod-Spiffy at rt.cpan.org`

# AUTHOR

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
