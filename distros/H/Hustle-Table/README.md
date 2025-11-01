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
$table->add( { matcher => "regex (match)", value=> "a value"});
```

Add entry as array ref (3 elements required):

```
$table->add( ["another", "another value", undef])
```

Add entry as flat key value pairs:

```perl
    $table->add(matcher=>"jones", value=> sub {"one more"}, type=>"begin");
```

Add entry as tuple

```perl
    $table->add("magic matcher" => "to a value");
    
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

Call dispatcher to return the matching entries and any RegExp captures. Multiple
items can be tested in a single call

```perl
my @pairs=$dispatch->("thing to match", "another thing", ...);        

# @pairs contains pairs of entries and capture arrays

# perl v5.36 
for my($e, $c)(@pairs){
  $e->[1]; # The value 
  $c;      # Possible captures
}
```

# DESCRIPTION

This module provides a class to construct a routing table and build a high
performance dispatcher from it. 

A table can have any combination of RegExp, subroutine, exact string, begin
string, end string or numeric matching of entries. The order in which the
entries are added defines their precedence. First in, first tested.

In the case of no entries matching the input, a default/fallback entry always
matches.

Once all the entries have been added to the table, a dispatcher needs to be
prepared/created. The dispatcher is an anonymous subroutine, which tests its
arguments against the matcher in each entry in the table.

**NOTE:** From v0.7.0 The entries that matched the input are returned along with
an anonymous array of RegExp captures if applicable, as a pair. Multiple pairs
are returned if more than one match. Prior to v0.7.0, testing would stop after
the first match.

If more entries are required to be added to the table, the dispatcher must be
prepared again.

A cache (hash) is used to drastically improve table lookup performance. Entries
are automatically added to the cache. Removal of cache entries is up to the
user to implement on a application basis.

## API Change

**From v0.8.0:** Matchers **MUST** be input as strings or CODE refs only. Regexp
matchers are generated internally from the matcher string. This is aid
searching through the table, for modifications by other packages.  CODE
matchers **MUST** specify the optional type argument as "code";

**From v0.6.0:** Regexp from non core Regexp engines are now usable as a matcher
directly. In previous versions, these where not detected and processed as a
string to be converted into a Perl core Regexp internally.

**In version v0.5.3 and earlier**, the dispatcher would always return a two
element list. The first being the match entry, and the second array ref of any
captures from a RegExp match. If the matcher type was 'begin', 'end', 'exact',
or 'numeric', the second element would always be an reference to an empty
array.

**From v0.5.4 onwards** to optimise performance of non RegExp matching, this is
no longer the case. Only RegExp type matching will generate this second
element.  Other matching types will not. 

In other words when calling the dispatcher:

```perl
my ($entry, $captures)=$dispatcher->($input)
```

The `$captures` variable above now will be `undef` instead of `[]`, for non
RegExp matching

# CREATING A TABLE 

```
Hustle::Table->new(...);
```

Calling the class constructor returns a new table. There are no required
arguments:

```perl
my $table=Hustle::Table->new;
```

In this case, a default catch all entry (an `undef` value) is added
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
[matcher, value, type]
```

- matcher

    `matcher` can be a RegExp (as source string), a subroutine, a string or a
    numeric value.

    When `matcher` treated as a RegExp, any captures are returned as the second
    item of the pair when calling the dispatcher

    When `matcher` is a subroutine,  it is called with input to test and a
    reference to the `value` field in the entry as the two arguments. If it
    returns a true value it matches. 

    When  `matcher` is string or numeric value, the last field `type` specifies
    how to perform the match. See `type` below.

    If no `type` is specified or is `undef`, the `matcher` is always treated as
    a RegExp.  **From v0.8.0:** If treated as a RegExp, the `type` field is
    replaced with the compiled RexExp.

- value

    This is the data you want to retrieve from the table when entry matches the
    input.

- type

    `type` is used to adjust how the matcher is interpreted. The possible values
    are:

    ```perl
    undef   =>    matcher treated as a RegExp source stirng. 

    "code"  =>  uses code refernce to match argument

    "begin"       =>      matcher string matches the begining of input string 

    "end"   =>  matcher string matches the end of input string 

    "exact"       =>      matcher string matches string equality 

    "numeric" =>  matcher number matches numeric equality
    ```

## Adding

```
$table->add(...);
```

Entries are added in anonymous hash, anonymous array or flattened format, using
the `add` method.

Anonymous array entries must contain 3 elements, in the order of:

```
$table->add([$matcher, $value, $type]);
```

Anonymous hashes format only need to specify the matcher and value pairs:

```perl
$table->add({matcher=>$matcher, value=>$value, type=>$type});
```

Single flattened format takes a list directly. It must contain 4 elements, and
will be treated as a RegExp match:

```perl
$table->add(matcher=>$matcher, value=> $value);
```

Single simple format takes two elements and will be treated as RegExp match:

```perl
$table->add("some matcher"=>$value);
```

Or add multiple at once using mixed formats together

```perl
$table->add( [$matcher, $value, $type], {matcher=> $matcher, value=>$value},
matcher=>$matcher, value=>$value);
```

In any case,`matcher` and `value` are the only items which must be defined
for subroutine and RegExp matchers. String, numeric and code matching will need
the `type` also specified.

## Default Matcher

```
$table->set_default($value)
```

Each list has a default matcher that will unconditionally match the input. It
is always in the table and **is only tested when no other matcher matched**

If the default matcher matches it will return `$value` on matching and an
empty capture array.

## Manipulating Table Entries

There are no explicit manipulation methods. The table is just an array and it
can be accessed like an any other array e.g. accessing elements, `splice`,
`shift`, `unshift`, `pop`, `push`.

Just keep in mind the last item in the table is always the default matcher.

After entires have been modified the dispatcher must be prepared again

# PREPARING A DISPATCHER

```perl
my $dispatcher=$table->prepare_dispatcher(%args);
```

Once all the entries are added to the table, the dispatcher can be constructed
by calling `prepare_dispatcher`:

Arguments to this method include:

- cache

    The hash ref to use as the dispatchers cache. Specifying a hash allows external
    management. If no cache is specified an internal cache is used.

When a dispatcher is prepared, the cache is emptied, any RegExp matchers are
compiled and the table is forced to always have at least one entry (the default
matcher).

# USING A DISPATCHER

```perl
my @pairs=$dispatcher->("input");

# perl v5.36 
for my($e, $c)(@pairs){
  $e->[1]; # The value 
  $c;      # Possible captures
}
```

The dispatcher is simply a sub, which you call with the input to match against
the table entries:

The returned list are pairs of entries and captures

The first pair item is the array reference to the table entry that matched (or
the default entry if no match was found). The value associated with the table
entry is located in position 1

The second pair item is an anonymous array of any captures due to a matching
RegExp, or `undef` otherwise

**NOTE In version 0.5.3 and earlier:** the second element was returned as a ref
to an empty array even if the matcher was not a RegExp.

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

# REPOSITORTY and BUGS

Please report any bugs via git hub: [http://github.com/drclaw1394/perl5-hustle-table](http://github.com/drclaw1394/perl5-hustle-table)

# COPYRIGHT AND LICENSE

Copyright (C) 2025 by Ruben Westerberg

Licensed under MIT

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.
