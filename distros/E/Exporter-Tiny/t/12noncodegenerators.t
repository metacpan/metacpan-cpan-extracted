=pod

=encoding utf-8

=head1 PURPOSE

Test Exporter::Tiny exporting non-code symbols from generators.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
	package My::Exporter;
	use Exporter::Shiny qw( $Foo @Bar %Baz );
	our $_Foo = 42;
	our @_Bar = (1, 2, 3);
	our %_Baz = (quux => 'xyzzy');
	sub _generateScalar_Foo { \$_Foo }
	sub _generateArray_Bar { \@_Bar }
	sub _generateHash_Baz { \%_Baz }
};

BEGIN {
	package My::Importer;
	use My::Exporter -all;
};

is($My::Importer::Foo, 42, 'importing scalar');
is_deeply(\@My::Importer::Bar, [1,2,3], 'importing array');
is_deeply(\%My::Importer::Baz, { quux => 'xyzzy' }, 'importing hash');

$My::Importer::Foo /= 2;
push @My::Importer::Bar, 4;
$My::Importer::Baz{quuux} = 'blarg';

is($My::Exporter::_Foo, 21, 'importing scalar does not copy');
is_deeply(\@My::Exporter::_Bar, [1,2,3,4], 'importing array does not copy');
is_deeply(\%My::Exporter::_Baz, { quux => 'xyzzy', quuux => 'blarg' }, 'importing hash does not copy');

my $into = {};
My::Exporter->import({ into => $into }, qw( $Foo @Bar %Baz ));
is_deeply($into, { '$Foo' => \21, '@Bar' => [1..4], '%Baz' => {qw/quux xyzzy quuux blarg/} }, 'importing non-code symbols into hashrefs');
