# FTN::Crypt::Error - Error processing for the FTN::Crypt module
#
# Copyright (C) 2019 by Petr Antonov
#
# This library is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.10.0. For more details, see the full text
# of the licenses at https://opensource.org/licenses/Artistic-1.0, and
# http://www.gnu.org/licenses/gpl-2.0.html.
#
# This package is provided "as is" and without any express or implied
# warranties, including, without limitation, the implied warranties of
# merchantability and fitness for a particular purpose.
#

package FTN::Crypt::Error;

use strict;
use warnings;
use v5.10.1;

#----------------------------------------------------------------------#

=head1 NAME

FTN::Crypt::Error - Error processing for the L<FTN::Crypt> module.

=head1 SYNOPSIS

Inherit your class from FTN::Crypt::Error. Then, to set error message:

    Class->set_error($message)
    $obj->set_error($message)

To get error message:

    Class->error
    $obj->error

=cut

#----------------------------------------------------------------------#

use vars qw/$_ERROR_/;

#----------------------------------------------------------------------#

=head2 new()

Constructor.

=head3 Parameters:

None.

=head3 Returns:

Created object.

=cut

sub new {
    return bless {
        _ERROR_ => '',
    }, shift;
}

#----------------------------------------------------------------------#

=head2 set_error()

Set error message.

=head3 Parameters:

=over 4

=item * Error message.

=back

=head3 Returns:

None.

=cut

sub set_error {
    my $self = shift;

    my $errstr = ref($_[0]) ? shift : join("\n", @_);
    if (ref($self)) {
        $self->{_ERROR_} = $errstr;
    } else {
        $_ERROR_ = $errstr;
    }
}

#----------------------------------------------------------------------#

=head2 error()

Get error message.

=head3 Parameters:

None.

=head3 Returns:

Error message.

=cut

sub error {
    my $self = shift;

    if (ref($self)) {
        return defined $self->{_ERROR_} ? $self->{_ERROR_} : '';
    } else {
        return defined $_ERROR_ ? $_ERROR_ : '';
    }
}

1;
__END__

=head1 AUTHOR

Petr Antonov, E<lt>pietro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Petr Antonov

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses at L<https://opensource.org/licenses/Artistic-1.0>, and
L<http://www.gnu.org/licenses/gpl-2.0.html>.

This package is provided "as is" and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantability and fitness for a particular purpose.
