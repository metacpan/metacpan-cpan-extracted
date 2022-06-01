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

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
