package Geoffrey::Action::Table;

use utf8;
use 5.016;
use strict;
use warnings;

$Geoffrey::Action::Table::VERSION = '0.000201';

use parent 'Geoffrey::Role::Action';

sub _hr_merge_templates {
    my ($self, $s_template, $s_table_name) = @_;
    if (($self->{template} && !$self->{template}->template($s_template)) || !$self->{template}) {
        require Geoffrey::Exception::Template;
        Geoffrey::Exception::Template::throw_template_not_found($s_template);
    }
    my $ar_template_columns     = [];
    my $ar_template_constraints = [];
    $self->column_action->for_table(1);
    $self->constraint_action->for_table(1);
    for (@{$self->{template}->template($s_template)}) {
        $_->{table} = $s_table_name;
        push @{$ar_template_columns},
            $self->column_action->add($_,
            $self->constraint_action->add($s_table_name, $_, $ar_template_constraints));
    }
    $self->column_action->for_table(0);
    $self->constraint_action->for_table(0);
    return {columns => $ar_template_columns, constraints => $ar_template_constraints};
}

sub postfix {
    return $_[0]->{postfix} // q~~ if !defined $_[1];
    $_[0]->{postfix} = $_[1];
    return $_[0]->{postfix};
}

sub prefix {
    return $_[0]->{prefix} // q~~ if !defined $_[1];
    $_[0]->{prefix} = $_[1];
    return $_[0]->{prefix};
}

sub constraint_action {
    my $self = shift;
    return $self->{constraint_action} if ($self->{constraint_action});
    require Geoffrey::Action::Constraint;
    $self->{constraint_action}
        = Geoffrey::Action::Constraint->new(converter => $self->converter, dbh => $self->dbh,);
    return $self->{constraint_action};
}

sub column_action {
    my $self = shift;
    return $self->{column_action} if ($self->{column_action});
    require Geoffrey::Action::Column;
    $self->{column_action}
        = Geoffrey::Action::Column->new(converter => $self->converter, dbh => $self->dbh,);
    return $self->{column_action};
}

sub action {
    my ($self, $s_action) = @_;
    $s_action = join q//, map {ucfirst} split /_/, $s_action;
    require Geoffrey::Utils;
    return Geoffrey::Utils::action_obj_from_name(
        $s_action,
        dbh       => $self->dbh,
        converter => $self->converter,
        dryrun    => $self->dryrun
    );
}

sub add {
    my ($self, $hr_params) = @_;
    if (!$hr_params || !$hr_params->{name}) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_table_name(__PACKAGE__);
    }
    my @columns           = ();
    my $ar_constraints    = [];
    my $constraint_action = $self->constraint_action;
    my $column_action     = $self->column_action;
    if ($hr_params->{template}) {
        my $templates = $self->_hr_merge_templates($hr_params->{template}, $hr_params->{name});
        push @columns, @{$templates->{columns}};
        push @{$ar_constraints}, @{$templates->{constraints}};
    }
    $constraint_action->for_table(1);
    $column_action->for_table(1);
    for my $hr_column (@{$hr_params->{columns}}) {
        $hr_column->{schema} = $hr_params->{schema} if exists $hr_params->{schema};
        $hr_column->{table} = $hr_params->{name};
        my $const = $constraint_action->add($hr_params->{name}, $hr_column, $ar_constraints);
        push @columns, $column_action->add($hr_column, $const);
    }
    for (@{$hr_params->{constraints}}) {
        $_->{schema} = $hr_params->{schema} if exists $hr_params->{schema};
        $constraint_action->add($hr_params->{name}, $_, $ar_constraints);
    }
    push @columns, @{$ar_constraints};
    if (scalar @columns == 0 && !$self->converter->can_create_empty_table) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_empty_table($self->converter,
            $hr_params);
    }
    $constraint_action->for_table(0);
    $column_action->for_table(0);

    #prepare finaly created table to SQL
    require Geoffrey::Utils;
    my $sql = Geoffrey::Utils::replace_spare( $self->converter->table->add, [
        ($hr_params->{schema} ? $hr_params->{schema} . q/./ : q//) . $self->prefix . $hr_params->{name} . $self->postfix,
        join(q/,/, @columns),
        $hr_params->{engine}, $hr_params->{charset}
    ]);
    return $self->do($sql);
}

sub alter {
    my ($self, $hr_params) = @_;
    require Ref::Util;
    if (!Ref::Util::is_hashref($hr_params)) {
        require Geoffrey::Exception::General;
        Geoffrey::Exception::General::throw_wrong_ref(__PACKAGE__ . '::alter', 'hash');
    }
    if (!$hr_params->{name}) {
        require Geoffrey::Exception::General;
        Geoffrey::Exception::General::throw_no_table_name('to alter');
    }
    my @ar_result = ();
    require Geoffrey::Utils;
    for (@{$hr_params->{alter}}) {
        my ($s_sub, $s_action) = Geoffrey::Utils::parse_package_sub($_->{action});
        my $obj_action = $self->action($s_action);
        if (!$s_sub || !$obj_action->can($s_sub)) {
            require Geoffrey::Exception::RequiredValue;
            Geoffrey::Exception::RequiredValue::throw_action_sub($s_action);
        }
        $_->{table} = $hr_params->{name};
        push @ar_result, $obj_action->$s_sub($_);
    }
    return \@ar_result;
}

sub drop {
    my ($self, $hr_params) = @_;
    require Ref::Util;
    my $s_name = Ref::Util::is_hashref($hr_params) ? $hr_params->{name} : undef;
    if (!$s_name) {
        require Geoffrey::Exception::General;
        Geoffrey::Exception::General::throw_no_table_name('to drop');
    }
    require Geoffrey::Utils;
    return $self->do(Geoffrey::Utils::replace_spare($self->converter->table->drop, [$s_name]));
}

sub list_from_schema {
    my ($self, $schema) = @_;
    return [map { $_->{name} } @{$self->do_arrayref($self->converter->table->list($schema), [])}];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Action::Table - Action handler for tables

=head1 VERSION

Version 0.000201

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 postfix

=head2 prefix

=head2 constraint_action

=head2 column_action

=head2 index_action

=head2 action

=head2 add

Create new table.

=head2 alter

Decides type of alter table
Run command of alter table

=head2 drop

Drop defined table.

=head2 list_from_schema 
    
Not needed!

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
