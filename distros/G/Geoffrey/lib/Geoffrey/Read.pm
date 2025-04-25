package Geoffrey::Read;

use utf8;
use 5.016;
use strict;
use warnings FATAL => 'all';
use Geoffrey::Template;
use Geoffrey::Changeset;

$Geoffrey::Read::VERSION = '0.000206';

use parent 'Geoffrey::Role::Core';

sub _obj_entries {
    my ($self) = @_;
    require Geoffrey::Action::Entry;
    $self->{entries} //= Geoffrey::Action::Entry->new(dbh => $self->dbh, converter => $self->converter,);
    return $self->{entries};
}

sub _parse_changelogs {
    my ($self, $ar_changelogs, $s_changelog_root) = @_;
    for my $i_changelog (@{$ar_changelogs}) {
        my $s_changelog
            = $s_changelog_root
            ? File::Spec->catfile($s_changelog_root, "changelog-$i_changelog")
            : "changelog-$i_changelog";
        return 0 if !$self->_parse_log($s_changelog);
    }
    return 1;
}

sub _parse_log {
    my ($self, $s_changelog) = @_;
    for (@{$self->changelog_io->load($s_changelog)}) {
        my $changeset_result = $self->run_changeset($_, $s_changelog);
        return 0 if $changeset_result->{exit};
    }
    return 1;
}

sub _get_sql_abstract {
    my ($self) = @_;
    require SQL::Abstract;
    $self->{sql_abstract} //= SQL::Abstract->new;
    return $self->{sql_abstract};
}

sub _get_changset_by_id {
    my ($self, $s_changeset_id) = @_;
    my $s_changelog_name = ($self->schema ? $self->schema . q/./ : q//) . $self->converter->changelog_table;
    my $s_changeset_sql = $self->_get_sql_abstract->select($s_changelog_name, qw/*/, {id => $s_changeset_id});
    my $hr_result = $self->dbh->selectrow_hashref($s_changeset_sql, {Slice => {}}, ($s_changeset_id));
    return unless $hr_result;
    require Geoffrey::Utils;
    return Geoffrey::Utils::to_lowercase($hr_result);
}

sub _check_key {
    my ($self, $s_changeset_id, $s_md5sum) = @_;
    my $hr_db_changeset = $self->_get_changset_by_id($s_changeset_id);
    return 0 unless scalar keys %{$hr_db_changeset};
    return 0 unless $hr_db_changeset->{md5sum};

    if ($hr_db_changeset->{md5sum} ne $s_md5sum) {
        require Geoffrey::Exception::Database;
        Geoffrey::Exception::Database::throw_changeset_corrupt($s_changeset_id, $s_md5sum, $hr_db_changeset->{md5sum});
    }
    return 1;
}

sub run_changeset {
    my ($self, $hr_changeset, $s_file) = @_;
    return {exit => 1} if $hr_changeset->{stop};
    if (!$hr_changeset->{id}) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_id($s_file);
    }
    require Hash::MD5;
    my $s_changeset_checksum = Hash::MD5::sum($hr_changeset);
    return {key => 1} if $self->_check_key($hr_changeset->{id}, $s_changeset_checksum);
    $self->changeset->handle_entries($hr_changeset->{entries});
    my $s_table_name = ($self->schema ? $self->schema . q/./ : q//) . $self->converter->changelog_table;
    require Geoffrey::Utils;
    my $hr_db_changeset = Geoffrey::Utils::to_lowercase($self->_get_changset_by_id($hr_changeset->{id}));

    if ($hr_db_changeset) {
        return {
            changeset => $self->_obj_entries->alter(
                $s_table_name,
                {id => $hr_changeset->{id}},
                [{md5sum => $s_changeset_checksum}],
            )};
    }

    return {
        changeset => $self->_obj_entries->add({
                table  => $s_table_name,
                values => [{
                        created_by       => $hr_changeset->{author},
                        geoffrey_version => $Geoffrey::Read::VERSION,
                        comment          => 'Imported by current db.',
                        id               => $hr_changeset->{id},
                        filename         => $s_file,
                        md5sum           => $s_changeset_checksum,
                    }]})};
}

sub schema { return shift->{schema}; }

sub changeset {
    my ($self, $obj_changeset) = @_;
    $self->{changeset} = $obj_changeset if $obj_changeset;
    $self->{changeset}
        //= Geoffrey::Changeset->new(converter => $self->converter, dbh => $self->dbh, schema => $self->schema,);
    return $self->{changeset};
}

sub run {
    my ($self, $s_changelog_root) = @_;
    $self->changelog_io->converter($self->converter) if $self->changelog_io->needs_converter;
    $self->changelog_io->dbh($self->dbh)             if $self->changelog_io->needs_dbh;
    my $hr_main_changeset = $self->changelog_io->load(File::Spec->catfile($s_changelog_root, 'changelog'));
    $self->changeset->template(Geoffrey::Template->new->load_templates($hr_main_changeset->{templates}));
    $self->changeset->prefix($hr_main_changeset->{prefix}   ? $hr_main_changeset->{prefix} . '_'  : q~~);
    $self->changeset->postfix($hr_main_changeset->{postfix} ? '_' . $hr_main_changeset->{postfix} : q~~);
    return $self->_parse_changelogs($hr_main_changeset->{changelogs}, $s_changelog_root);
}

1;    # End of Geoffrey::Read

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Read - Read existing db scheme.

=head1 VERSION

Version 0.000206

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

Read main changelog file and sub changelog files

=head2 schema

=head2 run_changeset

=head2 insert_dblog

=head2 changeset

=head2 loader

=head2 run

Read main changelog file and sub changelog files

=head1 SYNOPSIS

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

