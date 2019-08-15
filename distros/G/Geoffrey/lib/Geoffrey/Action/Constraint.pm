package Geoffrey::Action::Constraint;

use utf8;
use 5.016;
use strict;
use warnings;

$Geoffrey::Action::Constraint::VERSION = '0.000102';

use parent 'Geoffrey::Role::Action';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{constraints} = [
        qw/
            foreignkey
            primarykey
            check
            index
            unique
            /
    ];
    return bless $self, $class;
}

sub _obj_check {
    my ($self) = @_;
    require Geoffrey::Action::Constraint::Check;
    $self->{check} //= Geoffrey::Action::Constraint::Check->new(
        converter => $self->converter,
        dbh       => $self->dbh,
    );
    return $self->{check};
}

sub _obj_index {
    my ($self) = @_;
    require Geoffrey::Action::Constraint::Index;
    $self->{index} //= Geoffrey::Action::Constraint::Index->new(
        converter => $self->converter,
        dbh       => $self->dbh,
    );
    return $self->{index};
}

sub _obj_unique {
    my ($self) = @_;
    require Geoffrey::Action::Constraint::Unique;
    $self->{unique} //= Geoffrey::Action::Constraint::Unique->new(
        converter => $self->converter,
        dbh       => $self->dbh,
    );
    return $self->{unique};
}

sub _obj_primarykey {
    my ($self) = @_;
    require Geoffrey::Action::Constraint::PrimaryKey;
    $self->{primarykey} //= Geoffrey::Action::Constraint::PrimaryKey->new(
        converter => $self->converter,
        dbh       => $self->dbh,
    );
    return $self->{primarykey};
}

sub _obj_foreignkey {
    my ($self) = @_;
    require Geoffrey::Action::Constraint::ForeignKey;
    $self->{foreignkey} //= Geoffrey::Action::Constraint::ForeignKey->new(
        converter => $self->converter,
        dbh       => $self->dbh,
    );
    return $self->{foreignkey};
}


sub _set_collective_params {
    my ($self, $s_sub_call, $b_param) = @_;
    for (@{$self->{constraints}}) {
        my $s_obj_sub = '_obj_' . $_;
        $self->$s_obj_sub($self)->$s_sub_call($b_param);
    }
    return 1;
}

sub _collective_do {
    my ($self, $s_sub_call, $s_table_name, $constraints_to_alter) = @_;
    my @a_result = ();
    for (@{$constraints_to_alter}) {
        my $s_obj_sub = '_obj_' . delete $_->{constraint};
        if (!$self->can($s_obj_sub)) {
            require Geoffrey::Exception::General;
            return Geoffrey::Exception::General::throw_unknown_action($s_obj_sub);
        }
        $_->{table} = $s_table_name;
        push @a_result, $self->do($self->$s_obj_sub()->$s_sub_call($_));
    }
    return if scalar @a_result == 0;
    return shift @a_result if scalar @a_result == 1;
    return \@a_result;
}

sub for_table {
    my ($self, $b_for_table) = @_;
    return $self->{for_table} if (!defined $b_for_table);
    $self->{for_table} = $b_for_table;
    $self->_set_collective_params('for_table', $b_for_table);
    return $self;
}

sub dryrun {
    my ($self, $b_dryrun) = @_;
    return $self->{dryrun} if (!defined $b_dryrun);
    $self->{dryrun} = $b_dryrun;
    $self->_set_collective_params('dryrun', $b_dryrun);
    return $self;
}

sub add {
    my ($self, $s_table_name, $hr_params, $ar_constraint_params) = @_;
    return $self->create_table_column($s_table_name, $hr_params, $ar_constraint_params)
        if $self->for_table;
    require Geoffrey::Exception::General;
    return Geoffrey::Exception::General::throw_unknown_action('add constraint');
}

sub alter {
    my ($self, $hr_params) = @_;
    require Ref::Util;
    if (!Ref::Util::is_hashref($hr_params)) {
        require Geoffrey::Exception::General;
        Geoffrey::Exception::General::throw_wrong_ref(__PACKAGE__ . '::alter', 'hash');
    }
    return $self->_collective_do('alter', delete $hr_params->{table}, $hr_params->{constraints});
}

sub drop {
    my ($self, $s_table_name, $hr_params) = @_;
    if (!$s_table_name) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_reftable_missing();
    }
    return $self->_collective_do('drop', $s_table_name, $hr_params->{constraints});
}

sub create_table_column {
    my ($self, $s_table_name, $hr_column_params, $ar_constraint_params) = @_;
    if ($hr_column_params->{primarykey} && $hr_column_params->{primarykey} != 1) {
        return push @{$ar_constraint_params},
            $self->_obj_primarykey->add($s_table_name, $hr_column_params->{primarykey});
    }
    push @{$ar_constraint_params},
        $self->_uniques_to_add({
            unique => $hr_column_params->{unique},
            table  => $s_table_name,
            column => $hr_column_params->{name},
        });

    my $o_foreign_key = $self->_obj_foreignkey;
    if ($hr_column_params->{foreignkey}) {
        $hr_column_params->{foreignkey}->{column} = $hr_column_params->{name};
        $hr_column_params->{foreignkey}->{table}  = $s_table_name;
        $hr_column_params->{foreignkey}->{schema} = $hr_column_params->{schema}
            if $hr_column_params->{schema};
        push @{$ar_constraint_params},
            $o_foreign_key->for_table(1)->add($hr_column_params->{foreignkey});
    }

    my $consts     = $self->converter->constraints;
    my $not_null   = ($hr_column_params->{notnull}) ? $consts->{not_null} : q~~;
    my $primarykey = (defined $hr_column_params->{primarykey}) ? $consts->{primary_key} : q~~;
    $o_foreign_key->for_table(0);
    return qq~$not_null $primarykey~;
}

sub _uniques_to_add {
    my ($self, $hr_unique_params) = @_;
    return () if !$hr_unique_params->{unique};
    require Ref::Util;
    my $hr_to_add
        = Ref::Util::is_hashref($hr_unique_params->{unique})
        ? $hr_unique_params->{unique}
        : {columns => [$hr_unique_params->{column}]};
    return $self->_obj_unique->add($hr_unique_params->{table}, $hr_to_add);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Action::Constraint - Action handler for constraint

* CHECK - Ensures that all values in a column satisfies a specific condition
* FOREIGN KEY - Uniquely identifies a row/record in another table
* INDEX - Used to create and retrieve data from the database very quickly
* NOT NULL - Ensures that a column cannot have a NULL value
* PRIMARY KEY - A combination of a NOT NULL and UNIQUE. Uniquely identifies each row in a table
* UNIQUE - Ensures that all values in a column are different
* DEFAULT - Sets a default value for a column when no value is specified

=head1 VERSION

Version 0.000102

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 _obj_check

=head2 _obj_index

=head2 new

=head2 add

=head2 alter

=head2 drop

=head2 create_table_column

Prepare column string for create table.
Or add new column into table

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
