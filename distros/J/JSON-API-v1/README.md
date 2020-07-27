# DESCRIPTION

This module attempts to make a Moose object behave like a JSON API object as
defined by [jsonapi.org](https://metacpan.org/pod/jsonapi.org). This object adheres to the v1 specification

# SYNOPSIS

    use JSON::API::v1;

    my $object = JSON::API::v1->new(
        data => JSON::API::v1::Resource->new(
            ...
        );
    );

    $object->add_error(JSON::API::v1::Error->new(...));

    $object->add_relationship(JSON::API::v1::Error->new(...));

# ATTRIBUTES

## data

This data object is there a [JSON::API::v1::Resource](https://metacpan.org/pod/JSON%3A%3AAPI%3A%3Av1%3A%3AResource) lives.

## errors

This becomes an array ref of [JSON::API::v1::Error](https://metacpan.org/pod/JSON%3A%3AAPI%3A%3Av1%3A%3AError) once you start
adding errors to this object object via `add_error`.

## included

This becomes an array ref of [JSON::API::v1::Resource](https://metacpan.org/pod/JSON%3A%3AAPI%3A%3Av1%3A%3AResource) once you start
adding additional resources to this object object via `add_included`.

## is\_set

This is to tell the object it is a set and you can add data to it via
`add_data`. It will in turn JSON-y-fi the data to an array of the data you've
added. If you don't set this via the constructer, please read the documentation
of ["add\_data" in JSON::API::v1](https://metacpan.org/pod/JSON%3A%3AAPI%3A%3Av1#add_data)

# METHODS

## add\_data

You can add individual [JSON::API::v1::Resource](https://metacpan.org/pod/JSON%3A%3AAPI%3A%3Av1%3A%3AResource) objects to the
toplevel object. If you have not set is\_set the first call to this function
will assume you're adding data and thus want to be a set.

## add\_error

You can add individual [JSON::API::v1::Error](https://metacpan.org/pod/JSON%3A%3AAPI%3A%3Av1%3A%3AError) objects to the
toplevel object.

## add\_included

You can add individual [JSON::API::v1::Resource](https://metacpan.org/pod/JSON%3A%3AAPI%3A%3Av1%3A%3AResource) objects to the
toplevel object.
