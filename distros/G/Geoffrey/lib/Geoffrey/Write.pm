package Geoffrey::Write;

use utf8;
use 5.016;
use strict;
use warnings;

$Geoffrey::Write::VERSION = '0.000101';

use parent 'Geoffrey::Role::Core';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{changelog_types} = [
        qw/sequences tables primaries uniques
            foreigns indexes views functions triggers/
    ];
    return bless $self, $class;
}

sub author              { return $_[0]->{author} // 'Mario Zieschang'; }
sub changeset_key       { return $_[0]->{changeset_key} // 'maz'; }
sub inc_changelog_count { return $_[0]->{changelog_count}++; }
sub changelog_count     { $_[0]->{changelog_count} //= 0; return $_[0]->{changelog_count}; }

sub changeset_id {
    my ($self, $i_count) = @_;
    return join q/-/, $self->changelog_count, $i_count ? $i_count : 1, $self->changeset_key;
}

sub changeset {
    my $self = shift;
    return $self->{changeset} if ($self->{changeset});
    require Geoffrey::Changeset;
    $self->{changeset} = Geoffrey::Changeset->new(converter => $self->converter, dbh => $self->dbh,);
    return $self->{changeset};
}

sub run {
    my ($self, $s_dir, $s_schema, $b_dump) = @_;
    my $o_changelog_io = $self->changelog_io;
    $o_changelog_io->converter($self->converter) if $o_changelog_io->needs_converter;

    # if changelog_io needs a dbh it  must store the changelogs into a database
    # and not in a filepath
    if ($o_changelog_io->needs_dbh) {
        $o_changelog_io->dbh($self->dbh);
        $s_dir = q~changelog-~;
    }
    else {
        require File::Path;
        File::Path::make_path($s_dir);
        $s_dir = $s_dir . q~/changelog-~;
    }

    my @a_changelogs = ();
    for (@{$self->{changelog_types}}) {
        my $ar_data = eval { return $self->$_($s_schema, 1); } or do { next; };
        next if scalar @{$ar_data} == 0;
        my $s_file = $s_dir . $self->inc_changelog_count . q/-/ . $_;
        $o_changelog_io->write($s_file, $ar_data, $b_dump);
        push @a_changelogs, $self->changelog_count . q/-/ . $_;
    }
    return $o_changelog_io->write($s_dir . q~/changelog~, {changelogs => \@a_changelogs}, $b_dump);
}

sub sequences {
    my ($self, $s_schema) = @_;
    require Geoffrey::Action::Constraint::Default;
    return [{
            id     => $self->changeset_id,
            author => $self->author,
            entries =>
                Geoffrey::Action::Constraint::Default->new(dbh => $self->dbh, converter => $self->converter)
                ->list_from_schema($s_schema)}];
}

sub tables {
    my ($self, $s_schema, $include_columns) = @_;
    my $count = 1;
    require Geoffrey::Action::Table;
    my $o_tables = Geoffrey::Action::Table->new(dbh => $self->dbh, converter => $self->converter);

    return [map { $self->map_entry([{action => 'table.add', name => $_}], $count++) }
            @{$o_tables->list_from_schema($s_schema)}]
        if !$include_columns;

    require Geoffrey::Action::Column;
    my $o_columns = Geoffrey::Action::Column->new(dbh => $self->dbh, converter => $self->converter);
    return [
        map {
            $self->map_entry([{
                        action  => 'table.add',
                        name    => $_,
                        columns => $o_columns->list_from_schema($s_schema, $_)}
                ],
                $count++
                )
        } @{$o_tables->list_from_schema($s_schema)}];
}

sub primaries {
    my ($self, $s_schema) = @_;
    require Geoffrey::Action::Constraint::PrimaryKey;
    return [
        $self->map_entry(
            Geoffrey::Action::Constraint::PrimaryKey->new(dbh => $self->dbh, converter => $self->converter)
                ->list_from_schema($s_schema))];
}

sub uniques {
    my ($self, $s_schema) = @_;
    require Geoffrey::Action::Constraint::Unique;
    return [
        $self->map_entry(
            Geoffrey::Action::Constraint::Unique->new(dbh => $self->dbh, converter => $self->converter)
                ->list_from_schema($s_schema))];
}

sub foreigns {
    my ($self, $s_schema) = @_;
    my $count = 1;
    require Geoffrey::Action::Constraint::ForeignKey;
    my $o_foreign_keys
        = Geoffrey::Action::Constraint::ForeignKey->new(dbh => $self->dbh, converter => $self->converter);
    return [map { $self->map_entry([$_], $count++) } @{$o_foreign_keys->list_from_schema($s_schema)}];
}

sub indexes {
    my ($self, $s_schema) = @_;
    require Geoffrey::Action::Constraint::Index;
    return [
        $self->map_entry(
            Geoffrey::Action::Constraint::Index->new(converter => $self->converter, dbh => $self->dbh)
                ->list_from_schema($s_schema))];
}

sub views {
    my ($self, $s_schema) = @_;
    require Geoffrey::Action::View;
    return [
        $self->map_entry(
            Geoffrey::Action::View->new(converter => $self->converter, dbh => $self->dbh)
                ->list_from_schema($s_schema),
            1
        )];
}

sub functions {
    my ($self, $s_schema) = @_;
    my $count = 1;
    require Geoffrey::Action::Function;
    my $o_functions = Geoffrey::Action::Function->new(dbh => $self->dbh, converter => $self->converter);
    return [map { $self->map_entry([$_], $count++) } @{$o_functions->list($s_schema)}];
}

sub triggers {
    my ($self, $s_schema) = @_;
    my $count = 1;
    require Geoffrey::Action::Trigger;
    my $o_trigger = Geoffrey::Action::Trigger->new(dbh => $self->dbh, converter => $self->converter);
    return [map { $self->map_entry([$_], $count++) } @{$o_trigger->list($s_schema)}];
}

sub map_entry {
    my ($self, $ar_entries, $i_count) = @_;
    return {id => $self->changeset_id($i_count), author => $self->author, entries => $ar_entries,};
}

1;    # End of Geoffrey::Read

__END__

=head1 NAME

Geoffrey::Write - Write scheme from existing db.

=head1 VERSION

Version 0.000101

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

=head2 author

Read main changelog file and sub changelog files

=head2 changeset

=head2 run

Read main changelog file and sub changelog files

=head2 sequences

=head2 tables

=head2 primaries

=head2 uniques

=head2 foreigns

=head2 indexes

=head2 views

=head2 functions

=head2 triggers

=head2 changeset_key

=head2 map_entry

=head2 changelog_count

=head2 inc_changelog_count

=head2 changeset_id

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

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

