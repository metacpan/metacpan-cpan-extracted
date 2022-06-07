[![Actions Status](https://github.com/kfly8/p5-JSON-UnblessObject/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/p5-JSON-UnblessObject/actions) [![Coverage Status](http://codecov.io/github/kfly8/p5-JSON-UnblessObject/coverage.svg?branch=main)](https://codecov.io/github/kfly8/p5-JSON-UnblessObject?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/JSON-UnblessObject.svg)](https://metacpan.org/release/JSON-UnblessObject)
# NAME

JSON::UnblessObject - unbless object using JSON spec like Cpanel::JSON::XS::Type

# SYNOPSIS

```perl
use JSON::UnblessObject qw(unbless_object);

use Cpanel::JSON::XS::Type;

package SomeEntity {
    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class
    }
    sub a { shift->{a} }
    sub b { shift->{b} }
}

my $entity = SomeEntity->new(a => 123, b => 'HELLO');

unbless_object($entity, { a => JSON_TYPE_INT });
# => { a => 123 }

unbless_object($entity, { b => JSON_TYPE_STRING });
# => { b => 'HELLO' }

unbless_object($entity, { a => JSON_TYPE_INT, b => JSON_TYPE_STRING });
# => { a => 123, b => 'HELLO' }
```

# DESCRIPTION

JSON::UnblessObject is designed to assist with JSON encode.
For example, an blessed object can be encoded using JSON spec:

```perl
my $json = Cpanel::JSON::XS->new->canonical;
sub encode_json {
    my ($data, $spec) = @_;

    $data = unbless_object($data, $spec) if blessed $data;
    $json->encode($data, $spec)
}

encode_json($entity, { a => JSON_TYPE_INT });
# => {"a":123}

encode_json($entity, { b => JSON_TYPE_STRING });
# => {"b":"HELLO"}

encode_json($entity, { a => JSON_TYPE_INT, b => JSON_TYPE_STRING }),
# => {"a":123,"b":"HELLO"}
```

## RESOLVERS

The unbless\_object function performs a resolver for a given object type.

- resolve\_arrayref($object, $spec)

    When `$spec` is `ARRAYREF`, executes this function.
    `$object` must either have `@{}` overload or be an iterator with `next` method.
    If `$spec` is `[JSON_TYPE_STRING, JSON_TYPE_STRING]`, then resolve like this `list($object)->[0], list($object)->[1]`. `list` function is an internal utility function that converts `$object` to arrayref.

- resolve\_hashref($object, $spec)

    When `$spec` is `HASHREF`, executes this function.
    If `$spec` is `{ foo => JSON_TYPE_STRING, bar => JSON_TYPE_STRING }`, then resolve like this `{ foo => $object->foo, bar => $object->bar }`.

- resolve\_json\_type\_arrayof($object, $spec)

    When `$spec` is `Cpanel::JSON::XS::Type::ArrayOf`, executes this function.
    `$object` must either have `@{}` overload or be an iterator with `next` method.

- resolve\_json\_type\_hashof($object, $spec)

    When `$spec` is `Cpanel::JSON::XS::Type::HashOf`, executes this function.
    `$object` requires `JSON_KEYS` function. `JSON_KEYS` method is a whitelist of `$object`
    that are allowed to be published as JSON.

    ```perl
    package SomeEntity {
        sub new {
            my ($class, %args) = @_;
            return bless \%args, $class
        }

        sub secret { shift->{secret} }

        sub a { shift->{a} }
        sub b { shift->{b} }

        # Do not include keys that cannot be published like `secret`
        sub JSON_KEYS { qw/a b/ }
    }

    my $entity = SomeEntity->new(a => 1, b => 2, secret => 'XXX');
    unbless_object($entity, json_type_hashof(JSON_TYPE_STRING))
    # => { a => 1, b => 2 }
    ```

- resolve\_json\_type\_anyof($object, $spec)

    When `$spec` is `Cpanel::JSON::XS::Type::AnyOf`, executes this function.
    If `$object` is available as array, it is resolved as array; if it is available as hash, it is resolved as hash; otherwise, it is resolved as scalar.

# SEE ALSO

[Cpanel::JSON::XS::Type](https://metacpan.org/pod/Cpanel%3A%3AJSON%3A%3AXS%3A%3AType)

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
