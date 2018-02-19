#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

#plan tests => noplan1;

chdir 't';

my $Input = [
  '"iprev"="fail" "policy"."iprev"="123.123.123.123" (NOT FOUND)',
  '"x-ptr"="fail" "x-ptr-helo"="bad.name.google.com" "x-ptr-lookup"=""',
  '"spf"="fail" "smtp.mailfrom"="test@goestheweasel.com" "smtp"."helo"="bad.name.google.com"',
  '"dkim"="none" (no signatures found)',
  '"x-google-dkim"="none" (no signatures found)',
  '"dmarc"="fail" (p=none,d=none) "header"."from"="marcbradshaw.net"',
  '"dmarc"="fail" (p=reject,d=reject) "header.from"="goestheweasel.com"',
  '"dmarc"="none" (p=none,d=none) "header"."from"="example.com"'
];

my $Output = [
  'iprev=fail policy.iprev=123.123.123.123 (NOT FOUND)',
  'x-ptr=fail x-ptr-helo=bad.name.google.com x-ptr-lookup=""',
  'spf=fail smtp.mailfrom=test@goestheweasel.com smtp.helo=bad.name.google.com',
  'dkim=none (no signatures found)',
  'x-google-dkim=none (no signatures found)',
  'dmarc=fail (p=none,d=none) header.from=marcbradshaw.net',
  'dmarc=fail (p=reject,d=reject) header.from=goestheweasel.com',
  'dmarc=none (p=none,d=none) header.from=example.com'
];

my $InputARHeader = join( ";\n", '"test.example.com"', @$Input );

my $Parser;
lives_ok( sub{ $Parser = Mail::AuthenticationResults::Parser->new( $InputARHeader ) }, 'Parser parses' );
is( ref $Parser, 'Mail::AuthenticationResults::Parser', 'Returns Parser Object' );

my $Header;
lives_ok( sub{ $Header = $Parser->parsed() }, 'Parser returns data' );
is( ref $Header, 'Mail::AuthenticationResults::Header', 'Returns Header Object' );
is( $Header->value()->value(), 'test.example.com', 'Authserve Id correct' );
is( $Header->as_string(), join( ";\n    ", 'test.example.com', @$Output ), 'As String data matches input data' );

done_testing();

