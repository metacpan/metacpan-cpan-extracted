use FindBin '$Bin';
use lib $Bin;
use JCT;
use File::Spec;
use File::Temp;

use JSON::Parse 'read_json';
my $directory = File::Temp->newdir ();
my $out = File::Spec->catfile ($directory, "test-write-json.json");
# It's your thing.
my $thing = {a => 'b', c => 'd'};
write_json ($out, $thing);
ok (-f $out, "Wrote a file");
my $roundtrip = read_json ($out);
is_deeply ($roundtrip, $thing);
done_testing ();
