=pod

=encoding utf-8

=head1 PURPOSE

Tests destructors work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

our ( @BUILD, @DEMOLISH );

BEGIN {
	package Local::Foo;
	use Marlin;
	sub BUILD     { push @BUILD, __PACKAGE__ };
	sub DEMOLISH  { push @DEMOLISH, __PACKAGE__ };
};

BEGIN {
	package Local::Foo::Bar;
	use Marlin -base => \'Local::Foo';
	sub BUILD     { push @BUILD, __PACKAGE__ };
	sub DEMOLISH  { push @DEMOLISH, __PACKAGE__ };
};

do {
	my $x = Local::Foo::Bar->new;

	is( \@BUILD, [ 'Local::Foo', 'Local::Foo::Bar' ] ) or diag Dumper \@BUILD;
	is( \@DEMOLISH, [] ) or diag Dumper \@DEMOLISH;
	is( +{%$x}, {} );
};

is( \@BUILD, [ 'Local::Foo', 'Local::Foo::Bar' ] ) or diag Dumper \@BUILD;
is( \@DEMOLISH, [ 'Local::Foo::Bar', 'Local::Foo' ] ) or diag Dumper \@DEMOLISH;

done_testing;
