package Lingua::EN::GivenNames;

use feature 'say';
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Config::Tiny;

use File::ShareDir;
use File::Spec;

use Moo;

use Types::Standard qw/Int Str/;

has config =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has config_file =>
(
	default  => sub{return '.ht.lingua.en.givennames.conf'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has data_dir =>
(
	default  => sub{return 'data'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has sex =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has share_dir =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has sqlite_file =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has verbose =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);


our $VERSION = '1.04';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	(my $package = __PACKAGE__) =~ s/::/-/g;

	$self -> share_dir($ENV{AUTHOR_TESTING} ? 'share' : File::ShareDir::dist_dir($package) );

	say 'share_dir:   ', $self -> share_dir;
	say 'config_file: ', $self -> config_file;
	say 'catfile:     ', File::Spec -> catfile($self -> share_dir, $self -> config_file);

	$self -> config_file(File::Spec -> catfile($self -> share_dir, $self -> config_file) );

	$self -> config(Config::Tiny -> read($self -> config_file) );

	die Config::Tiny -> errstr if (Config::Tiny -> errstr);

	$self -> sqlite_file(File::Spec -> catfile($self -> share_dir, $self -> sqlite_file) );

	binmode STDOUT;

	$self -> log(debug => 'Config file: ' . $self -> config_file);
	$self -> log(debug => 'SQLite file: ' . $self -> sqlite_file);

} # End of BUILD.

# -----------------------------------------------

sub log
{
	my($self, $level, $s) = @_;
	$level ||= 'debug';
	$s     ||= '';

	say "$level: $s" if ($self -> verbose);

}	# End of log.

# -----------------------------------------------

1;

=pod

=head1 NAME

Lingua::EN::GivenNames - An SQLite database of derivations of English given names

=head1 Synopsis

L<http://www.20000-names.com> I<has been scraped> for English given names. You do not need to run the script
which downloads pages from there. That web site, though, does have names for 13 other languages, if you wish
to adapt this distro for a different language.

So, just use the SQLite database shipped with this module, as discussed next, or scripts/export.pl to output to
CSV or HTML.

The database has been exported as L<HTML|http://savage.net.au/Perl-modules/html/given.names.html>.
This on-line version was created with scripts/export.pl's I<jquery> switch set to 1.

The database is also shipped as data/given.names.csv and data/given.names.html, although this latter page
was created with scripts/export.pl's I<jquery> switch set to 0.

=head2 Basic Usage

This is the simplest way to access the data.

	use Lingua::EN::GivenNames::Database;

	my($database) = Lingua::EN::GivenNames::Database -> new;

	# $names is an arrayref of hashrefs.

	my($names) = $database -> read_names_table;

Each element in @$names contains a hashref of data for 1 record in the database, and has these keys
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

The most important fields are: name, sex and derivation.

Here, sex means the classification of the name into I<male> or I<female> within the web site which was scraped
to provide the given name data.

See L</FAQ> entries for details.

=head2 Scripts which output to a file

scripts/export.pl responds to the -h option.

Some examples, with output files that happen to be the defaults:

	shell>perl scripts/export.pl -cvs_file      given.names.csv
	shell>perl scripts/export.pl -web_page_file given.names.html -j 1

=head1 Description

C<Lingua::EN::GivenNames> is a pure Perl module.

It is used to download various Englsh given names-related pages from 20000-names.com, and to then
import data scraped from those pages into an SQLite database.

The pages have already been downloaded, so that phase only needs to be run when pages are updated.
Likewise, the data has been imported.

This means you would normally only ever use the database in read-only mode, as per the L</Synopsis>.

=head1 Constructor and initialization

new(...) returns an object of type C<Lingua::EN::GivenNames>.

This is the class's contructor.

Usage: C<< Lingua::EN::GivenNames -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (these are also methods):

=over 4

=item o config_file => $file_name

The name of the file containing config info, such as I<css_url> and I<template_path>, as used by various modules.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()> on the end-user's
machine, and prefixes it with a simple 'share' on the author's machine (i.e. when $ENV{AUTHOR_TESTING} is 1).

Default: .ht.lingua.en.givennames.conf.

=item o sex => $male_or_female

Some scripts (scripts/extract.derivations.pl and scripts/get.name.pages.pl) set this parameter to 'male' or
'female' as needed. See scripts/import.sh for details.

Default: ''.

=item o sqlite_file => $file_name

The name of the SQLite database of given name data.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()> or with 'share',
as explained under I<config_file> just above.

Default: lingua.en.givennames.sqlite.

=item o verbose => $integer

Print more or less information.

Default: 0 (print nothing).

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

Install Lingua::EN::GivenNames as you would for any C<Perl> module:

Run:

	cpanm Lingua::EN::GivenNames

or run:

	sudo cpan Lingua::EN::GivenNames

or unpack the distro, and then run:

	perl Makefile.PL
	make (or dmake)
	make test
	make install

See L<http://savage.net.au/Perl-modules.html> for details.

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html> for
help on unpacking and installing.

=head1 Methods

=head2 config()

Returns the hashref of config data as read by L<Config::Tiny>. Used like this:

	my($config)  = $self -> config;
	my($css_url) = $$config{_}{css_url}; # Note the '_' hash key!

=head2 config_file($file_name)

Get or set the name of the config file.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()>.

Also, I<config_file> is an option to L</new()>.

=head2 data_dir()

Returns the name of the data dir within the distro, which is the constant 'data'.

=head2 log($level => $s)

Print $s at log level $level, if ($self -> verbose);

Since $self -> verbose defaults to 0, nothing is printed by default.

=head2 new()

See L</Constructor and initialization>.

=head2 sex($male_or_female)

Gets and sets the sex attribute, as used by scripts/extract.derivations.pl and scripts/get.name.pages.pl.

Also, I<sex> is an option to L</new()>.

=head2 share_dir()

Returns the name of the share dir. When $ENV{AUTHOR_TESTING} is 1, this will be 'share', within the distro.
And when $ENV{AUTHOR_TESTING} is 0 (i.e. on an end-user machine), it will be the directory returned by
L<File::ShareDir/dist_dir()>.

=head2 sqlite_file($file_name)

Get or set the name of the database file.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()>.

Also, I<sqlite_file> is an option to L</new()>.

=head2 verbose($integer)

Get or set the verbosity level.

Also, I<verbose> is an option to L</new()>.

=head1 FAQ

=head2 What does L<Lingua::EN::GivenNames::Database>'s read_names_table() return?

It returns an arrayref of hashrefs.

Each element in the arrayref contains data for 1 record built from the names table, and has these keys
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

Details:

=over 4

=item o derivation

This is the name field from the derivations table.

=item o fc_name

This is the case-folded version of the name field (below).

=item o form

This is the name field from the forms table.

=item o id

This is the primary key in the names table.

=item o kind

This is the name field from the kinds table.

=item o meaning

This is the name field from the meanings table.

=item o name

This is, finally, the name itself.

=item o original

This is the name field from the originals table.

=item o rating

This is the name field from the ratings table.

=item o sex

This is the name field from the sexes table.

The value is the classification of the name into I<male> or I<female> within the web site which was scraped
to provide the given name data.

=item o source

This is the name field from the sources table.

=back

=head2 Are the input web pages difficult to process?

Yes! Some pages contain names in various character encodings, making the derivation analysis very
difficult.

Examples of the many, many things to watch out for are:

=over 4

=item o data/female_english_names.htm line 4913

=item o data/female_english_names_05.htm line 3284

=item o The hex char \xC2

This appears all over the place.

=item o Nested web pages

The pages contain the names in a table of 1 row and 1 column, within which is a long list
of the <li> entries I parse.

But elsewhere on the pages, entire web pages have been jammed into table cells. Thanx FrontPage!

=back

=head2 Where is the database?

It is shipped in share/lingua.en.givennames.sqlite.

It is installed into the distro's shared dir, as returned by L<File::ShareDir/dist_dir()>.
On my machine that's:

/home/ron/perl5/perlbrew/perls/perl-5.14.2/lib/site_perl/5.14.2/auto/share/dist/Lingua-EN-GivenNames/lingua.en.givennames.sqlite.

=head2 Where is the config file?

It is shipped in share/.ht.lingua.en.givennames.conf.

It is installed into the distro's shared dir, along with the database.

=head2 What is the database schema?

See data/schema.png.

The table names are: forms, kinds, meanings, names, originals, ratings, sexes and sources,
with names being the main table.

These are the columns in the names table:

=over 4

=item o derivation_id

This is a foreign key pointing to the id column of the derivations table. See data/schema.png.

The name field in the derivations table is constructed from various fields in the input,
in one of the following ways. These fields are extracted from the input using capturing parentheses
in regexps.

=over 4

=item o qq|$$item{kind} $$item{form}, $$item{rating} $$item{meaning}|

That is, for a given name, the kind field in the input is put into the kinds table, and the
id which results from that insertion goes into the kind_id field in the names table. Likewise for the
other components in this derivation.

This is used when the regexp in L<Lingua::EN::GivenNames::Database::Import> sub parse_derivations()
is type 'c', and hence there is no field in the input which can be extracted and put into the
originals table. In this case, the name field in the originals table is '-'. The id in the originals
table will, in this case, be 1 and the original_id field in the names table will also be 1.
Note: whenever the name field in the originals table is '-', then the name in the sources table is
also '-'.

=item o qq|$$item{kind} $$item{form} of $$item{source} $$item{original}, $$item{rating} $$item{meaning}|

This is used for regexp types 'a', 'b' and 'd', when a meaningful value for original can be extracted
from the input.

=back

In other words, when extracting data from the various tables, if you wish to reconstruct the value
in the derivations table from the foreign keys in the names table, then one of these syntaxes must
be used to build the original derivation scraped from the web pages. To save you that effort is
of course why the derivations table is provided, and which is accessed via the derivation_id in the
names table.

=item o fc_name

This is the case-folded version of the name field (below).

=item o form_id

This is a foreign key pointing to the id column of the forms table.

If we say the name 'Tonya' is the English equivalent of the Italian/Spanish 'Tonia', then the
'equivalent' component comes from the forms table.

=item o id

This is the primary key.

=item o kind_id

This is a foreign key pointing to the id column of the kinds table.

If we say the name 'Tonya' is the English equivalent of the Italian/Spanish 'Tonia', then the
'English' component of that derivation comes from the kinds table

=item o meaning_id

This is a foreign key pointing to the id column of the meanings table.

Given the derivation of Tonya as 'English equivalent of Italian/Spanish Tonia, a short form of Latin Antonia, possibly meaning "invaluable"',
then the component "invaluable" comes from the meanings table.

=item o name

This is the name itself.

=item o original_id

This is a foreign key pointing to the id column of the originals table.

Given the derivation of Tonya as 'English equivalent of Italian/Spanish Tonia, a short form of Latin Antonia, possibly meaning "invaluable"',
then the component 'Tonia, a short form of Latin Antonia' comes from the originals table.

=item o rating_id

This is a foreign key pointing to the id column of the ratings table.

The value in the ratings table gives an indicator of the reliability of the meaning of the name,
where the meaning comes from the meanings table.

The value will be one of:

=over 4

=item o meaning

It just means what it means.

=item o meaning both

That is, the name has 2 meanings.

Thus the name 'Bonny' means both "good" and "pretty".

=item o meaning either

That is, there is doubt as to which of the 2 meanings is most reliable. The name field in the
corresponding meanings table will have 2 separate meanings in double-quotes.

Thus the name 'Ailward' has the meaning "noble guard" or "elf guard".

=item o meaning simply

Thus the name 'Brande' means simply "brandy".

=item o possibly meaning

Thus the name 'Raelene' possibly means "sunbeam".

=back

=item o sex_id

This is a foreign key pointing to the id column of the sexes table.

The value in the sexes table, female or male, is how the web site classified the name.
So, female means the name came from one of the data/female_english_names*.htm files. Likewise for male.

=item o source_id

This is a foreign key pointing to the id column of the sources table.

The value in the sources table is often a language, e.g. 'Italian/Spanish'.

Thus when we say the name 'Tonya' is the English equivalent of the Italian/Spanish 'Tonia', this means
'Tonya' is sourced from 'Tonia' in Italian/Spanish.

=back

=head2 What do I do if I find a mistake in the data?

What data? What mistake? How do you know it's wrong?

Also, you must decide what exactly you were expecting the data to be.

Firstly, report your claim to the webmaster at L<20000-names.com>.

Note: The input data is partially free-form, as per the original web pages, and commentary
as used on those pages I<is impossible to parse perfectly with regexps>.

So, perhaps the solution lies in making the regexps in L<Lingua::EN::GivenNames::Database::Import> smarter.

Another possibility is to pre-process one or both of the input files data/derivations.raw and
data/derivations.csv before they are processed. The next question discusses how to intervene in the
data flow.

=head2 How do the scripts and modules interact to produce the data?

Recall from above that the web site L<20000-names.com> I<has been scraped>. The output files from that
step are in data/*.htm.

The database tables are created with:

	scripts/drop.tables.pl
	scripts/create.tables.pl

Then the data is processed with (see scripts/import.sh):

	Input files: data/*.htm
	Reader:      scripts/extract.derivations.pl
	Output file: data/derivations.raw
	Reader:      scripts/parse.derivations.pl
	Output file: data/derivations.csv
	Reader:      scripts/import.derivations.pl
	Output file: share/lingua.en.givennames.sqlite (when $ENV{AUTHOR_TESTING} == 1)
	Reader:      scripts/export.pl
	Output file: data/given.names.html

Scripts (in alphabetical order):

=over 4

=item o scripts/create.tables.pl

Creates all the database tables. Remember to run drop.tables.pl first if the tables already exist.

=item o scripts/drop.tables.pl

Drops all the database tables. Then run create.tables.pl immediately afterwards.

=item o scripts/export.pl

This script obviously reads the database and outputs the expected data. It uses
L<Lingua::EN::GivenNames::Database::Export>, and command line options -csv_file or -web_page_file.

=item o scripts/extract.derivations.pl

This script is run once each for 20 pages of female names and once each for 17 pages of male names.
It uses L<Lingua::EN::GivenNames::Database::Import>.

=item o scripts/extract.parse.sh

Run scripts/extract.derivations.pl and then scripts/parse.derivations.pl on one page for one sex.
This script is used only by the author while developing the module.

=item o scripts/get.name.pages.pl

This script is run once to get 20 pages of female names and once to get 17 pages of male names.
It uses L<Lingua::EN::GivenNames::Database::Download>.

=item o scripts/import.derivations.pl

This scripts actually writes the database tables. It uses L<Lingua::EN::GivenNames::Database::Import>.

=item o scripts/import.sh

That sequence of commands (above) is performed by scripts/import.sh.

To re-create the database, do this:

=over 4

=item o shell> AUTHOR_TESTING=1

This will tell the code to write to share/lingua.en.givennames.sqlite, rather than to the installed database.
The latter is probably read-only, anyway.

=item o shell> export AUTHOR_TESTING

=item o shell> scripts/import.sh

This runs all the appropriate scripts in one hit. The output is worth examining to get some idea of what happens.

=back

=item o scripts/parse.derivations.pl

Besides outputting data/derivations.csv, this script also outputs data/mismatches.log and
data/parse.log. It uses L<Lingua::EN::GivenNames::Database::Import>.

See L</TODO> for more about the mismatches file.

Also, this script uses data/unparsable.txt to skip some names. Further, it currently skips names which
are not all ASCII characters.

=item o scripts/pod2html.sh

A bash script to convert all *.pm files into HTML under my web server's doc root.

=item o scripts/report.name.pl

Takes a '-name $name' parameter. Samples:

1) perl -Ilib scripts/report.name.pl -n Abaegayle

	derivation  Variant spelling of English Abigail, meaning "father rejoices"
	fc_name     abaegayle
	form        spelling
	id          8
	kind        Variant
	meaning     "father rejoices"
	name        Abaegayle
	original    Abigail
	rating      meaning
	sex         female
	source      English

Consult L<http://savage.net.au/Perl-modules/html/Lingua/EN/GivenNames/given.names.html> for the 6 ways to spell
Abagail.

2) perl scripts/report.name.pl -n Zoe

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

=item o scripts/report.statistics.pl

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

=item o scripts/report.stop.words.pl

This uses Lingua::EN::StopWordList to report any stop words which happened to be picked up by the regexps
used to parse the web page data.

Currently prints this report:

	Table 'sources' contains these stop words: of
	Table 'forms' contains these stop words: from, name

=item o scripts/test.pattern.pl

This is code I use to test new regexps before putting them into production in sub parse_derivations()
in L<Lingua::EN::GivenNames::Database::Import>.

=back

=head2 What is $ENV{AUTHOR_TESTING} used for?

When this env var is 1, scripts output to share/*.sqlite within the distro's dir. That's how I populate the
database tables. After installation, the database is elsewhere, and read-only, so you don't want the scripts
writing to that copy anyway.

After end-user installation, L<File::ShareDir> is used to find the installed version of *.sqlite.

=head2 TODO

Mismatches, output from analyzing the web pages, are shipped in data/mismatches.log. The next step is to
extend the list of regexps in L<Lingua::EN::GivenNames::Database::Import>'s sub parse_derivations() to
capture more derivations.

The mismatch file is sorted and reformatted compared to the data/derivations.*, to make it easy to use to
build new regexps.

=head2 Why don't you use Perl6::Slurp to read files?

Because I found it (V 0.051000) did not respect the 'raw' file encoding option I specified.

=head1 Non-English names

The web site L<20000-names.com> has names in various other languages, for those wishing the adapt
this code to deal with those cases.

=head1 REPOSITORY

L<https://github.com/ronsavage/Lingua-EN-GivenNames>

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
