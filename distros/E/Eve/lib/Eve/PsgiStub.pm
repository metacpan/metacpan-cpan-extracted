package Eve::PsgiStub;

use strict;
use warnings;

use Eve::RegistryStub;

use Eve::HttpRequest::Psgi;
use Eve::Registry;

=head1 NAME

B<Eve::PsgiStub> - a stub class to easily create mock versions of HTTP requests.

=head1 SYNOPSIS

    use Eve::PsgiStub;

    my $request = Eve::PsgiStub->get_request(
        'method' => $method_string,
        'uri' => $uri_string,
        'host' => $domain_strin,
        'query' => $query_string,
        'cookie' => $cookie_string);

=head1 DESCRIPTION

B<Eve::PsgiStub> is a helper abstract factory class that generates
HTTP requests for making tests easier.

=head1 METHODS

=head2 B<get_request()>

Returns a B<Eve::HttpRequest::Psgi> object based on arguments. All
arguments are optional.

=head3 Arguments

=over 4

=item C<uri>

a request URI part string, defaults to C</>,

=item C<host>

a request host string, defaults to C<example.localhost>,

=item C<query>

a request URI query string part, defaults to an empty string,

=item C<method>

a request method string, defaults to C<GET>

=item C<body>

a request body, defaults to an empty string

=item C<cookie>

a request C<Set-Cookie> string, defaults to an empty string,

=item C<content_type>

a request C<content-type> string, defaults to an empty string.

=back

=cut

sub get_request {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(
        \%arg_hash,
        my $uri = '/',
        my $host = 'example.localhost',
        my $query = '',
        my $method = 'GET',
        my $body = '',
        my $cookie = '',
        my $content_type = \undef);

    my $env_hash = {
        'psgi.multiprocess' => 1,
        'SCRIPT_NAME' => '',
        'PATH_INFO' => $uri,
        'HTTP_ACCEPT' =>
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'REQUEST_METHOD' => $method,
        'psgi.multithread' => '',
        'SCRIPT_FILENAME' => '/var/www/some/path',
        'SERVER_SOFTWARE' => 'Apache/2.2.20 (Ubuntu)',
        'HTTP_USER_AGENT' => 'Mozilla/5.0 Gecko/20100101 Firefox/9.0.1',
        'REMOTE_PORT' => '53427',
        'QUERY_STRING' => $query,
        'SERVER_SIGNATURE' => '<address>Apache/2.2.20 Port 80</address>',
        'HTTP_CACHE_CONTROL' => 'max-age=0',
        'HTTP_ACCEPT_LANGUAGE' => 'en-us,en;q=0.7,ru;q=0.3',
        'HTTP_X_REAL_IP' => '127.0.0.1',
        'psgi.streaming' => 1,
        'MOD_PERL_API_VERSION' => 2,
        'PATH' => '/usr/local/bin:/usr/bin:/bin',
        'GATEWAY_INTERFACE' => 'CGI/1.1',
        'psgi.version' => [ 1, 1 ],
        'DOCUMENT_ROOT' => '/var/www/some/other/path',
        'psgi.run_once' => '',
        'SERVER_NAME' => $host,
        'SERVER_ADMIN' => '[no address given]',
        'HTTP_ACCEPT_ENCODING' => 'gzip, deflate',
        'HTTP_CONNECTION' => 'close',
        'HTTP_ACCEPT_CHARSET' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
        'SERVER_PORT' => '80',
        'HTTP_COOKIE' => $cookie,
        'REMOTE_ADDR' => '127.0.0.1',
        'SERVER_PROTOCOL' => 'HTTP/1.0',
        'HTTP_X_FORWARDED_FOR' => '127.0.0.1',
        'psgi.errors' => *STDERR,
        'REQUEST_URI' => $uri . (length $query ? '?' . $query : ''),
        'psgi.nonblocking' => '',
        'SERVER_ADDR' => '127.0.0.1',
        'psgi.url_scheme' => 'http',
        'HTTP_HOST' => $host,
        'psgi.input' =>
            bless( do{ \ (my $o = '140160744829088')}, 'Apache2::RequestRec'),
        'MOD_PERL' => 'mod_perl/2.0.5'};

    if ($method eq 'POST' and defined $body and length $body) {
        $env_hash = {
            %{$env_hash},
            'CONTENT_LENGTH' => length $body,
            'CONTENT_TYPE' =>
                'application/x-www-form-urlencoded; charset=UTF-8',
            'psgix.input.buffered' => 1,
            'psgi.input' => FileHandle->new(\ $body, '<')};
    }

    if (defined $content_type) {
        $env_hash = {
            %{$env_hash},
            'CONTENT_TYPE' => $content_type . '; charset=UTF-8'};
    }

    my $registry = Eve::Registry->new();

    return Eve::HttpRequest::Psgi->new(
        uri_constructor => sub {
            return $registry->get_uri(@_);
        },
        env_hash => $env_hash);
}

=head1 SEE ALSO

=over 4

=item L<Eve::Test>

=item L<Test::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Sergey Konoplev, Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;
