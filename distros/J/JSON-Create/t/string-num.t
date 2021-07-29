use FindBin '$Bin';
use lib $Bin;
use JCT;
my $num = '123';
bless \$num, 'nothing';
my %thing = (num => $num);
my $thing = \%thing;
bless $thing, 'nothing';
my @ref = ($thing);
for (@ref) {
    $_->{num} = int ($_->{num});
    my $json = create_json ($_);
    unlike ($json, qr!"123"!, "destringifying numbers");
}
done_testing ();
