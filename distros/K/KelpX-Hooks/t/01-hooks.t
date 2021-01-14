use strict;
use warnings;

use Test::More;
BEGIN { use_ok('KelpX::Hooks') }

{

	package HooksTest1;
	use Kelp::Base 'Kelp';
	use KelpX::Hooks;

	sub _load_config
	{
		my ($self) = @_;
		$self->SUPER::_load_config();
		$self->load_module("JSON");
	}

	hook "json" => sub {
		return "not json anymore";
	};
}

{

	package HooksTest2;
	use Kelp::Base 'Kelp';
	use KelpX::Hooks;
	use Test::More;

	sub _load_config
	{
		my ($self) = @_;
		$self->SUPER::_load_config();
		$self->load_module("JSON");
	}

	sub build
	{
		my ($self) = @_;

		can_ok $self, 'json';
		is($self->json(["this shouldn't be an object"]), '["this shouldn\'t be an object"]', "method replacement ok");
		is($self->something, 50, "this package method hooked");
	}

	sub something
	{
		13;
	}

	hook "json" => sub {
		my ($orig, $self, @args) = @_;

		return $self->$orig->encode(@args);
	};

	hook "something" => sub {
		my ($orig, $self, @args) = @_;
		return $self->$orig(@args) + 37;
	};
}

{

	package HooksTest3;
	use Kelp::Base 'Kelp';
	use KelpX::Hooks;

	hook "not_here" => sub {
		my ($orig, $self, @args) = @_;

		return $self->$orig->encode(@args);
	};
}

HOOKS_WORK: {
	my $app = HooksTest1->new;
	is($app->json, "not json anymore", "method replacement ok");
}

HOOKS_AVAILABLE_IN_BUILD: {
	my $app = HooksTest2->new;
	is($app->json(["test"]), '["test"]', "method replacement ok");
}

CANNOT_HOOK_IF_NOT_EXIST: {
	eval { my $app = HooksTest3->new; };
	my $e = $@;
	like($e, qr/hook not_here/, "no method found ok");
}

done_testing(7);
