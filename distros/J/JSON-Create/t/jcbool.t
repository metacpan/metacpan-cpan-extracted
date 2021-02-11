use FindBin '$Bin';
use lib "$Bin";
use JCT;
use JSON::Create::Bool qw!true false!;

my %obj = (yes => true, no => false);
my $out = create_json (\%obj);
like ($out, qr!"yes":true!, "True OK");
like ($out, qr!"no":false!, "False OK");

done_testing ();
