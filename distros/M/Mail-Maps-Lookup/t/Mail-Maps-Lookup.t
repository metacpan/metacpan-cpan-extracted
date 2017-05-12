use Test::More tests => 1;
BEGIN { use_ok('Mail::Maps::Lookup') };

my $ip_address = "1.1.1.1";

my $req = Mail::Maps::Lookup->new(
	activation_code => "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        ip_address => $ip_address,
);

$req->lookup;

exit(0);
