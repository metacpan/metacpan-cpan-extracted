use EntityModel::Class;
use EntityModel::Log qw(:all);
EntityModel::Log->instance->min_level(0);

use Test::More tests => 4;

use EntityModel::EntityCollection;

note 'Basic tests first';
subtest 'EntityModel::Collection compatibility' => (my $coll = sub {
	my ($class, $extra) = @_;
	sub {
		plan tests => 24 + $extra;
		# Instantiate, check some methods and overloads exist
		my $c = new_ok($class => [
		]);
		can_ok($c, qw{done fail commit each add_handler has_pending});
		is(ref(\&{$c}), 'CODE', 'can use as a coderef');

		my $v = 17;
		my $committed = 0;
		my $fail = 0;
		my $post_check = sub {
			is($v, 17, '$v is unchanged before commit');
			is($committed, 0, 'not committed yet');
			is($fail, 0, 'no failures seen');
		};
		is($c->each(sub {
			is($_[0], $c, '$self matches $c in callback for ->each');
			is($_[1], $v, 'item matches in callback for ->each');
			$v = 0;
		}), $c, 'can queue a callback for ->each');
		$post_check->();
		is($c->done(sub {
			note explain \@_;
			++$committed;
		}), $c, 'can queue a callback for ->done');
		$post_check->();
		is($c->fail(sub {
			++$fail;
		}), $c, 'can queue a callback for ->fail');
		is($v, 17, '$v is still unchanged before commit');
		is($committed, 0, 'not committed yet');
		is($c->(item => $v), $c, 'can queue an item');
		is($v, 0, 'value was successfully reset');
		is($committed, 0, 'marked as committed');
		is($fail, 0, 'no failures seen');
		is($c->(fail => 'some problem'), $c, 'can signal failure');
		is($v, 0, 'value is unchanged');
		is($committed, 0, 'still marked as committed');
		is($fail, 1, 'single failure seen');
	}
})->('EntityModel::EntityCollection', 0);

subtest 'Basic EntityModel::EntityCollection functionality' => (my $basic = sub {
	my ($class, $extra) = @_;
	sub {
		plan tests => 24 + $extra;
		# Instantiate, check some methods and overloads exist
		my $c = new_ok($class => [
		]);
		can_ok($c, qw{done fail commit each add_handler has_pending});
		is(ref(\&{$c}), 'CODE', 'can use as a coderef');

		my $v = 17;
		my $committed = 0;
		my $fail = 0;
		my $post_check = sub {
			is($v, 17, '$v is unchanged before commit');
			is($committed, 0, 'not committed yet');
			is($fail, 0, 'no failures seen');
		};
		is($c->each(sub {
			is($_[0], $c, '$self matches $c in callback for ->each');
			is($_[1], $v, 'item matches in callback for ->each');
			$v = 0;
		}), $c, 'can queue a callback for ->each');
		$post_check->();
		is($c->done(sub {
			note explain \@_;
			++$committed;
		}), $c, 'can queue a callback for ->done');
		$post_check->();
		is($c->fail(sub {
			++$fail;
		}), $c, 'can queue a callback for ->fail');
		is($v, 17, '$v is still unchanged before commit');
		is($committed, 0, 'not committed yet');
		is($c->(item => $v), $c, 'can queue an item');
		is($v, 0, 'value was successfully reset');
		is($committed, 0, 'marked as committed');
		is($fail, 0, 'no failures seen');
		is($c->(fail => 'some problem'), $c, 'can signal failure');
		is($v, 0, 'value is unchanged');
		is($committed, 0, 'still marked as committed');
		is($fail, 1, 'single failure seen');
	}
})->('EntityModel::EntityCollection', 0);


note 'Verify subclassing works as expected';
package Local::CollectionTestClass;
use EntityModel::Class;
use parent qw(EntityModel::Collection);

# Push an event handler onto the stack before we do anything else
sub import {
	my $class = shift;
	my %args = @_;
	my $pkg = caller(1);
	my $inject = sub {
		my $method = shift;
		logDebug("Injecting method [%s] into [%s] under [%s]", $method, $class, $pkg);
		my $sym = join '::', $class, $method;
		{ no strict 'refs'; *$sym = $args{$method} }
	};
	$inject->($_) for sort keys %args;
}

package main;
subtest 'Subclass functionality' => $basic->('Local::CollectionTestClass', 0);
Local::CollectionTestClass->import(
	'new' => sub {
		my $class = shift;
		bless {
			event_handler => { fail => [ sub {
				is($_[1], 'some problem', 'have expected message');
			} ] }
		}, $class;
	}
);
subtest 'Hardcoded fail handler' => $basic->('Local::CollectionTestClass', 1);

