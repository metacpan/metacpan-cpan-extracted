# NAME

Hash::Match - match contents of a hash against rules

# VERSION

version v0.7.1

# SYNOPSIS

```perl
use Hash::Match;

my $m = Hash::Match->new( rules => { key => qr/ba/ } );

$m->( { key => 'foo' } ); # returns false
$m->( { key => 'bar' } ); # returns true
$m->( { foo => 'bar' } ); # returns false

my $n = Hash::Match->new( rules => {
   -any => [ key => qr/ba/,
             key => qr/fo/,
           ],
} )

$n->( { key => 'foo' } ); # returns true
```

# DESCRIPTION

This module allows you to specify complex matching rules for the
contents of a hash.

# METHODS

## `new`

```perl
my $m = Hash::Match->new( rules => $rules );
```

Returns a function that matches a hash reference against the
`$rules`, e.g.

```
if ( $m->( \%hash ) ) { ... }
```

### Rules

The rules can be a hash or array reference of key-value pairs, e.g.

```perl
{
  k_1 => 'string',    # k_1 eq 'string'
  k_2 => qr/xyz/,     # k_2 =~ qr/xyz/
  k_3 => sub { ... }, # k_3 exists and sub->($hash->{k_3}) is true
}
```

For a hash reference, all keys in the rule must exist in the hash and
match the criteria specified by the rules' values.

For an array reference, some (any) key must exist and match the
criteria specified in the rules.

You can specify more complex rules using special key names:

- `-all`

    ```perl
    {
      -all => $rules,
    }
    ```

    All of the `$rules` must match, where `$rules` is an array or hash
    reference.

- `-any`

    ```perl
    {
      -any => $rules,
    }
    ```

    Any of the `$rules` must match.

- `-notall`

    ```perl
    {
      -notall => $rules,
    }
    ```

    Not all of the `$rules` can match (i.e., at least one rule must
    fail).

- `-notany`

    ```perl
    {
      -notany => $rules,
    }
    ```

    None of the `$rules` can match.

- `-and`

    This is a (deprecated) synonym for `-all`.

- `-or`

    This is a (deprecated) synonym for `-any`.

- `-not`

    This is a (deprecated) synonym for `-notall` and `-notany`,
    depending on the context.

Note that rules can be specified arbitrarily deep, e.g.

```perl
{
  -any => [
     -all => { ... },
     -all => { ... },
  ],
}
```

or

```perl
{
  -all => [
     -any => [ ... ],
     -any => [ ... ],
  ],
}
```

The values for special keys can be either a hash or array
reference. But note that hash references only allow strings as keys,
and that keys must be unique.

You can use regular expressions for matching keys. For example,

```perl
-any => [
  qr/xyz/ => $rule,
]
```

will match if there is any key that matches the regular expression has
a corresponding value which matches the `$rule`.

You can also use

```perl
-all => [
  qr/xyz/ => $rule,
]
```

to match if all keys that match the regular expression have
corresponding values which match the `$rule`.

You can also use functions to match keys. For example,

```perl
-any => [
  sub { $_[0] > 10 } => $rule,
]
```

# SEE ALSO

The following modules have similar functionality:

- [Data::Match](https://metacpan.org/pod/Data::Match)
- [Data::Search](https://metacpan.org/pod/Data::Search)

# SOURCE

The development version is on github at [https://github.com/robrwo/Hash-Match](https://github.com/robrwo/Hash-Match)
and may be cloned from [git://github.com/robrwo/Hash-Match.git](git://github.com/robrwo/Hash-Match.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Hash-Match/issues](https://github.com/robrwo/Hash-Match/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Some development of this module was based on work for
Foxtons [http://www.foxtons.co.uk](http://www.foxtons.co.uk).

# CONTRIBUTOR

Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
