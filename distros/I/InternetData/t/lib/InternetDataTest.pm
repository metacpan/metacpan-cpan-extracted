package InternetDataTest;

use strict;
use warnings;

use Mojo::File 'path';
use Mojo::JSON qw(decode_json false true);

# The language-neutral conformance corpus, generated into every InternetData SDK
# so a binding that drifts fails its own suite.
sub corpus {
    my $root = path(__FILE__)->to_abs->dirname->dirname->dirname;
    return decode_json($root->child('testdata', 'testdata.json')->slurp);
}

sub lookup_case {
    my ($name) = @_;
    my ($case) = grep { $_->{name} eq $name } @{ corpus()->{lookup} };
    die "no lookup case named '$name'" unless $case;
    return $case;
}

sub batch_case {
    my ($name) = @_;
    my ($case) = grep { $_->{name} eq $name } @{ corpus()->{batch} };
    die "no batch case named '$name'" unless $case;
    return $case;
}

# An address's answer on Unlimited, every member the spec requires and nothing
# more, so a test can vary the one member it is about.
sub lookup {
    my (%overrides) = @_;
    return {
        ip => '9.9.9.9',
        is_bogon => false,
        (map { ($_ => false) } qw(
            is_tor is_relay is_anycast is_carrier is_satellite is_ssh is_smtp is_web is_dns_resolver
            is_bittorrent
        )),
        tor => {},
        relay => {},
        location => {
            continent => 'EU', continent_name => 'Europe', country => 'AT', country_name => 'Austria',
            timezone => 'Europe/Vienna', currency_code => 'EUR', currency_name => 'Euro',
            currency_symbol => 'E', flag_emoji => 'AT', flag_unicode => 'U+1F1E6 U+1F1F9',
        },
        asn => { asn => 9009, name => 'M247 Europe SRL', domain => 'm247global.com', type => 'hosting', prefix => '9.9.9.0/24' },
        company => { name => 'M247', domain => 'm247.ro' },
        hostname => '',
        abuse => { email => 'abuse@m247.ro' },
        %overrides,
    };
}

# An AS's answer and a domain's on Unlimited, in the same terms.
sub asn {
    my (%overrides) = @_;
    return {
        asn => 9009, name => 'M247 Europe SRL', country => 'RO', registry => 'ripe',
        allocated => '2005-06-06', domain => 'm247global.com', %overrides,
    };
}

sub domain {
    my (%overrides) = @_;
    return {
        domain => 'example.com', is_registered => true,
        (map { ($_ => false) } qw(has_a has_aaaa has_mx has_ns has_cname)),
        %overrides,
    };
}

# One licensed family in the shape /api/v2/database/list answers, so a test can
# vary the one field it is about rather than restating the whole document.
sub family {
    my (%overrides) = @_;
    return {
        base => 'bogon_ip',
        name => 'Bogon IP',
        summary => 'IP ranges that cannot legitimately appear on the internet.',
        standing => 'licensed',
        open => false,
        license_type => 'standard',
        starts => '2026-09-04T07:49:45.118Z',
        expires => undef,
        versions => [{
            id => 'bogon_ip_v1',
            version => 1,
            summary => 'IP ranges that cannot legitimately appear on the internet.',
            formats => ['csvgz', 'mmdb'],
        }],
        %overrides,
    };
}

# One download attempt with every member the spec requires.
sub download {
    my (%overrides) = @_;
    return {
        dataset_id => 'bogon_ip_v1',
        format => 'csvgz',
        outcome => 'ok',
        sample => false,
        open => false,
        bytes => 760,
        http_status => 200,
        apikey_id => 'key_1',
        client_ip => '203.0.113.7',
        user_agent => 'curl/8.5.0',
        created => '2026-09-04T10:00:00.000Z',
        %overrides,
    };
}

# A checksum answer with every member the spec requires.
sub checksum {
    my (%overrides) = @_;
    return {
        id => 'bogon_ip_v1',
        format => 'csvgz',
        checksums => { md5 => 'm', sha1 => 's1', sha256 => 's256', sha512 => 's512' },
        %overrides,
    };
}

# A dataset's metadata with every member the spec requires.
sub metadata {
    my (%overrides) = @_;
    return {
        id => 'bogon_ip_v1',
        updated => '2026-09-04',
        entries => 42,
        schema => { csvgz => [{ name => 'range_start', type => 'varchar' }] },
        size => { csvgz => 760 },
        %overrides,
    };
}

1;
