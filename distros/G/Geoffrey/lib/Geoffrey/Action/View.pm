package Geoffrey::Action::View;

use utf8;
use 5.016;
use strict;
use warnings;

use parent 'Geoffrey::Role::Action';

$Geoffrey::Action::View::VERSION = '0.000206';

sub add {
    my ( $self, $params ) = @_;
    require Geoffrey::Utils;
    my $sql = Geoffrey::Utils::replace_spare( $self->converter->view->add,
        [ $params->{name}, $params->{as} ] );
    return $self->do($sql);
}

sub alter {
    my ( $self, $params ) = @_;
    return [ $self->drop( $params->{name} ), $self->add($params) ];
}

sub drop {
    my ( $self, $hr_params ) = @_;
    require Geoffrey::Utils;
    require Ref::Util;
    my $s_name = Ref::Util::is_hashref($hr_params) ? delete $hr_params->{name} : $hr_params;
    if ( !$s_name ) {
        require Geoffrey::Exception::General;
        Geoffrey::Exception::General::throw_no_table_name('to drop');
    }
    return $self->do( Geoffrey::Utils::replace_spare( $self->converter->view->drop, [$s_name] ) );
}

sub list_from_schema {
    my ( $self, $schema ) = @_;
    my $converter = $self->converter;
    return $converter->view_information( $self->do_arrayref( $converter->view->list($schema) ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Action::View - Handles view actions

=head1 VERSION

Version 0.000206

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 add

Add view

=head2 alter

Drop view and add new one.

=head2 drop

Drop defined view.

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
