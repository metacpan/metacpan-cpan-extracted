use strict;
use warnings;
use Test::More;

use iabtcfv2;

my $tc_string
  = 'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA.argAC0gAAAAAAAAAAAA';

subtest 'tcf() returns a GDPR::IAB::TCFv2::Parser instance' => sub {
  my $c = tcf($tc_string);
  isa_ok $c, 'GDPR::IAB::TCFv2::Parser';
  is $c->tc_string, $tc_string, 'tcf roundtrips the TC string';
};

subtest 'validator() returns a usable GDPR::IAB::TCFv2::Validator' => sub {
  my $v = validator(vendor_id => 284, consent_purpose_ids => [1, 3],);
  isa_ok $v, 'GDPR::IAB::TCFv2::Validator';

  my $result = $v->validate($tc_string);
  ok defined $result, 'validator->validate returns a defined result';
};

subtest 'exports landed in the caller namespace' => sub {
  ok __PACKAGE__->can('tcf'),       'tcf is imported into main:: by use iabtcfv2';
  ok __PACKAGE__->can('validator'), 'validator is imported into main:: by use iabtcfv2';
};

subtest 'no class-method surface on iabtcfv2' => sub {
  is(iabtcfv2->can('Parse'), undef, 'iabtcfv2 deliberately does not expose Parse as a class method');
};

subtest 'representative one-liner roundtrip' => sub {
  is tcf($tc_string)->cmp_id,           21,   'cmp_id';
  is tcf($tc_string)->consent_language, 'EN', 'consent_language';
  is tcf($tc_string)->policy_version,   2,    'policy_version';
};

done_testing;
