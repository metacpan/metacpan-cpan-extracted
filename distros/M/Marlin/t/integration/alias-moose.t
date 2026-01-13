=pod

=encoding utf-8

=head1 PURPOSE

Tests Marlin::XAttribute::Alias works with Moose.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Test2::Require::Module 'Moose';
use Test2::Require::Module 'MooseX::Aliases';
use Data::Dumper;

{
	package Local::Foo1;
	use Marlin foo => { ':Alias' => 'bar' };
}

{
	package Local::Foo2;
	use Moose;
	use MooseX::Marlin;
	extends 'Local::Foo1';
	has 'baz' => ( is => 'ro' );
	Local::Foo2->meta->make_immutable;
}

my $o = Local::Foo2->new( bar => 42 );
is( $o->foo, 42 );

#local $Data::Dumper::Deparse = 1;
#diag Dumper( \&Local::Foo2::new );

done_testing;
