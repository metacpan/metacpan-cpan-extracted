[![Build Status](https://travis-ci.org/ernix/p5-Hash-Squash.png?branch=master)](https://travis-ci.org/ernix/p5-Hash-Squash)
# NAME

Hash::Squash - Remove numbered keys from a nested hash/array

# DESCRIPTION

This package provides **squash** and **unnumber** subroutines to simplify
hash/array structures.

# SYNOPSIS

## `squash`

**squash** does 3 things to the argument recursively

1\. Remove numbered keys from hashes and map them to arrays

2\. Convert hashes/arrays with single element to single value

3\. Convert empty hashes/arrays to \`undef\`

    use Hash::Squash qw(squash);
    my $hash = squash(+{
        foo => +{
            '0' => 'numbered',
            '1' => 'hash',
            '2' => 'structures',
        },
        bar => +{
            '0' => 'obviously a single value',
        },
        buz => [
            +{
                nest => +{
                    '0' => 'nested',
                    '2' => 'discreated',
                    '3' => 'array',
                },
            },
            +{
                nest => +{
                    '0' => 'FOO',
                    '1' => 'BAR',
                    '2' => 'BUZ',
                },
            },
        ],
    });

Turns to:

    +{
        foo => [
            'numbered',
            'hash',
            'structures',
        ],
        bar => 'obviously a single value',
        buz => [
            +{
                nest => [
                    'nested',
                    undef,
                    'discreated',
                    'array',
                ],
            },
            +{
                nest => [
                    'FOO',
                    'BAR',
                    'BUZ',
                ],
            }
        ],
    };

## `unnumber`

**unnumber** is similar to **squash**, but keep hashes/arrays

    use Hash::Squash qw(unnumber);
    my $hash = unnumber(+{
        foo => +{
            '0' => 'numbered',
            '1' => 'hash',
            '2' => 'structures',
        },
        bar => +{
            '0' => 'obviously a single value',
        },
        buz => [
            +{
                nest => +{
                    '0' => 'nested',
                    '2' => 'partial',
                    '3' => 'array',
                },
            },
        ],
    });

Turns to:

    +{
        foo => [
            'numbered',
            'hash',
            'structures',
        ],
        bar => ['obviously a single value'],
        buz => [
            +{
                nest => [
                    'nested',
                    undef,
                    'partial',
                    'array',
                ],
            },
        ],
    };

# AUTHOR

Shin Kojima <shin@kojima.org>

# LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
