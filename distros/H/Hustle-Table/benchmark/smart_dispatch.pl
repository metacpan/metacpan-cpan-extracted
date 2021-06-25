use common::sense;
use Smart::Dispatch;
use Benchmark qw<timethis>;
use  FindBin;

my ($matchers,$samples)=do "$FindBin::Bin/data.pl";

local $,=", ";
#say @$samples;

my $dispatch= dispatcher {
	for(@$matchers){
		say $_;
		match $_, dispatch {};
	}
	  otherwise failover {};
};

timethis(200, sub {
		for my $sample (@$samples){
			$dispatch->($sample);
		}
	}
)
