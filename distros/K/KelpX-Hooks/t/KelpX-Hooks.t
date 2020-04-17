use strict;
use warnings;

use Test::More;
BEGIN { use_ok('KelpX::Hooks') };

{
	package HooksTest1;
	use Kelp::Base 'Kelp';
	use KelpX::Hooks;

	sub _load_config {
		my ($self) = @_;
		$self->SUPER::_load_config();
		$self->load_module("JSON");
	}

	hook "json" => sub {
		return "not json anymore";
	};

	1;
}

{
	package HooksTest2;
	use Kelp::Base 'Kelp';
	use KelpX::Hooks;

	sub _load_config {
		my ($self) = @_;
		$self->SUPER::_load_config();
		$self->load_module("JSON");
	}

	hook "json" => sub {
		my ($orig, $self, @args) = @_;

		return $self->$orig->encode(@args);
	};

	1;
}

{
	package HooksTest3;
	use Kelp::Base 'Kelp';
	use KelpX::Hooks;

	hook "not_here" => sub {
		my ($orig, $self, @args) = @_;

		return $self->$orig->encode(@args);
	};

	1;
}

my $app = HooksTest1->new;
is($app->json, "not json anymore", "method replacement ok");

$app = HooksTest2->new;
is($app->json(["test"]), '["test"]', "method replacement ok");

eval { $app = HooksTest3->new; };
my $e = $@;
ok($e, "exception caught during construction");
like($e, qr/hook not_here/, "no method found");

done_testing();
