use strict;
use warnings;
use blib;

use Error ':try';
use Net::DNS::Resolver::Programmable;
use Net::DNS::RR;

use Test::More tests => 23;

my $test_resolver_empty = Net::DNS::Resolver::Programmable->new(
    records         => {}
);

my $test_resolver_1 = Net::DNS::Resolver::Programmable->new(
    records         => {
        'example.com'   => [
            Net::DNS::RR->new('example.com. A 192.168.0.1')
        ]
    }
);

my $test_resolver_nxdomain = Net::DNS::Resolver::Programmable->new(
    resolver_code   => sub { return ('NXDOMAIN', undef) }
);

my $test_resolver_servfail = Net::DNS::Resolver::Programmable->new(
    resolver_code   => sub { return ('SERVFAIL', undef) }
);


#### Class Compilation ####

BEGIN { use_ok('Mail::SPF::Server') }


#### Basic Instantiation ####

{
    my $server = eval { Mail::SPF::Server->new(
        dns_resolver                    => $test_resolver_empty,
        max_dns_interactive_terms       => 1,
        max_name_lookups_per_term       => 2,
        max_name_lookups_per_mx_mech    => 3
    ) };

    $@ eq '' and isa_ok($server, 'Mail::SPF::Server',   'Basic server object')
        or BAIL_OUT("Basic server instantiation failed: $@");

    # Have options been interpreted correctly?
    isa_ok($server->dns_resolver, 'Net::DNS::Resolver::Programmable', 'Basic server dns_resolver()');
    is($server->max_dns_interactive_terms,     1,       'Basic server max_dns_interactive_terms()');
    is($server->max_name_lookups_per_term,     2,       'Basic server max_name_lookups_per_term()');
    is($server->max_name_lookups_per_mx_mech,  3,       'Basic server max_name_lookups_per_mx_mech()');
    is($server->max_name_lookups_per_ptr_mech, 2,       'Basic server fallback max_name_lookups_per_ptr_mech()');
}


#### Minimally Parameterized Server ####

{
    my $server = eval { Mail::SPF::Server->new() };

    $@ eq '' and isa_ok($server, 'Mail::SPF::Server',   'Minimal server object')
        or BAIL_OUT("Minimal server instantiation failed: $@");

    # Have omitted options been defaulted correctly?
    isa_ok($server->dns_resolver, 'Net::DNS::Resolver', 'Minimal server default dns_resolver()');
    is($server->max_dns_interactive_terms,     10,      'Minimal server default max_dns_interactive_terms()');
    is($server->max_name_lookups_per_term,     10,      'Minimal server default max_name_lookups_per_term()');
    is($server->max_name_lookups_per_mx_mech,  10,      'Minimal server default max_name_lookups_per_mx_mech()');
    is($server->max_name_lookups_per_ptr_mech, 10,      'Minimal server default max_name_lookups_per_ptr_mech()');
}


#### dns_lookup() ####

# No-records lookup:

{
    my $server = Mail::SPF::Server->new(
        dns_resolver => $test_resolver_empty
    );

    my $packet = $server->dns_lookup('example.com', 'A');
    isa_ok($packet,                 'Net::DNS::Packet', 'Server no-records dns_lookup() packet object');
    is($packet->header->rcode,      'NOERROR',          'Server no-records dns_lookup() rcode');
    is($packet->answer,             0,                  'Server no-records dns_lookup() answer RR count');
}

# 'A' record lookup:

{
    my $server = Mail::SPF::Server->new(
        dns_resolver => $test_resolver_1
    );

    my $packet = $server->dns_lookup('example.com', 'A');
    isa_ok($packet,                 'Net::DNS::Packet', 'Server "A" dns_lookup() packet object');

    my @rrs = $packet->answer;
    is($rrs[0]->name,               'example.com',      'Server "A" dns_lookup() answer domain name');
    is($rrs[0]->type,               'A',                'Server "A" dns_lookup() answer RR type');
}

# NXDOMAIN lookup:

{
    my $server = Mail::SPF::Server->new(
        dns_resolver => $test_resolver_nxdomain
    );

    my $packet = $server->dns_lookup('example.com', 'A');
    isa_ok($packet,                 'Net::DNS::Packet', 'Server NXDOMAIN dns_lookup() packet object');
    is($packet->header->rcode,      'NXDOMAIN',         'Server NXDOMAIN dns_lookup() rcode');
    is($packet->answer,             0,                  'Server NXDOMAIN dns_lookup() answer RR count');
}

# SERVFAIL lookup:

{
    my $server = Mail::SPF::Server->new(
        dns_resolver => $test_resolver_servfail
    );

    my $packet = eval { $server->dns_lookup('example.com', 'A') };
    isa_ok($@,                  'Mail::SPF::EDNSError', 'Server SERVFAIL dns_lookup()');
}


#### SPF Record Selection / select_record(), get_acceptable_records_from_packet() ####

# This gets checked by the RFC 4408 test suite.
