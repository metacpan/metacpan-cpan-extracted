=pod

=encoding utf-8

=head1 PURPOSE

Test that LINQ::Database works.

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
use LINQ::Database;

my $db = 'LINQ::Database'->new( "dbi:SQLite:dbname=$Bin/data/disney.sqlite", "", "" );

my @people =
	$db
		->table( 'person' )
		->select( fields 'id', 'name', -as => 'moniker' )
		->order_by( -numeric, sub { $_->id } )
		->to_list;

is_deeply(
	[ map $_->moniker, @people ],
	[ qw( Anna Elsa Kristoff Sophia Rapunzel Lottie ) ],
	'$db->table("person")->select->order_by'
);

is(
	$db->{last_sql},
	'SELECT "id", "name" FROM person',
	'... expected SQL'
);

@people =
	$db
		->table( 'person' )
		->order_by( -numeric, sub { $_->id } )
		->select( fields 'id', 'name', -as => 'moniker' )
		->to_list;

is_deeply(
	[ map $_->moniker, @people ],
	[ qw( Anna Elsa Kristoff Sophia Rapunzel Lottie ) ],
	'$db->table("person")->order_by->select'
);

is(
	$db->{last_sql},
	'SELECT * FROM person',
	'... expected SQL'
);

is(
	$db
		->table( 'pet' )
		->where( check_fields 'id', -is => 2 )
		->single
		->name,
	'Pascal',
	'$db->table("pet")->where->single'
);

is(
	$db->{last_sql},
	'SELECT * FROM pet WHERE ("id" == \'2\')',
	'... expected SQL'
);

is(
	$db
		->table( 'pet' )
		->where( check_fields 'id', -is => 2 )
		->select( fields 'name', -as => 'moniker' )
		->single
		->moniker,
	'Pascal',
	'$db->table("pet")->where->select->single'
);

is(
	$db->{last_sql},
	'SELECT "name" FROM pet WHERE ("id" == \'2\')',
	'... expected SQL'
);

is(
	$db
		->table( 'pet' )
		->where( check_fields 'id', -match => [ 2 ] )
		->select( fields 'name', -as => 'moniker' )
		->single
		->moniker,
	'Pascal',
	'$db->table("pet")->where(PERL)->select->single'
);

is(
	$db->{last_sql},
	'SELECT * FROM pet',
	'... expected SQL'
);

is(
	$db
		->table( 'pet' )
		->select( fields 'name', -as => 'moniker' )
		->where( check_fields 'moniker', -match => qr/^Pas/ )
		->single
		->moniker,
	'Pascal',
	'$db->table("pet")->select->where->single'
);

is(
	$db->{last_sql},
	'SELECT "name" FROM pet',
	'... expected SQL'
);

done_testing;

