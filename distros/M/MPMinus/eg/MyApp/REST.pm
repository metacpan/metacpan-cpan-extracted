package MyApp::REST;
use strict;
use utf8;

=encoding utf8

=head1 NAME

MyApp::REST - Example of REST server

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    PerlOptions +GlobalRequest
    PerlModule MyApp::REST
    <Location /foo>
      PerlInitHandler MyApp::REST
      PerlSetVar Debug on
      PerlSetVar Location foo
    </Location>

=head1 DESCRIPTION

The module demonstrate various examples of how RAMST handlers work.

=cut

use vars qw/ $VERSION /;
$VERSION = "1.00";

use base qw/MPMinus::REST/;

use Apache2::Util;
use Apache2::Const -compile => qw/ :common :http /;

use Encode;
use Encode::Locale;
use Sys::Hostname qw/ hostname /;

use MPMinus::Util qw/ getHiTime /;

use constant {
        DATE_FORMAT => "%D %H:%M:%S %Z",
    };

=head1 METHODS

Base methods

=head2 handler

See L<MPMinus::REST/handler>

=head2 hInit

See L<MPMinus::REST/hInit>

=cut

sub handler : method {
    my $class = (@_ >= 2) ? shift : __PACKAGE__;
    my $r = shift;
    #
    # ... preinit statements ...
    #
    return $class->init($r);
}

sub hInit {
    my $self = shift;
    my $r = shift;

    # Dir config variables
    $self->set_dvar(testvalue => $r->dir_config("testvalue") // "");

    # Session variables
    $self->set_svar(init_label => __PACKAGE__);

    return $self->SUPER::hInit($r);
}

=head1 RAMST METHODS

RAMST methods

=head2 GET /foo

    curl -v --raw -H "Accept: application/json" http://rest.localhost/foo?bar=123

    > GET /foo?bar=123 HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: application/json
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 12 Apr 2019 11:42:18 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Content-Length: 623
    < Content-Type: application/json
    <
    {
       "debug_time" : "0.517",
       "code" : 200,
       "location" : "foo",
       "uri" : "/foo",
       "name" : "getIndex",
       "servers" : [
          "MyApp-REST#/",
          "MyApp-REST#foo"
       ],
       "hostname" : "mnslpt",
       "startedfmt" : "04/12/19 14:42:18 MSK",
       "foo_attr" : "blah-blah-blah",
       "server_status" : 1,
       "stamp" : "[5153] MyApp::REST at Fri Apr 12 14:42:18 2019",
       "usr" : {
          "bar" : "123"
       },
       "key" : "GET#/#default",
       "error" : "",
       "dvars" : {
          "testvalue" : "",
          "debug" : "on",
          "location" : "foo"
       },
       "remote_addr" : "127.0.0.1",
       "path" : "/",
       "started" : 1555069338
    }

Examples:

    curl -v --raw http://rest.localhost/foo
    curl -v --raw -H "Accept: application/json" http://rest.localhost/foo
    curl -v --raw -H "Accept: application/xml" http://rest.localhost/foo
    curl -v --raw -H "Accept: application/x-yaml" http://rest.localhost/foo

=cut

__PACKAGE__->register_handler( # GET /
    handler => "getIndex",
    method  => "GET",
    path    => "/",
    query   => undef,
    attrs   => {
            foo             => 'blah-blah-blah',
            #debug           => 'on',
            #content_type    => CONTENT_TYPE,
            #deserialize     => 1,
            serialize       => 1,
        },
    description => "Index",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;
    my $q = $self->get("q");
    my $usr = $self->get("usr");
    #my $req_data = $self->get("req_data");
    #my $res_data = $self->get("res_data");

    # Output
    my $uri = $r->uri || ""; $uri =~ s/\/+$//;
    $self->set( res_data => {
        foo_attr        => $self->get_attr("foo"),
        hostname        => hostname,
        name            => $name,
        server_status   => $self->status,
        code            => $self->code,
        error           => $self->error,
        key             => $self->get_svar("key"),
        path            => $self->get_svar("path"),
        remote_addr     => $self->get_svar("remote_addr"),
        location        => $self->{location},
        #data            => $self->data,
        #svars           => $self->{svars},
        #m               => $m,
        stamp           => $self->{stamp},
        dvars           => $self->{dvars},
        uri             => $uri,
        started         => $r->request_time,
        startedfmt      => decode(locale => Apache2::Util::ht_time($r->pool, $r->request_time, DATE_FORMAT, 0)),
        debug_time      => sprintf("%.3f", (getHiTime() - $self->get_svar('hitime'))),
        usr             => $usr,
        servers         => [$self->registered_servers],
    });

    return 1; # Or 0 only!!
});


=head2 GET /foo?act=error

    curl -v --raw -H "Accept: application/json" "http://rest.localhost/foo?act=error"

    > GET /foo?act=error HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: application/json
    >
    < HTTP/1.1 500 Internal Server Error
    < Date: Fri, 12 Apr 2019 11:47:35 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Content-length: 90
    < Connection: close
    < Content-Type: application/json
    <
    {
       "error" : {
          "code" : 500,
          "message" : "getIndexError test error!"
       }
    }

=cut

__PACKAGE__->register_handler( # GET /?act=error
    handler => "getIndexError",
    method  => "GET",
    path    => "/",
    query   => "act=error",
    attrs   => {
            debug           => 'on',
            serialize       => 1,
        },
    description => "Returns SERVER_ERROR if QS arg act eq \"error\"",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;
    return $self->error(Apache2::Const::SERVER_ERROR, sprintf("%s test error!", $name));
});


=head2 GET /foo?act=custom

    curl -v --raw -H "Accept: application/json" "http://rest.localhost/foo?act=custom"

    > GET /foo?act=custom HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: application/json
    >
    < HTTP/1.1 503 Service Unavailable
    < Date: Fri, 12 Apr 2019 11:50:17 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < X-Test-Header: Foo
    < Content-Length: 78
    < Connection: close
    < Content-Type: application/json
    <
    {
       "customerror" : "Test custom error",
       "name" : "getIndexCustomError"
    }

=cut

__PACKAGE__->register_handler( # GET /?act=custom
    handler => "getIndexCustomError",
    method  => "GET",
    path    => "/",
    query   => "act=custom",
    attrs   => {
            debug           => 'on',
            serialize       => 1,
        },
    description => "Returns custom HTTP_SERVICE_UNAVAILABLE if QS arg act eq \"error\" and mode eq \"custom\"",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;

    $self->set( res_data => {
            name        => $name,
            customerror => "Test custom error",
        } );
    $self->code(Apache2::Const::HTTP_SERVICE_UNAVAILABLE);
    $r->headers_out()->set("X-Test-Header", "Foo");
    return 1;
});

=head2 GET /foo?act=custom

    curl -v --raw -H "Accept: application/json" http://rest.localhost/foo/deep/user/123

    > GET /foo/deep/user/123 HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: application/json
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 12 Apr 2019 12:11:54 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Content-Length: 112
    < Content-Type: application/json
    <
    {
       "path" : "/deep/user/123",
       "location" : "foo",
       "uri" : "/foo/deep/user/123",
       "name" : "getDeep"
    }

=cut

__PACKAGE__->register_handler( # GET /deep
    handler => "getDeep",
    method  => "GET",
    path    => "/deep",
    deep    => 1,
    #query   => "act=catch",
    attrs   => {
            debug           => 'on',
            serialize       => 1,
        },
    description => "Returns deeped response",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;

    $self->set( res_data => {
            name    => $name,
            location=> $self->location,
            path    => $self->get_svar("path"),
            uri     => $r->uri,
        } );

    return 1;
});

=head2 POST /foo

    curl -X POST -v -d '{"object": "list_services", "params": {}}' --raw -H "Content-Type: application/json" http://rest.localhost/foo

    > POST /foo HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    > Content-Type: application/json
    > Content-Length: 41
    >
    * upload completely sent off: 41 out of 41 bytes
    < HTTP/1.1 200 OK
    < Date: Fri, 12 Apr 2019 11:51:41 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Content-Length: 195
    < Content-Type: application/json
    <
    {
       "key" : "POST#/#default",
       "error" : "",
       "code" : 200,
       "server_status" : 1,
       "input_data" : {
          "params" : {},
          "object" : "list_services"
       },
       "name" : "postIndex"
    }

=cut

__PACKAGE__->register_handler( # POST /
    handler => "postIndex",
    method  => "POST",
    path    => "/",
    query   => undef,
    attrs   => {
            debug           => 'on',
            #content_type    => 'text/plain; charset=utf-8',
            #content_type    => 'text/xml; charset=utf-8',
            deserialize     => 1,
            serialize       => 1,
        },
    description => "Returns re-serialized input data (for test only)",
    requires=> [qw/
            ADMIN USER TEST SVC SDK
        /],
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;

    my $res_data = {
        name            => $name,
        server_status   => $self->status,
        code            => $self->code,
        error           => $self->error,
        key             => $self->get_svar("key"),
        input_data      => $self->get("req_data") // '',
    };

    $self->set(res_data => $res_data);
    return 1; # Or 0 only!!
});

=head2 GET /foo/null

    curl -v --raw -H "Accept: application/json" "http://rest.localhost/foo/null"

    > GET /foo/null HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: application/json
    >
    < HTTP/1.1 204 No Content
    < Date: Fri, 12 Apr 2019 11:52:43 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Content-Type: text/plain; charset=utf-8
    <

=cut

__PACKAGE__->register_handler( # GET /foo/null
    handler => "getNull",
    method  => "GET",
    path    => "/null",
    description => "Test NULL (No input, no output)",
    code    => sub {
    return 1; # Or 0 only!!
});

=head2 GET /foo/test

    curl -v --raw -H "Accept: application/json" "http://rest.localhost/foo/test"

    > GET /foo/test HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: application/json
    >
    < HTTP/1.1 200 OK
    < Date: Fri, 12 Apr 2019 11:53:27 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Content-Length: 49
    < Content-Type: application/json
    <
    {
       "uri" : "foo/test",
       "name" : "getTest"
    }

=cut

__PACKAGE__->register_handler( # GET /foo/test
    handler => "getTest",
    method  => "GET",
    path    => "/test",
    attrs   => {
            serialize       => 1,
        },
    description => "Test (GET default)",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;

    my $look = $self->lookup_handler;
    my $loc = sprintf("%s%s", $self->{location}, $look->{path} || "");
    $self->set(res_data => {
            name => $name,
            uri => $loc,
        });
    return 1; # Or 0 only!!
});

=head2 PUT /foo/test

    curl -v --raw -X PUT -H "Content-Type: application/json" -d '{"foo":"bar"}' "http://rest.localhost/foo/test"

    > PUT /foo/test HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    > Content-Type: application/json
    > Content-Length: 13
    >
    * upload completely sent off: 13 out of 13 bytes
    < HTTP/1.1 201 Created
    < Date: Fri, 12 Apr 2019 11:54:40 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Location: foo/test
    < Content-Length: 95
    < Content-Type: application/json
    <
    {
       "uri" : "foo/test",
       "input_data" : {
          "foo" : "bar"
       },
       "name" : "putTest"
    }

=cut

__PACKAGE__->register_handler( # PUT /foo/test
    handler => "putTest",
    method  => "PUT",
    path    => "/test",
    attrs   => {
            deserialize     => 1,
            serialize       => 1,
        },
    description => "Test (PUT default)",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;

    my $look = $self->lookup_handler;
    my $loc = sprintf("%s%s", $self->{location}, $look->{path} || "");
    $self->set(res_data => {
            name => $name,
            input_data => $self->get("req_data"),
            uri => $loc,
        });
    $self->code(Apache2::Const::HTTP_CREATED);
    $r->headers_out->{Location} = $loc;
    #return $self->error("My test error!");
    return 1; # Or 0 only!!
});

=head2 POST /foo/test

    curl -v --raw -H "Content-Type: application/json" -d '{"foo":"bar"}' "http://rest.localhost/foo/test"

    > POST /foo/test HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    > Content-Type: application/json
    > Content-Length: 13
    >
    * upload completely sent off: 13 out of 13 bytes
    < HTTP/1.1 201 Created
    < Date: Fri, 12 Apr 2019 11:55:56 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Location: foo/test
    < Content-Length: 96
    < Content-Type: application/json
    <
    {
       "uri" : "foo/test",
       "input_data" : {
          "foo" : "bar"
       },
       "name" : "postTest"
    }

=cut

__PACKAGE__->register_handler( # POST /foo/test
    handler => "postTest",
    method  => "POST",
    path    => "/test",
    attrs   => {
            deserialize     => 1,
            serialize       => 1,
        },
    description => "Test (POST default)",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;

    my $look = $self->lookup_handler;
    my $loc = sprintf("%s%s", $self->{location}, $look->{path} || "");
    $self->set(res_data => {
            name => $name,
            input_data => $self->get("req_data"),
            uri => $loc,
        });
    $self->code(Apache2::Const::HTTP_CREATED);
    $r->headers_out->{Location} = $loc;
    #return $self->error("My test error!");
    return 1; # Or 0 only!!
});

=head2 PATCH /foo/test

    curl -v --raw -X PATCH -H "Content-Type: application/json" -d '{"foo":"bar"}' "http://rest.localhost/foo/test"

    > PATCH /foo/test HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    > Content-Type: application/json
    > Content-Length: 13
    >
    * upload completely sent off: 13 out of 13 bytes
    < HTTP/1.1 200 OK
    < Date: Fri, 12 Apr 2019 11:57:23 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Content-Length: 97
    < Content-Type: application/json
    <
    {
       "uri" : "foo/test",
       "input_data" : {
          "foo" : "bar"
       },
       "name" : "patchTest"
    }

=cut

__PACKAGE__->register_handler( # PATCH /foo/test
    handler => "patchTest",
    method  => "PATCH",
    path    => "/test",
    attrs   => {
            deserialize     => 1,
            serialize       => 1,
        },
    description => "Test (PATCH default)",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;

    my $look = $self->lookup_handler;
    my $loc = sprintf("%s%s", $self->{location}, $look->{path} || "");
    $self->set(res_data => {
            name => $name,
            input_data => $self->get("req_data"),
            uri => $loc,
        });
    return 1; # Or 0 only!!
});

=head2 PATCH /foo/test

    curl -v --raw -X DELETE http://rest.localhost/foo/test

    > DELETE /foo/test HTTP/1.1
    > Host: rest.localhost
    > User-Agent: curl/7.50.1
    > Accept: */*
    >
    < HTTP/1.1 204 No Content
    < Date: Fri, 12 Apr 2019 12:03:07 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    <

=cut

__PACKAGE__->register_handler( # DELETE /foo/test
    handler => "deleteTest",
    method  => "DELETE",
    path    => "/test",
    query   => undef,
    description => "Test (DELETE default)",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;
    $r->content_type(""); # Unset Content-Type
    return 1; # Or 0 only!!
});

1;

=head1 DEPENDENCIES

C<mod_perl2>, L<MPMinus>, L<MPMinus::REST>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<MPMinus>, L<MPMinus::REST>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

__END__
