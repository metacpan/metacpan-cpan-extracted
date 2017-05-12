package Drogo::Server::Nginx;
use strict;
use IO::File;

=head1 NAME

Drogo::Server::Nginx - Directly interface with Nginx using --with-http_perl_module

=head1 METHODS

Implements all methods in 'nginx' module provided with Nginx's --with-http_perl_module option.

=cut

use base qw(
    Drogo::Server
    nginx
);

my %request_data;

sub initialize
{
    my ($class, $obj) = @_;

    bless($obj, __PACKAGE__);

    %request_data = ();

    my $ip_header = $obj->variable('proxy_ip_header');

    if ($ip_header)
    {
        $request_data{remote_addr} = $obj->header_in($ip_header);
    }
    elsif (my $remote_addr = $obj->variable('remote_addr'))
    {
        $request_data{remote_addr} = $remote_addr;
    }
    else
    {
        $request_data{remote_addr} = $obj->SUPER::remote_addr;
    }

    return $obj;
}

sub remote_addr { $request_data{remote_addr} }

sub server_return
{
    my ($self, $what) = @_;

    return $what;
}

sub cleanup
{
    my $self = shift;

    # cleanup magical request file
    unlink($self->request_body_file)
        if $self->request_body_file;

    if ($request_data{tmp_file})
    {
        eval { $request_data{input_fh}->close };
        unlink($request_data{tmp_file});
    }

    %request_data = ();
}

sub tmpfilename { join('-', 'drogongxp', $$, time) }

=head2 input

Returns a filestream to the input.

=cut

sub input { $request_data{input_fh} }

my $request_body_method;

# This is a hack since Nginx's has_request_body returns a new
# 'nginx' object, opposed to a Drogo::Server::Nginx object

sub process_request_method ($&)
{
    my $self = shift; #nginx object, not this server object
    $request_body_method = shift;

    return $self->has_request_body(\&request_body_override);
}

sub request_body { $request_data{request_body} }    

sub request_body_override
{
    my $self = shift; #nginx object, not this server object
    __PACKAGE__->initialize($self); # rebless as this object

    my $tmpdir = $self->variable('tmpdir') ||  '/tmp';

    if ($self->request_body_file)
    {
        my $input = '';

        $request_data{input_fh} = IO::File->new('< ' . $self->request_body_file);
        $request_data{input_fh}->read($input, $self->post_limit)
            if $request_data{input_fh};
        $request_data{request_body} = $input;
    }

    unless ($request_data{input_fh})
    {
        $request_data{tmp_file} = $tmpdir . '/' . tmpfilename();

        my $wfh = IO::File->new('> ' . $request_data{tmp_file});
        $wfh->print($self->SUPER::request_body);
        $wfh->close;

        $request_data{input_fh} = IO::File->new('< ' . $request_data{tmp_file});

        my $input = '';
        $request_data{input_fh}->read($input, $self->post_limit);
        $request_data{request_body} = $input;
    }


    {
        no strict 'refs';
        return &$request_body_method($self);
    }
}

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

