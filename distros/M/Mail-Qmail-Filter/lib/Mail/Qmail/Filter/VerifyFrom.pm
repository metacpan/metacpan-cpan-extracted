use 5.014;
use warnings;    # no default before Perl 5.35

package Mail::Qmail::Filter::VerifyFrom;

our $VERSION = '0.41';

use Mo qw(coerce default);
extends 'Mail::Qmail::Filter::Base::CalloutVerify';

has address_type => 'From';

sub filter {
    my $self                = shift;
    my $header_from         = $self->message->header_from or return;
    my $header_from_address = $header_from->address;
    $self->callout_verify($header_from_address);
}

1;

__END__

=head1 NAME

Mail::Qmail::Filter::VerifySender -
verify RFC5322.From address via SMTP callout

=head1 SYNOPSIS

    use Mail::Qmail::Filter;

    Mail::Qmail::Filter->new->add_filters(
        '::VerifyFrom' => {
            skip_for_rcpt => [ 'postmaster', 'postmaster@' . $mydomain ],
        },
        '::Queue',
    )->run;

=head1 DESCRIPTION

This L<Mail::Qmail::Filter> plugin checks if the RFC5322.From aka the
envelope sender of the message is an existing e-mail address via doing
SMTP callouts.

For further details, please refer to
L<Mail::Qmail::Filter::Base::CalloutVerify>.

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Martin Sluka.

This module is free software; you can redistribute it and/or modify it
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
mark, tradename, or logo of the Copyright Holder.

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
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
