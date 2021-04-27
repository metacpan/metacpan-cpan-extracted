use FindBin '$Bin';
use lib "$Bin";
use IPNGDT;

my @filex = (
    ['luv.png', 0],
    ['blue.png', 1],
);

for (@filex) {
    cmp_ok (
	alpha_unused (
	    read_png_file ("$Bin/$_->[0]")
	), '==', $_->[1],
	"Got expected $_->[1] for $_->[0]"
    );
}
done_testing ();
