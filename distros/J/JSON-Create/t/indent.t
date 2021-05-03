# Test the indentation feature.

use FindBin '$Bin';
use lib $Bin;
use JCT;

use JSON::Parse 'valid_json';
# Get up offa that thing
my %thing = ("it's your thing" => [qw! do what you wanna do!],
	     "I can't tell you" => [qw! who to sock it to !]);
for my $object (0..1) {
    my $out;
    if ($object) {
	my $jc = JSON::Create->new ();
	$jc->indent (1);
	$out = $jc->create (\%thing);
    }
    else {
	$out = create_json (\%thing, indent => 1);
    }
	#print "$out\n";
    like ($out, qr!^\t"I!sm, "indentation of object key");
    like ($out, qr!^\t\t"sock!sm, "indentation of array element");
    like ($out, qr!\n$!, "final newline");
    ok (valid_json ($out), "JSON is valid");
}

# http://mikan/bugs/bug/2067
# Add a newline after singles with indent

my $in = undef;
my $out = create_json ($in, indent => 1);
like ($out, qr!null\n!, "Add newline on singles");

done_testing ();
