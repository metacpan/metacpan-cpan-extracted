=pod

=encoding utf-8

=head1 PURPOSE

Tests the example shown in L<Marlin::Manual::Comparison>, with minor
adaptations to make it run on Perl v5.8.8.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

{
	package Local::MyRole;
	use Marlin::Role 'foo';
}

{
	package Local::MyClass;
	use Marlin -with => \'Local::MyRole', -strict;
}

is( Local::MyClass->new( foo => 42 )->foo, 42 );

{
	package Local::MyRole2;
	use Marlin::Role 'bar', -with => \'Local::MyRole', -requires => [ 'foobar' ];
}

{
	package Local::MyClass2;
	use Marlin -with => \'Local::MyRole2', -strict;
	
	sub foobar {
		my $self = shift;
		$self->foo * $self->bar;
	}
}

is( Local::MyClass2->new( foo => 7, bar => 6 )->foobar, 42 );

done_testing;
