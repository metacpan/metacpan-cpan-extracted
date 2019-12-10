package Geoffrey::Action::Constraint::Index;

use utf8;
use 5.016;
use strict;
use warnings;

use parent 'Geoffrey::Role::Action';

$Geoffrey::Action::Constraint::Index::VERSION = '0.000205';

sub add {
    my ( $self, $hr_params ) = @_;
    return $self->do( $self->converter->index->add($hr_params) );
}

sub alter {
    my ( $self, $hr_params ) = @_;
    return [ $self->drop($hr_params), $self->add($hr_params) ];
}

sub drop {
    my ( $self, $hr_params ) = @_;
    require Ref::Util;
    my $s_name = Ref::Util::is_hashref($hr_params) ? $hr_params->{name} : undef;
    if ( !$s_name ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_index_name('to drop');
    }
    return $self->do( $self->converter->index->drop($s_name) );
}

sub list_from_schema {
    my ( $self, $schema ) = @_;
    my $converter = $self->converter;
    return $converter->index_information( $self->do_arrayref( $converter->index->list($schema) ) );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Action::Constraint::Index - Action handler for indexes

=head1 VERSION

Version 0.000205

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 add
 
If it's supported new index will be created.

=head2 alter

Not needed!

=head2 drop
    
Not needed!

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
