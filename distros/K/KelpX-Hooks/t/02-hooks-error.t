use strict;
use warnings;

use Test::More;

{

	package BuildHook;
	use Kelp::Base 'Kelp';
	use KelpX::Hooks;
	use Test::More;

	eval {
		hook "build" => sub {
			my ($orig, $self, @args) = @_;

			return $self->$orig(@args);
		};
	};

	my $e = $@;
	like($e, qr/Hooking build\(\)/, "cannot hook build ok");
}

{

	package NotKelp;
	use KelpX::Hooks;
	use Test::More;

	eval {
		hook "something" => sub {
			my ($orig, $self, @args) = @_;

			return $self->$orig(@args);
		};
	};

	my $e = $@;
	like($e, qr/no build\(\) method/, "cannot hook without build");
}

done_testing(2);
