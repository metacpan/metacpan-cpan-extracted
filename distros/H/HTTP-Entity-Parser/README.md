# NAME

HTTP::Entity::Parser - PSGI compliant HTTP Entity Parser

# SYNOPSIS

    use HTTP::Entity::Parser;

    my $parser = HTTP::Entity::Parser->new;
    $parser->register('application/x-www-form-urlencoded','HTTP::Entity::Parser::UrlEncoded');
    $parser->register('multipart/form-data','HTTP::Entity::Parser::MultiPart');
    $parser->register('application/json','HTTP::Entity::Parser::JSON');

    sub app {
        my $env = shift;
        my ( $params, $uploads) = $parser->parse($env);
    }

# DESCRIPTION

HTTP::Entity::Parser is a PSGI-compliant HTTP Entity parser. This module also is compatible
with [HTTP::Body](https://metacpan.org/pod/HTTP::Body). Unlike HTTP::Body, HTTP::Entity::Parser reads HTTP entities from
PSGI's environment `$env->{'psgi.input'}` and parses it.
This module supports application/x-www-form-urlencoded, multipart/form-data and application/json.

# METHODS

- new( buffer\_length => $length:Intger)

    Create the instance.

    - buffer\_length

        The buffer length that HTTP::Entity::Parser reads from psgi.input. 16384 by default.

- register($content\_type:String, $class:String, $opts:HashRef)

    Register parser class.

        $parser->register('application/x-www-form-urlencoded','HTTP::Entity::Parser::UrlEncoded');
        $parser->register('multipart/form-data','HTTP::Entity::Parser::MultiPart');
        $parser->register('application/json','HTTP::Entity::Parser::JSON');

    If the request content\_type matches the registered type, HTTP::Entity::Parser uses the registered
    parser class. If content\_type does not match any registered type, HTTP::Entity::Parser::OctetStream is used.

- parse($env:HashRef)

    parse HTTP entities from PSGI's env.

        my ( $params:ArrayRef, $uploads:ArrayRef) = $parser->parse($env);

    `$param` is a key-value pair list.

        my ( $params, $uploads) = $parser->parse($env);
        my $body_parameters = Hash::MultiValue->new(@$params);

    `$uploads` is an ArrayRef of HashRef.

        my ( $params, $uploads) = $parser->parse($env);
        warn Dumper($uploads->[0]);
        {
            "name" => "upload", #field name
            "headers" => [
                "Content-Type" => "application/octet-stream",
                "Content-Disposition" => "form-data; name=\"upload\"; filename=\"hello.pl\""           
            ],
            "size" => 78, #size of upload content
            "filename" => "hello.png", #original filename in the client
            "tempname" => "/tmp/XXXXX", # path to the temporary file where uploaded file is saved
        }

    When used with [Plack::Request::Upload](https://metacpan.org/pod/Plack::Request::Upload):

        my ( $params, $uploads) = $parser->parse($env);
         my $upload_hmv = Hash::MultiValue->new();
         while ( my ($k,$v) = splice @$uploads, 0, 2 ) {
             my %copy = %$v;
             $copy{headers} = HTTP::Headers::Fast->new(@{$v->{headers}});
             $upload_hmv->add($k, Plack::Request::Upload->new(%copy));
         }

# PARSERS

- OctetStream

    Default parser, This parser does not parse entity, always return empty list. 

- UrlEncoded

    For `application/x-www-form-urlencoded`. It is used for HTTP POST without file upload

- MultiPart

    For `multipart/form-data`. It is used for HTTP POST contains file upload.

    MultiPart parser use [HTTP::MultiPartParser](https://metacpan.org/pod/HTTP::MultiPartParser).

- JSON

    For `application/json`. This parser decodes JSON body automatically.

    It is convenient to use with Ajax forms.

# WHAT'S DIFFERENT FROM HTTP::Body

HTTP::Entity::Parser accept PSGI's env and read body from it.

HTTP::Entity::Parser is able to choose parsers by the instance, HTTP::Body requires to modify global variables.

# SEE ALSO

- [HTTP::Body](https://metacpan.org/pod/HTTP::Body)
- [HTTP::MultiPartParser](https://metacpan.org/pod/HTTP::MultiPartParser)
- [Plack::Request](https://metacpan.org/pod/Plack::Request)
- [WWW::Form::UrlEncoded](https://metacpan.org/pod/WWW::Form::UrlEncoded)

    HTTP::Entity::Parser uses this for parse application/x-www-form-urlencoded

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>

Tokuhiro Matsuno <tokuhirom@gmail.com>

This module is based on tokuhirom's code, see [https://github.com/plack/Plack/pull/434](https://github.com/plack/Plack/pull/434)
