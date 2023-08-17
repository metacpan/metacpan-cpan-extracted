# NAME

Hustle::Table - Cached general purpose dispatch and routing table

# SYNOPSIS

```perl
use Hustle::Table;
```

Create a new table:

```perl
my $table=Hustle::Table->new;
```

Add entry as hash ref:

```perl
$table->add( { matcher => qr/regex (match)/, value=> "a value"});
```

Add entry as array ref (3 elements required):

```
$table->add( [qr/another/, "another value", undef])
```

Add entry as flat key value pairs:

```perl
    $table->add(matcher=>"jones", value=> sub {"one more"}, type=>"begin");
```

Add entry as tuple

```perl
    $table->add(qr|magic matcher| => "to a value");
    
```

Set the default entry:

```
    $table->set_default("default value");
```

Prepare a dispatcher external cache:

```perl
    my %cache;
    my $dispatch = $table->prepare_dispatcher(cache=>\%cache);
```

Call dispatcher to return the matching entry and any regex captures

```perl
my ($entry, $captures)=$dispatch->("thing to match"); 
```

# DESCRIPTION

This module provides a class to construct a routing table and build a high
performance dispatcher from it. 

A table can have any combination of regex, subroutine, exact string, begin
string end string or numeric matching of entries. The order in which the
entries are added defines their precedence. First in, first tested.

In the case of no entries matching the input, a default/fallback entry always
matches.

Once all the entries have been added to the table, a dispatcher is
prepared/created. The dispatcher is an anonymous subroutine, which tests its
argument against the matcher in each entry in the table.

It returns a list containing the first entry that matched, and if applicable,
an anonymous array of any captures from regex matching.

If more entries are required to be added to the table, the dispatcher must be
prepared again.

A cache (hash) is used to drastically improve table lookup performance. Entries
are automatically added to the cache. A cache hit with a regex matcher will re
execute the regexp to ensure the captures are returned as expected. Removal of
cache entries is up to the user to implement on a application basis.

## API Change

**From v0.6.0:** Regexp from non core Regexp engines are now usable as a matcher
directly. In previous versions, these where not detected and processed as a
string to be converted into a Perl core Regexp internally.

**In version v0.5.3 and earlier**, the dispatcher would always return a two
element list. The first being the match entry, and the second array ref of any
captures from a regexp match. If the matcher type was 'begin', 'end', 'exact',
or 'numeric', the second element would always be an reference to an empty
array.

**From v0.5.4 onwards** to optimise performance of non regex matching, this is
no longer the case. Only regex type matching will generate this second element.
Other matching types will not. 

In other words when calling the dispatcher:

```perl
            my ($entry, $captures)=$dispatcher->($input)
```

The `$captures` variable above now will be `undef` instead of `[]`, for non
regex matching

# CREATING A TABLE

Calling the class constructor returns a new table. There are no required
arguments:

```perl
    my $table=Hustle::Table->new;
```

In this case, a default catch all entry (an undef value) is added
automatically.

If an argument is provided, it is the value used in the default/catch all
entry:

```perl
    my $table=Hustle::Table->new($default);
```

# ENTRIES

## Structure

An entry is an anonymous array containing the following elements:

```
    [matcher, value, type, default]
```

- matcher

    `matcher` can be a regex, a subroutine, a string or a numeric value.

    When `matcher` is a regex, any captures are returned as the second item when
    calling the dispatcher

    When `matcher` is a subroutine,  it is called with input to test and a
    reference to the `value` field in the entry as the two arguments. If it
    returns a true value it matches. 

    When  `matcher` is string or numeric value, the last field `type` specifies
    how to perform the match. See `type` below.

    If no `type` is specified or is `undef`, the `matcher` is always treated as
    a regex

- value

    This is the data you want to retrieve from the table when the matches.

- type

    `type` is used to adjust how the matcher is interpreted. The possible values
    are:

    ```perl
        undef   =>      matcher treated as a regex or subroutine if possible
                        forces basic scalars to become a regexp

        "begin" =>      matcher string matches the begining of input string
        "end"   =>      matcher string matches the end of input string
        "exact" =>      matcher string matches string equality
        "numeric" =>    matcher number matches numeric equality
    ```

    If `matcher` is a precompiled regex (i.e. `qr{}`), or a subroutine (i.e. CODE
    reference), `type` is ignored. 

    If `matcher` is a string or number, it is treated as a regex unless `type` is
    as above.

- default

    This is a flag indicating if the entry was the default entry. This can not be
    set

## Adding

Entries are added in anonymous hash, anonymous array or flattened format, using
the `add` method.

Anonymous array entries must contain 3 elements, in the order of:

```
    $table->add([$matcher, $value, $type]);
```

Anonymous hashes format only need to specify the matcher and value pairs

```perl
    $table->add({matcher=>$matcher, value=>$value, type=>$type});
```

Single flattened format takes a list directly. It must contain 4 elements

```perl
    $table->add(matcher=>$matcher, value=> $value);
```

Single simple format takes two elements

```perl
    $table->add(qr{some matcher}=>$value);
```

Or add multiple at once using mixed formats together

```perl
    $table->add(
            [$matcher, $value, $type],
            {matcher=> $matcher, value=>$value},
            matcher=>$matcher, value=>$value
    );
```

In any case,`matcher` and `value` are the only items which must be defined
for subroutine and regex matchers. String matching will need the `type` also
specified.

## Default Matcher

Each list has a default matcher that will unconditionally match the input. This
entry is specified by using `undef` as the matcher when adding an entry. 

To make it more explicit, the it can also be changed via the `set_default`
method. 

The default `value` of the 'default' entry is undef

# PREPARING A DISPATCHER

Once all the entries are added to the table, the dispatcher can be
constructed by calling `prepare_dispatcher`:

```perl
    my $dispatcher=$table->prepare_dispatcher(%args);
```

Arguments to this method include:

- cache

    The hash ref to use as the dispatchers cache. Specifying a hash allows external
    management. If no cache is specified an internal cache is used.

# USING A DISPATCHER

The dispatcher is simply a sub, which you call with the input to match against
the table entries:

```perl
    my ($entry, $captures)=$dispatcher->("input");
    my $value=$entry->[1];
```

The return from the dispatcher is a list of up to two elements.

The first is the array reference to the table entry that matched (or the
default entry if no match was found). The value associated with the table entry
is located in position 1

The second item, if present, is an anonymous array of any captures due to a
matching regex.

**NOTE In version 0.5.3 and earlier:** the second element was returned as a ref
to an empty array even if the matcher was not a regex.

# COMPARISON TO OTHER MODULES

Solid performance compared to other Perl routing/dispatch modules. Faster in
basic tests then other Perl modules: 

[Smart::Dispatch](https://metacpan.org/pod/Smart%3A%3ADispatch)
[Router::Simple](https://metacpan.org/pod/Router%3A%3ASimple)
[Router::Boom](https://metacpan.org/pod/Router%3A%3ABoom)

If you need even more performance then checkout [URI::Router](https://metacpan.org/pod/URI%3A%3ARouter)

TODO: make proper benchmark and comparison

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2022 by Ruben Westerberg

Licensed under MIT

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.
