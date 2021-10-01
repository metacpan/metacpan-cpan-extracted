package Geonode::Free::ProxyList;

use 5.010;
use strict;
use warnings;
use Carp 'croak';
use List::Util qw( shuffle );
use List::MoreUtils qw( uniq );
use LWP::UserAgent;
use JSON::PP;
use utf8;

use Geonode::Free::Proxy;

=head1 NAME

Geonode::Free::ProxyList - Get Free Geonode Proxies by using some filters

=head1 VERSION

Version 0.0.5

=cut

our $VERSION = '0.0.5';

my $API_ROOT = 'https://proxylist.geonode.com/api/proxy-list?';

=head1 SYNOPSIS

Get Geonode's free proxy list and apply some filters. You can later choose them by random.

    my $proxy_list = Geonode::Free::ProxyList->new();

    $list->set_filter_google('true');
    $list->set_filter_port(3128);
    $list->set_filter_limit(200);

    $list->add_proxies; # Add proxies to the list for current filters

    $list->set_filter_google('false');
    $list->set_filter_port();  # reset filter
    $list->set_filter_limit(); # reset filter
    $list->set_filter_protocol_list( [ 'socks4', 'socks5' ] );
    $list->set_filter_speed('fast');

    $list->add_proxies; # Add proxies to the list for current filters

    # List of proxies is shuffled

    my $some_proxy = $list->get_next;  # Repeats when list is exhausted
    my $other_proxy = $list->get_next; # Repeats when list is exhausted

    my $random_proxy = $list->get_random_proxy;  # Can repeat

    $some_proxy->get_methods();  # [ 'http', 'socks5' ]

    Geonode::Free::Proxy::prefer_socks(); # Will use socks for url, if available

    $some_proxy->get_url(); # 'socks://127.0.0.1:3128';

    Geonode::Free::Proxy::prefer_http(); # Will use http url, if available

    $some_proxy->get_url(); # 'http://127.0.0.1:3128';

    $some_proxy->can_use_http();  # 1
    $some_proxy->can_use_socks(); # 1

    $other_proxy->can_use_socks(); # q()
    $other_proxy->can_use_http();  # 1

    Geonode::Free::Proxy::prefer_socks(); # Will use socks for url, if available

    $some_proxy->get_url(); # 'http://foo.bar.proxy:1234';

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate Geonode::Free::ProxyList object

=cut

sub new {
    my $self = bless {
        proxy_list => [],
        index      => 0,
        filters    => {},
        ua         => LWP::UserAgent->new()
      },
      shift;

    $self->reset_filters();

    return $self;
}

=head2 reset_proxy_list

Clears proxy list

=cut

sub reset_proxy_list {
    my $self = @_;

    $self->{proxy_list} = [];

    return;
}

=head2 reset_filters

Reset filtering options

=cut

sub reset_filters {
    my ($self) = @_;

    $self->{filters} = {
        country           => undef,
        google            => undef,
        filterPort        => undef,
        protocols         => undef,
        anonymityLevel    => undef,
        speed             => undef,
        filterByOrg       => undef,
        filterUpTime      => undef,
        filterLastChecked => undef,
        limit             => undef
    };

    return;
}

=head2 set_filter_country

Set country filter. Requires a two character uppercase string or undef to reset the filter

=cut

sub set_filter_country {
    my ( $self, $country ) = @_;

    if ( defined $country && $country !~ m{^[A-Z]{2}$}sxm ) {
        croak q()
            . "ERROR: '$country' is not a two character uppercase code\n"
            . "Please, check valid values at following url:\n"
            . 'https://geonode.com/free-proxy-list';
    }

    $self->{filters}{country} = $country;

    return;
}

=head2 set_filter_google

Set google filter. Allowed values are 'true'/'false'. You can use undef to reset the filter

=cut

sub set_filter_google {
    my ( $self, $google ) = @_;

    if ( defined $google && $google !~ m{^(?: true|false )$}sxm ) {
        croak q()
            . "ERROR: '$google' is not a valid value for google filter\n"
            . 'Valid values are: true/false';
    }

    $self->{filters}{google} = $google;

    return;
}

=head2 set_filter_port

Set port filter. Allowed values are numbers that does not start by zero. You can use undef to reset the filter

=cut

sub set_filter_port {
    my ( $self, $port ) = @_;

    if ( defined $port && $port !~ m{^(?: (?!0)[0-9]++ )$}sxm ) {
        croak "ERROR: '$port' is not a valid value for por filter";
    }

    $self->{filters}{filterPort} = $port;

    return;
}

=head2 set_filter_protocol_list

Set protocol list filter. Allowed values are http, https, socks4, socks5. You can use an scalar or a list of values. By using undef you can reset the filter

=cut

sub set_filter_protocol_list {
    my ( $self, $protocol_list ) = @_;

    if ( defined $protocol_list && ref $protocol_list eq q() ) {
        $protocol_list = [$protocol_list];
    }
    elsif ( defined $protocol_list && ref $protocol_list ne 'ARRAY' ) {
        croak 'ERROR: just a single scalar or an array reference are accepted';
    }

    if ( !defined $protocol_list ) {
        $self->{filters}{protocols} = undef;
        return;
    }

    my @list;
    for my $option ( @{$protocol_list} ) {
        if ( $option !~ m{ ^(?:https?|socks[45])$ }sxm ) {
            croak "ERROR: '$option' is not a valid value for protocol list";
        }

        push @list, $option;
    }

    if ( defined $protocol_list && @list == 0 ) {
        croak 'ERROR: Cannot set empty protocol list';
    }

    $self->{filters}{protocols} = [ uniq @list ];

    return;
}

=head2 set_filter_anonymity_list

Set anonimity list filter. Allowed values are http, https, socks4, socks5. You can use an scalar or a list of values. By using undef you can reset the filter

=cut

sub set_filter_anonymity_list {
    my ( $self, $anonymity_list ) = @_;

    if ( defined $anonymity_list && ref $anonymity_list eq q() ) {
        $anonymity_list = [$anonymity_list];
    }
    elsif ( defined $anonymity_list && ref $anonymity_list ne 'ARRAY' ) {
        croak 'ERROR: just a single scalar or an array reference are accepted';
    }

    if ( !defined $anonymity_list ) {
        $self->{filters}{anonymityLevel} = undef;
        return;
    }

    my @list;
    for my $option ( @{$anonymity_list} ) {
        if ( $option !~ m{ ^(?:elite|anonymous|transparent)$ }sxm ) {
            croak "ERROR: '$option' is not a valid value for anonymity list";
        }

        push @list, $option;
    }

    if ( defined $anonymity_list && @list == 0 ) {
        croak 'ERROR: Cannot set empty protocol list';
    }

    $self->{filters}{anonymityLevel} = [ uniq @list ];

    return;
}

=head2 set_filter_speed

Set speed filter. Allowed values are: fast, medium, slow. You can use undef to reset the filter

=cut

sub set_filter_speed {
    my ( $self, $speed ) = @_;

    if ( defined $speed && $speed !~ m{^(?: fast|medium|slow )$}sxm ) {
        croak q()
            . "ERROR: '$speed' is not a valid value for por speed\n"
            . 'Valid values are: fast/slow/medium';
    }

    $self->{filters}{speed} = $speed;

    return;
}

=head2 set_filter_org

Set organization filter. Requires some non empty string. You can use undef to reset the filter

=cut

sub set_filter_org {
    my ( $self, $org ) = @_;

    if ( defined $org && $org eq q() ) {
        croak 'ERROR: Cannot set empty organization filter';
    }

    $self->{filters}{filterByOrg} = $org;

    return;
}

=head2 set_filter_uptime

Set uptime filter. Allowed values are: 0-100 in 10% increments. You can use undef to reset the filter

=cut

sub set_filter_uptime {
    my ( $self, $uptime ) = @_;

    if ( defined $uptime && $uptime !~ m{^(?: 0 | [1-9]0 | 100 )$}sxm ) {
        croak q()
            . "ERROR: '$uptime' is not a valid value for por uptime\n"
            . 'Valid values are: 0-100% in 10% increments';
    }

    $self->{filters}{filterUpTime} = $uptime;

    return;
}

=head2 set_filter_last_checked

Set last checked filter. Allowed values are: 1-9 and 20-60 in 10% increments. You can use undef to reset the filter

=cut

sub set_filter_last_checked {
    my ( $self, $last_checked ) = @_;

    if ( defined $last_checked && $last_checked !~ m{^(?:[1-9]|[1-6]0)$}sxm ) {
        croak q()
            . "ERROR: '$last_checked' is not a valid value for por uptime\n"
            . 'Valid values are: 0-100% in 10% increments';
    }

    $self->{filters}{filterLastChecked} = $last_checked;

    return;
}

=head2 set_filter_limit

Set speed filter. Allowed values are numbers greater than 0. You can use undef to reset the filter

=cut

sub set_filter_limit {
    my ( $self, $limit ) = @_;

    if ( defined $limit && $limit !~ m{^ (?!0)[0-9]++ $}sxm ) {
        croak q()
            . "ERROR: '$limit' is not a valid value for por speed\n"
            . 'Valid values are: numbers > 0';
    }

    $self->{filters}{limit} = $limit;

    return;
}

=head2 set_env_proxy

Use proxy based on environment variables

See: https://metacpan.org/pod/LWP::UserAgent#env_proxy

Example:

$proxy_list->set_env_proxy();

=cut

sub set_env_proxy {
    my ($self) = @_;

    $self->{ua}->env_proxy;

    return;
}

=head2 set_proxy

Exposes LWP::UserAgent's proxy method to configure proxy server

See: https://metacpan.org/pod/LWP::UserAgent#proxy

Example:

$proxy_list->proxy(['http', 'ftp'], 'http://proxy.sn.no:8001/');

=cut

sub set_proxy {
    my ( $self, @params ) = @_;

    $self->{ua}->proxy(@params);

    return;
}

=head2 set_timeout

Set petition timeout. Exposes LWP::UserAgent's timeout method

See: https://metacpan.org/pod/LWP::UserAgent#timeout

Example:

$proxy_list->timeout(10);

=cut

sub set_timeout {
    my ( $self, @params ) = @_;

    $self->{ua}->timeout(@params);

    return;
}

=head2 add_proxies

Add proxy list according to stored filters

=cut

sub add_proxies {
    my ($self) = @_;

    my $response = $self->{ua}->get( $API_ROOT . $self->_calculate_api_url );

    if ( !$response->is_success ) {
        croak 'ERROR: Could not get url, ' . $response->status_line;
    }

    my $data = encode( 'utf-8', $response->decoded_content, sub { q() } );

    $self->{proxy_list} = [ shuffle @{ $self->_create_proxy_list($data) } ];
    $self->{index}      = 0;

    return;
}

sub _create_proxy_list {
    my ( $self, $struct ) = @_;

    $struct = decode_json $struct;

    my %proxies = map { $_->id => $_ } $self->get_all_proxies;

    for my $item ( @{ $struct->{data} } ) {
        $proxies{ $item->{_id} } = Geonode::Free::Proxy->new(
            $item->{_id},
            $item->{ip},
            $item->{port},
            $item->{protocols}
        );
    }

    return [ values %proxies ];
}

sub _calculate_api_url {
    my $self = shift;

    return join q(&),
        map  { $self->_serialize_filter($_) }
        grep { defined $self->{filters}{$_} }
        sort keys %{ $self->{filters} };
}

sub _serialize_filter {
    my ( $self, $filter ) = @_;

    my $value = $self->{filters}{$filter};

    return ref $value eq 'ARRAY'
        ? join q(&), map { "$filter=$_" } sort @{ $value }
        : $filter . q(=) . $value;
}

=head2 get_all_proxies

Return the whole proxy list

=cut

sub get_all_proxies {
    my ($self) = @_;

    return @{ $self->{proxy_list} };
}

=head2 get_random_proxy

Returns a proxy from the list at random (with repetition)

=cut

sub get_random_proxy {
    my ($self) = @_;

    my $rand_index = int rand @{ $self->{proxy_list} };

    return $self->{proxy_list}[$rand_index];
}

=head2 get_next

Returns next proxy from the shuffled list (no repetition until list is exhausted)

=cut

sub get_next {
    my ($self) = @_;

    my $proxy = $self->{proxy_list}[ $self->{index} ];

    $self->{index} = $self->{index} + 1;

    if ( $self->{index} > @{ $self->{proxy_list} } - 1 ) {
        $self->{index} = 0;
    }

    return $proxy;
}

=head1 AUTHOR

Julio de Castro, C<< <julio.dcs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geonode-free-proxylist at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geonode-Free-ProxyList>.

I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geonode::Free::ProxyList

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

1;    # End of Geonode::Free::ProxyList
