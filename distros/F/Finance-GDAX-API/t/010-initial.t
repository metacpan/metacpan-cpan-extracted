use v5.20;
use warnings;
use Test::More;
use File::Temp ();
use lib qw(lib t/lib);

BEGIN {
    use_ok('JSON');
    use_ok('Finance::GDAX::API::Quote');
    use_ok('Finance::GDAX::API');
}

my $quote = Finance::GDAX::API::Quote->new;
isa_ok($quote, 'Finance::GDAX::API::Quote');

ok $quote->product('BTC-USD'), 'Can set quote product';
ok my $q = $quote->get, 'quote is returned';
is(ref($q), 'HASH', 'quote->get returns a hashref');
ok($$q{price} > 0, 'quote->get returns a price looking like a number');

my $req = Finance::GDAX::API->new(key        => 'temp',
				  secret     => 'temp',
				  passphrase => 'temp');

can_ok $req, 'debug';
can_ok $req, 'key';
can_ok $req, 'secret';
can_ok $req, 'passphrase';
can_ok $req, 'method';
can_ok $req, 'path';
can_ok $req, 'body';
can_ok $req, 'timestamp';
can_ok $req, 'timeout';
can_ok $req, 'error';
can_ok $req, 'response_code';
can_ok $req, 'send';
can_ok $req, 'signature';
can_ok $req, 'body_json';
can_ok $req, 'external_secret';
can_ok $req, 'save_secrets_to_environment';

my $ts = $req->timestamp;
ok(($ts > 1000 && $ts <= time), 'request timestamp appears sane');

$req->path('test');
ok(is_base64($req->signature), 'request WITHOUT body signature is base64');
$req->body({ test => 1, string => 'My test is a body test' });
ok(is_base64($req->signature), 'request WITH body signature is base64');

ok(${JSON->new->decode($req->body_json)}{string} eq "My test is a body test", 'body encoded to JSON');

ok(my $r = $req->send, 'send seems to work');
is($req->response_code, 400, 'valid REST error return code');
like($req->error, '/invalid/i', 'looks like good error test returned');

my $tmp = File::Temp->new;
my $key = "thisisthekey";
my $sec = "ThisISTHeSEcret";
my $pas = "MyverYSEcReTPasSPHraSe";
$tmp->print("key:$key\n");
$tmp->print("secret:$sec\n");
$tmp->print("\n");
$tmp->print("passphrase:$pas\n");
$tmp->flush;
$req->external_secret($tmp);
close $tmp;
is($req->key, $key, 'external_secret key read ok');
is($req->secret, $sec, 'external_secret secret read ok');
is($req->passphrase, $pas, 'external_secret passphrase read ok');

if (%ENV{AUTHOR_TESTING}) {
    my $tmp2 = File::Temp->new(UNLINK => 0);
    print $tmp2 <<"EOB";
#!/usr/bin/env perl
print "key:$key\n";
print "secret:$sec\n";
print "# This is a comment\n";
print "passphrase:$pas\n";
EOB
    $tmp2->flush;
    chmod 0744, $tmp2->filename;
    my $tmp2_filename = $tmp2->filename;
    $tmp2->close;
    $req->external_secret($tmp2_filename, 1);
    unlink $tmp2_filename;
    is($req->key, $key, 'external_secret forked key read ok');
    is($req->secret, $sec, 'external_secret forked secret read ok');
    is($req->passphrase, $pas, 'external_secret forked passphrase read ok');
}

done_testing();

sub is_base64 {
    my $string = shift;
    return $string =~
	m{
             ^
		 (?: [A-Za-z0-9+/]{4} )*
		 (?:
		  [A-Za-z0-9+/]{2} [AEIMQUYcgkosw048] =
		  |
		  [A-Za-z0-9+/] [AQgw] ==
		 )?
		 \z
            }x
	? 1 : 0;
}
