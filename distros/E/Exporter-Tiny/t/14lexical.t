=pod

=encoding utf-8

=head1 PURPOSE

Tests support for lexical imports on Perl 5.37.2 and above.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires '5.037002';

BEGIN {
	package My::Utils;
	use Exporter::Shiny qw( foo $bar );
	our $bar = 42;
	sub foo { return $bar }
};

{
	use My::Utils -lexical, qw( foo $bar );
	is( foo(), 42 );
	is( $bar, 42 );
	ok ! main->can( 'foo' );
}

ok ! eval ' foo() ';
ok ! eval ' $bar ';

done_testing;
