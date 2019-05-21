package MPMinus::RAMST; # $Id: RAMST.pm 274 2019-05-09 18:52:43Z minus $
use strict;
use warnings FATAL => 'all';
use utf8;

=encoding utf8

=head1 NAME

MPMinus::RAMST - RAMST Ain't an MVC SKEL Transaction

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use base qw/MPMinus::RAMST/;

    __PACKAGE__->register_handler( # GET /
        handler => "index",
        method  => "GET",
        path    => "/",
        query   => undef,
        deep    => 0,
        requires=> [qw/
                ADMIN USER TEST
            /],
        attrs   => {
                foo => 'test',
                bar => 1,
                baz => undef,
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

        $self->set( res_data => "Output scalar value" );
        $self->code( 200 );
        return 1; # Or 0 only!!
    });

    my $server = __PACKAGE__->new(
                request  => $r, # Apache2::RequestRec object
                location => "/rest",
                blank    => {
                        param1 => "init value"
                    },
                dvars    => { # Valid dir variables
                        key1 => "default value",
                        key2 => 0,
                    },
            );

    $server->run_handler( $m );

    $server->cleanup;

=head1 DESCRIPTION

Base class for not "MVC SKEL Transaction" model implementation

=head2 register_handler

    __PACKAGE__->register_handler( # GET /
        handler => "index",
        method  => "GET",
        path    => "/",
        query   => undef,
        deep    => 0,
        requires=> [qw/
                ADMIN USER TEST
            /],
        attrs   => {
                foo => 'test',
                bar => 1,
                baz => undef,
            },
        description => "Index",
        code    => sub {
        my $self = shift;
        my $name = shift;
        my $m = shift;
        my $r = $m->r;
        my $q = $self->get("q");
        my $usr = $self->get("usr");
        #my $req_data = $self->get("req_data");
        #my $res_data = $self->get("res_data");

        $self->set( res_data => "Output scalar value" );
        $self->code( 200 );
        return 1; # Or 0 only!!
    });

This is non class method! Sets new handler for trapping the request

=over 8

=item attrs

Sets attributes of the handler as hashref

Default: {}

In the future, you can get the attribute values using the get_attr("attr_name") method

=item code

Sets callback function

This callback function returns bool status of the operation

=item deep

Enables deeply scanning of path for handler lookup. If this param is set to true then the
mechanism of the deeply lookuping will be enabled. For example:

For registered path /foo with enabled deep lookuping will be matched any another
incoming path that begins from /foo prefix: /foo, /foo/bar, /foo/bar/baz and etc.

=item description

Sets the description of handler

Default: none

=item handler

Sets the name of handler

Default: noname

=item method

Sets the method for trapping. Supported: GET, POST, PUT, DELETE.

Default: GET

=item path

Sets the path for trapping

Default: /

Note: This is second (tailed) part of the full path - it's suffix.
Path not contents the base location string, e.g. without "/rest" prefix.
If you specify "/test/null", then the real path will be trapped "/rest/test/null" as path

=item query

Sets the query string for trapping

Default: undef

    Example #1: action=foo

Catch if the "action" parameter in query string equals "foo"

    Example #2: action=foo&object=bar

Catch if the "action" parameter in query string equals "foo" and "object" parameter equals "bar"

    Example #3: action=

Catch if the "action" parameter in query string equals any value

=item requires

Array-ref structure that contains list of roles or any data for authorization

Default: []

=back

=head2 new

    my $server = __PACKAGE__->new(
                prefix   => "MyTestApp",
                request  => $r, # Apache2::RequestRec object
                location => "/rest",
                blank    => {
                        param1 => "init value"
                    },
                dvars    => { # Valid dir variables
                        key1 => "default value",
                        key2 => 0,
                    },
            );

Constructor. Creates server instance by base location prefix (base attribute)

=over 8

=item B<blank>

The "blank" defines initial working structure for input and output variable data

=item B<dvars>

The key-value structure, that defines list of dir_config variables and default values for each

=item B<location>, B<base>

Location is a named part of the "Location" section in Apache's configuration file

=item B<prefix>

Prefix string. Default: current invocant class name

=item B<request>

Optional value of the Apache2::RequestRec object

=back

You can set and get data from the working structure using the "set" and "get" methods

=head2 cleanup

    $server->cleanup;

Cleans the all working data and sets it to blank structure

=head2 code

    my $code = $server->code;
    my $code = $server->code( 500 );

Gets/Sets response HTTP code

Default: 200 (OK)

=head2 data

    my $data = $server->data;
    $server->data({
            param1 => "new value",
        });

Gets/Sets working structure

Default: $self->{blank}

=head2 error

    my $error = $server->error;

Returns current error string

    my $status = $server->error( "new error string" );

Sets error string and returns status of the server

    my $status = $server->error( 500, "new error string" );

Sets response code and error string and returns status of the server

=head2 get

    my $value = $server->get("param1");

Returns parameter "param1" from working structure

=head2 get_attr

    my $value = $server->get_attr("foo");

Returns attribute "foo" from attributes of the current handler

=head2 get_dvar

    my $value = $server->get_dvar("key");

Returns dir config variable "key"

=head2 get_svar

    my $value = $server->get_svar("key");

Returns system variable "key"

=head2 init_svars

    $server->init_svars;

Takes current method, path and query string from request heads and sets
system "key" value for definition the current handler

=head2 location

    my $location = $server->location;

Returns base location of current server instance. Default: "" in root (default) context "/"

=head2 lookup_handler

    my $handler = $server->lookup_handler;
    my $handler = $server->lookup_handler("handler_name");

Returns $handler structure from hash of registered handlers; or undef if handler is not registered

=head2 lookup_method

    $server->lookup_method("GET"); # returns 1
    $server->lookup_method("OPTIONS"); # returns 0

Checks the availability of the method by its name and returns the status

=head2 prefix

    my $prefix = $server->prefix;

Returns prefix of current server instance. Default: invocant class name

=head2 requires

    my $requires = $server->requires; # [1, 2, 7]

Returns list as "array-ref" of requires for authorization from attributes of the current handler

=head2 run_handler

    $server->run_handler( $m ); # $m - this is MPMinus main object

Runs the callback function from current handler with $m parameter

Note: any number of parameters can be specified,
all of them will be receive in the callback function

Returns: server status

=head2 set

    $server->get("param1", "new value");

Sets new value to parameter "param1" in working structure and returns status of the operation

=head2 set_dvar

    $server->set_dvar("key", "new value");

Sets new value to dir config variable "key"


=head2 set_svar

    $server->set_svar("key", "new value");

Sets new value to system variable "key"

=head2 status

    my $status = $server->status;
    my $status = $server->status( $new_status );

Gets/Sets status of the server

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

C<mod_perl2>, L<MPMinus>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<MPMinus>, L<Apache2::REST>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
our $VERSION = '1.02';

BEGIN {strict::unimport(0, "subs") unless $ENV{MOD_PERL}}

use Apache2::Const -compile => qw/ :common :http /;
use Apache2::RequestUtil ();
use Apache2::URI;

use Carp;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use constant {
    METHODS => {
            GET     => 1,
            POST    => 1,
            PUT     => 1,
            DELETE  => 1,
            PATCH   => 1,
        },
    KEYMASK => "%s#%s#%s",
    QUERY_DEFAULT => "default",
};

my %ibuff; # Buffer for initializing

# Non class method
sub register_handler {
    my $class = shift; # Caller's class
    croak("Can't use reference in class name context") if ref($class);
    my %info = @_;
    $ibuff{$class} = {} unless exists($ibuff{$class});
    my $handlers = $ibuff{$class};

    # Method & Path & Query
    my $meth = $info{method} || "GET";
    $meth = "GET" unless grep {$_ eq $meth} keys %{(METHODS())};
    my $path = $info{path} || "/"; # Root
    $path =~ s/\/+$//;
    $path ||= "/";
    my $query = $info{query} || QUERY_DEFAULT;
    my $name = $info{handler} || "noname";
    my $code = $info{code} || sub {return 1};
    my $attrs = $info{attrs} && is_hash($info{attrs}) ? $info{attrs} : {};
    my $description = $info{description} || "";
    my $deep = $info{deep} || 0;
    my $requires = array($info{requires} || []);

    my $key = sprintf(KEYMASK, $meth, $path, $query);
    if ($handlers->{$key}) {
        my $tname = $handlers->{$key}{name} || "noname";
        return 0 if $tname ne $name;
    }

    $handlers->{$key} = {
            method  => $meth,
            path    => $path,
            query   => $query,
            name    => $name,
            code    => $code,
            deep    => $deep,
            requires=> $requires,
            attrs   => $attrs,
            description => $description,
        };
    return 1;
}

sub new {
    my $class = shift;
    my %opts = @_;

    # Blank structure
    my $blank = $opts{blank} && is_hash($opts{blank}) ? $opts{blank} : {};
    my %props = (
            class   => $class,
            prefix  => $opts{prefix} || $class,
            error   => '',
            status  => 1,
            code    => Apache2::Const::HTTP_OK,
            location=> $opts{location} || $opts{base} || $opts{location_base} || "",
            stamp   => sprintf("[%d] %s at %s", $$, $class, scalar(localtime(time()))),
            blank   => {%$blank},
            data    => {%$blank},
            dvars   => {}, # Dir variables (Apache2::ServerUtil dir_config)
            svars   => {}, # Session variables
            handlers=> exists($ibuff{$class}) ? $ibuff{$class} : {},
        );
    #$ibuff{$class} = {};
    my $self = bless { %props }, $class;

    # Get $r
    my $r = $opts{request} || $opts{r} || Apache2::RequestUtil->request();
    unless ($r) {
        $self->error(Apache2::Const::HTTP_BAD_REQUEST, "The request() method is only available if PerlOptions +GlobalRequest");
        return $self;
    }

    # Init dvars
    my $valid_dvars = $opts{dvars} || $opts{valid_dvars};
    if ($valid_dvars && ref($valid_dvars) eq 'HASH') {
        my %tmp;
        my %Config = %$valid_dvars;
        while(my ($key, $val) = each %Config) {
            $tmp{$key} = $r->dir_config($key) // $val;
        }
        $self->{dvars} = {%tmp};
    }

    return $self;
}
sub location {
    my $self = shift;
    return $self->{location};
}
sub prefix {
    my $self = shift;
    return $self->{prefix};
}
sub status {
    my $self = shift;
    my $value = shift;
    return fv2zero($self->{status}) unless defined($value);
    $self->{status} = $value ? 1 : 0;
    return $self->{status};
}
sub error {
    my $self = shift;
    my ($code, $value);
    $code = shift if scalar(@_) > 1;
    $value = shift;
    return uv2null($self->{error}) unless defined($value);
    $self->{error} = $value;
    $self->status($value ne "" ? 0 : 1);
    $self->code($code) if defined($code);
    return $self->status;
}
sub code {
    my $self = shift;
    my $value = shift;
    return fv2zero($self->{code}) unless defined($value);
    $self->{code} = $value || Apache2::Const::HTTP_OK;
    return $self->{code};
}
sub data {
    my $self = shift;
    my $struct = shift;
    return $self->{data} unless defined($struct);
    $self->{data} = $struct;
    return 1;
}
sub get {
    my $self = shift;
    my $name = shift;
    return undef unless defined $name;
    my $data = $self->data;
    return undef unless defined $data->{$name};
    return $data->{$name};
}
sub set {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    return 0 unless defined $name;
    my $data = $self->data;
    $data->{$name} = $value;
    return 1;
}
sub lookup_method {
    my $self = shift;
    my $meth = shift;
    return 0 unless $meth;
    return 1 if $meth eq 'HEAD';
    my $meths = METHODS;
    return $meths->{$meth} ? 1 : 0;
}
sub lookup_handler {
    my $self = shift;
    my $name = shift; # ...by name
    my $handlers = $self->{handlers};
    unless ($name) { # ...by svars (auto)
        $self->init_svars || return undef;
        my $key = $self->get_svar("key");
        #printf STDERR "!!!!!!!!! Key: %s\n", $key;
        if ($handlers->{$key} && $handlers->{$key}{name}) { # ...by key
            return $handlers->{$key}
        } else { # ...by path
            my $query = $self->get_svar("query") || QUERY_DEFAULT;
            foreach my $p (_scan_backward($self->get_svar("path"))) {
                #printf STDERR ">>> %s\n", $p;
                my $qr = $query;
                my @catched = ();
                foreach my $k (keys %$handlers) {
                    if ($handlers->{$k} && defined($handlers->{$k}{query})) {
                        my $rndr = $handlers->{$k};
                        next unless $self->get_svar("method") eq ($rndr->{method} || "GET");
                        next unless $p eq ($rndr->{path} || "/");
                        my $rq = $rndr->{query} || QUERY_DEFAULT;
                        if ($rq eq QUERY_DEFAULT) {
                            push @catched, QUERY_DEFAULT;
                        } else {
                            unshift @catched, $rq;
                        }
                    }
                }
                foreach my $chd (@catched) {
                    if (_test_qs($qr, $chd)) {
                        $qr = $chd;
                        last;
                    }
                }
                my $key = sprintf(KEYMASK, $self->get_svar("method"), $p, $qr);
                #printf STDERR ">>> %s\n", $key;
                return $handlers->{$key} if $handlers->{$key} && $handlers->{$key}{name} && $handlers->{$key}{deep};
            }
        }
        return undef;
    }
    foreach my $k (keys %$handlers) {
        return $handlers->{$k}
            if $handlers->{$k} && $handlers->{$k}{name} && $handlers->{$k}{name} eq $name
    }
    return undef;
}
sub get_attr {
    my $self = shift;
    my $name = shift;
    return undef unless defined $name;
    my $handler = $self->lookup_handler || return undef;
    return undef unless defined $handler->{attrs}{$name};
    return $handler->{attrs}{$name};
}
sub requires {
    my $self = shift;
    my $handler = $self->lookup_handler || return [];
    return [] unless defined $handler->{requires};
    return $handler->{requires};
}
sub init_svars { # Setup session varaiables only
    my $self = shift;
    return 1 if $self->get_svar("key");
    my $r = Apache2::RequestUtil->request();
    return $self->error(Apache2::Const::HTTP_BAD_REQUEST, "The request() method is only available if PerlOptions +GlobalRequest") unless $r;

    # 1. Method
    my $meth = uc($r->method || "GET");
    $meth = "GET" if $meth eq 'HEAD';
    return $self->error(Apache2::Const::HTTP_METHOD_NOT_ALLOWED, sprintf("The %s method not allowed", $meth)) unless $self->lookup_method($meth);
    $self->set_svar(method => $meth);

    # 2. Request uri (path)
    my $location = $self->{location};
    my $ruri = $r->uri || ""; $ruri =~ s/\/+$//;
    my $idx = index($ruri, $location);
    my $path = ($idx >= 0) ? substr($ruri, $idx + length($location)) : '/'; $path ||= "/";
    $self->set_svar(path => $path);

    # 3. Query string
    my $query = $r->args() || QUERY_DEFAULT;
    my $handlers = $self->{handlers};
    my @catched = ();
    foreach my $k (keys %$handlers) {
        if ($handlers->{$k} && defined($handlers->{$k}{query})) {
            my $rndr = $handlers->{$k};
            my $md = $rndr->{method} || "GET";
            next unless $meth eq $md;
            my $ph = $rndr->{path} || "/";
            next unless $path eq $ph;
            my $rq = $rndr->{query} || QUERY_DEFAULT;
            if ($rq eq QUERY_DEFAULT) {
                push @catched, QUERY_DEFAULT;
            } else {
                unshift @catched, $rq;
            }
        }
    }
    #$self->set(CATCHED => \@catched);
    foreach my $chd (@catched) {
        if (_test_qs($query, $chd)) {
            $query = $chd;
            last;
        }
    }
    $self->set_svar(query => $query);

    # 4. Key for searching
    my $key = sprintf(KEYMASK, $meth, $path, $query);
    $self->set_svar(key => $key);

    return 1;
}
sub get_svar {
    my $self = shift;
    my $name = shift;
    return undef unless defined $name;
    return undef unless defined $self->{svars}{$name};
    return $self->{svars}{$name};
}
sub set_svar {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    return 0 unless defined $name;
    $self->{svars}{$name} = $value;
    return 1;
}
sub get_dvar {
    my $self = shift;
    my $name = shift;
    return undef unless defined $name;
    return undef unless defined $self->{dvars}{$name};
    return $self->{dvars}{$name};
}
sub set_dvar {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    return 0 unless defined $name;
    $self->{dvars}{$name} = $value;
    return 1;
}
sub run_handler {
    my $self = shift;
    return 0 unless $self->status;
    $self->init_svars || return $self->status;
    my $key = $self->get_svar("key");

    # Lookup handler
    my $handler = $self->lookup_handler;
    return $self->error(Apache2::Const::HTTP_NOT_FOUND, sprintf("RAMST Handler \"%s\" not found", $key)) unless $handler;
    my $name = $handler->{name};
    return $self->error(Apache2::Const::HTTP_NOT_EXTENDED, sprintf("Invalid RAMST handler \"%s\"", $key)) unless $name;
    my $code = $handler->{code};
    return $self->error(Apache2::Const::HTTP_NOT_IMPLEMENTED, sprintf("Invalid RAMST handler \"%s\". Code not defined for %s handler", $key, $name))
        unless $code && ref($code) eq 'CODE';

    # Run!
    my $status = &$code($self, $name, @_);

    # Set name in svars for later using
    $self->set_svar(name => $name);

    return $self->status($status);
}
sub cleanup {
    my $self = shift;
    $self->error("","");
    $self->{svars} = {};
    my $blank = $self->{blank};
    $self->data({%$blank});
}

sub _test_qs {
    my $where = shift || QUERY_DEFAULT; # Gdzie? (from real user request)
    my $what  = shift || QUERY_DEFAULT; # Co? (from meta data in handler)
    return 1 if $what eq QUERY_DEFAULT; # Jesli nie ma zadnych QS w mecie
    return 0 if $where eq QUERY_DEFAULT; # Jesli nie ma zadnych QS w zaproszie

    my @whats = _parse_qs($what);
    my @wheres = _parse_qs($where);
    my $cnt = scalar(@whats) || 0;
    foreach my $wt (@whats) {
        foreach my $wr (@wheres) {
            if (($wt =~ /\=$/) && index($wr,$wt) == 0) {
                $cnt--;
                last;
            }
            if ($wt eq $wr) {
                $cnt--;
                last;
            }
        }
    }
    return 1 unless $cnt;
    return 0;
}
sub _parse_qs {
    my $tosplit = shift;
    my @ret;
    my(@pairs) = split(/[&;]/,$tosplit);
    my($param,$value);
    for (@pairs) {
        ($param,$value) = split('=',$_,2);
        next unless defined $param;
        $value //= '';
        $param = Apache2::URI::unescape_url($param);
        $value = Apache2::URI::unescape_url($value);
        push @ret, sprintf("%s=%s",$param,$value);
    }
    return @ret;
}
sub _scan_backward { # Returns for /foo/bar/baz array: /foo/bar/baz, /foo/bar, /foo, /
    my $p = shift // '';
    my @out = ($p) if length($p) && $p ne '/';
    while ($p =~ s/\/[^\/]+$//) {
        push @out, $p if length($p)
    }
    push @out, '/';
    return @out;
}

1;

__END__
