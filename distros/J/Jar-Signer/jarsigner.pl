#!perl

use FindBin qw( $RealBin );
use lib "$RealBin/lib/";
use Jar::Signer;

my $signer = Jar::Signer->new;
$signer->keystore("$RealBin/MyKeyStore");
$signer->dname("CN=Mark Southern, O=My Company, L=My State, C=USA");
$signer->alias("$RealBin/MyCert");
$signer->jar(shift);
$signer->signed_jar(shift);
$signer->process;
exit;