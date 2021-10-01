package Geonode::Free::Proxy;

use 5.010;
use strict;
use warnings;
use Carp 'croak';

=head1 NAME

Geonode::Free::Proxy - Geonode's Proxy Object returned by Geonode::Free::ProxyList

Note: this a companion module for Geonode::Free::ProxyList

=head1 VERSION

Version 0.0.5

=cut

our $VERSION = '0.0.5';

my $preferred_method = 'socks';

=head1 SYNOPSIS

Geonode's Proxy Object returned by Geonode::Free::ProxyList

    my $some_proxy = Geonode::Free::Proxy->new(
        'some-id',
        '127.0.0.1',
        3128,
        [ 'http', 'socks5' ]
    );

    $some_proxy->get_host();    # '127.0.0.1'
    $some_proxy->get_port();    # 3128
    $some_proxy->get_methods(); # [ 'http', 'socks5' ]

    my $other_proxy = Geonode::Free::Proxy->new(
        'some-id',
        '127.0.0.1',
        3128,
        [ 'http', 'socks5' ]
    );

    Geonode::Free::Proxy::prefer_socks();
    $some_proxy->get_url(); # 'socks://127.0.0.1:3128';

    Geonode::Free::Proxy::prefer_http();
    $other_proxy->get_url(); # 'http://127.0.0.1:3128';

    my $http_proxy = Geonode::Free::Proxy->new(
        'some-id',
        '127.0.0.1',
        3128,
        [ 'http' ]
    );

    $http_proxy->can_use_http();  # 1;
    $http_proxy->can_use_socks(); # 0;

    Geonode::Free::Proxy::prefer_socks();
    $http_proxy->get_url(); # 'http://127.0.0.1:3128';

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate Geonode::Free::Proxy object (id, host, port, methods)

=cut

sub new {
    my ( $class, $id, $host, $port, $methods ) = @_;

    if ( !defined $id || $id =~ m{^\s*+$}sxmi ) {
        croak 'ERROR: id not informed';
    }

    if ( !defined $host || $host =~ m{^\s*+$}sxmi ) {
        croak 'ERROR: host not informed';
    }

    if ( !defined $port || $port !~ m{^[1-9][0-9]*+$}sxmi ) {
        croak 'ERROR: port must be a number';
    }

    if ( !defined $methods || ref($methods) ne 'ARRAY' ) {
        croak 'ERROR: methods must be an array reference';
    }

    if ( @{$methods} == 0 ) {
        croak 'ERROR: no informed methods';
    }

    foreach my $method ( @{$methods} ) {
        if ( $method !~ m{^(?>socks[45]|https?)$}sxm ) {
            croak q()
                . "ERROR: '$method' is not a valid method\n"
                . '       Valid methods are: socks4/socks5/http/https';
        }
    }

    my $self = {
        id      => $id,
        host    => $host,
        port    => $port,
        methods => $methods
    };

    return bless $self, $class;
}

=head2 prefer_socks

Sets preferred method to socks. This is used when getting the full proxy url.

Preferred method is set up *globally*.

=cut

sub prefer_socks {
    $preferred_method = 'socks';
    return;
}

=head2 prefer_http

Sets preferred method to http. This is used when getting the full proxy url.

Preferred method is set up *globally*.

=cut

sub prefer_http {
    $preferred_method = 'http';
    return;
}

=head2 get_preferred_method

Gets preferred method

=cut

sub get_preferred_method {
    return $preferred_method;
}

=head2 get_id

Gets host

=cut

sub get_id {
    my $self = shift;
    return $self->{id};
}

=head2 get_host

Gets host

=cut

sub get_host {
    my $self = shift;
    return $self->{host};
}

=head2 get_port

Gets port

=cut

sub get_port {
    my $self = shift;
    return $self->{port};
}

=head2 get_methods

Gets methods

=cut

sub get_methods {
    my $self = shift;
    return @{ $self->{methods} };
}

=head2 can_use_socks

Returns truthy if proxy can use socks method

=cut

sub can_use_socks {
    my $self = shift;
    return 0 < grep { m{^socks}sxmi } $self->get_methods();
}

=head2 can_use_http

Returns truthy if proxy can use http method

=cut

sub can_use_http {
    my $self = shift;
    return 0 < grep { m{^http}sxmi } $self->get_methods();
}

=head2 get_url

Gets proxy url

=cut

sub get_url {
    my $self = shift;

    my $method;
    if ( $self->can_use_socks && $preferred_method eq 'socks' ) {
        $method = 'socks';
    }
    elsif ( $self->can_use_http && $preferred_method eq 'http' ) {
        $method = 'http';
    }
    elsif ( $self->can_use_socks ) {
        $method = 'socks';
    }
    elsif ( $self->can_use_http ) {
        $method = 'http';
    }
    else {
        croak 'ERROR: Cannot find a valid method';
    }

    return $method . q(://) . $self->get_host() . q(:) . $self->get_port();
}

=head1 AUTHOR

Julio de Castro, C<< <julio.dcs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geonode-free-proxylist at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geonode-Free-ProxyList>.

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geonode::Free::Proxy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geonode-Free-ProxyList>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Geonode-Free-ProxyList>

=item * Search CPAN

L<https://metacpan.org/release/Geonode-Free-ProxyList>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Julio de Castro.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Geonode::Free::Proxy
