package TestSymbiont;

use Kelp::Base qw(Kelp::Module::Symbiosis::Base);
use Plack::Response;

# Some module that can be served by Plack via run()
# extending Symbiosis::Base

attr -num => 1;

sub psgi
{
	my ($self) = @_;

	return sub {
		my $res = Plack::Response->new(200);
		$res->body("mounted" . $self->num);
		return $res->finalize;
	};
}

sub build
{
	my ($self, %args) = @_;
	$self->SUPER::build(%args);

	$self->register(
		testmod => sub {
			return $self;
		}
	);

	my $max_num = $self->num;
	$self->register(
		another => sub {
			my $another = __PACKAGE__->new(app => $self->app, num => ++$max_num);
			$another->SUPER::build(%args);
			return $another;
		}
	);
}

1;
