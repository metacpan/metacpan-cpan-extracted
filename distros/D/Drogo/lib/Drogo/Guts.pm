package Drogo::Guts;
use strict;

use Exporter;
our @ISA     = qw(Exporter);

use constant OK                             => 0;
use constant DECLINED                       => -5;

use constant HTTP_OK                        => 200;
use constant HTTP_CREATED                   => 201;
use constant HTTP_ACCEPTED                  => 202;
use constant HTTP_NO_CONTENT                => 204;
use constant HTTP_PARTIAL_CONTENT           => 206;

use constant HTTP_MOVED_PERMANENTLY         => 301;
use constant HTTP_MOVED_TEMPORARILY         => 302;
use constant HTTP_REDIRECT                  => 302;
use constant HTTP_NOT_MODIFIED              => 304;

use constant HTTP_BAD_REQUEST               => 400;
use constant HTTP_UNAUTHORIZED              => 401;
use constant HTTP_PAYMENT_REQUIRED          => 402;
use constant HTTP_FORBIDDEN                 => 403;
use constant HTTP_NOT_FOUND                 => 404;
use constant HTTP_NOT_ALLOWED               => 405;
use constant HTTP_NOT_ACCEPTABLE            => 406;
use constant HTTP_REQUEST_TIME_OUT          => 408;
use constant HTTP_CONFLICT                  => 409;
use constant HTTP_GONE                      => 410;
use constant HTTP_LENGTH_REQUIRED           => 411;
use constant HTTP_REQUEST_ENTITY_TOO_LARGE  => 413;
use constant HTTP_REQUEST_URI_TOO_LARGE     => 414;
use constant HTTP_UNSUPPORTED_MEDIA_TYPE    => 415;
use constant HTTP_RANGE_NOT_SATISFIABLE     => 416;

use constant HTTP_INTERNAL_SERVER_ERROR     => 500;
use constant HTTP_SERVER_ERROR              => 500;
use constant HTTP_NOT_IMPLEMENTED           => 501;
use constant HTTP_BAD_GATEWAY               => 502;
use constant HTTP_SERVICE_UNAVAILABLE       => 503;
use constant HTTP_GATEWAY_TIME_OUT          => 504;
use constant HTTP_INSUFFICIENT_STORAGE      => 507;

use Drogo::Cookie;
use Drogo::MultiPart;

use Time::HiRes qw(gettimeofday tv_interval);

BEGIN { require 5.008004; }

# Export all @HTTP_STATUS_CODES
our @EXPORT = qw(
    OK
    DECLINED

    HTTP_OK
    HTTP_CREATED
    HTTP_ACCEPTED
    HTTP_NO_CONTENT
    HTTP_PARTIAL_CONTENT

    HTTP_MOVED_PERMANENTLY
    HTTP_MOVED_TEMPORARILY
    HTTP_REDIRECT
    HTTP_NOT_MODIFIED

    HTTP_BAD_REQUEST
    HTTP_UNAUTHORIZED
    HTTP_PAYMENT_REQUIRED
    HTTP_FORBIDDEN
    HTTP_NOT_FOUND
    HTTP_NOT_ALLOWED
    HTTP_NOT_ACCEPTABLE
    HTTP_REQUEST_TIME_OUT
    HTTP_CONFLICT
    HTTP_GONE
    HTTP_LENGTH_REQUIRED
    HTTP_REQUEST_ENTITY_TOO_LARGE
    HTTP_REQUEST_URI_TOO_LARGE
    HTTP_UNSUPPORTED_MEDIA_TYPE
    HTTP_RANGE_NOT_SATISFIABLE

    HTTP_INTERNAL_SERVER_ERROR
    HTTP_SERVER_ERROR
    HTTP_NOT_IMPLEMENTED
    HTTP_BAD_GATEWAY
    HTTP_SERVICE_UNAVAILABLE
    HTTP_GATEWAY_TIME_OUT
    HTTP_INSUFFICIENT_STORAGE

    dispatch
);

$SIG{__DIE__} = sub { &format_error(shift) };

# data for request
my %request_data;
my @error_stack;
my $die_error;

=head1 NAME

Drogo::Guts - Shared components used by framework.

=head1 SYNOPSIS

=cut

my %request_meta_data;

sub dispatch
{
    my ($r, %params) = @_;
    my $class        = $params{class};
    my $method       = $params{method};
    my $error        = $params{error};
    my $bless        = $params{bless};
    my $base_class   = $params{base_class};
    my $dispatch_url = $params{dispatch_url};
    my $post_args    = $params{post_args} || [ ];

    # perform server initialization magic
    $r->initialize($r);

    %request_meta_data = (
        call_class   => $class,
        call_method  => $method       || 'main',
        error        => $error        || '',
        bless        => $bless        || '',
        base_class   => $base_class   || '',
        dispatch_url => $dispatch_url || '',
        post_args    => ($post_args   || [ ]),
        server_class => ref($r),
    );

    &_store_request_meta_data($r);

    unless ($method eq 'error')
    {
        @error_stack = ( );
        $die_error   = q[];
    }

    return (not $error and $r and $r->can('process_request_method') and
        $r->process_request_method(\&handle_request_body)) 
            ? $r->server_return(OK)
            : &init_dispatcher($r);
}

sub cleanup
{
    if ($request_data{request_parts})
    {
        for my $part (@{$request_data{request_parts}})
        {
            next unless $part->{fh};

            # close each open fh
            eval { $part->{fh}->close };

            # unlink file
            unlink($part->{tmp_file});
        }
    }
}

=head1 METHODS

=head3 $self->server

Returns the server object.

=cut

sub server           { $request_data{server_object}        }
sub set_server       { $request_data{server_object} = $_[1] }

=head3 $self->uri

Returns the uri.

=cut

sub uri              { shift->server->uri                  }

=head3 $self->module_url

Returns the url associated with the module.

=cut

sub module_url
{
    my $self = shift;

    my @parts = split('/', $request_meta_data{'dispatch_url'});
    pop @parts;

    return join('/', @parts);
}

=head3 $self->filename

Returns the path filename.

=cut

sub filename         { shift->server->filename             }

=head3 $self->request_method

Returns the request_method.

=cut

sub request_method   { shift->server->request_method       }

=head3 $self->remote_addr

Returns the remote_addr.

=cut

sub remote_addr      { shift->server->remote_addr          }

=head3 $self->header_in

Return value of header_in.

=cut

sub header_in        { shift->server->header_in(@_)        }

sub rflush           { shift->server->rflush               }
sub flush            { shift->rflush                       }


=head3 $self->print(...)

Output via http.

=cut

sub print 
{
    my $self = shift;

    $request_data{output} .= join '', @_;
    return 1;
}

=head3 $self->auto_header

Returns true if set, otherwise args 1 sets true and 0 false.

=cut

sub auto_header
{
    my ($self, $arg) = @_;

    if (defined $arg)
    {
        if ($arg)
        {
            delete $request_data{disable_auto_header};
        }
        else	
        {
            $request_data{disable_auto_header} = 1;
        }
    }

    return(not exists $request_data{disable_auto_header});
}

=head3 $self->dispatching

Returns true if we're dispatching actively.

=cut

sub dispatching
{
    my ($self, $arg) = @_;

    if (defined $arg)
    {
        if ($arg)
        {
            delete $request_data{disable_dispatching};
        }
        else	
        {
            $request_data{disable_dispatching} = 1;
        }
    }

    return(not exists $request_data{disable_dispatching});
}

=head3 $self->header_set('header_type', 'value')

Set output header.

=cut

sub header_set 
{
    my ($self, $key, $value) = @_;

    $request_data{headers}{$key} = $value;
}

=head3 $self->header('content-type')

Set content type.

=cut

sub header
{
    my ($self, $value) = @_;

    __PACKAGE__->header_set('Content-Type', $value);
}

=head3 $self->headers

Returns hashref of response headers.

=cut

sub headers
{
    my ($self, $value) = @_;

    return $request_data{headers};
}

=head3 $self->location('url')

Redirect to a url (sets the Location header out).

=cut

sub location         { shift->header_set('Location', shift) }

=head3 $self->status(...)

Set output status... (200, 404, etc...)
If no argument given, returns status.

=cut

sub status 
{
    my ($self, $status) = @_;

    if ($status)
    {
        $request_data{status} = $status;
    }
    else
    {
        return $request_data{status};
    }
}

# map $self->log to print STDERR
sub log              { shift; print STDERR @_;             }

=head3 $self->request_part(...)

Returns reference for upload.

  {
     'filename' => 'filename',
     'tmp_file' => '/tmp/drogomp-23198-1330057261',
     'fh'       => \*{'Drogo::MultiPart::$request_part{...}'},
     'name'     => 'foo'
  }

=cut

sub request_part
{
    my ($self, $lookup_key) = @_;
    my @values;

    if ($request_data{request_parts})
    {
        for my $part (@{$request_data{request_parts}})
        {
            push @values, $part if $lookup_key eq $part->{name};
        }
    }

    return unless @values;    
    return (scalar @values == 1 ? $values[0] : @values);
}

=head3 $self->param(...)

Return a parameter passed via CGI--works like CGI::param.

=cut

sub param 
{
    my ($self, $lookup_key) = @_;
    
    my @values;
    my %seen_hash;
    my $request = $request_data{args};

    if ($request_data{request_parts})
    {
        for my $part (@{$request_data{request_parts}})
        {
            # don't return uploads here
            next if $part->{fh};

            if ($lookup_key)
            {
                push @values, __PACKAGE__->unescape($part->{data})
                    if $lookup_key eq $part->{name};
            }
            else
            {
                next if $seen_hash{$part->{name}}++;
                push @values, $part->{name};
            }
        }
    }
    else
    {
        my @args = split('&', $request);
        for my $arg (@args)
        {
            my ($key, $value) = split('=', $arg);
            
            if ($lookup_key)
            {
                push @values, __PACKAGE__->unescape($value)
                    if $lookup_key eq $key;
            }
            else
            {
                next if $seen_hash{$key}++;
                push @values, $key;
            }
        }
    }
    
    return unless @values;
    
    return (scalar @values == 1 ? $values[0] : @values);
}

=head3 $self->param_hash
    
Return a friendly hashref of CGI parameters.

=cut

sub param_hash
{
    my $self = shift;

    my %param_hash;
    
    for my $key (__PACKAGE__->param)
    {
        next if $param_hash{$key};
        
        my @params = __PACKAGE__->param($key);
        
        if (scalar @params == 1)
        {
            $param_hash{$key} = $params[0];
        }
        else
        {
            $param_hash{$key} = [ @params ],
        }
    }
    
    return \%param_hash;
}

=head3 $self->request_body & $self->request
    
Returns request body.

=cut

sub request_body { $request_data{request} }
sub request      { shift->request_body    }

=head3 $self->request_parts

Returns arrayref of request parts, used for multipart/form-data requests.

=cut

sub request_parts { $request_data{request_parts} || [] }

=head3 $self->args

Returns args.

=cut

sub args         { $request_data{args}    }

=head3 $self->matches

Returns array of post_arguments (matching path after a matched ActionMatch attribute)
Returns array of matching elements when used with ActionRegex.

=cut

sub matches   { @{ $request_data{post_args} || [ ] } }

=head3 $self->post_args

Same as matches, deprecated.

=cut

sub post_args   { @{ $request_data{post_args} || [ ] } }

sub handle_request_body
{
    my $r = shift;

    # reinflate $r if necessary
    &_inflate_request_meta_data($r);
    if (ref($r) ne $request_meta_data{server_class})
    {
        my $server_class = $request_meta_data{server_class};
        $server_class->initialize($r);
    }

    my $request_body = $r->request_body;
    my %params;

    # if no args are passed, assume they are in the post
    if (not $r->args and
        substr($request_body, 0, 1) ne '{' and
        index($request_body, "\n") == -1)
    {
        $params{args} = $request_body;
    }
    else # process multi-line data
    {
        # decode multi-part data
        $params{request_parts} = Drogo::MultiPart::process($r)
            if substr($request_body, 0, 1) eq '-';
    }

    return &init_dispatcher($r, %params);
}

sub init_dispatcher {
    my ($r, %params) = @_;

    %request_data = (
        headers       => { 'Content-Type' => 'text/html' },
        output        => q[],
        status        => 200,
        server_object => $r,
        request       => $params{request} || $r->request_body,
        args          => $params{args}    || $r->args,
        request_parts => $params{request_parts},
        begin_time    => [gettimeofday],
        post_args     => $request_meta_data{post_args},
    );

    my $class      = $request_meta_data{'call_class'};
    my $bless      = $request_meta_data{'bless'};
    my $base_class = $request_meta_data{'base_class'};
    my $method     = $request_meta_data{'call_method'};

    my $self = { };
    $bless ? bless($self, $class) : bless($self);

    my $sub_call = "$class\::$method";
    if (UNIVERSAL::can($class, $method))
    { 
        no strict 'refs';

        # pre-run sub, if defined
        my $init_class = $base_class || $class;
        if (UNIVERSAL::can($init_class, 'init') and not $method eq 'error')
        {
            no strict 'refs';
            eval {
                local $SIG{__DIE__} = sub { &format_error(shift) };
                if ($bless)
                {
                    $self->init;
                }
                else
                {
                    my $prerun_sub = "$init_class\::init";
                    $prerun_sub->($self);
                }
            };

            if ($@ and $@ ne "drogo-exit\n")
            {
                if ($method eq 'error')
                {
                    # you've got an error in your error handler
                    warn "Error in error handler... ($class\::error)\n";

                    return __PACKAGE__->init_error($sub_call);
                }

                # reset request data
                %request_data = (
                    %request_data,
                    headers       => { 'Content-Type' => 'text/html' },
                    output        => q[],
                    status        => 200,
                    server_object => $r,
                    request       => $params{request} || $r->request_body,
                    args          => $params{args}    || $r->args,
                    request_parts => $params{request_parts},
                );

                eval {
                    no strict 'refs';
                    local $SIG{__DIE__} = sub { &format_error(shift) };
                    if ($bless)
                    {
                        $self->error;
                    }
                    else
                    {
                        my $prerun_sub = "$init_class\::error";
                        $prerun_sub->($self);
                    }
                };

                if ($@ and $@ ne "drogo-exit\n")
                {
                    if ($method eq 'error')
                    {
                        # you've got an error in your error handler
                        warn "Error in error handler... ($class\::error)\n";

                        return __PACKAGE__->init_error($sub_call);
                    }
                }
                else
                {
                    __PACKAGE__->process_auto_header
                        if __PACKAGE__->auto_header and __PACKAGE__->dispatching;

                    # cleanup drogo internals from dispatch
                    &cleanup($r);
                    $r->cleanup;

                    return $r->server_return(OK);
                }
            }
        }

        my $error = $request_meta_data{'error'};

        if (__PACKAGE__->dispatching)
        {
            eval {
                no strict 'refs';
                local $SIG{__DIE__} = sub { &format_error(shift) };

                my @args;
                push @args, $error if $error;

                if ($bless)
                {
                    $self->$method(@args);
                }
                else
                {
                    $sub_call->($self, @args);
                }
            };

            if ($@ and $@ ne "drogo-exit\n")
            {
                if ($method eq 'error')
                {
                    # you've got an error in your error handler
                    warn "Error in error handler... ($class\::error)\n";

                    return __PACKAGE__->init_error($sub_call);
                }

                # reset request data
                %request_data = (
                    %request_data,
                    headers       => { 'Content-Type' => 'text/html' },
                    output        => q[],
                    status        => 200,
                    server_object => $r,
                    request       => $params{request} || $r->request_body,
                    args          => $params{args}    || $r->args,
                    request_parts => $params{request_parts},
                );

                eval {
                    no strict 'refs';
                    local $SIG{__DIE__} = sub { &format_error(shift) };
                    if ($bless)
                    {
                        $self->error;
                    }
                    else
                    {
                        my $prerun_sub = "$init_class\::error";
                        $prerun_sub->($self);
                    }
                };

                if ($@ and $@ ne "drogo-exit\n")
                {
                    if ($method eq 'error')
                    {
                        # you've got an error in your error handler
                        warn "Error in error handler... ($class\::error)\n";

                        return __PACKAGE__->init_error($sub_call);
                    }
                }
                else
                {
                    __PACKAGE__->process_auto_header
                        if __PACKAGE__->auto_header and __PACKAGE__->dispatching;

                    # cleanup drogo internals from dispatch
                    &cleanup($r);
                    $r->cleanup;

                    return $r->server_return(OK);
                }
            }
            else
            {
                # process all data
                __PACKAGE__->process_auto_header
                    if __PACKAGE__->auto_header and __PACKAGE__->dispatching;

                # post-run sub, if defined
                my $cleanup_class = $base_class || $class;
                if (UNIVERSAL::can($cleanup_class, 'cleanup') and $method ne 'error'
                    and __PACKAGE__->dispatching)
                {
                    eval {
                        no strict 'refs';
                        local $SIG{__DIE__} = sub { &format_error(shift) };
                        if ($bless)
                        {
                            $self->cleanup;
                        }
                        else
                        {
                            my $cleanup_sub = "$cleanup_class\::cleanup";
                            $cleanup_sub->($self);
                        }
                    };
                }
            }
        }

        undef $self;

        # cleanup drogo internals from dispatch
        &cleanup($r);
        $r->cleanup;

        return $r->server_return(OK);
    }
    else
    {
        return __PACKAGE__->init_error($r, $sub_call);
    }
}

=head3 detach

Stops processing and "exits"

=cut

sub detach { die "drogo-exit\n" }

=head3 process_auto_header

Process the autoheader.

=cut

sub process_auto_header
{
    my $self = shift;

    __PACKAGE__->server->status($self->status);
            
    my $content_type = delete $request_data{headers}{'Content-Type'};

    __PACKAGE__->server->header_out($_, $request_data{headers}{$_})
        for keys %{$request_data{headers}};

    __PACKAGE__->server->send_http_header($content_type);

    $request_data{headers}{'Content-Type'} = $content_type;

    __PACKAGE__->server->print($request_data{output});

    __PACKAGE__->flush;
}

sub format_error
{
    my $error  = shift;
    my @stack  = &make_error_stack;
    $die_error = $error;

    return if $error eq "drogo-exit\n";

    warn $error;

    for my $e (@stack)
    {
        warn "$e->{sub} called at $e->{file} line $e->{line}\n";
    }
}

=head3 error_stack

Returns the "error stack" as an array.

=cut

sub error_stack { @error_stack };

=head3 get_error

Returns error as string.

=cut

sub get_error   { $die_error   };

sub make_error_stack
{
    my @stack;
    my $i = 0;
    while (my @x = caller(++$i)) {
        push @stack, {
            pack => $x[0],
            file => $x[1],
            line => $x[2],
            sub  => $x[3],
        };
    }

    shift @stack;
    shift @stack;
    pop @stack;

    @error_stack = @stack;

    return @stack;
}

sub init_error
{
    my ($self, $r, $sub) = @_;
    
    # cleanup drogo internals from dispatch
    &cleanup($r);
    $r->cleanup;

    warn(__PACKAGE__ . qq[: '$sub' does not exist...\n]) 
        unless $sub =~ /error$/;

    return $r->server_return(HTTP_SERVER_ERROR);
}

=head3 $self->unescape

Unscape HTTP URI encoding.

=cut

sub unescape
{
    my ($self, $value) = @_;

    $value =~ s/\+/ /g;
    $value = __PACKAGE__->server->unescape($value);

    return $value;
}

=head3 $self->cookie

Cookie methods:

   $self->cookie->set(-name => 'foo', -value => 'bar');
   my %cookies = $self->cookie->read;

=cut

sub cookie { new Drogo::Cookie(shift) }

=head3 $self->elapsed_time

Returns elapsed time since initial dispatch.

=cut

sub elapsed_time { tv_interval($request_data{begin_time}, [gettimeofday]) }



sub _store_request_meta_data
{
    my $r = shift;

    # nginx needs to pass this data between threads
    $r->variable( $_ => $request_meta_data{$_} )
        for qw(call_class call_method error bless base_class dispatch_url server_class);

    # dragons
    $r->variable( post_args => join('|', @{$request_meta_data{post_args} || [ ]}) );
}

sub _inflate_request_meta_data
{
    my $r = shift;
    %request_meta_data = ( );
    $request_meta_data{$_} = $r->variable($_)
        for qw(call_class call_method error bless base_class dispatch_url server_class);
    $request_meta_data{post_args} = 
        [ split(/\|/, $r->variable('post_args')) ];
}

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
