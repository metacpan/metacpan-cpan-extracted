package Geoffrey::Action::Column;

use utf8;
use 5.016;
use strict;
use warnings;

$Geoffrey::Action::Column::VERSION = '0.000201';

use parent 'Geoffrey::Role::Action';

sub add {
    my ($self, $hr_params, $constraint) = @_;
    require Ref::Util;
    if (!Ref::Util::is_hashref($hr_params)) {
        require Geoffrey::Exception::General;
        Geoffrey::Exception::General::throw_wrong_ref(__PACKAGE__ . '::add', 'hash');
    }
    return $self->appending($hr_params->{table}, $hr_params, $constraint) if $self->for_table;
    my $tables = $self->converter->table;
    if (!$tables || !$tables->can('add_column')) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_column('add', $self->converter);
    }
    if (defined $hr_params->{primarykey}) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_column_default($hr_params->{table},
            $hr_params->{name});
    }
    require Geoffrey::Utils;
    my $sql = Geoffrey::Utils::replace_spare(
        $tables->add_column,
        [
            $hr_params->{table},
            (
                join q/ /,
                (
                    $hr_params->{name}, $self->converter()->type($hr_params),
                    $constraint // (), $self->defaults($hr_params) // ()))]);
    return $self->do($sql);

}

sub drop {
    my ($self, $hr_params) = @_;
    require Ref::Util;
    if (!Ref::Util::is_hashref($hr_params)) {
        require Geoffrey::Exception::General;
        Geoffrey::Exception::General::throw_wrong_ref(__PACKAGE__ . '::drop', 'hash');
    }
    my $table = $self->converter->table;
    if (!$table || !$table->can('drop_column')) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_column('drop', $self->converter);
    }
    require Geoffrey::Utils;
    return [
        map {
            $self->do(
                Geoffrey::Utils::replace_spare($table->drop_column, [$hr_params->{table}, $_]))
        } @{$hr_params->{dropcolumn}}];
}

sub list_from_schema {
    my ($self, $schema, $table) = @_;
    my $converter = $self->converter;
    return $converter->colums_information(
        $self->do_arrayref($converter->table->s_list_columns($schema), [$table]));
}

sub appending {
    my ($self, $s_table_name, $hr_params, $constraint) = @_;
    my $b_primarykey = (defined $hr_params->{primarykey}) ? 1 : 0;
    my $b_has_value = (exists $hr_params->{default} || exists $hr_params->{foreignkey}) ? 1 : 0;
    if ($b_primarykey && !$b_has_value) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_column_default($s_table_name, $hr_params->{name});
    }
    return join q/ /,
        (
        $hr_params->{name}, $self->converter()->type($hr_params),
        $constraint,        $self->defaults($hr_params),
        );
}

sub defaults {
    my ($self, $params) = @_;
    return () if !defined $params->{default};
    my $defaults       = $self->converter()->defaults;
    my $default_by_key = $defaults->{$params->{default}};

    unless ($default_by_key) {
        return 'DEFAULT ' . $params->{default} if $params->{default} eq q/''/;
        return 'DEFAULT ' . $self->converter()->convert_defaults($params);
    }

    if ($params->{default} eq 'autoincrement') {
        return $self->sequences->add($params) if $defaults->{$params->{default}} eq 'sequence';
        return $defaults->{$params->{default}};
    }
    elsif (defined $defaults->{$params->{default}}) {
        return 'DEFAULT ' . $defaults->{$params->{default}};
    }
    return ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Action::Column - Action handler for table columns

=head1 VERSION

Version 0.000201

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 add

Prepare column string for create table.
Or add new column into table

=head2 drop

If it's supported, it will drop defined column from table.

=head2 list_from_schema 

=head2 appending

Prepare column string for create table. Or add new column into table.

=head2 defaults 
    
Generate and define default values for column

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
