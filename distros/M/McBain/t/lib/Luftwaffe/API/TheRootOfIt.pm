package Luftwaffe::API::TheRootOfIt;

use McBain -contextual;

get '/' => (
	cb => sub {
		return ref $_[0];
	}
);

sub new { bless {}, shift };

1;
__END__
