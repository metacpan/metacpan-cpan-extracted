use Test::Spec;
use lib qw(t);
use Jasmine::Spy qw(:all);
use ExampleClass;

my $invocant;

shared_examples_for "all spies" => sub {
	it "replaces original method" => sub {
		spyOn($invocant, 'foo');
		is($invocant->foo, undef);
	};
	it "does not effect other methods" => sub {
		spyOn($invocant, 'foo');
		is($invocant->bar, 'bar');
	};
	it "can set a return value" => sub {
		spyOn($invocant, 'foo')->andReturn('faz');
		is($invocant->foo, 'faz');
	};
	it "can return list in list context" => sub {
		spyOn($invocant, 'foo')->andReturn(['faz', 'bar', 'bat']);
		my(@list) = $invocant->foo;
		ok(scalar(@list) == 3);
	};
	it "can return hash in list context" => sub {
		spyOn($invocant, 'foo')->andReturn({faz => 'baz', far => 'bar'});
		my(%hash) = $invocant->foo;
		ok(scalar(keys %hash) == 2);
	};
	it "can set a list of return values to be returned in sequence by subsequent calls" => sub {
		spyOn($invocant, 'foo')->andReturnValues('baz', 'bat', 'bar');
		is($invocant->foo, 'baz');
		is($invocant->foo, 'bat');
		is($invocant->foo, 'bar');
	};
	it "can replace a method with a subroutine" => sub {
		my $bar = undef;
		spyOn($invocant, 'foo')->andCallFake(sub { $bar = 'word'; return 'blragh'; });
		$invocant->foo();
		is($bar, 'word');
	};
	it "can call through to the original method" => sub {
		spyOn($invocant, 'foo')->andCallThrough;
		is($invocant->foo, 'foo');
	};
	it "can validate that the spy method was called" => sub {
		spyOn($invocant, 'foo');
		$invocant->foo;
		expectSpy($invocant, 'foo')->toHaveBeenCalled();
	};
	it "can validate that the spy method was called once" => sub {
		spyOn($invocant, 'foo');
		$invocant->foo;
		expectSpy($invocant, 'foo')->toHaveBeenCalled()->once;
	};
	it "can validate that the spy method was called atleast X times" => sub {
		spyOn($invocant, 'foo');
		$invocant->foo;
		$invocant->foo;
		$invocant->foo;
		$invocant->foo;
		expectSpy($invocant, 'foo')->toHaveBeenCalled()->atleast(3);
	};
	it "can validate that the spy method was called at most X times" => sub {
		spyOn($invocant, 'foo');
		$invocant->foo;
		$invocant->foo;
		expectSpy($invocant, 'foo')->toHaveBeenCalled()->atMost(3);
	};
	it "can validate that the spy method was called exactly X times" => sub {
		spyOn($invocant, 'foo');
		$invocant->foo;
		$invocant->foo;
		expectSpy($invocant, 'foo')->toHaveBeenCalled()->exactly(2);
	};
	it "can validate that the spy method was called with specific arguments" => sub {
		spyOn($invocant, 'foo');
		$invocant->foo('baz');
		expectSpy($invocant, 'foo')->toHaveBeenCalledWith('baz');
	};
	it "can validate that the spy method was never called" => sub {
		spyOn($invocant, 'foo');
		expectSpy($invocant, 'foo')->notToHaveBeenCalled();
	};
	it "can validate that the spy method was not called with specific arguments" => sub {
		spyOn($invocant, 'foo');
		$invocant->foo('baz');
		expectSpy($invocant, 'foo')->notToHaveBeenCalledWith('ban');
	};
	it "can retrieve the arguments passed to the spied method" => sub {
		spyOn($invocant, 'foo');
		$invocant->foo('baz');
		eq_deeply(getCalls($invocant, 'foo'), [['baz']]);
	};
	it "stores the calls correctly even when multiple methods are spied upon" => sub {
		spyOn($invocant, 'foo');
		spyOn($invocant, 'bar');
		$invocant->foo('baz');
		$invocant->bar('bat');
		expectSpy($invocant, 'foo')->toHaveBeenCalled;
		is(getCalls($invocant, 'foo')->mostRecent->[0], 'baz');
		expectSpy($invocant, 'bar')->toHaveBeenCalled;
		is(getCalls($invocant, 'bar')->mostRecent->[0], 'bat');
	};
	it "can reset the call list" => sub {
		spyOn($invocant, 'foo');
		$invocant->foo('baz');
		$invocant->foo('baz');
		getCalls($invocant, 'foo')->reset();
		expectSpy($invocant, 'foo')->notToHaveBeenCalled();
	};
	it "can stop spying" => sub  {
		spyOn($invocant, 'foo');
		stopSpying($invocant);
		is($invocant->foo, 'foo');
	};
};

describe "spyOn" => sub {
	describe "an instance" => sub {
		before each => sub {
			$invocant = ExampleClass->new;
		};

		it_should_behave_like "all spies";

		it "only replaces the method on the instance, not the class" => sub {
			spyOn($invocant, 'foo');
			is(ExampleClass->foo, 'foo');
		};
	};
	describe "a package" => sub {
		before each => sub {
			$invocant = "ExampleClass";
		};
		it_should_behave_like "all spies";
		it "also replaces instance methods" => sub {
			spyOn("ExampleClass", "foo");
			my $example = ExampleClass->new;
			is($example->foo, undef);
		};
		after each => sub {
			stopSpying("ExampleClass");
		};
	};
};

runtests;
