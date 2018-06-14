# NAME

Hash::MoreUtils - Provide the stuff missing in Hash::Util

# SYNOPSIS

    use Hash::MoreUtils qw(:all);
    
    my %h = (foo => "bar", FOO => "BAR", true => 1, false => 0);
    my %s = slice \%h, qw(true false); # (true => 1, false => 0)
    my %f = slice_false \%h; # (false => 0)
    my %u = slice_grep { $_ =~ m/^[A-Z]/ }, \%h; # (FOO => "BAR")
    
    my %r = safe_reverse \%h; # (bar => "foo", BAR => "FOO", 0 => "false", 1 => "true")

# DESCRIPTION

Similar to [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils), `Hash::MoreUtils` contains trivial
but commonly-used functionality for hashes. The primary focus for
the moment is providing a common API - speeding up by XS is far
away at the moment.

# FUNCTIONS

## `slice` HASHREF\[, LIST\]

Returns a hash containing the (key, value) pair for every
key in LIST.

If no `LIST` is given, all keys are assumed as `LIST`.

## `slice_def` HASHREF\[, LIST\]

As `slice`, but only includes keys whose values are
defined.

If no `LIST` is given, all keys are assumed as `LIST`.

## `slice_exists` HASHREF\[, LIST\]

As `slice` but only includes keys which exist in the
hashref.

If no `LIST` is given, all keys are assumed as `LIST`.

## `slice_without` HASHREF\[, LIST \]

As `slice` but without any (key/value) pair whose key is
in LIST.

If no `LIST` is given, in opposite to slice an empty list
is assumed, thus nothing will be deleted.

## `slice_missing` HASHREF\[, LIST\]

Returns a HASH containing the (key => undef) pair for every
`LIST` element (as key) that does not exist hashref.

If no `LIST` is given there are obviously no non-existent
keys in `HASHREF` so the returned HASH is empty.

## `slice_notdef` HASHREF\[, LIST\]

Searches for undefined slices with the given `LIST`
elements as keys in the given `HASHREF`.
Returns a `HASHREF` containing the slices (key -> undef)
for every undefined item.

To search for undefined slices `slice_notdef` needs a
`LIST` with items to search for (as keys). If no `LIST`
is given it returns an empty `HASHREF` even when the given
`HASHREF` contains undefined slices.

## `slice_true` HASHREF\[, LIST\]

A special `slice_grep` which returns only those elements
of the hash which's values evaluates to `TRUE`.

If no `LIST` is given, all keys are assumed as `LIST`.

## `slice_false` HASHREF\[, LIST\]

A special `slice_grep` which returns only those elements
of the hash which's values evaluates to `FALSE`.

If no `LIST` is given, all keys are assumed as `LIST`.

## `slice_grep` BLOCK, HASHREF\[, LIST\]

As `slice`, with an arbitrary condition.

If no `LIST` is given, all keys are assumed as `LIST`.

Unlike `grep`, the condition is not given aliases to
elements of anything.  Instead, `%_` is set to the
contents of the hashref, to avoid accidentally
auto-vivifying when checking keys or values.  Also,
'uninitialized' warnings are turned off in the enclosing
scope.

## `slice_map` HASHREF\[, MAP\]

Returns a hash containing the (key, value) pair for every
key in `MAP`.

If no `MAP` is given, all keys of `HASHREF` are assumed mapped to themselves.

## `slice_def_map` HASHREF\[, MAP\]

As `slice_map`, but only includes keys whose values are
defined.

If no `MAP` is given, all keys of `HASHREF` are assumed mapped to themselves.

## `slice_exists_map` HASHREF\[, MAP\]

As `slice_map` but only includes keys which exist in the
hashref.

If no `MAP` is given, all keys of `HASHREF` are assumed mapped to themselves.

## `slice_missing_map` HASHREF\[, MAP\]

As `slice_missing` but checks for missing keys (of `MAP`) and map to the value (of `MAP`) as key in the returned HASH.
The slices of the returned `HASHREF` are always undefined.

If no `MAP` is given, `slice_missing` will be used on `HASHREF` which will return an empty HASH.

## `slice_notdef_map` HASHREF\[, MAP\]

As `slice_notdef` but checks for undefined keys (of `MAP`) and map to the value (of `MAP`) as key in the returned HASH.

If no `MAP` is given, `slice_notdef` will be used on `HASHREF` which will return an empty HASH.

## `slice_true_map` HASHREF\[, MAP\]

As `slice_map`, but only includes pairs whose values are
`TRUE`.

If no `MAP` is given, all keys of `HASHREF` are assumed mapped to themselves.

## `slice_false_map` HASHREF\[, MAP\]

As `slice_map`, but only includes pairs whose values are
`FALSE`.

If no `MAP` is given, all keys of `HASHREF` are assumed mapped to themselves.

## `slice_grep_map` BLOCK, HASHREF\[, MAP\]

As `slice_map`, with an arbitrary condition.

If no `MAP` is given, all keys of `HASHREF` are assumed mapped to themselves.

Unlike `grep`, the condition is not given aliases to
elements of anything.  Instead, `%_` is set to the
contents of the hashref, to avoid accidentally
auto-vivifying when checking keys or values.  Also,
'uninitialized' warnings are turned off in the enclosing
scope.

## `hashsort` \[BLOCK,\] HASHREF

    my @array_of_pairs  = hashsort \%hash;
    my @pairs_by_length = hashsort sub { length($a) <=> length($b) }, \%hash;

Returns the (key, value) pairs of the hash, sorted by some
property of the keys.  By default (if no sort block given), sorts the
keys with `cmp`.

I'm not convinced this is useful yet.  If you can think of
some way it could be more so, please let me know.

## `safe_reverse` \[BLOCK,\] HASHREF

    my %dup_rev = safe_reverse \%hash

    sub croak_dup {
        my ($k, $v, $r) = @_;
        exists( $r->{$v} ) and
          croak "Cannot safe reverse: $v would be mapped to both $k and $r->{$v}";
        $v;
    };
    my %easy_rev = safe_reverse \&croak_dup, \%hash

Returns safely reversed hash (value, key pairs of original hash). If no
`BLOCK` is given, following routine will be used:

    sub merge_dup {
        my ($k, $v, $r) = @_;
        return exists( $r->{$v} )
               ? ( ref($r->{$v}) ? [ @{$r->{$v}}, $k ] : [ $r->{$v}, $k ] )
               : $k;
    };

The `BLOCK` will be called with 3 arguments:

- `key`

    The key from the `( key, value )` pair in the original hash

- `value`

    The value from the `( key, value )` pair in the original hash

- `ref-hash`

    Reference to the reversed hash (read-only)

The `BLOCK` is expected to return the value which will used
for the resulting hash.

# AUTHOR

Hans Dieter Pearcey, `<hdp@cpan.org>`,
Jens Rehsack, `<rehsack@cpan.org>`

# BUGS

Please report any bugs or feature requests to
`bug-hash-moreutils@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-MoreUtils](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-MoreUtils).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::MoreUtils

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-MoreUtils](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-MoreUtils)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Hash-MoreUtils](http://annocpan.org/dist/Hash-MoreUtils)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Hash-MoreUtils](http://cpanratings.perl.org/d/Hash-MoreUtils)

- Search CPAN

    [http://search.cpan.org/dist/Hash-MoreUtils/](http://search.cpan.org/dist/Hash-MoreUtils/)

# ACKNOWLEDGEMENTS

# COPYRIGHT & LICENSE

Copyright 2005 Hans Dieter Pearcey, all rights reserved.
Copyright 2010-2018 Jens Rehsack

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
