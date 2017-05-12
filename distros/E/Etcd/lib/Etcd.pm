package Etcd;
$Etcd::VERSION = '0.004';
# ABSTRACT: Client library for etcd

use namespace::autoclean;

use HTTP::Tiny 0.014;
use URI::Escape qw(uri_escape);
use Carp qw(croak);

use Moo;
use Type::Utils qw(class_type);
use Types::Standard qw(Str Int Bool HashRef);

has host => ( is => 'ro', isa => Str, default => '127.0.0.1' );
has port => ( is => 'ro', isa => Int, default => 4001 );

has ssl => ( is => 'ro', isa => Bool, default => 0 );

has http => ( is => 'lazy', isa => class_type('HTTP::Tiny') );
sub _build_http { HTTP::Tiny->new };

has version_prefix => ( is => 'ro', isa => Str, default => '/v2' );

has _url_base => ( is => 'lazy' );
sub _build__url_base {
    my ($self) = @_;
    ($self->ssl ? 'https' : 'http') .'://'.$self->host.':'.$self->port;
}

sub _prep_url {
    my ($self, $path, %args) = @_;
    my $trailing = $path =~ m{/$};
    my $url = $self->_url_base.join('/', map { uri_escape($_) } split('/', $path));
    $url .= '/' if $trailing;
    $url .= '?'.$self->http->www_form_urlencode(\%args) if %args;
    $url;
}

sub api_exec {
    my ($self, $path, $method, %args) = @_;
    my $res = $self->http->request($method, $self->_prep_url($path, %args));
    $res = $self->http->request($method, $res->{headers}->{location})
        if $res && $res->{status} eq 307;
    return $res if $res->{success};
    croak "$res->{status} $res->{reason}: $res->{content}" if $res->{status} >= 500;
    require Etcd::Error;
    die Etcd::Error->new_from_http($res);
}

sub server_version {
    my ($self) = @_;
    my $res = $self->api_exec('/version', 'GET');
    $res->{content};
}

with 'Etcd::Keys';
with 'Etcd::Stats';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Etcd - Client library for etcd

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Etcd;
    my $etcd = Etcd->new;
    
    say "server version: ".$etcd->server_version;
    
    # Key space API
    # See Etcd::Keys for more info
    $etcd->set("/message", "hello world");
    say "message is: ".$etcd->get("/message")->node->value;
    
    # Stats API
    # See Etcd::Stats for more info
    say "leader is: ".$etcd->stats("leader")->{leader};

=head1 DESCRIPTION

This is a client library for accessing and manipulating data in an etcd
cluster. It targets the etcd v2 API.

This module is quite low-level. You're expected to have a good understanding of
etcd and its API to understand the methods this module provides. See L</SEE
ALSO> for further reading.

=head1 METHODS

=head2 new

    my $etcd = Etcd->new( %args );

This constructor returns a new Etcd object. Valid arguments include:

=over 4

=item *

C<host>

Hostname or IP address of an etcd server (default: C<127.0.0.1>)

=item *

C<port>

Port where the etcd server is listening (default: C<4001>)

=item *

C<ssl>

Use SSL/TLS (ie HTTPS) when talking to the etcd server (default: off)

=item *

C<http>

A C<HTTP::Tiny> object to use to access the server. If not specified, one will
be created

=back

=head2 server_version

    my $version = $etcd->server_version;

Queries and returns the server version as a string.

=head1 ENDPOINTS

Individual API endpoints are implemented in separate modules. See the documentation for the following modules for more information:

=over 4

=item *

L<Etcd::Keys> - Key space API

=item *

L<Etcd::Stats> - Stats API

=back

=head1 SEE ALSO

=over 4

=item *

L<HTTP::Tiny> - for further HTTP client configuration, especially SSL configuration

=item *

L<https://github.com/coreos/etcd> - etcd source and documentation

=item *

L<https://coreos.com/docs/distributed-configuration/etcd-api/> - etcd API documentation

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report bugs or feature requests through the issue tracker at
L<https://github.com/robn/p5-etcd/issues>. You will be notified automatically
of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/p5-etcd>

  git clone https://github.com/robn/p5-etcd.git

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=item *

Matt Harrington

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
