[![Build Status](https://travis-ci.org/pine/p5-JSON-Types-Flexible.svg?branch=master)](https://travis-ci.org/pine/p5-JSON-Types-Flexible) [![Coverage Status](http://codecov.io/github/pine/p5-JSON-Types-Flexible/coverage.svg?branch=master)](https://codecov.io/github/pine/p5-JSON-Types-Flexible?branch=master)
# NAME

JSON::Types::Flexible - Yet another [JSON::Types](https://metacpan.org/pod/JSON::Types) module

# SYNOPSIS

    # Strict mode
    use JSON::Types::Flexible;

    # Loose mode
    use JSON::Types::Flexible ':loose';

# DESCRIPTION

JSON::Types::Flexible is yet another [JSON::Types](https://metacpan.org/pod/JSON::Types) module.

## WHY ?

    $ node
    > typeof(1)
    'number'

    > typeof("1")
    'string'

    > typeof(true)
    'boolean'

## MODE

### Strict mode

Export `number`, `string` and `boolean` methods.

### Loose mode

Export `number`, `string`, `boolean` and `bool` methods.

## METHODS

### number

### string

### bool

See also [JSON::Types](https://metacpan.org/pod/JSON::Types).

### boolean

Alias for `bool`.

# LICENSE

(The MIT license)

Copyright (c) 2016 Pine Mizune <pinemz@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# AUTHOR

Pine Mizune <pinemz@gmail.com>
