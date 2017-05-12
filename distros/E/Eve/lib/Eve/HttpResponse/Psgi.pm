package Eve::HttpResponse::Psgi;

use parent qw(Eve::HttpResponse);

use utf8;
use strict;
use autodie;
use warnings;
use open qw(:std :utf8);
use charnames qw(:full);

use HTTP::Status;
use Encode ();
use Plack::Response ();

=head1 NAME

B<Eve::HttpResponse> - an HTTP response adapter.

=head1 SYNOPSIS

    use Eve::HttpResponse;

    my $response = Eve::HttpResponse->new(nph_mode => 0);

    $response->set_status(code => 302);
    $response->set_header(name => 'Location', value => '/other');
    $response->set_cookie(
        name => 'cookie1',
        value => 'value',
        domain => '.example.com',
        path => '/some/',
        expires => '+1d',
        secure = >1);
    $response->set_body(text => 'Hello world!');

    print $response->get_text();

=head1 DESCRIPTION

The class is an adapter for the Plack::Request module. It is used to
store the response data before it is being sent to the client.

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my $self = shift;

    $self->{'_psgi'} = Plack::Response->new(200);
    $self->SUPER::init();

    return;
}

=head2 B<set_header()>

Sets or overwrites an HTTP header of the response.

=head3 Arguments

=over 4

=item C<name>

=item C<value>

=back

=cut

sub set_header {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($name, $value));

    if ($name =~ /encoding|charset/i) {
        my $enc = Encode::find_encoding($value);
        if (not defined $enc) {
            Eve::Error::Value->throw(message => 'Unknown charset: '.$value);
        }
        $value = $enc->mime_name();
    }

    $self->_psgi->header($name => $value);

    return;
}

=head2 B<set_status()>

Sets or overwrites the HTTP response status.

=head3 Arguments

=over 4

=item C<code>

=back

=cut

sub set_status {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $code);

    $self->_psgi->status($code);

    return;
}

=head2 B<set_cookie()>

Sets an HTTP response cookie.

=head3 Arguments

=over 4

=item C<name>

=item C<value>

=item C<domain>

=item C<path>

=item C<expires>

(optional) a cookie expiration time in the epoch format

=item C<secure>

(optional) defaults to false

=back

=cut

sub set_cookie {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash,
        my ($name, $value), my $path = '/',
        my ($domain, $expires, $secure) = ((\undef) x 3));

    $self->_psgi->cookies->{$name} = {
        value => $value,
        path  => $path,
        domain => $domain,
        expires => $expires,
        secure => $secure
    };

    return;
}

=head2 B<set_body()>

Sets or overwrites the HTTP response body.

=head3 Arguments

=over 4

=item C<text>

=back

=cut

sub set_body {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my $text);

    use bytes;
    $self->_psgi->body($text);
    $self->_psgi->content_length(length $text);
    no bytes;

    return;
}

=head2 B<get_text()>

=head3 Returns

The HTTP response as text.

=cut

sub get_text {
    my $self = shift;

    my $result = $self->_psgi->finalize();
    my $headers = '';

    while(@{$result->[1]}) {
        my $name = shift(@{$result->[1]});
        my $value = shift(@{$result->[1]});

        $headers .= $name . ": " . $value . "\r\n";
    }

    return
        "Status: " . $result->[0] . " "
        . HTTP::Status::status_message($result->[0]) . "\r\n"
        . $headers . "\r\n"
        . join("\r\n", @{$result->[2]});
}

=head2 B<get_raw_list()>

=head3 Returns

The passthrough method for the Plack::Request C<finalize> method.

=cut

sub get_raw_list {
    my $self = shift;

    return $self->_psgi->finalize();
}

=head1 SEE ALSO

=over 4

=item C<Encode>

=item C<HTTP::Status>

=item C<Plack::Request>

=item C<Eve::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHORS

=over 4

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
