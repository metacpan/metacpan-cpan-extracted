
=head1 NAME

Gtk2::Ex::DbLinker - Gui building part with Gtk2 of DbLinker

=cut

package Gtk2::Ex::DbLinker;
use strict;
use warnings;

=head1 VERSION

version  0.112

=cut

our $VERSION     = '0.112';
$VERSION = eval $VERSION;

1;

__END__


=head1 INSTALLATION

To install this module type the following:
	perl Makefile.PL
	make
	make test
	make install

On windows use nmake or dmake instead of make.

=head1 DEPENDENCIES

The following modules are required in order to use Gtk2::Ex::Linker

	Gtk2::Ex::DbLinker::DbTools => latest version (see README)
	DateTime::Format::Strptime => 1.5,
	Test::More => 1,
	Gtk2 => 1.240,
	Log::Log4perl => 1.41,
	Data::Dumper' => 2.154,
	DBD::SQLite'	=> 1.46
    Scalar::Util => 1.45
    Class::InsideOut => 1.13,
    

Install one of Rose::DB::Object or DBIx::Class if you want to use these orm to access your data.

Rose::DB object is required to get example 2_rdb working.
DBIx::Class is required to get example 2_dbc working.

=head1 DESCRIPTION

This module automates the process of tying data from a database to widgets on a Glade-generated form.
All that is required is that you name your widgets the same as the fields in your data source.

Steps for use:

=over

=item * 

Create a DataManager object that contains the rows to display. Use DbiDataManager, RdbDataManager or DbcDataManager depending on how you access the database: sql commands and DBI, DBIx::Class or Rose::DB::Object

=item * 

Create a Gtk2::GladeXML object to construct the Gtk2 windows

=item * 

Create a Gtk2::Ex::DbLinker::Form object that links the data and the windows

=item *

You would then typically connect the buttons to the methods below to handle common actions
such as inserting, moving, deleting, etc.

=back

=head1 EXAMPLES

The examples folder (located in the Gtk2-Ex-DbLinker-xxx folder under cpan/build in your perl folders tree) contains five examples that use a sqlite database of three tables: 

=over

=item *

countries (countryid, country, mainlangid), 

=item *

langues (langid, langue), 

=item *

speaks (langid, countryid) in example2_dbc, file ./data/ex1_1 or (speaksid, langid, countryid) in example2_dbi and 2_rdb, file ./data/ex1

=back

=over

=item *

C<runexample1.pl> runs at the command line, gives a form that uses DBI and sql commands to populate a drop box and a datasheet.

=item *

C<runeexample2_xxx.pl> gives a main form with a bottom navigation bar that displays each record (a country and its main language) one by one. 

A subform displays other(s) language(s) spoken in that country. Each language is displayed one by one and a second navigation bar is used to show these in turn.

For each language, a list gives the others countries where this idiom is spoken. Items from this lists are also add/delete/changed with a third navigation bar.

=item *

C<runexample2_dbc.pl> uses DBIx::Class and Gtk2::Ex::DbLinker::DbcDataManager. The speaks table primary key is the complete row itself, with the two fields, countryid and langid.

=item *

C<runexample2_sqla.pl> uses SQL::Abstract::More and Gtk2::Ex::DbLinker::SqlADataManager. The database is the same as above.

=item *

C<runexample2_dbi.pl> uses sql commands and Gtk2::Ex::DbLinker::DbiDataManager. The speaks table primary key is a counter speaksid (primary key) and the two fields, countryid and langid compose an index which does not allow duplicate rows.

=item *

C<runexample2_rdb.pl> uses Rose::Data::Object and Gtk2::Ex::DbLinker::RdbDataManager. The database is the same as above.

=back

=head1 SUPPORT

Any Gk2::Ex::DbLinker questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/gtk2-ex-dblinker/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Gtk2::Ex::DbLinker::DbTools>

=cut


