package AnotherTestSymbiont;

use Kelp::Base qw(Kelp::Module::Symbiosis::Base);
use Plack::Response;

sub psgi
{
	my ($self) = @_;

	return sub {
		my $res = Plack::Response->new(200);
		$res->body("also mounted");
		return $res->finalize;
	};
}

1;
