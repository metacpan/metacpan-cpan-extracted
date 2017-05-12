#!perl -w

use strict;
use Benchmark qw(:all);

{
	package UseMD;
	use Method::Destructor;

	sub new{ bless {}, shift }

	sub DEMOLISH{
		my $i = 0;
		$i++;
	}

	package UseMD_optional;
	use Method::Destructor -optional;

	sub new{ bless {}, shift }

	sub DEMOLISH{
		my $i = 0;
		$i++;
	}
}
{
	package Normal;

	sub new{ bless {}, shift }

	sub DESTROY{
		my $i = 0;
		$i++;
	}
}

cmpthese -1 => {
	demolish => sub{
		for(1 .. 100){
			UseMD->new();
		}
	},
	'demolish/o' => sub{
		for(1 .. 100){
			UseMD_optional->new();
		}
	},
	destroy => sub{
		for(1 .. 100){
			Normal->new();
		}
	},
};
