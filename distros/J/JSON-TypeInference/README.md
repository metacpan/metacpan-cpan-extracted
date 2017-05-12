[![Build Status](https://travis-ci.org/aereal/JSON-TypeInference.svg?branch=master)](https://travis-ci.org/aereal/JSON-TypeInference) [![Coverage Status](https://img.shields.io/coveralls/aereal/JSON-TypeInference/master.svg?style=flat)](https://coveralls.io/r/aereal/JSON-TypeInference?branch=master)
# NAME

JSON::TypeInference - Inferencing JSON types from given Perl values

# SYNOPSIS

    use JSON::TypeInference;

    my $data = [
      { name => 'yuno' },
      { name => 'miyako' },
      { name => 'nazuna' },
      { name => 'nori' },
    ];
    my $inferred_type = JSON::TypeInference->infer($data); # object[name:string]

# DESCRIPTION

` JSON::TypeInference ` infers the type of JSON values from the given Perl values.

If some candidate types of the given Perl values are inferred, ` JSON::TypeInference ` reports the type of it as a union type that consists of all candidate types.

# CLASS METHODS

- `infer($dataset: ArrayRef[Any]); # => JSON::TypeInference::Type`

    To infer the type of JSON values from the given values.

    Return value is a instance of ` JSON::TypeInference::Type ` that means the inferred JSON type.

# LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

aereal &lt;aereal@aereal.org>

# SEE ALSO

[JSON::TypeInference::Type](https://metacpan.org/pod/JSON::TypeInference::Type)
