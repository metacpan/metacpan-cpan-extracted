package Lingua::EN::GivenNames::Database::Create;

use feature 'say';
use parent 'Lingua::EN::GivenNames::Database';
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Moo;

our $VERSION = '1.04';

# -----------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	# Warning: The order is important.

	my($method);
	my($table_name);

	for $table_name (qw/
derivations
forms
kinds
meanings
originals
ratings
sexes
sources
names
/)
	{
		$method = "create_${table_name}_table";

		$self -> $method;
	}

	# Return 0 for success and 1 for failure.

	return 0;

}	# End of create_all_tables.

# --------------------------------------------------

sub create_derivations_table
{
	my($self)        = @_;
	my($table_name)  = 'derivations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
fc_name varchar(255) not null,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_derivations_table.

# --------------------------------------------------

sub create_forms_table
{
	my($self)        = @_;
	my($table_name)  = 'forms';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
fc_name varchar(255) not null,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_forms_table.

# --------------------------------------------------

sub create_kinds_table
{
	my($self)        = @_;
	my($table_name)  = 'kinds';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
fc_name varchar(255) not null,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_kinds_table.

# --------------------------------------------------

sub create_meanings_table
{
	my($self)        = @_;
	my($table_name)  = 'meanings';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
fc_name varchar(255) not null,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_meanings_table.

# --------------------------------------------------

sub create_names_table
{
	my($self)        = @_;
	my($table_name)  = 'names';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
derivation_id integer not null references derivations(id),
form_id integer not null references forms(id),
kind_id integer not null references kinds(id),
meaning_id integer not null references meanings(id),
original_id integer not null references originals(id),
rating_id integer not null references ratings(id),
sex_id integer not null references sexes(id),
source_id integer not null references sources(id),
comment varchar(255) default '',
fc_name varchar(255) not null,
name varchar(255) not null,
timestamp timestamp $time_option not null default current_timestamp
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_names_table.

# --------------------------------------------------

sub create_originals_table
{
	my($self)        = @_;
	my($table_name)  = 'originals';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
fc_name varchar(255) not null,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_originals_table.

# --------------------------------------------------

sub create_ratings_table
{
	my($self)        = @_;
	my($table_name)  = 'ratings';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
fc_name varchar(255) not null,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_ratings_table.

# --------------------------------------------------

sub create_sexes_table
{
	my($self)        = @_;
	my($table_name)  = 'sexes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
fc_name varchar(255) not null,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_sexes_table.

# --------------------------------------------------

sub create_sources_table
{
	my($self)        = @_;
	my($table_name)  = 'sources';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
fc_name varchar(255) not null,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_sources_table.

# -----------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	my($table_name);

	for $table_name (qw/
names
sources
sexes
ratings
originals
meanings
kinds
forms
derivations
/)
	{
		$self -> drop_table($table_name);
	}

	# Return 0 for success and 1 for failure.

	return 0;

}	# End of drop_all_tables.

# -----------------------------------------------

sub drop_table
{
	my($self, $table_name) = @_;

	$self -> creator -> drop_table($table_name);
	$self -> report($table_name, 'dropped', '');

} # End of drop_table.

# -----------------------------------------------

sub report
{
	my($self, $table_name, $message, $result) = @_;

	if ($result)
	{
		die "Table '$table_name' $result\n";
	}
	else
	{
		$self -> log(debug => "Table '$table_name' $message");
	}

} # End of report.

# -----------------------------------------------

1;

=pod

=head1 NAME

Lingua::EN::GivenNames::Database::Create - An SQLite database of derivations of English given names

=head1 Synopsis

See L<Lingua::EN::GivenNames/Synopsis> for a long synopsis.

See also L<Lingua::EN::GivenNames/How do the scripts and modules interact to produce the data?>.

=head1 Description

Documents the methods end-users need to create/drop tables in the SQLite database,
I<lingua.en.givennames.sqlite>, which ships with this distro.

See scripts/create.tables.pl and scripts/drop.tables.pl.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<Lingua::EN::GivenNames::Database::Create>.

This is the class's contructor.

Usage: C<< Lingua::EN::GivenNames::Database::Create -> new() >>.

=head1 Methods

This module is a sub-class of L<Lingua::EN::GivenNames::Database> and consequently inherits its methods.

=head2 create_all_tables()

Create these tables: forms, kinds, meanings, names, originals, ratings, sexes, sources.

Returns 0 to indicate success.

=head2 create_${name}_table()

Create the I<$name> table.

=head2 drop_all_tables()

Drop all the tables.

Returns 0 to indicate success.

=head2 drop_table($table_name)

Drop the table called $table_name,

=head2 new()

See L</Constructor and initialization>.

=head2 report($table_name, $message, $result)

For $table_name, if the result of the create or drop is an error, die with $message.

If there was no error, log a create/drop message at level I<debug>.

=head1 FAQ

For the database schema, etc, see L<Lingua::EN::GivenNames/FAQ>.

=head1 References

See L<Lingua::EN::GivenNames/References>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua::EN::GivenNames>.

=head1 Author

C<Lingua::EN::GivenNames> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
