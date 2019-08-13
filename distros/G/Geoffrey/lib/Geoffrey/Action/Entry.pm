package Geoffrey::Action::Entry;

use utf8;
use strict;
use warnings;

$Geoffrey::Action::Entry::VERSION = '0.000101';

use parent 'Geoffrey::Role::Action';

sub add {
    my ( $self, $hr_params ) = @_;
    my $s_table_name = $hr_params->{table};
    my $ar_columns   = $hr_params->{columns};
    my $ar_values    = $hr_params->{values};

    if ( !$s_table_name ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_table_name( __PACKAGE__ . '::add' );
    }
    if ( !$ar_columns ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_table_column( __PACKAGE__ . '::add' );
    }
    if ( !$ar_values ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_values( __PACKAGE__ . '::add' );
    }
    return $self->do_prepared(
        qq~INSERT INTO $s_table_name ( ~
          . ( join q/,/, @{$ar_columns} )
          . ' ) VALUES ('
          . ( join q/,/, map { q~?~ } @{$ar_columns} ) . ')',
        $ar_values
    );
}

sub alter {
    my ( $self, $s_table_name, $ar_columns, $ar_where_and, $ar_values ) = @_;
    if ( !$s_table_name ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_table_name( __PACKAGE__ . '::alter' );
    }
    if ( !$ar_columns ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_table_column( __PACKAGE__ . '::alter' );
    }
    if ( !$ar_where_and ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_where_clause( __PACKAGE__ . '::alter' );
    }
    return $self->do_prepared(
        qq~UPDATE $s_table_name SET ~
          . ( join ', ', map { $_ . ' = ?' } @{$ar_columns} )
          . ' WHERE ( '
          . _s_where_clause($ar_where_and) . ' )',
        $ar_values
    );
}

sub drop {
    my ( $self, $s_table_name, $ar_where_and ) = @_;
    if ( !$s_table_name ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_table_name( __PACKAGE__ . '::drop' );
    }
    if ( !$ar_where_and ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_where_clause( __PACKAGE__ . '::drop' );
    }
    return $self->do( qq~DELETE FROM $s_table_name WHERE ( ~ . _s_where_clause($ar_where_and) . ' )' );
}

sub _s_where_clause {
    my ($ar_where_and) = @_;
    return ( join ' AND ', map { join q/ /, ( $_->{column}, $_->{operator}, $_->{value} ) } @{$ar_where_and} );
}

1;

__END__

=head1 NAME

Geoffrey::Action::Entry - Action to insert change or delete entries from tables

=head1 VERSION

Version 0.000101

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 add

Insert entry into table

=head2 _s_where_clause

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
