package Lingua::EN::GivenNames::Database;

use feature 'say';
use parent 'Lingua::EN::GivenNames';
use strict;
use warnings;
use warnings qw(FATAL utf8);

use DBI;

use DBIx::Admin::CreateTable;
use DBIx::Table2Hash;

use File::Slurp; # For read_dir().

use Lingua::EN::StopWordList;

use List::Compare;

use Moo;

use Types::Standard qw/HashRef Str/;

has attributes =>
(
	default  => sub{return {AutoCommit => 1, RaiseError => 1, sqlite_unicode => 1} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has creator =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has dbh =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has dsn =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has engine =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has name =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has page_counts =>
(
	default  => sub{return {female => 20, male => 17} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has password =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has time_option =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has username =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.04';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> dsn('dbi:SQLite:dbname=' . $self -> sqlite_file);
	$self -> dsn('dbi:Pg:dbname=test');
	$self -> username('testuser');
	$self -> password('testpass');
	$self -> dbh(DBI -> connect($self -> dsn, $self -> username, $self -> password, $self -> attributes) ) || die $DBI::errstr;
	$self -> dbh -> do('PRAGMA foreign_keys = ON') if ($self -> dsn =~ /SQLite/i);

	$self -> creator
		(
		 DBIx::Admin::CreateTable -> new
		 (
		  dbh     => $self -> dbh,
		  verbose => 0,
		 )
		);

	$self -> engine
		(
		 $self -> creator -> db_vendor =~ /(?:Mysql)/i ? 'engine=innodb' : ''
		);

	$self -> time_option
		(
		 $self -> creator -> db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : ''
		);

} # End of BUILD.

# ----------------------------------------------

sub get_name_count
{
	my($self) = @_;

	return ($self -> dbh -> selectrow_array('select count(*) from names') )[0];

} # End of get_name_count.

# ----------------------------------------------

sub get_table_names
{
	my($self) = @_;

	return
	{
		derivation => 'derivations',
		form       => 'forms',
		kind       => 'kinds',
		meaning    => 'meanings',
		name       => 'names',
		original   => 'originals',
		rating     => 'ratings',
		sex        => 'sexes',
		source     => 'sources',
	};

} # End of get_table_names.

# -----------------------------------------------

sub get_tables
{
	my($self) = @_;

	my(%data);

	for my $table_name (values %{$self -> get_table_names})
	{
		$data{$table_name} = DBIx::Table2Hash -> new
		(
			dbh        => $self -> dbh,
			key_column => 'id',
			table_name => $table_name,
		) -> select_hashref;
	}

	return \%data;

} # End of get_tables.

# ----------------------------------------------

sub read_names_table
{
	my($self) = @_;
	my($data) = $self -> get_tables;

	my($entry);
	my(@name);

	for my $id (keys %{$$data{names} })
	{
		$entry = $$data{names}{$id};

		push @name,
		{
			derivation => $$data{derivations}{$$entry{derivation_id} }{name},
			fc_name    => $$entry{fc_name},
			form       => $$data{forms}{$$entry{form_id} }{name},
			id         => $id,
			kind       => $$data{kinds}{$$entry{kind_id} }{name},
			meaning    => $$data{meanings}{$$entry{meaning_id} }{name},
			name       => $$entry{name},
			original   => $$data{originals}{$$entry{original_id} }{name},
			rating     => $$data{ratings}{$$entry{rating_id} }{name},
 			sex        => $$data{sexes}{$$entry{sex_id} }{name},
			source     => $$data{sources}{$$entry{source_id} }{name},
		};
	}

	return [sort{$$a{fc_name} cmp $$b{fc_name} } @name];

} # End of read_names_table.

# -----------------------------------------------

sub report_name
{
	my($self, $name) = @_;
	$name            = ucfirst lc ($name || $self -> name);

	die "No name specified\n" if (! $name);

	my($format) = '%-10s  %s';

	for my $item (@{$self -> read_names_table})
	{
		next if ($name ne $$item{name});

		for my $key (sort keys %$item)
		{
			say sprintf $format, $key, $$item{$key};
		}
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of report_name.

# ----------------------------------------------

sub report_statistics
{
	my($self)   = @_;
	my($data)   = $self -> get_tables;
	my($format) = "%-15s  %7s";

	say sprintf $format, 'Table', 'Records';

	my($records);

	for my $table_name (sort keys %$data)
	{
		$records = $$data{$table_name};

		say sprintf $format, $table_name, scalar keys %$records;
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of report_statistics.

# ----------------------------------------------

sub report_stop_words
{
	my($self)       = @_;
	my($data)       = $self -> get_tables;
	my($stop_words) = Lingua::EN::StopWordList -> new -> words;

	for my $table_name (grep{! /names/} values %{$self -> get_table_names})
	{
		my($result) = List::Compare -> new($stop_words, [map{$$data{$table_name}{$_}{name} } keys %{$$data{$table_name} }]);
		my(@match)  = $result -> get_intersection;

		if ($#match >= 0)
		{
			say "Table '$table_name' contains these stop words: ", join(', ', @match);
		}
	}

	# Return 0 for success and 1 for failure.

	return 0;

} # End of report_stop_words.

# -----------------------------------------------

1;

=pod

=head1 NAME

Lingua::EN::GivenNames::Database - An SQLite database of derivations of English given names

=head1 Synopsis

See L<Lingua::EN::GivenNames/Synopsis> for a long synopsis.

See also L<Lingua::EN::GivenNames/How do the scripts and modules interact to produce the data?>.

=head1 Description

Documents the methods end-users need to access the SQLite database,
I<lingua.en.givennames.sqlite>, which ships with this distro.

See L<Lingua::EN::GivenNames/Description> for a long description. See also scripts/*.pl.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<Lingua::EN::GivenNames::Database>.

This is the class's contructor.

Usage: C<< Lingua::EN::GivenNames::Database -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options:

=over 4

=item o attributes => $hash_ref

This is the hashref of attributes passed to L<DBI>'s I<connect()> method.

Default: {AutoCommit => 1, RaiseError => 1, sqlite_unicode => 1}

=item o name => $string

Used to specify a given name which scripts/report.name.pl uses as a key into the database.

Default: ''.

See L</report_name([$name])> below for sample code.

=back

=head1 Methods

This module is a sub-class of L<Lingua::EN::GivenNames> and consequently inherits its methods.

=head2 attributes($hashref)

Get or set the hashref of attributes passes to L<DBI>'s I<connect()> method.

Also, I<attributes> is an option to L</new()>.

=head2 get_name_count()

Returns the result of: 'select count(*) from names'.

=head2 get_table_names()

Returns a hashref where the keys are the English singluar versions of the names of the table, and the values
are the actual table names.

=head2 get_tables()

Returns a hashref whose keys are the table names as returned by sub get_table_names().

The values for these keys are hashrefs of all the data in the corresponding table, as returned by
L<DBIx::Table2Hash>'s select_hashref() method.

These nested hashrefs are keys by the primary key (integer) of each table.

Consequently, get_tables() returns all data for all tables.

See the source code for sub read_names_table() for how to access such data.

=head2 name($string)

Gets and sets the name attribute, as used by scripts/report.name.pl.

Also, I<name> is an option to L</new()>.

=head2 new()

See L</Constructor and initialization>.

=head2 page_counts()

Returns a hashref of the number of web pages dedicated to female and male names:

	{
		female => 20,
		male   => 17,
	}

Used by L<Lingua::EN::GivenNames::Database::Download>.

=head2 read_names_table()

Returns an arrayref of hashrefs of names, sorted by fc_name.

Each element in @$names contains data for 1 record in the database, and has these keys
(in alphabetical order):

	{
		derivation => The derivation,
		fc_name    => The case-folded name,
		form       => The form,
		id         => The primary key of this record,
		kind       => The kind,
		meaning    => The meaning,
		name       => The name,
		original   => The original (name),
		rating     => The rating (relability indicator),
		sex        => The sex,
		source     => The source (language or name),
	}

This is discussed further in L<Lingua::EN::GivenNames/Basic Usage> and L<Lingua::EN::GivenNames/FAQ>.

=head2 report_name([$name])

Here, [] indicate an optional parameter.

Prints the result of searching the I<names> table for a name specified either with the $name parameter, or via
the name parameter to L</new()>.

Sample usage:

	perl scripts/report.name.pl -n Zoe
	outputs:
	derivation  Greek name, meaning "life"
	fc_name     zoe
	form        name
	id          3962
	kind        Greek
	meaning     "life"
	name        Zoe
	original    -
	rating      meaning
	sex         female
	source      -

=head2 report_statistics()

Currently prints these database statistics:

	Table            Records
	derivations         3062
	forms                 15
	kinds                 52
	meanings            1356
	names               3967
	originals           2393
	ratings                5
	sexes                  2
	sources               56

=head2 report_stop_words()

This uses Lingua::EN::StopWordList to report any stop words which happened to be picked up by the regexps
used to parse the web page data.

Currently prints this report:

	Table 'sources' contains these stop words: of
	Table 'forms' contains these stop words: from, name

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
