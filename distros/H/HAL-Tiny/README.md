# NAME

HAL::Tiny - Hypertext Application Language Encoder

# SYNOPSIS

    use HAL::Tiny;

    my $resource = HAL::Tiny->new(
        state => +{
            currentlyProcessing => 14,
            shippedToday => 20,
        },
        links => +{
            self => '/orders',
            next => '/orders?page=2',
            find => {
                href      => '/orders{?id}',
                templated => JSON::true,
            },
        },
        embedded => +{
            orders => [
                HAL::Tiny->new(
                    state => +{ id => 10 },
                    links => +{ self => '/orders/10' },
                ),
                HAL::Tiny->new(
                    state => +{ id => 11 },
                    links => +{ self => '/orders/11' },
                )
            ],
        },
    );

    $resource->as_json;

# DESCRIPTION

HAL::Tiny is a minimum implementation of Hypertext Application Language(HAL).

# METHODS

- **new** - Create a resource instance.

        HAL::Tiny->new(%args);

    %args are

    - state

        The hash of representing the current state.

    - links

        The hash of links related to the current state.

    - embedded

        The hash of embedded objects.
        Each hash value must be an array of HAL::Tiny objects or a HAL::Tiny object.

- **as\_json** - Encode to json.

    Encode to json string.

# LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuuki Furuyama <addsict@gmail.com>
