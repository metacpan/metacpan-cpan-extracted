=pod

=encoding utf-8

=head1 PURPOSE

Test joining tables.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use FindBin '$Bin';

use LINQ;
use LINQ::Util -all;
use LINQ::DSL 'HashSmush';
use LINQ::Database;

my $db = 'LINQ::Database'->new( "dbi:SQLite:dbname=$Bin/data/disney.sqlite", "", "" );

my $people = $db->table( 'person' );
my $pets   = $db->table( 'pet' );

my $joined = $people->join(
	$pets,
	field 'id',
	field 'owner',
	-auto,
);


is( $joined->count, 6 );
like( $db->{last_sql}, qr/JOIN/ );

done_testing;
