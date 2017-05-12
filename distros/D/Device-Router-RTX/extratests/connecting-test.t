use Test::More;
use warnings;
use strict;
use FindBin;
use Device::Router::RTX;


# Edit the following lines or set the environment variables up to test
# connectivity.

my $address = $ENV{RTX_ADDRESS};
my $password = $ENV{RTX_PASSWORD};
my $admin = $ENV{RTX_ADMIN_PASSWORD};

print "Connecting with password '$password' and admin password '$admin'\n";

my $rtx = Device::Router::RTX->new (
    address => $address,
    password => $password,
    admin_password => $admin,
    verbose => 'yes',
);
ok ($rtx, "created object");
eval {
    $rtx->connect ();
};
ok (! $@, "connection succeeded");
my $arp = $rtx->arp ();
ok ($arp, "got arp");
for my $line (@$arp) {
    ok ($line->{lan} && $line->{ip} && $line->{mac} && $line->{ttl},
	"Got required fields from arp");
}

my $config = "$FindBin::Bin/rtx-config-temp.$$";

if (-f $config) {
    unlink $config or die $!;
}
$rtx->get_config ($config);

ok (-f $config, "Downloaded config OK");
if (-f $config) {
    unlink $config or die $!;
}
done_testing ();

