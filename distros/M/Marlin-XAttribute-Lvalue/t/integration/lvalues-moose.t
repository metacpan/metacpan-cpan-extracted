=pod

=encoding utf-8

=head1 PURPOSE

Tests Marlin::XAttribute::Lvalue works with Moose.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Test2::Require::Module 'Moose';
use Test2::Require::Module 'MooseX::LvalueAttribute';
use Data::Dumper;

{
	package Local::Foo1;
	use Marlin foo => { ':Lvalue' => 1 };
}

{
	package Local::Foo2;
	use Moose;
	use MooseX::Marlin;
	extends 'Local::Foo1';
	Local::Foo2->meta->make_immutable;
}

my $o = Local::Foo2->new( foo => 42 );
is( $o->foo, 42 );
$o->foo = 99;
is( $o->foo, 99 );

my $attr = Moose::Util::find_meta('Local::Foo1')->get_attribute('foo');
ok( Moose::Util::does_role( $attr, 'MooseX::LvalueAttribute::Trait::Attribute') )
	or diag Dumper($attr);

my $accessor = $attr->associated_methods->[0];
ok( Moose::Util::does_role( $accessor, 'MooseX::LvalueAttribute::Trait::Accessor') )
	or diag Dumper($accessor);

done_testing;
