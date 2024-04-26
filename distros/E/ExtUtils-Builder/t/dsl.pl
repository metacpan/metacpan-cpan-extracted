use strict;
use warnings;

load_module("Callback");

add_foo($_) for 0..2;

create_node(
	target => 'foo',
	dependencies => [ map { "foo$_" } 0..2 ],
	phony => 1,
);

