=pod

=encoding utf-8

=head1 PURPOSE

Test that chaining works

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;

BEGIN {
	package Local::MyClass;
	use Marlin
		foo => { accessor => 'foo', clearer => 'clear_foo', writer => 'set_foo', chain => 1 },
		bar => { accessor => 'bar', clearer => 'clear_bar', writer => 'set_bar', chain => 0 };
};

my $obj = Local::MyClass->new;

$obj->foo(42);
$obj->bar(666);

is($obj->foo, 42);
is($obj->bar, 666);

is(
	+{ %$obj },
	+{ foo => 42, bar => 666 },
);

is( Local::MyClass->new(bar => 42)->foo(1)->set_foo(2)->clear_foo->clear_foo->bar, 42 );
is( Local::MyClass->new(bar => 42)->clear_bar, 42 );
is( Local::MyClass->new(bar => 42)->bar(66), 66 );
is( Local::MyClass->new(bar => 42)->set_bar(66), 66 );

done_testing;
