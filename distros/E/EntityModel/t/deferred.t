use strict;
use warnings;

use Test::More tests => 19;
use EntityModel::Deferred;

{ # Handler first, then value
	my $d = new_ok('EntityModel::Deferred' => [ ]);
	ok($d->add_handler('ready', sub {
		my $defer = shift;
		isa_ok($defer, 'EntityModel::Deferred');
		is($defer->value, 15, 'value is correct');
	}), 'queue the callback');
	ok($d->provide_value(15), 'provide a value');
}
{ # Value from new, then handler
	my $d = new_ok('EntityModel::Deferred' => [ value => 17]);
	ok($d->add_handler('ready', sub {
		my $defer = shift;
		isa_ok($defer, 'EntityModel::Deferred');
		is($defer->value, 17, 'set value immediately');
	}), 'queue the callback');
}
{ # Provide value, then handler
	my $d = new_ok('EntityModel::Deferred' => [ ]);
	ok($d->provide_value(45), 'provide a value before handler');
	ok($d->add_handler('ready', sub {
		my $defer = shift;
		isa_ok($defer, 'EntityModel::Deferred');
		is($defer->value, 45, 'handler picks up the right value');
	}), 'queue the callback');
}
{ # Value from new, then set different value, then handler
	my $d = new_ok('EntityModel::Deferred' => [ value => 8 ]);
	ok($d->provide_value(97), 'provide a value before handler');
	ok($d->add_handler('ready', sub {
		my $defer = shift;
		isa_ok($defer, 'EntityModel::Deferred');
		is($defer->value, 97, 'handler picks up the right value');
	}), 'queue the callback');
}

