use EntityModel::Class;
use EntityModel::Log qw(:all);
EntityModel::Log->instance->min_level(0);

use Test::More tests => 3;

use EntityModel::Collection;

note 'Basic tests first';
# We keep a copy of this test in $basic so we can reuse it for subclasses later
subtest 'Basic EntityModel::Collection functionality' => (my $basic = sub {
	my ($class, $extra) = @_;
	sub {
		plan tests => 26 + $extra;
		# Instantiate, check some methods and overloads exist
		my $c = new_ok($class => [ ]);
		Scalar::Util::weaken(my $weak_c = $c);
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
			is($_[0], $weak_c, '$self matches $c in callback for ->each');
			is($_[1], $v, 'item matches in callback for ->each');
			$v = 0;
		}), $c, 'can queue a callback for ->each');
		$post_check->();
		is($c->done(sub {
			is($_[0], $weak_c, '$self matches $c in callback for ->done');
			++$committed;
		}), $c, 'can queue a callback for ->done');
		$post_check->();
		is($c->fail(sub {
			is($_[0], $weak_c, '$self matches $c in callback for ->fail');
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
		undef $c;
		done_testing();
	}
})->('EntityModel::Collection', 0);


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
done_testing();

