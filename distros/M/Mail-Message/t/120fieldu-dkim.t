#!/usr/bin/env perl
#
# Test processing of Authentication-Results
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Field::DKIM;
use Mail::Message::Field::Full;

use Test::More tests => 16;

my $mmff  = 'Mail::Message::Field::Full';
my $mmfd  = 'Mail::Message::Field::DKIM';

#use Data::Dumper;

#
### constructing
#

#
### Parsing
#

# Example from RFC6376 section 3.5

my $d1 = $mmff->new(
  'DKIM-Signature: v=1; a=rsa-sha256; d=example.net; s=brisbane;
   c=simple; q=dns/txt; i=@eng.example.net;
   t=1117574938; x=1118006938;
   h=from:to:subject:date;
   z=From:foo@eng.example.net|To:joe@example.com|
   Subject:demo=20run|Date:July=205,=202005=203:44:08=20PM=20-0700;
   bh=MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=;
   b=dzdVyOfAKCdLXdJOc9G2q8LoXSlEniSbav+yuU4zGeeruD00lszZVoG4ZHRNiYzR');

ok defined $d1, '1 parse';
isa_ok $d1, $mmff;
isa_ok $d1, $mmfd;

is $d1->tagVersion, '1';
is $d1->tagAlgorithm, 'rsa-sha256';
is $d1->tagDomain, 'example.net';
is $d1->tagSelector, 'brisbane';
is $d1->tagC14N, 'simple';
is $d1->tagQueryMethods, 'dns/txt';
is $d1->tagAgentID, '@eng.example.net';
is $d1->tagTimestamp, 1117574938;
is $d1->tagExpires, 1118006938;
is $d1->tagSignedHeaders, 'from:to:subject:date';
is $d1->tagExtract, 'From:foo@eng.example.net|To:joe@example.com|
   Subject:demo=20run|Date:July=205,=202005=203:44:08=20PM=20-0700';
is $d1->tagSignature, 'MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI=';
is $d1->tagSignData, 'dzdVyOfAKCdLXdJOc9G2q8LoXSlEniSbav+yuU4zGeeruD00lszZVoG4ZHRNiYzR';

