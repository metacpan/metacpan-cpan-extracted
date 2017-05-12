use v5.14;

package Foo {
	use Moose;
	use MooseX::KavorkaInfo;
	use Kavorka qw( -default -modifiers );
	method xxx (Int $x) { return $x ** 3 }
}

package Foo::Verbose {
	use Moose;
	use MooseX::KavorkaInfo;
	use Kavorka qw( -default -modifiers );
	extends "Foo";
	before xxx { warn "Called xxx" }
}

my $method = Foo::Verbose->meta->get_method("xxx");
say $method->signature->params->[1]->type->name;  # says "Int"
