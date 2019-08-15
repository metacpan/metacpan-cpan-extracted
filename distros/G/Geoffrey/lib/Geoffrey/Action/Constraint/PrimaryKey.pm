package Geoffrey::Action::Constraint::PrimaryKey;

use utf8;
use 5.016;
use strict;
use warnings;
use Time::HiRes qw/ time /;

$Geoffrey::Action::Constraint::PrimaryKey::VERSION = '0.000103';

use parent 'Geoffrey::Role::Action';

sub add {
    my ( $self, $s_table_name, $hr_params ) = @_;
    if ( !$self->converter->primary_key ) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_primarykey( 'add', $self->converter );
    }
    my $gentime = time;
    $gentime =~ s/\.//g;
    $hr_params->{name} ||= q~pk_~ . $s_table_name . q~_~ . $gentime;
    require Geoffrey::Utils;
    return Geoffrey::Utils::replace_spare( $self->converter->primary_key->add,
        [ $hr_params->{name}, ( join q/,/, @{ $hr_params->{columns} } ) ] );
}

sub alter {
    my ( $self, $s_table_name, $hr_params ) = @_;
    if ( !$self->converter->primary_key ) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_primarykey( 'alter', $self->converter );
    }
    return [
        $self->drop( $s_table_name, $hr_params ),
        $self->add( $s_table_name, $hr_params ),
    ];
}

sub drop {
    my ( $self, $table, $name, $schema ) = @_;
    if ( !$self->converter->primary_key ) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_primarykey( 'drop', $self->converter );
    }
    require Geoffrey::Utils;
    return Geoffrey::Utils::replace_spare( $self->converter->primary_key->drop($schema),
        [ $table, $name ] );
}

sub list_from_schema {
    my ( $self, $schema ) = @_;
    if ( !$self->converter->primary_key ) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_primarykey( 'list', $self->converter );
    }
    return $self->converter->primary_key_information(
        $self->do_arrayref( $self->converter->primary_key->list($schema), [] ),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Action::Constraint::PrimaryKey - Action handler for primary keys

=head1 VERSION

Version 0.000103

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 add

=head2 alter

=head2 drop

=head2 list_from_schema

=head2 create_table_column
    
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
