=pod

=encoding utf-8

=head1 PURPOSE

Test the C<< !notwant >> notation.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More tests => 1;

{
	package Local::Foo;
	use Exporter::Shiny qw(foo bar);
	sub foo {
		return 42;
	}
	sub bar {
		return 666;
	}
}

my %imported;
'Local::Foo'->import({ into => \%imported }, qw( -all !foo ));

is_deeply([sort keys %imported], ['bar']);
