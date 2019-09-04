package Geoffrey::Action::Entry;

use utf8;
use strict;
use warnings;

$Geoffrey::Action::Entry::VERSION = '0.000204';

use parent 'Geoffrey::Role::Action';

sub _get_sql_abstract {
    my ($self) = @_;
    require SQL::Abstract;
    $self->{sql_abstract} //= SQL::Abstract->new;
    return $self->{sql_abstract};
}

sub add {
    my ( $self, $hr_params ) = @_;

    if ( !$hr_params->{table} ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_table_name( __PACKAGE__ . '::add' );
    }
    if ( !$hr_params->{values} ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_values( __PACKAGE__ . '::add' );
    }

    my ( $s_stmt, @a_bindings ) = $self->_get_sql_abstract->insert(
        ( $hr_params->{schema} ? $hr_params->{schema} . q/./ : q// ) . $hr_params->{table},
        $hr_params->{values}->[0],
    );

    return $self->do_prepared( $s_stmt, \@a_bindings );
}

sub alter {
    my ( $self, $s_table_name, $hr_where, $ar_values ) = @_;

    if ( !$s_table_name ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_table_name( __PACKAGE__ . '::alter' );
    }

    if ( !$hr_where ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_where_clause( __PACKAGE__ . '::alter' );
    }

    my ( $s_stmt, @a_bindings ) = $self->_get_sql_abstract->update( $s_table_name, $ar_values->[0], $hr_where );

    return $self->do_prepared( $s_stmt, \@a_bindings );
}

sub drop {
    my ( $self, $hr_params ) = @_;
    if ( !$hr_params->{table} ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_table_name( __PACKAGE__ . '::drop' );
    }
    if ( !$hr_params->{conditions} ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_where_clause( __PACKAGE__ . '::drop' );
    }

    my ( $s_stmt, @a_bindings ) = $self->_get_sql_abstract->delete(
        ( $hr_params->{schema} ? $hr_params->{schema} . q/./ : q// ) . $hr_params->{table},
        $hr_params->{conditions},
    );
    return $self->do_prepared( $s_stmt, \@a_bindings );
}

1;

__END__

=head1 NAME

Geoffrey::Action::Entry - Action to insert change or delete entries from tables

=head1 VERSION

Version 0.000204

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 add

Insert entry into table

=head2 drop

Delete entry from table

=head2 alter

Change values from entry in table

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
