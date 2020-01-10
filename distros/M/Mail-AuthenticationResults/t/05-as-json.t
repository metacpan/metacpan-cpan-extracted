#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $Header = 'test.example.com;
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

my $Parser = Mail::AuthenticationResults::Parser->new( $Header );
my $Parsed = $Parser->parsed();

my $AsJson = '{"authserv_id":{"children":[],"type":"authservid","value":"test.example.com"},"children":[{"children":[{"children":[{"type":"comment","value":"NOT FOUND"}],"key":"policy.iprev","type":"subentry","value":"123.123.123.123"}],"key":"iprev","type":"entry","value":"fail"},{"children":[{"children":[],"key":"x-ptr-helo","type":"subentry","value":"bad.name.google.com"},{"children":[],"key":"x-ptr-lookup","type":"subentry","value":""}],"key":"x-ptr","type":"entry","value":"fail"},{"children":[{"children":[],"key":"smtp.mailfrom","type":"subentry","value":"test@goestheweasel.com"},{"children":[],"key":"smtp.helo","type":"subentry","value":"bad.name.google.com"}],"key":"spf","type":"entry","value":"fail"},{"children":[{"type":"comment","value":"no signatures found"}],"key":"dkim","type":"entry","value":"none"},{"children":[{"type":"comment","value":"no signatures found"}],"key":"x-google-dkim","type":"entry","value":"none"},{"children":[{"type":"comment","value":"p=none,d=none"},{"children":[],"key":"header.from","type":"subentry","value":"marcbradshaw.net"}],"key":"dmarc","type":"entry","value":"fail"},{"children":[{"type":"comment","value":"p=reject,d=reject"},{"children":[],"key":"header.from","type":"subentry","value":"goestheweasel.com"}],"key":"dmarc","type":"entry","value":"fail"},{"children":[{"type":"comment","value":"p=none,d=none"},{"children":[],"key":"header.from","type":"subentry","value":"example.com"}],"key":"dmarc","type":"entry","value":"none"}],"type":"header"}';

is ( $Parsed->as_json(), $AsJson, 'JSON Serialised as expected' );

done_testing();

