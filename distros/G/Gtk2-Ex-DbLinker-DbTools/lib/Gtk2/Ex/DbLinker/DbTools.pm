
=head1 NAME

Gtk2::Ex::DbLinker::DbTools - Databases access part of DbLinker 

=cut

package Gtk2::Ex::DbLinker::DbTools;
use strict;
use warnings;

=head1 VERSION

version  0.112 

=cut

our $VERSION = '0.112';
$VERSION = eval $VERSION;

sub new {
    my ( $class, $arg ) = @_;
    my $self = {};
    return bless $self, $class;
}

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

	Test::More => 1
	Class::Interface => 1.01
	Try::Tiny => 0.22
	DBI => 1.631
	Log::Log4perl => 1.41
	Data::Dumper => 2.154
	Carp => 1.1631
	SQL::Abstract::More => 1.27

Install one of Rose::DB::Object or DBIx::Class if you want to use these orm to access your data.

Insall one of Gtk2::Ex::DbLinker or Wx::Perl::DbLinker depending on the gui framework you want to use.

=head1 DESCRIPTION

This module automates the process of tying data from a database to widgets build with Gtk2 or Wx.

Steps for use:

=over

=item * 

Create a DataManager object that contains the rows to display. Useone of DbiDataManager, SqlADataManager, RdbDataManager or DbcDataManager depending on how you access the database: DBI with plain sql commands or SQL::Abstract::More, DBIx::Class or Rose::DB::Object.

=item * 

Create a Gtk2::GladeXML object to construct the Gtk2 windows or a xrc resource file to build a Wx Window.
Names of the fields in the form have to be identical with the fields in the tables.

=item * 

Create a Gtk2::Ex::DbLinker::Form or a Wx::Perl::DbLinker::Wxform object that links the data and the windows 

=item *

Cnnect the buttons to methods that handle common actions such as inserting, moving, deleting, etc.

=back

=head1 SUPPORT

Any Gk2::Ex::DbLinker::DbTools questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/gtk2-ex-dblinker-dbtools/>.

=head1 AUTHOR

  FranE<ccedil>ois Rappaz <rappazf@gmail.com>
  CPAN ID: RAPPAZF

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Gtk2::Ex::DbLinker>

L<Wx::Perl::DbLinker>

=cut
