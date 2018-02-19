#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

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

my $InputARHeader = join( ";\n", 'test.example.com', @$Input );

my $Parser = Mail::AuthenticationResults::Parser->new( $InputARHeader );
my $Parsed = $Parser->parsed();

my $None = 'test.example.com; iprev=fail policy.iprev=123.123.123.123 (NOT FOUND); x-ptr=fail x-ptr-helo=bad.name.google.com x-ptr-lookup=""; spf=fail smtp.mailfrom=test@goestheweasel.com smtp.helo=bad.name.google.com; dkim=none (no signatures found); x-google-dkim=none (no signatures found); dmarc=fail (p=none,d=none) header.from=marcbradshaw.net; dmarc=fail (p=reject,d=reject) header.from=goestheweasel.com; dmarc=none (p=none,d=none) header.from=example.com';

my $Entry = 'test.example.com;
    iprev=fail policy.iprev=123.123.123.123 (NOT FOUND);
    x-ptr=fail x-ptr-helo=bad.name.google.com x-ptr-lookup="";
    spf=fail smtp.mailfrom=test@goestheweasel.com smtp.helo=bad.name.google.com;
    dkim=none (no signatures found);
    x-google-dkim=none (no signatures found);
    dmarc=fail (p=none,d=none) header.from=marcbradshaw.net;
    dmarc=fail (p=reject,d=reject) header.from=goestheweasel.com;
    dmarc=none (p=none,d=none) header.from=example.com';

my $SubEntry = 'test.example.com;
    iprev=fail
        policy.iprev=123.123.123.123 (NOT FOUND);
    x-ptr=fail
        x-ptr-helo=bad.name.google.com
        x-ptr-lookup="";
    spf=fail
        smtp.mailfrom=test@goestheweasel.com
        smtp.helo=bad.name.google.com;
    dkim=none (no signatures found);
    x-google-dkim=none (no signatures found);
    dmarc=fail (p=none,d=none)
        header.from=marcbradshaw.net;
    dmarc=fail (p=reject,d=reject)
        header.from=goestheweasel.com;
    dmarc=none (p=none,d=none)
        header.from=example.com';

my $Full = 'test.example.com;
    iprev=fail
        policy.iprev=123.123.123.123
            (NOT FOUND);
    x-ptr=fail
        x-ptr-helo=bad.name.google.com
        x-ptr-lookup="";
    spf=fail
        smtp.mailfrom=test@goestheweasel.com
        smtp.helo=bad.name.google.com;
    dkim=none
        (no signatures found);
    x-google-dkim=none
        (no signatures found);
    dmarc=fail
        (p=none,d=none)
        header.from=marcbradshaw.net;
    dmarc=fail
        (p=reject,d=reject)
        header.from=goestheweasel.com;
    dmarc=none
        (p=none,d=none)
        header.from=example.com';


is( $Parsed->set_indent_style( 'none' )->as_string(), $None, 'None stringifies correctly' );
is( $Parsed->set_indent_style( 'entry' )->as_string(), $Entry, 'Entry stringifies correctly' );
is( $Parsed->set_indent_style( 'subentry' )->as_string(), $SubEntry, 'SubEntry stringifies correctly' );
is( $Parsed->set_indent_style( 'full' )->as_string(), $Full, 'Full stringifies correctly' );
dies_ok( sub{ $Parsed->set_indent_style( 'bogus_indent_style' ); }, 'invalid style dies' );

done_testing();

