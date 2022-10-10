use lib "lib";
use lib "blib/lib";
use lib "blib/arch";
use IO::FD;

use Benchmark qw<cmpthese>;

my $size=4096*8;#4096*4;
my $source= "X" x $size;
cmpthese -1, {
	copy=>sub {
		my $x=$source;
		substr $x,0,1,"y";
		$x=undef;
	},
	repeat=> sub {
		my $x= "x" x $size;
		substr $x,0,1,"y";
		$x=undef;
	},
	iofdsv=>sub {
		my $x=IO::FD::SV($size);
		substr $x,0,1,"y";
		$x=undef;
	}

};
