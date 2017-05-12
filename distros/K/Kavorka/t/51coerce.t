=pod

=encoding utf-8

=head1 PURPOSE

Check that type coercions work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package Example;
	use Kavorka;
	use Type::Registry qw(t);
	
	BEGIN {
		t->add_types( -Standard );
		t->add_type( t->Int->create_child_type(name => 'RoundedInt1') );
		t->add_type( t->Int->create_child_type(name => 'RoundedInt2') );
		
		t->RoundedInt1->coercion->add_type_coercions(t->Num, q   { int($_) });
		t->RoundedInt2->coercion->add_type_coercions(t->Num, sub { int($_) });
	};
	
	# We need to test a non-inlinable coercion.
	::ok( not t->RoundedInt2->coercion->can_be_inlined );
	
	fun foo ( RoundedInt1 $x )              { return $x }
	fun bar ( RoundedInt1 $x does coerce )  { return $x }
	fun baz ( RoundedInt2 $x does coerce )  { return $x }
	
	fun foo_array ( RoundedInt1 @y )              { return \@y }
	fun bar_array ( RoundedInt1 @y does coerce )  { return \@y }
	fun baz_array ( RoundedInt2 @y does coerce )  { return \@y }

	fun foo_arrayref ( slurpy ArrayRef[RoundedInt1] $z )              { return $z }
	fun bar_arrayref ( slurpy ArrayRef[RoundedInt1] $z does coerce )  { return $z }
	fun baz_arrayref ( slurpy ArrayRef[RoundedInt2] $z does coerce )  { return $z }
}

is(
	Example::foo(42),
	42,
	'type constraint with coercion, but parameter does not coerce - valid value'
);

ok(
	exception { Example::foo(42.1) },
	'type constraint with coercion, but parameter does not coerce - invalid value'
);

is(
	Example::bar(42),
	42,
	'type constraint with coercion - valid value'
);

is(
	Example::bar(42.2),
	42,
	'type constraint with coercion - coercible value'
);

ok(
	exception { Example::bar("Non-numeric") },
	'type constraint with coercion - invalid value'
);

is(
	Example::baz(42),
	42,
	'type constraint with non-inlinable coercion - valid value'
);

is(
	Example::baz(42.2),
	42,
	'type constraint with non-inlinable coercion - coercible value'
);

ok(
	exception { Example::baz("Non-numeric") },
	'type constraint with non-inlinable coercion - invalid value'
);

note "arrays...";

is_deeply(
	Example::foo_array(123, 42),
	[123, 42],
	'type constraint with coercion, but parameter does not coerce - valid value'
);

ok(
	exception { Example::foo_array(123, 42.1) },
	'type constraint with coercion, but parameter does not coerce - invalid value'
);

is_deeply(
	Example::bar_array(123, 42),
	[123, 42],
	'type constraint with coercion - valid value'
);

is_deeply(
	Example::bar_array(123, 42.2),
	[123, 42],
	'type constraint with coercion - coercible value'
);

ok(
	exception { Example::bar_array("Non-numeric") },
	'type constraint with coercion - invalid value'
);

is_deeply(
	Example::baz_array(123, 42),
	[123, 42],
	'type constraint with non-inlinable coercion - valid value'
);

is_deeply(
	Example::baz_array(123, 42.2),
	[123, 42],
	'type constraint with non-inlinable coercion - coercible value'
);

ok(
	exception { Example::baz_array("Non-numeric") },
	'type constraint with non-inlinable coercion - invalid value'
);

note "arrayrefs...";

is_deeply(
	Example::foo_arrayref(123, 42),
	[123, 42],
	'type constraint with coercion, but parameter does not coerce - valid value'
);

ok(
	exception { Example::foo_arrayref(123, 42.1) },
	'type constraint with coercion, but parameter does not coerce - invalid value'
);

is_deeply(
	Example::bar_arrayref(123, 42),
	[123, 42],
	'type constraint with coercion - valid value'
);

is_deeply(
	Example::bar_arrayref(123, 42.2),
	[123, 42],
	'type constraint with coercion - coercible value'
);

ok(
	exception { Example::bar_arrayref("Non-numeric") },
	'type constraint with coercion - invalid value'
);

is_deeply(
	Example::baz_arrayref(123, 42),
	[123, 42],
	'type constraint with non-inlinable coercion - valid value'
);

is_deeply(
	Example::baz_arrayref(123, 42.2),
	[123, 42],
	'type constraint with non-inlinable coercion - coercible value'
);

ok(
	exception { Example::baz_arrayref("Non-numeric") },
	'type constraint with non-inlinable coercion - invalid value'
);

done_testing;

