#!/usr/bin/env perl
use Carp::Always;
use LWP::Online qw(:skip_all);
use Test::More;
use strict;

my $class = 'ICANN::gTLD';

require_ok $class;

my @gtlds = $class->get_all;

ok scalar(@gtlds) > 0;

isa_ok($gtlds[0], $class);

my $tld = $class->get(q{org});

foreach my $method (qw(gtld u_label registry_operator registry_operator_country_code date_of_contract_signature delegation_date removal_date contract_terminated application_id third_or_lower_level_registration registry_class_domain_name_list specification_13 rdap_record rdap_server)) {
    ok($tld->can($method));
}

isa_ok($tld, $class);

is($tld->gtld->name, q{org});

$tld = $class->from_domain(q{example.com});
isa_ok($tld, $class);

is($tld->gtld->name, q{com});

$tld = $class->get(q{invalid});

isnt($tld, $class);

done_testing;
