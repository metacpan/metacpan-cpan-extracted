# NAME

HTTP::Response::Maker - easy HTTP response object maker functions

# SYNOPSIS

    use HTTP::Response::Maker 'HTTPResponse', (
        default_headers => [
            'Content-Type' => 'text/html; charset=utf-8'
        ],
        prefix => 'RESPOND_',
    );

    # now you can use functions like RESPOND_OK() or RESPOND_NOT_FOUND()

or

    use HTTP::Response::Maker::Exception prefix => 'throw_';

    throw_FOUND(Location => '/');

# DESCRIPTION

HTTP::Response::Maker provides HTTP response object maker functions.
They are named as `OK()` or `NOT_FOUND()`, corresponding to
the [HTTP::Status](http://search.cpan.org/perldoc?HTTP::Status) constant names.

# USAGE

## use HTTP::Response::Maker _$impl_, _%args_;

Exports HTTP response maker functions to current package.

_$impl_ specifies what functions make. See IMPLEMENTATION.

_%args_ has these keys:

- prefix => ''

Prefix for exported functions names.

- default\_headers => \\@HTTP::Response::Maker::DefaultHeaders

Default HTTP headers in arrayref.

# IMPLEMENTATION

`import()`'s first argument specifies what type of objects functions generate.
Currently it is one of:

- [HTTPResponse](http://search.cpan.org/perldoc?HTTP::Response::Maker::HTTPResponse)

Generates an [HTTP::Response](http://search.cpan.org/perldoc?HTTP::Response) object.

- [PSGI](http://search.cpan.org/perldoc?HTTP::Response::Maker::PSGI)

Generates an arrayref of [PSGI response](http://search.cpan.org/perldoc?PSGI#The\_Response) format.

- [Plack](http://search.cpan.org/perldoc?HTTP::Response::Maker::Plack)

Generates a [Plack::Response](http://search.cpan.org/perldoc?Plack::Response) object.

You can specify subclass of [Plack::Response](http://search.cpan.org/perldoc?Plack::Response) to generate:

    use HTTP::Response::Maker 'Plack', class => 'Your::Plack::Response';

- [Exception](http://search.cpan.org/perldoc?HTTP::Response::Maker::Exception)

Throws an [HTTP::Exception](http://search.cpan.org/perldoc?HTTP::Exception).

# FUNCTION ARGS

Exported functions accept arguments in some ways:

    my $res = OK;
    my $res = OK $content;
    my $res = OK \@headers;
    my $res = OK \@headers, $content;

# AUTHOR

motemen <motemen@gmail.com>

# SEE ALSO

[HTTP::Status](http://search.cpan.org/perldoc?HTTP::Status), [PSGI](http://search.cpan.org/perldoc?PSGI), [HTTP::Response](http://search.cpan.org/perldoc?HTTP::Response), [HTTP::Exception](http://search.cpan.org/perldoc?HTTP::Exception)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
