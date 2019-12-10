package Geoffrey;

use utf8;
use 5.016;
use strict;
use warnings;
use Readonly;
use Geoffrey::Action::Table;

$Geoffrey::VERSION = '0.000205';

use parent 'Geoffrey::Role::Core';

Readonly::Scalar my $IDX_DATABASE_DRIVER => 18;    #ok

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    bless $self, $class;
    $self->converter->check_version($self->dbh->get_info($IDX_DATABASE_DRIVER));
    $self->_prepare_tables;
    return $self;
}

sub _prepare_tables {
    my ($self) = @_;

    my $o_action_table = Geoffrey::Action::Table->new(dbh => $self->dbh, converter => $self->converter);

    my $hr_changelog_table = $self->converter->get_changelog_table_hashref($self->dbh, $self->schema);
    $o_action_table->add($hr_changelog_table) if $hr_changelog_table;
    return $hr_changelog_table;
}

sub reader {
    my $self = shift;
    require Geoffrey::Read;
    $self->{reader} //= Geoffrey::Read->new(
        converter => $self->converter,
        dbh       => $self->dbh,
        io_name   => $self->io_name,
        schema    => $self->schema,
    );
    return $self->{reader};
}

sub writer {
    my $self = shift;
    require Geoffrey::Write;
    $self->{writer} //= Geoffrey::Write->new(
        converter => $self->converter,
        dbh       => $self->dbh,
        io_name   => $self->io_name,
        schema    => $self->schema,
    );
    return $self->{writer};
}

sub read {
    my ($self, $s_changelog_root) = @_;
    return $self->reader->run($s_changelog_root);
}

sub write {
    my ($self, $s_changelog_root, $s_schema, $dump) = @_;
    return $self->writer->run($s_changelog_root, $s_schema, $dump);
}

sub delete {
    my ($self, $s_changeset_id) = @_;
    return $self->changelog_io->delete($s_changeset_id);
}

sub insert {
    my ($self, $s_file, $hr_changeset) = @_;
    return $self->changelog_io->insert($s_file, $hr_changeset);
}

sub rewrite {
    my ($self, $hr_changeset) = @_;
    return unless $hr_changeset->{id};
    return $self->delete($hr_changeset->{id}) ? $self->insert(q//, [$hr_changeset]) : 0;
}

sub load_changeset {
    my ($self, $s_changeset_id, $s_file) = @_;
    if (!$s_changeset_id) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_id();
    }

    return $self->changelog_io->load_changeset($s_changeset_id, $s_file);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey - Continuous Database Migration

=head1 VERSION

Version 0.000205

=head1 DESCRIPTION

C<Geoffrey> is a pure Perl module.

Continuous Database Migration

A package which allows a continuous development with an application that hold 
the appropriate database system synchronously.

=head1 SYNOPSIS

    use DBI;
    use Geoffrey;

    my $dbh = DBI->connect( "dbi:SQLite:database=league.sqlite" );
    Geoffrey->new( dbh => $dbh )->read( $FindBin::Bin . '/../changelog' );

    ...
    
    my $dbh = DBI->connect( "dbi:Pg:dbname=database;host=127.0.0.1", "user", "password" );
    Geoffrey->new( 
        dbh => $dbh,
        converter_name => 'Pg'
    )->read( $FindBin::Bin . '/../changelog' );

=head1 SUBROUTINES/METHODS

=head2 new

Run to check converter version with installed db converter.

=head2 reader

Instantiates Geoffrey::Read object if none is the in the internal key 'reader'
and returns it

=head2 writer

Instantiates Geoffrey::Write object if none is the in the internal key 'write'
and returns it

=head2 read

Read main changelog file and sub changelog files
Creates changelog table if it's not existing.

=head2 write

Write main changelog file and sub changelog files

=head2 delete

Delete a specific changeset as long there's no md5hash yet.

=head2 insert

Insert a new changeset

=head2 rewrite

The sub delete and insert combined

=head2 load_changeset

Get the value of a changeset by given changeset id.

=head1 MOTIVATION

When working with several people on a large project that is bound to a database.
If you there and back the databases have different levels of development.

You can keep in sync with SQL statements, but these are then incompatible with 
other database systems.

It also should give the posibility to generate the same db schema on several databases
without changing some sql scripts.

=head1 Constructor and initialization

new(...) returns an object of type C<Geoffrey>.

This is the class's constructor.

Usage: Geoffrey->new().

This method takes a set of parameters. Only the dbh parameter is mandatory.

For each parameter you wish to use, call new as new(param_1 => value_1, ...).

=over 4

=item dbh

This is a database handle, returned from DBI's connect() call.

This parameter is mandatory.

There is no default.

=item verbose

=back

=head1 Method: read()

=over 4

=item path to changelog folder

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Geoffrey

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geoffrey

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Geoffrey

    CPAN Ratings
        http://cpanratings.perl.org/d/Geoffrey

    Search CPAN
        http://search.cpan.org/dist/Geoffrey/

=head1 SEE ALSO

=head2 L<DBIx::Admin::CreateTable|DBIx::Admin::CreateTable>

=over 4

The package from which the idea originated.

=back

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

