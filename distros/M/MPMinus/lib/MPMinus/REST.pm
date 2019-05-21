package MPMinus::REST; # $Id: REST.pm 280 2019-05-14 06:47:06Z minus $

require 5.016;

use strict;
use warnings FATAL => 'all';
use utf8;

=encoding utf-8

=head1 NAME

MPMinus::REST - Base class of the MPMinus REST server

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    PerlModule MyApp::REST
    PerlOptions +GlobalRequest +ParseHeaders

    <Location />
        PerlInitHandler MyApp::REST
    </Location>
    <Location /foo>
        PerlInitHandler MyApp::REST
        PerlSetVar Location foo
        PerlSetVar Debug on
    </Location>

    package MyApp::REST;

    use base qw/MPMinus::REST/;

    sub handler : method {
        my $class = (@_ >= 2) ? shift : __PACKAGE__;
        my $r = shift;

        # ... preinit statements ...

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

    __PACKAGE__->register_handler( # GET /
        handler => "getIndex",
        method  => "GET",
        path    => "/",
        query   => undef,
        attrs   => {
                foo             => 'blah-blah-blah',
                #debug           => 'on', # off
                #content_type    => 'text/plain; charset=utf-8',
                #deserialize     => 1,
                #deserialize_att => {},
                serialize       => 1,
                #serialize_att   => {},
            },
        description => "Index",
        code    => sub {
        my $self = shift;
        my $name = shift;
        my $r = shift;
        my $q = $self->get("q");
        my $usr = $self->get("usr");
        my $req_data = $self->get("req_data");

        # Output
        my $uri = $r->uri || ""; $uri =~ s/\/+$//;
        $self->set( res_data => {
            foo_attr        => $self->get_attr("foo"),
            name            => $name,
            init_label      => $self->get_svar("init_label"),
            server_status   => $self->status,
            code            => $self->code,
            error           => $self->error,
            key             => $self->get_svar("key"),
            path            => $self->get_svar("path"),
            remote_addr     => $self->get_svar("remote_addr"),
            location        => $self->{location},
            #data            => $self->data,
            stamp           => $self->{stamp},
            dvars           => $self->{dvars},
            uri             => $uri,
            usr             => $usr,
            req_data        => $req_data,
            servers         => [$self->registered_servers],
        });

        return 1; # Or 0 only!!
    });

=head1 DESCRIPTION

This module allows you to quickly and easily write a mod_perl2 REST server

Please note! This module REQUIRES Apache 2.2+ and mod_perl 2.0+

So. And now about REST and RESTfull

Information bellow has been copied from page L<https://spring.io/understanding/REST>

REST (Representational State Transfer) was introduced and defined in 2000 by Roy Fielding in his
L<doctoral dissertation|https://www.ics.uci.edu/~fielding/pubs/dissertation/top.htm>.
REST is an architectural style for designing distributed systems. It is not a standard but a set
of constraints, such as being stateless, having a client/server relationship, and a uniform interface.
REST is not strictly related to HTTP, but it is most commonly associated with it.

=head2 REST AND CRUD

The MPMinus::REST tries to keep its HTTP methods joined up with CRUD methods.

The acronym CRUD refers to all of the major functions that are implemented in relational
database applications. Each letter in the acronym can map to a standard Structured
Query Language (SQL) statement, Hypertext Transfer Protocol (HTTP) method
(this is typically used to build RESTful APIs) or Data Distribution Service (DDS) operation:

     CRUD             | SQL    | HTTP           | RESTful| DDS       | Prefix
    ------------------+--------+----------------+--------+-----------+--------
     Create           | INSERT | PUT/POST       | POST   | write     | add
     Read (Retrieve)  | SELECT | GET            | GET    | read/take | get/is
     Update (Modify)  | UPDATE | PUT/POST/PATCH | PUT    | write     | set
     Delete (Destroy) | DELETE | DELETE         | DELETE | dispose   | del/rm

B<Note!> Create - PUT with a new URI; POST to a base URI returning a newly created URI

B<Note!> Update - PUT with an existing URI

B<Note!> HTTP PATCH - When PUTting a complete resource representation is cumbersome and utilizes more
bandwidth, e.g.: when you have to update partially a column

=head2 PRINCIPIES OF REST

=over 8

=item *

Resources expose easily understood directory structure URIs.

=item *

Representations transfer JSON or XML to represent data objects and attributes.

=item *

Messages use HTTP methods explicitly (for example, GET, POST, PUT, and DELETE).

=item *

Stateless interactions store no client context on the server between requests. State dependencies
limit and restrict scalability. The client holds session state.

=back

=head2 HTTP METHODS

Use HTTP methods to map CRUD (create, retrieve, update, delete) operations to HTTP requests.

=head3 GET

Retrieve information. GET requests must be safe and idempotent, meaning regardless of how many
times it repeats with the same parameters, the results are the same. They can have side effects,
but the user doesn't expect them, so they cannot be critical to the operation of the system.
Requests can also be partial or conditional.

Retrieve an address with an ID of 1:

    GET /addresses/1

=head3 POST

Request that the resource at the URI do something with the provided entity. Often POST is used to
create a new entity, but it can also be used to update an entity.

Create a new address:

    POST /addresses

=head3 PUT

Store an entity at a URI. PUT can create a new entity or update an existing one. A PUT request is
idempotent. Idempotency is the main difference between the expectations of PUT versus a POST request.

Modify the address with an ID of 1:

    PUT /addresses/1

B<Note:> PUT replaces an existing entity. If only a subset of data elements are provided, the rest
will be replaced with empty or null.

=head3 PATCH

Update only the specified fields of an entity at a URI. A PATCH request is neither safe nor
idempotent (RFC 5789). That's because a PATCH operation cannot ensure the entire resource
has been updated.

    PATCH /addresses/1

=head3 DELETE

Request that a resource be removed; however, the resource does not have to be removed immediately.
It could be an asynchronous or long-running request.

Delete an address with an ID of 1:

    DELETE /addresses/1

=head2 HTTP 1.1 STATUS CODES

=over 8

=item 1XX - informational

    100 HTTP_CONTINUE                        Continue
    101 HTTP_SWITCHING_PROTOCOLS             Switching Protocols

=item 2XX - success

    200 HTTP_OK                              OK
    201 HTTP_CREATED                         Created
    202 HTTP_ACCEPTED                        Accepted
    203 HTTP_NON_AUTHORITATIVE               Non-Authoritative Information
    204 HTTP_NO_CONTENT                      No Content
    205 HTTP_RESET_CONTENT                   Reset Content
    206 HTTP_PARTIAL_CONTENT                 Partial Content

=item 3XX - redirection

    300 HTTP_MULTIPLE_CHOICES                Multiple Choices
    301 HTTP_MOVED_PERMANENTLY               Moved Permanently
    302 HTTP_MOVED_TEMPORARILY               Found
    303 HTTP_SEE_OTHER                       See Other
    304 HTTP_NOT_MODIFIED                    Not Modified
    305 HTTP_USE_PROXY                       Use Proxy
    306                                      (Unused)
    307 HTTP_TEMPORARY_REDIRECT              Temporary Redirect

=item 4XX - client error

    400 HTTP_BAD_REQUEST                     Bad Request
    401 HTTP_UNAUTHORIZED                    Unauthorized
    402 HTTP_PAYMENT_REQUIRED                Payment Required
    403 HTTP_FORBIDDEN                       Forbidden
    404 HTTP_NOT_FOUND                       Not Found
    405 HTTP_METHOD_NOT_ALLOWED              Method Not Allowed
    406 HTTP_NOT_ACCEPTABLE                  Not Acceptable
    407 HTTP_PROXY_AUTHENTICATION_REQUIRED   Proxy Authentication Required
    408 HTTP_REQUEST_TIMEOUT                 Request Timeout
    409 HTTP_CONFLICT                        Conflict
    410 HTTP_GONE                            Gone
    411 HTTP_LENGTH REQUIRED                 Length Required
    412 HTTP_PRECONDITION_FAILED             Precondition Failed
    413 HTTP_REQUEST_ENTITY_TOO_LARGE        Request Entity Too Large
    414 HTTP_REQUEST_URI_TOO_LARGE           Request-URI Too Long
    415 HTTP_UNSUPPORTED_MEDIA_TYPE          Unsupported Media Type
    416 HTTP_RANGE_NOT_SATISFIABLE           Requested Range Not Satisfiable
    417 HTTP_EXPECTATION_FAILED              Expectation Failed

=item 5XX - server error

    500 HTTP_INTERNAL_SERVER_ERROR           Internal Server Error
    501 HTTP_NOT IMPLEMENTED                 Not Implemented
    502 HTTP_BAD_GATEWAY                     Bad Gateway
    503 HTTP_SERVICE_UNAVAILABLE             Service Unavailable
    504 HTTP_GATEWAY_TIME_OUT                Gateway Timeout
    505 HTTP_VERSION_NOT_SUPPORTED           HTTP Version Not Supported

=back

See L<Apache Constants|http://perl.apache.org/docs/2.0/api/Apache2/Const.html>

=head2 MEDIA TYPES

The C<Accept> and C<Content-Type> HTTP headers can be used to describe the content being sent or requested
within an HTTP request. The client may set C<Accept> to C<application/json> if it is requesting a
response in JSON. Conversely, when sending data, setting the C<Content-Type> to
C<application/xml> tells the client that the data being sent in the request is XML.

=head1 CONFIGURATION

The simplest configuration of MPMinus REST server requires a few lines in your httpd.conf:

    PerlModule MyApp::REST
    PerlOptions +GlobalRequest +ParseHeaders
    <Location />
        PerlInitHandler MyApp::REST
    </Location>

The <Location> section routes all requests to the MPMinus REST handler,
which is a simple way to try out MPMinus REST

=head1 METHODS

=head2 handler

The main Apache mod_perl2 entry point. This method MUST BE overwritten in your class!

    sub handler : method {
        my $class = (@_ >= 2) ? shift : __PACKAGE__;
        my $r = shift;

        # ... preinit statements ...

        return $class->init($r, arg1 => "foo", arg2 => "bar");
    }

=head2 init

In your class of the server, you MUST SPECIFY the initializer call string that returns
the mod_perl2 (L<Apache2::Const>) code - common or http.

    my $rc = $class->init($r, ...ARGUMENTS...);

As first parameter ($r) is the L<Apache2::RequestRec> object

Arguments is a hash-pairs (list of name and values) of additional parameters for RAMST base class

=over 8

=item B<location>, B<base>

It is part of the URL-path that will bases for your REST methods, e.g., "/", "rest", "/foo"

=item B<prefix>

Prefix name for signing LOG-strings and your files. Default: name of your server class

=item B<blank>

Specifies blank-structure for RAMST working data in current request context.
In the next request, all data will be reset according to the default data defined in
the blank-structure.

Default blank is:

    {
        q           => undef, # CGI object
        usr         => {},    # User params (from QueryString or form-data)
        req_data    => '',    # Request data
        res_data    => '',    # Response data
    }

For get and set data please use get and set methods

=item B<dvars>, B<valid_dvars>

Defines defaults for variables specified in the httpd.conf <Location>, <Directory>, and <Files> section

Defaults:

    {
        debug       => 'off',
        location    => 'default',
    },

=item B<sr_attrs>

Defines dafaults for L<CTK::Serializer>

Defaults:

    {
        xml => [
                { # Serialize
                    RootName        => "response",
                    NoAttr          => 1,
                },
                { # Deserialize
                    ForceArray      => 1,
                    ForceContent    => 1,
                }
            ],
        json => [
                { # Sserialize
                    utf8            => 0,
                    pretty          => 1,
                    allow_nonref    => 1,
                    allow_blessed   => 1,
                },
                { # Deserialize
                    utf8            => 0,
                    pretty          => 1,
                    allow_nonref    => 1,
                    allow_blessed   => 1,
                },
            ],
    }

=back

=head2 registered_servers

    my @servers = $self->registered_servers();

Returns list of the defined RAMST server's instances

=head2 error_response

    sub error_response {
        my $self = shift;
        return {
            error => {
                code    => $self->code,
                message => $self->error
            }
        }
    }

Defines error response format

You can override this method in your class

=head1 HANDLER METHODS

You can override all of these methods in your class

=head2 hInit

The First (Init) handler method

    sub hInit {
        my $self = shift;
        my $r = shift;

        # Dir config variables
        $self->set_dvar(testvalue => $r->dir_config("testvalue") // "");

        # Session variables
        $self->set_svar(init_label => __PACKAGE__);

        return $self->SUPER::hInit($r);
    }

By default the method performs:

=over 8

=item 1

Sets the hitime and the sid session variables (svars)

=item 2

Checks the HTTP Method of the current request

=item 3

Inits CGI query object and sets it as the "q" node in RAMST data structure

=item 4

Inits usr structure from $q->param's (QUERY_STRING parsed params)
and sets it as the "usr" node in RAMST data structure

=item 5

Inits request data from REQUEST in "as-is" format and sets it as the "req_data"
node in RAMST data structure

=item 6

Sets "debug" session variable from dvars or RAMST handler's attributes

=back

Type: RUN_ALL

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head2 hAccess

The Access handler method

    sub hAccess {
        my $self = shift;
        my $r = shift;
        # ... your statements ...
        return $self->SUPER::hAccess($r);
    }

By default the method sets remote_addr session variable from X-Real-IP header or
remote_ip of L<Apache2::Connection> method

Type: RUN_ALL

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head2 hAuthen

The Authen handler method

    sub hAuthen {
        my $self = shift;
        my $r = shift;
        # ... your statements ...
        return $self->SUPER::hAuthen($r);
    }

By default the method nothing to do and returns Apache2::Const::DECLINED response code

Type: RUN_FIRST

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head2 hAuthz

The Authz handler method

    sub hAuthz {
        my $self = shift;
        my $r = shift;
        # ... your statements ...
        return $self->SUPER::hAuthz($r);
    }

By default the method nothing to do and returns Apache2::Const::DECLINED response code

Type: RUN_FIRST

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head2 hType

The Type handler method

    sub hType {
        my $self = shift;
        my $r = shift;
        # ... your statements ...
        return $self->SUPER::hType($r);
    }

By default the method sets the "format" session variable and sets Content-Type header
according defined format

Type: RUN_FIRST

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head2 hFixup

The Fixup handler method

    sub hFixup {
        my $self = shift;
        my $r = shift;
        # ... your statements ...
        return $self->SUPER::hFixup($r);
    }

By default the method sets the "serializer" session variable and sets serializer's attributes
as "deserialize_attr" and "serialize_attr" session variables (svars). Also this method sets the
"req_data" data node according selected serialization

Type: RUN_ALL

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head2 hResponse

The Response handler method

    sub hResponse {
        my $self = shift;
        my $r = shift;
        # ... your statements ...
        return $self->SUPER::hResponse($r);
    }

By default the method runs RAMST registered handler, gets data and prepare response content
(or error response content), serialize it and sents to client

Type: RUN_FIRST

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head2 hLog

The Log handler method

    sub hLog {
        my $self = shift;
        my $r = shift;
        # ... your statements ...
        return $self->SUPER::hLog($r);
    }

By default the method writes to system log status of the current request-transaction

Type: RUN_ALL

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head2 hCleanup

The Cleanup handler method

    sub hCleanup {
        my $self = shift;
        my $r = shift;
        # ... your statements ...
        return $self->SUPER::hCleanup($r);
    }

By default the method flushes the RAMST data node to blank-data structure, flushes session variables (svars) and
resets status and errors of current RAMST server object

Type: RUN_ALL

See L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head1 VARIABLES

MPMinus REST supports current session variables (svars), directory-variables (dvars) and data variables (data)

=head2 SESSION VARIABLES

Session variables are set only per session and are valid only within the current request

=over 8

=item debug

Defines DEBUG flag. Contains boolean values 0 or 1

Default: 0

Defined in: hInit

=item format

Format name of the current transaction

Possible values: xml, yaml, json, none

Default: none

Defined in: hType

=item hitime

High time value (microseconds)

Defined in: hInit

=item key

Key of the current handler

Default: GET#/#default

Defined in: hInit

=item method

Current HTTP method

Default: GET

Defined in: hInit

=item name

Name of the current handler

Default: ""

Defined in: hResponse

=item path

Current URL-path

Default: /

Defined in: hInit

=item query

Current URL-query string

Default: ""

Defined in: hInit

=item remote_addr

Current remote client IP address

Default: 127.0.0.1

Defined in: hAccess

=item serializer

Serializer object

Default: undef

Defined in: hFixup

=item sid

Session ID

Defined in: hInit

=item deserialize_attr

Deserialize attributes

Default: undef

Defined in: hFixup

=item serialize_attr

Serialize attributes

Default: undef

Defined in: hFixup

=back

=head2 DIRECTORY VARIABLES

Variables obtained from the Apache configuration sections <Location>, <Directory>
or <Files> using PerlSetVar and PerlAddVar directives.

These variables do not flushes automatically in cleanup handler, so the dvars
pool can be used for persistent objects, e.g., DBI

=over 8

=item debug

Debug value

Possible values: on, yes, 1, off, no, 0

Default: off

=item location

Base location name or path

Default: default

=back

=head2 DATA VARIABLES

These variables are initialized to BLANK structure and then modified from the handler to the handler.
The Data variables are automatically flushes at the Cleanup handler.

By default BLANK is follow structure:

    {
        q           => undef, # CGI object
        usr         => {},    # User params (from QueryString or form-data)
        req_data    => '',    # Request data
        res_data    => '',    # Response data
    }

=over 8

=item req_data

Request data

Sets in: hInit, hFixup

=item res_data

Response data

Sets in: hResponse (RAMST handler)

=item usr

User params (from QueryString or form-data)

Sets in: hInit

=item q

CGI object

Sets in: hInit

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

C<mod_perl2>, L<MPMinus>, L<MPMinus::RAMST>, L<CTK::Serializer>, L<CGI>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<mod_perl2>,
L<https://www.restapitutorial.com>,
L<https://spring.io/understanding/REST>,
L<https://restfulapi.net>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION $PATCH_20141100055 /;
$VERSION = "1.00";
$PATCH_20141100055 = 0;

use Encode;

use Apache2::ServerRec ();
use Apache2::ServerUtil ();

use Apache2::Response ();

use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();

use Apache2::Connection ();

use Apache2::Const -compile => qw/ :common :http /;

use Apache2::Log;
use Apache2::Util ();

use APR::Const -compile => qw/ :common /;
use APR::Table ();
use APR::Finfo ();
use APR::Status ();

use Apache2::Log ();
use Apache2::Access ();

use base qw/MPMinus::RAMST/;

use Carp; # qw/carp croak cluck confess/

use CGI qw//;

use MPMinus::Util qw/ getHiTime getSID /;

use CTK::Serializer;

use constant {
        MP              => exists($ENV{MOD_PERL}) ? 1 : 0,
        MP2             => (exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) ? 1 : 0,
        OPTS_REQUIRES   => [qw/
                GlobalRequest
            /],
        INSTANCE        => 'default', # Default instance for root (/) handlers
        LOCATION        => '/',
        VALID_DVARS     => { # Valid dir variables of the dir-config (also from .htacces)
                debug           => 'off',
                location        => 'default',
            },
        BLANK           => {
                q           => undef, # CGI object
                usr         => {},    # User params
                req_data    => '',    # Request data
                res_data    => '',    # Response data
            },

        # Serializer
        CONTENT_TYPE    => 'text/plain; charset=utf-8',
        FORMAT          => 'none',
        FORMAT2CT       => {
            xml     => "application/xml",
            json    => "application/json",
            yaml    => "application/x-yaml",
            none    => "text/plain",
            html    => "text/html",
            txt     => "text/plain",
        },
        SR_ATTRS => {
                xml => [
                        { # Serialize
                            RootName        => "response",
                            NoAttr          => 1,
                        },
                        { # Deserialize
                            ForceArray      => 1,
                            ForceContent    => 1,
                        }
                    ],
                json => [
                        { # Serialize
                            utf8            => 0,
                            pretty          => 1,
                            allow_nonref    => 1,
                            allow_blessed   => 1,
                        },
                        { # Deserialize
                            utf8            => 0,
                            pretty          => 1,
                            allow_nonref    => 1,
                            allow_blessed   => 1,
                        },
                    ],
            },

        # XML
        NOXMLDECL       => 1,
        FORCEARRAY      => 1,
        FORCECONTENT    => 1,
    };

my %_RAMST_SERVERS = (); # CLASS -> SERVER INSTANCE

die("Incorrect mod_perl API version. Requires 2 or greater") if MP && !MP2;

# Patch: http://osdir.com/ml/modperl.perl.apache.org/2014-11/msg00055.html
if (MP2 && !$PATCH_20141100055) {
    if (!Apache2::Connection->can('remote_ip')) { # Apache 2.4.x or larger
        eval 'sub Apache2::Connection::remote_ip { return $_[0]->client_ip }';
    }
    $PATCH_20141100055 = 1;
}

sub handler {
    die("Please overwrite this method in your subclass");
}

sub init { # Main init
    my $class = shift;
    my $r = shift // Apache2::RequestUtil->request;
    my %args = @_;
    croak("Please call correctly the init method in your handler. E.g, __PACKAGE__->init()") unless $class && $r;
    croak("Incorrect Apache2::RequestRec object") unless $r->isa("Apache2::RequestRec");
    for (@{(OPTS_REQUIRES)}) {
        warn sprintf("%s: PerlOption +%s required", $class, $_) unless $r->is_perl_option_enabled($_);
    }

    # Initialize
    $r->handler('modperl');

    # ... base location argument
    my $base = $args{location} // $args{base} // $args{location_base};
    unless ($base) {
        my $instance =  $r->dir_config("location") // $r->dir_config("base");
        if (!$instance) { # Not defined in config
            $base = LOCATION; # "/"
        } elsif ($instance eq INSTANCE) { # eq "default"
            $base = $r->location || LOCATION; # current <Location /foo> in config file
        } else {
            $base = $instance; # Custom value
        }
        $base =~ s/\/{2,}/\//g;
        $base =~ s/\/+$//;
        $args{base} = $base;
    }

    # Init RAMST Server as instance!
    my $key = sprintf("%s#%s", $class, $base || LOCATION); $key=~s/\:\:/\-/g;
    unless ($_RAMST_SERVERS{$key}) {
        $_RAMST_SERVERS{$key} = $class->new(
            prefix  => $args{prefix},
            request => $r,
            location=> $base,                 # Base location
            blank   => $args{blank} || BLANK, # Defaults
            dvars   => $args{dvars} || $args{valid_dvars} || VALID_DVARS, # Valid dvars
        );
        $_RAMST_SERVERS{$key}->{_sr_attrs} = $args{sr_attrs} || SR_ATTRS;
    }
    my $self = $_RAMST_SERVERS{$key};

    # Register Apache2 Request handlers
    $r->push_handlers(PerlAccessHandler     => sub { $self->hAccess(shift) });
    $r->push_handlers(PerlAuthenHandler     => sub { $self->hAuthen(shift) });
    $r->push_handlers(PerlAuthzHandler      => sub { $self->hAuthz(shift) });
    $r->push_handlers(PerlTypeHandler       => sub { $self->hType(shift) });
    $r->push_handlers(PerlFixupHandler      => sub { $self->hFixup(shift) });
    $r->push_handlers(PerlResponseHandler   => sub { $self->hResponse(shift) });
    $r->push_handlers(PerlLogHandler        => sub { $self->hLog(shift) });
    $r->push_handlers(PerlCleanupHandler    => sub { $self->hCleanup(shift) });
    return $self->hInit($r);
}

#
# Default handlers
#

sub hInit { # Type: RUN_ALL
    my $self = shift;
    my $r = shift;

    # Variable data
    $self->set_svar(hitime  => getHiTime());
    $self->set_svar(sid     => getSID());

    # REST Method
    my $meth = uc($r->method() || 'GET');
    unless ($self->lookup_method($meth)) {
        $self->error(Apache2::Const::HTTP_METHOD_NOT_ALLOWED, sprintf("Method Not Allowed (%s)", $meth));
        return Apache2::Const::DECLINED;
    }

    # Init query object
    my $q = new CGI;
    $self->set(q => $q);

    # Init usr structure
    my %usr = ();
    foreach ($q->all_parameters) {
        next if $_ eq 'POSTDATA' or $_ eq 'PUTDATA' or $_ eq 'PATCHDATA';
        $usr{$_} = $q->param($_);
        Encode::_utf8_on($usr{$_});
    }
    $self->set(usr => \%usr);

    # Init request data from REQUEST in "as-is" format (req_data)
    my $req_data = $q->param($meth.'DATA') // $q->param('XForms:Model') // ''; # Fix: no data where content type is application/xml
    Encode::_utf8_on($req_data);
    $self->set(req_data => $req_data);

    # Set "is_exists" session variable
    $self->set_svar(is_exists => $self->lookup_handler ? 1 : 0);

    # Set debug session variable
    my $debug = 0;
    foreach ($self->get_attr("debug"), $self->get_dvar("debug")) {
        $_ //= "off";
        $debug = 1 if /(on)|(yes)|1/i;
        last if $debug;
    }
    $self->set_svar(debug => $debug);

    return Apache2::Const::OK;
}
sub hAccess { # Type: RUN_ALL
    my $self = shift;
    my $r = shift;
    $self->set_svar(remote_addr => $r->headers_in->get("x-real-ip") || $ENV{HTTP_X_REAL_IP} || $r->connection->remote_ip || $ENV{REMOTE_ADDR});
    return Apache2::Const::OK;
}
sub hAuthen { # Type: RUN_FIRST
    my $self = shift;
    my $r = shift;
    return Apache2::Const::DECLINED;
}
sub hAuthz { # Type: RUN_FIRST
    my $self = shift;
    my $r = shift;
    return Apache2::Const::DECLINED;
}
sub hType { # Type: RUN_FIRST
    my $self = shift;
    my $r = shift;

    my $meth = uc($r->method() || 'GET');
    my $is_get = $meth =~ /GET|HEAD/ ? 1 : 0;
    my $headers = $r->headers_in(); # APR::Table object

    # If content-type is predefined! Nothing to do
    my $content_type = $self->get_attr("content_type");
    if ($content_type) {
        $self->set_svar(format => _ctlookup($content_type) || FORMAT);
        $r->content_type($content_type);
        return Apache2::Const::OK;
    }

    # Content-Type Values from headers
    my $req_content_type = $headers->get("content-type") // '';
    my $req_accept = $headers->get("accept") // '';

    # Try get format from request header first and from the Accept header
    my $format = _ctlookup($req_content_type) || _ctlookup($req_accept);
    my $default_format = $format || FORMAT;
    my $default_content_type = $req_content_type || _format2ct($default_format) || CONTENT_TYPE;

    # If handler not exists
    unless ($self->get_svar("is_exists")) {
        $self->set_svar(format => $default_format);
        $r->content_type($default_content_type);
        return Apache2::Const::OK;
    }

    # If method is GET/HEAD and no need serialization (or handler is not found) --> set defaults!
    if ($is_get && !$self->get_attr("serialize")) {
        $self->set_svar(format => $default_format);
        $r->content_type($default_content_type);
        return Apache2::Const::OK;
    }

    # Return
    if ($format) { # The format detected correctly
        $self->set_svar(format => $format);
        $r->content_type(_format2ct($format));
    } else { # Format is not found
        $self->set_svar(format => $default_format);
        $r->content_type($default_content_type);
        return Apache2::Const::OK if $is_get;
        # Incorrect content type!
        $self->error(Apache2::Const::HTTP_UNSUPPORTED_MEDIA_TYPE,
            sprintf("Content-type %s is not supported", $req_content_type)) if $req_content_type;
    }

    return Apache2::Const::OK;
}
sub hFixup { # Type: RUN_ALL
    my $self = shift;
    my $r = shift;
    my $format = $self->get_svar("format");

    # Flash response data
    $self->set(res_data => "");

    # Serializer?
    return Apache2::Const::OK unless $self->get_attr("deserialize") || $self->get_attr("serialize");

    # Set Serializer
    $self->set_svar(serialize_attr => $self->get_attr("serialize_attr"));
    $self->set_svar(deserialize_attr => $self->get_attr("deserialize_attr"));
    my $serializer = new CTK::Serializer($format, attrs => $self->{_sr_attrs});
    return $self->_raise(sprintf("Can't use format %s for serializer", $format))
        unless $serializer->status;
    $self->set_svar(serializer => $serializer);

    # Deserialization (preparing input (request) data)
    return Apache2::Const::OK unless $self->get_attr("deserialize");
    my $req_data = $self->get("req_data");
    my $structure = $serializer->deserialize($format, $req_data, $self->get_svar("deserialize_attr") || $serializer->{deserialize_attr});
    $self->error(Apache2::Const::HTTP_BAD_REQUEST, $serializer->error) unless $serializer->status;
    $self->set(req_data => $structure);

    return Apache2::Const::OK;
}
sub hResponse { # Type: RUN_FIRST
    my $self = shift;
    my $r = shift;

    # Get serializers
    my $serialize = $self->get_attr("serialize");
    my $serializer = $self->get_svar("serializer");

    # Return errors if occurred
    unless ($self->status && $self->get_svar("is_exists")) {
        unless ($self->get_attr("deserialize") || $serialize) {
            my $format = $self->get_svar("format");
            $self->set_svar(serialize_attr => $self->get_attr("serialize_attr"));
            $self->set_svar(deserialize_attr => $self->get_attr("deserialize_attr"));
            $serializer = new CTK::Serializer($format, attrs => $self->{_sr_attrs});
            return $self->_raise(sprintf("Can't use format %s for serializer", $format))
                unless $serializer->status;
        }
        $serialize = 1;
    }

    # Dispatching
    $self->run_handler( $r ); # !! $r - Это параметры что будут переданы в обработчик

    # Get response data from RAMST handlers
    my $res_data = $self->get("res_data");
    if ($self->status) {
        unless ($res_data && length($res_data)) {
            $r->status(Apache2::Const::HTTP_NO_CONTENT);
            return Apache2::Const::OK;
        }
    }

    # Serialization (preparing output (response) data)
    my $output;
    if ($self->status) {
        if ($serialize) {
            $output = $serializer->serialize($self->get_svar("format"), $res_data, $self->get_svar("serialize_attr") || $serializer->{serialize_attr});
            $self->error(Apache2::Const::HTTP_INTERNAL_SERVER_ERROR, $serializer->error) unless $serializer->status;
        } else {
            $output = $res_data;
        }
    }

    # Return errors
    unless ($self->status) {
        $ENV{REDIRECT_ERROR_NOTES} = $self->error;
        $r->subprocess_env(REDIRECT_ERROR_NOTES => $self->error);
        $r->notes->set('error-notes' => $self->error);
        if ($serialize) {
            $output = $serializer->serialize($self->get_svar("format"), $self->error_response, $self->get_svar("serialize_attr") || $serializer->{serialize_attr});
            return $self->_raise($serializer->error) unless $serializer->status;
        } else {
            $output = $self->error;
        }
    }

    # Output
    $r->status($self->code);
    #$r->headers_out->set('Accept-Ranges', 'none');
    my $clength = length(Encode::encode_utf8($output)) || 0;
    if ($self->status) { $r->set_content_length($clength) }
    else {$r->err_headers_out()->add('Content-length', $clength)}

    # Return
    $r->print($output) if uc($r->method) ne "HEAD";
    $r->rflush();
    return Apache2::Const::OK;
}
sub hLog { # Type: RUN_ALL
    my $self = shift;
    my $r = shift;

    if ($self->get_svar("debug")) {
        my $msg = $self->_stamp($r->uri);
        if ($self->status) { $r->log->debug($msg) } else { $r->log->error($msg) }
    }

    return Apache2::Const::OK;
}
sub hCleanup { # Type: RUN_ALL
    my $self = shift;
    my $r = shift;
    $self->cleanup;
    return Apache2::Const::OK;
}

#
# Common methods
#
sub registered_servers {
    my $self = shift;
    return keys %_RAMST_SERVERS;
}
sub error_response {
    my $self = shift;
    return {
        error => {
            code    => $self->code,
            message => $self->error
        }
    }
}

#
# Internal methods
#

sub _raise { # Exceptions only! Sets all envs and returns SERVER_ERROR
    my $self = shift;
    my $errmsg = shift;
    my $r = Apache2::RequestUtil->request();
    $r->log->error(sprintf("%s:%s [%d]> %s", $self->prefix, $self->location || LOCATION, Apache2::Const::SERVER_ERROR, $errmsg));
    $r->notes->set('error-notes' => $errmsg);
    return Apache2::Const::SERVER_ERROR;
}

sub _stamp {
    my $self = shift;
    my $uri = shift;
    my $loc = LOCATION . $self->location;
    $loc =~ s/\/{2,}/\//g;
    my $path = LOCATION . ($self->get_svar("path") // "");
    $path =~ s/\/{2,}/\//g;
    my $err = $self->error ? sprintf("> %s", $self->error) : "";
    my $name = $self->get_svar("name") ? sprintf(" %s", $self->get_svar("name")) : "";
    sprintf("[%s %s] %s %s%s >>> %d %s in %.3f secs%s", $self->prefix, $loc,
        $self->get_svar("method") // "GET", $uri // $path,
        $name, $self->code, $self->status ? "OK" : "ERROR",
        (getHiTime() - $self->get_svar('hitime'))*1, $err);
}

sub _ctlookup {
    my $t = shift || return "";
    if    ($t =~ /xml/)        { return "xml" }
    elsif ($t =~ /json/)       { return "json" }
    elsif ($t =~ /yaml/)       { return "yaml" }
    elsif ($t =~ /plain|html/) { return FORMAT }
    else                       { return "" }
};

sub _format2ct {
    my $fmt = shift || FORMAT;
    FORMAT2CT->{$fmt} || CONTENT_TYPE;
}

1;

__END__
