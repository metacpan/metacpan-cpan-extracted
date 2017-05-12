package Drogo::Server::PSGI;
use strict;
use URI::Escape;
use PSGI;
use IO::File;

use base 'Drogo::Server';

my %SERVER_VARIABLES;

=head1 NAME

Drogo::Server::PSGI - Implement a Drogo PSGI application.

=head1 METHODS

=head3 new 

Create a new server instance.

Parameters:
    respond => response object,

Example app.psgi file.

  my $app = sub {
      my $env = shift;

      return sub {
          my $respond = shift;

          # create new server object
          my $server = Drogo::Server::PSGI->new( env => $env, respond => $respond );

          # set default application package
          $server->variable( app_package => 'dev' );

          # do something with server...
          Example::App->handler( server  => $server );
      }
  };


=cut

sub new
{
    my ($class, %params) = @_;

    my $self = { %params, output => '' };

    %SERVER_VARIABLES = ( );

    my ($path, $args) = split(/\?/, $self->{env}{REQUEST_URI});
    $self->{uri}  = $path;
    $self->{args} = $args || '';
    $self->{request_method}     = $self->{env}{REQUEST_METHOD};
    $self->{remote_addr}        = $self->{env}{REMOTE_ADDR};

    # set proper headers_in
    for my $env_key (keys %{$self->{env}})
    {
        if ($env_key =~ /^HTTP_(.*)$/)
        {
            my $header = lc($1);
            $self->{headers_in}{$header} = $self->{env}{$env_key};

            # map dashes too
            $header =~ s/_/-/g;
            $self->{headers_in}{$header} = $self->{env}{$env_key};
        }
    }

    $self->{respond} = $params{respond};

    # content type needs manually set
    $self->{headers_in}{'content-type'} =
        $self->{env}{CONTENT_TYPE};

    bless($self);

    return $self;
}

=head3 initialize

Initializes Drogo instance.

=cut

sub initialize
{
    my $self = shift;
    my $ip_header = $self->variable('proxy_ip_header');

    if ($ip_header)
    {
        $self->{remote_addr} = $self->header_in($ip_header);
    }
    elsif (my $remote_addr = $self->variable('remote_addr'))
    {
        $self->{remote_addr} = $remote_addr;
    }
    else
    {
        $self->{remote_addr} = $self->{env}{REMOTE_ADDR};
    }
}

sub tmpfilename { join('-', 'drogopsgip', $$, time) }

=head3 input

Returns input stream.

=cut

sub input { shift->{input_fh} }

=head3 process_request_method

Processes a post.

=cut

sub process_request_method
{
    my ($self, $coderef) = @_;

    return unless $self->{request_method} eq 'POST';

    # copy post data to temporary file
    my $input = $self->{env}{'psgi.input'};
    my $tmpdir = $self->variable('tmpdir') ||  '/tmp';

    # PSGI's Apache gateway lacks seek.
    if ($input->can('seek'))
    {
        $self->{input_fh} = $input;
    }
    else
    {
        $self->{tmp_file} = $tmpdir . '/' . tmpfilename();
        my $fh = IO::File->new('> ' . $self->{tmp_file});

        my $buffer;
        $fh->print($buffer) while($input->read($buffer, 1024));
        $fh->close;

        $self->{input_fh} = IO::File->new('< ' . $self->{tmp_file});
    }

    my $input = '';
    $self->{input_fh}->read($input, $self->post_limit);

    $self->{request_body} = $input;

    &$coderef($self);

    return 1;
}

=head3 cleanup

Cleanup processing.

=cut

sub cleanup
{
    my $self = shift;

    if ($self->{tmp_file})
    {
        eval { $self->{input_fh}->close };
        unlink($self->{tmp_file});
    }
}

=head3 variable(key => $value)

Returns a persistant server variable.

Key without value returns variable.

These include variables set by the server configuration, as "user variables" in nginx.

=cut

sub variable
{
    my ($self, $key, $value) = @_;

    if ($value)
    {
        $SERVER_VARIABLES{$key} = $value;
    }
    else
    {
        return $SERVER_VARIABLES{$key};
    }
}

=head3 uri

Returns the uri.

=cut

sub uri { shift->{uri} }

=head3 args

Returns string of arguments.

=cut

sub args { shift->{args} }

=head3 request_body

Returns the request body (used for posts)

=cut

sub request_body { shift->{request_body} }

=head3 request_method

Returns the request method (GET or POST)

=cut

sub request_method   { shift->{request_method} || 'GET' }

=head3 remote_addr

Returns remote address.

=cut

sub remote_addr
{
    my $self = shift;

    return $self->{remote_addr} || '127.0.0.1';
}

=head3 has_request_body

Used by nginx for request body processing.

This function is only called when the request method is a post,
in an effort to reduce processing time.

=cut

sub has_request_body { }

=head3 header_in

Returns a request header.

=cut

sub header_in
{
    my ($self, $what) = @_;

    return $self->{headers_in}{lc($what)};
}

=head3 header_out

Sets a header out.

=cut

sub header_out
{
    my ($self, $header, $value) = @_;

    return $self->{headers_out}{$header} = $value;
}

=head3 send_http_header

Send the http header.

=cut

sub send_http_header
{
    my ($self, $header) = @_;

    if ($self->{writer})
    {
        die 'PSGI: respond already called';
    }
    elsif ($self->{respond})
    {
        $self->{writer} =
            $self->{respond}->([ ($self->status || 200), [
                'Content-Type' => $header,
                %{$self->{headers_out} || {}}
            ]]);
    }
    else
    {
        $self->{http_header} = $header;
    }
}

=head3 $self->status(...)

Set output status... (200, 404, etc...)
If no argument given, returns status.

=cut

sub status 
{
    my ($self, $status) = @_;

    if ($status)
    {
        $self->{status} = $status;
    }
    else
    {
        return $self->{status};
    }
}

=head3 print

Print stuff to the http stream.

=cut

sub print {
    my ($self, $line) = @_;

    if ($self->{writer})
    {
        $self->{writer}->write($line);
    }
    else
    {
        $self->{output} .= $line;
    }
}

sub rflush { }

=head3  sleep

Sleeps (used by nginx), not needed for other server implementations.

=cut

sub sleep
{
    my $self = shift;
    sleep(shift);
}

=head3 header_only

Returns true of only the header was requested.

=cut

sub header_only { 0 }

sub server_returns_object { 1 }

=head3 unescape

Unescape an encoded uri.

=cut

sub unescape
{
    my ($self, $string) = @_;

    return uri_unescape($string);
}

=head3 server_return

This function defines what is returned to the server at the end of a dispatch.
For nginx, this will be a status code, but in this test implementation we're
returning the actual server object itself, so we can evaluate it while testing

=cut

sub server_return
{
    my ($self, $what) = @_;

    my $rstatus      = $self->{status} || 200;
    my $content_type = $self->{http_header};

    if ($self->{writer})
    {
        $self->{writer}->close;
    }
    else
    {
        return [
            $rstatus,
            [ 
              'Content-Type' => $content_type, 
              %{$self->{headers_out} || {}}
            ],
            [ $self->{output} ],
        ];
    }
}

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

