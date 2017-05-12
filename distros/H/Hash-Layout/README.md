## NAME

Hash::Layout - hashes with predefined levels, composite keys and default values

## SYNOPSIS

    use Hash::Layout;
    
    # Create new Hash::Layout object with 3 levels and unique delimiters:
    my $HL = Hash::Layout->new({
     levels => [
       { delimiter => ':' },
       { delimiter => '/' }, 
       {}, # <-- last level never has a delimiter
     ]
    });
    
    # load using actual hash structure:
    $HL->load({
      '*' => {
        '*' => {
          foo_rule => 'always deny',
          blah     => 'thing'
        },
        NewYork => {
          foo_rule => 'prompt'
        }
      }
    });
    
    # load using composite keys:
    $HL->load({
      'Office:NewYork/foo_rule' => 'allow',
      'Store:*/foo_rule'        => 'other',
      'Store:London/blah'       => 'purple'
    });
    
    # load composite keys w/o values (uses default_value):
    $HL->load(qw/baz:bool_key flag01/);
    
    # get a copy of the hash data:
    my $hash = $HL->Data;
    
    #  $hash now contains:
    #
    #    {
    #      "*" => {
    #        "*" => {
    #          blah => "thing",
    #          flag01 => 1,
    #          foo_rule => "always deny"
    #        },
    #        NewYork => {
    #          foo_rule => "prompt"
    #        }
    #      },
    #      Office => {
    #        NewYork => {
    #          foo_rule => "allow"
    #        }
    #      },
    #      Store => {
    #        "*" => {
    #          foo_rule => "other"
    #        },
    #        London => {
    #          blah => "purple"
    #        }
    #      },
    #      baz => {
    #        "*" => {
    #          bool_key => 1
    #        }
    #      }
    #    }
    #
    
    
    # lookup values by composite keys:
    $HL->lookup('*:*/foo_rule')              # 'always deny'
    $HL->lookup('foo_rule')                  # 'always deny'
    $HL->lookup('ABC:XYZ/foo_rule')          # 'always deny'  # (virtual/fallback)
    $HL->lookup('Lima/foo_rule')             # 'always deny'  # (virtual/fallback)
    $HL->lookup('NewYork/foo_rule')          # 'prompt'
    $HL->lookup('Office:NewYork/foo_rule')   # 'allow'
    $HL->lookup('Store:foo_rule')            # 'other'
    $HL->lookup('baz:Anything/bool_key')     # 1              # (virtual/fallback)
    
    # lookup values by full/absolute paths:
    $HL->lookup_path(qw/ABC XYZ foo_rule/)   # 'always deny'  # (virtual/fallback)
    $HL->lookup_path(qw/Store * foo_rule/)   # 'other'

## DESCRIPTION

`Hash::Layout` provides deep hashes with a predefined number of levels which you can access using
special "composite keys". These are essentially string paths that inflate into actual hash keys according
to the defined levels and delimiter mappings, which can be the same or different for each level. 
This is useful both for shorter keys as well as merge/fallback to default values, such as when 
defining overlapping configs ranging from broad to narrowing scope (see example in SYNOPIS above).

This module is general-purpose, but was written specifically for the flexible 
[filter()](https://metacpan.org/pod/DBIx::Class::Schema::Diff#filter) feature of [DBIx::Class::Schema::Diff](https://metacpan.org/pod/DBIx::Class::Schema::Diff), 
so refer to its documentation as well for a real-world example application. There are also lots of 
examples and use scenarios in the unit tests under `t/`.

## METHODS

### new

Create a new Hash::Layout instance. The following build options are supported:

- levels

    Required. ArrayRef of level config definitions, or a numeric number of levels for default level
    configs. Each level can define its own `delimiter` (except the last level) and list of 
    `registered_keys`, both of which are optional and determine how ambiguous/partial composite keys are resolved.

    Level-specific delimiters provide a mechanism to supply partial paths in composite keys but resolve
    to a specific level. The word/string to the left of a delimiter character that is specific to a given level
    is resolved as the key of that level, however, the correct path order is required (keys are only tokenized
    in order from left to right).

    Specific strings can also be declared to belong to a particular level with `registered_keys`. This
    also only effects how ambiguity is resolved with partial composite keys. See also the `no_fill` and 
    `no_pad` options.

    See the unit tests for examples of exactly how this works.

    Internally, the level configs are coerced into [Hash::Layout::Level](https://metacpan.org/pod/Hash::Layout::Level) objects.

    For Hash::Layouts that don't need/want level-specific delimiters, or level-specific registered\_keys,
    a simple integer value can be supplied instead for default level configs all using `/` as the delimiter.

    So, this:

        my $HL = Hash::Layout->new({ levels => 5 });

    Is equivalent to:

        $HL = Hash::Layout->new({
         levels => [
           { delimiter => '/' }
           { delimiter => '/' }
           { delimiter => '/' }
           { delimiter => '/' }
           {} #<-- last level never has a delimiter
         ]
        });

    `levels` is the only required parameter.

- default\_value

    Value to assign keys when supplied to `load()` as simple strings instead of key/value pairs. 
    Defaults to the standard bool/true value of `1`.

- default\_key

    Value to use for the key for levels which are not specified, as well as the key to use for default/fallback 
    when looking up non-existant keys (see also `lookup_mode`). Defaults to a single asterisk `(*)`.

- no\_fill

    If true, partial composite keys are not expanded with the default\_key (in the middle) to fill to 
    the last level.
    Defaults to 0.

- no\_pad

    If true, partial composite keys are not expanded with the default\_key (at the front or middle) to 
    fill to the last level. `no_pad` implies `no_fill`. Again, see the tests for a more complete 
    explanation. Defaults to 0.

- allow\_deep\_values

    If true, values at the bottom level are allowed to be hashes, too, for the purposes of addressing
    the deeper paths using composite keys (see `deep_delimiter` below). Defaults to 1.

- deep\_delimiter

    When `allow_deep_values` is enabled, the deep\_delimiter character is used to resolve composite key
    mappings into the deep hash values (i.e. beyond the predefined levels). Must be different from the 
    delimiter used by any of the levels. Defaults to a single dot `(.)`.

    For example:

        $HL->lookup('something/foo.deeper.hash.path')

- lookup\_mode

    One of either `get`, `fallback` or `merge`. In `fallback` mode, when a non-existent composite 
    key is looked up, the value of the first closest found key path using default keys is returned 
    instead of `undef` as is the case with `get` mode. `merge` mode is like `fallback` mode, except 
    hashref values are merged with matching default key paths which are also hashrefs. Defaults to `merge`.

### clone

Returns a new/cloned `Hash::Layout` instance

### coerce

Dynamic method coerces supplied value into a new `Hash::Layout` instance with a new set of loaded data. 
See unit tests for more info.

### coercer

CodeRef wrapper around `coerce()`, suitable for use in a [Moo](https://metacpan.org/pod/Moo#has)-compatible attribute declaration

### load

Loads new data into the hash.

Data can be supplied as hashrefs with normal/local keys or composite keys, or both. Composite keys can 
also be supplied as sub-keys and are resolved relative to the location in which they appear as one would 
expect.

Composite keys can also be supplied as simple strings w/o corresponding values in which case their value
is set to whatever `default_value` is set to (which defaults to 1).

See the unit tests for more details and lots of examples of using `load()`.

### set

Simpler alternative to `load()`. Expects exactly two arguments as standard key/values.

### resolve\_key\_path

Converts a composite key string into its full path and returns it as a list. Called internally wherever
composite keys are resolved.

### path\_to\_composite\_key

Inverse of `resolve_key_path`; takes a path as a list and returns a single composite key string (i.e. joins using the
delimiters for each level). Obviously, it only returns fully-qualified, non-ambiguous (not partial) composite keys.

### exists

Returns true if the supplied composite key exists and false if it doesn't. Does not consider default/fallback
key paths.

### exists\_path

Like `exists()`, but requires the key to be supplied as a resolved/fully-qualified path as a list of arguments. 
Used internally by `exists()`.

### get

Retrieves the _real_ value of the supplied composite key, or undef if it does not exist. Use `exists()` to 
distinguish undef values. Does not consider default/fallback key paths (that is what `lookup()` is for).

### get\_path

Like `get()`, but requires the key to be supplied as a resolved/fully-qualified path as a list of arguments. 
Used internally by `get()`.

### lookup

Returns the value of the supplied composite key, falling back to default key paths if it does not exist, 
depending on the value of `lookup_mode`.

If the lookup\_mode is set to `'get'`, lookup() behaves exactly the same as get().

If the lookup\_mode is set to `'fallback'` and the supplied key does not exist, lookup() will search the 
hierarchy of matching default key paths, returning the first value that exists.

If the lookup\_mode is set to `'merge'`, lookup() behaves the same as it does in `'fallback'` mode for
all non-hashref values. For hashref values, the hierarchy of default key paths is searched and all
matches (that are themselves hashrefs), including the exact/lowest value itself, are merged and returned. 

### lookup\_path

Like `lookup()`, but requires the key to be supplied as a resolved/fully-qualified path as a list of arguments. 
Used internally by `lookup()`.

### lookup\_leaf\_path

Like `lookup_path()`, but only returns the value if it is a _"leaf"_ (i.e. not a hashref with deeper sub-values).
Empty hashrefs (`{}`) are also considered leaf values.

### delete

Deletes the supplied composite key and returns the deleted value, or undef if it does not exist. 
Does not consider default/fallback key paths, or delete multiple items at once (e.g. like the Linux `rm` 
command does with shell globs).

### delete\_path

Like `delete()`, but requires the key to be supplied as a resolved/fully-qualified path as a list of arguments. 
Used internally by `delete()`.

### Data

Returns a read-only (i.e. cloned) copy of the full loaded hash structure.

### num\_levels

Returns the number of levels defined for this `Hash::Layout` instance.

### level\_keys

Returns a hashref of all the keys that have been loaded/exist for the supplied level index (the first level
is at index `0`).

### def\_key\_bitmask\_strings

Debug method. Returns a list of all the default key paths as a list of bitmasks (in binary/string form).
Any key path which has at least one default key at any level is considered a default path and is indexed
as a bitmask, with '1' values representing the default key position(s). For instance, the key 
path `{*}{*}{foo_rule}` from the 3-level example from the SYNOPSIS is indexed as the bitmask `110` (`6` in decimal).

These bitmasks are used internally to efficiently search for and properly order default key values 
for quick fallback/merge lookups, even when there are a very large number of levels (and thus very, 
VERY large number of possible default paths). That is why they are tracked and indexed ahead of time.

This is a debug method which should not be needed to be used for any production code. I decided to leave
it in just to help document some of the internal workings of this module.

### reset

Clears and removes all loaded data and resets internal key indexes and counters.

## EXAMPLES

For more examples, see the following:

- The SYNOPSIS
- The unit tests in `t/`
- [DBIx::Class::Schema::Diff#filter](https://metacpan.org/pod/DBIx::Class::Schema::Diff#filter)

## AUTHOR

Henry Van Styn <vanstyn@cpan.org>

## COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
