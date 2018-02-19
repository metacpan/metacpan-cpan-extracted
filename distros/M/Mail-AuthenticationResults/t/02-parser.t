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
  'iprev=fail policy.iprev=123.123.123.123 (NOT FOUND)',
  'x-ptr=fail x-ptr-helo=bad.name.google.com x-ptr-lookup=',
  'spf=fail smtp.mailfrom=test@goestheweasel.com smtp.helo=bad.name.google.com',
  'dkim=none (no signatures found)',
  'x-google-dkim=none (no signatures found)',
  'dmarc=fail (p=none,d=none) header.from=marcbradshaw.net',
  'dmarc=fail (p=reject,d=reject) header.from=goestheweasel.com',
  'dmarc=none (p=none,d=none) header.from=example.com'
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

my $InputARHeader = join( ";\n", 'test.example.com', @$Input );

my $Parser;
dies_ok( sub{ $Parser = Mail::AuthenticationResults::Parser->new()->parse( '' ) }, 'Parser dies on empty' );
lives_ok( sub{ $Parser = Mail::AuthenticationResults::Parser->new( $InputARHeader ) }, 'Parser parses' );
is( ref $Parser, 'Mail::AuthenticationResults::Parser', 'Returns Parser Object' );

my $Header;
lives_ok( sub{ $Header = $Parser->parsed() }, 'Parser returns data' );
is( ref $Header, 'Mail::AuthenticationResults::Header', 'Returns Header Object' );
is( $Header->value()->value(), 'test.example.com', 'Authserve Id correct' );
is( $Header->as_string(), join( ";\n    ", 'test.example.com', @$Output ), 'As String data matches input data' );

my $Search;
lives_ok( sub{ $Search = $Header->search({ 'key'=>'dmarc','value'=>'none' }) }, 'Searches returns data' );
is( ref $Search, 'Mail::AuthenticationResults::Header::Group', 'Returns Header Group Object' );
is( $Search->as_string(), $Input->[7], 'As String data matches expected data' );

my $MultiSearch;
lives_ok( sub{ $MultiSearch = $Header->search({ 'key'=>'dmarc' }) }, 'Searches returns data' );
is( ref $MultiSearch, 'Mail::AuthenticationResults::Header::Group', 'Returns Header Group Object' );
is( $MultiSearch->as_string(), join( ";\n", $Input->[5] , $Input->[6], $Input->[7] ), 'As String data matches expected data' );

done_testing();

