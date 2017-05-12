[![Build Status](https://travis-ci.org/kablamo/HTTP-Request-AsCurl.png?branch=master)](https://travis-ci.org/kablamo/HTTP-Request-AsCurl)
# NAME

HTTP::Request::AsCurl - Generate a curl command from an HTTP::Request object.



# SYNOPSIS

    use HTTP::Request::Common;
    use HTTP::Request::AsCurl qw/as_curl/;

    my $request = POST('api.earth.defense/weapon1', { 
        target => 'mothership', 
        when   => 'now' 
    });

    system as_curl($request);

    print as_curl($request, pretty => 1, newline => "\n", shell => 'bourne');
    # curl \
    # --request POST api.earth.defense/weapon1 \
    # --dump-header - \
    # --data target=mothership \
    # --data when=now



# DESCRIPTION

This module converts an HTTP::Request object to a curl command.  It can be used
for debugging REST APIs. 

It handles headers and basic authentication.



# METHODS

## as\_curl($request, %params)

Accepts an HTTP::Request object and converts it to a curl command.  If there
are no `%params`, `as_curl()` returns the cmd as an array suitable for being
passed to system().  

If there are `%params`, `as_curl()` returns a formatted string.  The string's
format defaults to using "\\n" for newlines and escaping the curl command using
bourne shell rules unless you are on a win32 system in which case it defaults
to using win32 cmd.exe escaping rules.

Available params are as follows

    newline: defaults to "\n"
    shell:   currently available options are 'bourne' and 'win32'



# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



# AUTHOR

Eric Johnson <eric.git@iijo.org>
