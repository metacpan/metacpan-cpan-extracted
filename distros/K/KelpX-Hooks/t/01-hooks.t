use strict;
use warnings;

use Test::More;
BEGIN { use_ok('KelpX::Hooks') }

{

	package HooksTest1;
	use Kelp::Base 'Kelp';
	use KelpX::Hooks;

	hook "json" => sub {
		return "not json anymore";
	};

	hook "json" => sub {
		my $orig = shift;

		return $orig->(@_) . '??';
	};
}

{

	package HooksTest2;
	use Kelp::Base 'Kelp';
	use KelpX::Hooks;
	use Test::More;

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

{

	package HooksTest4;
	use Kelp::Base 'Kelp';
	use KelpX::Hooks;

	sub new
	{
		my ($self, %args) = @_;
		$args{config_module} = 'Config::Less';

		return $self->SUPER::new(%args);
	}

	sub build
	{
		my ($self) = @_;

		$self->load_module('JSON');
	}

	hook "json" => sub {
		return "not json anymore";
	};
}

subtest 'hooks should work' => sub {
	my $app = HooksTest1->new;
	is($app->json, "not json anymore??", "method replacement ok");
};

subtest 'hooks should be available in build' => sub {
	plan tests => 4;

	my $app = HooksTest2->new;
	is($app->json(["test"]), '["test"]', "method replacement ok");
};

subtest 'should not hook if method does not exist' => sub {
	eval { my $app = HooksTest3->new; };
	my $e = $@;
	like($e, qr/hook not_here/, "no method found ok");
};

subtest 'should try to apply the hook late' => sub {
	my $app = HooksTest4->new;
	is($app->json, "not json anymore", "method replacement ok");
};

done_testing;

