use 5.014;
use warnings;

package Mail::Qmail::Filter::RewriteSender;

our $VERSION = '1.0';

use Mo qw(coerce required);
extends 'Mail::Qmail::Filter';

has mail_from => required => 1;

sub filter {
    my $self    = shift;
    my $message = $self->message;

    $self->debug( 'new RFC5321.MailFrom' => ${ $message->from_ref } =
          $self->mail_from );
}

1;

__END__

=head1 NAME

Mail::Qmail::Filter::RewriteSender -
exchange RFC5321.MailFrom address

=head1 SYNOPSIS

    use Mail::Qmail::Filter;

    Mail::Qmail::Filter->new->add_filters(
        '::RewriteSender' => {
            skip_for_from => [$mydomain],
            mail_from     => 'postmaster@' . $mydomain,
        },
        '::Queue',
    )->run;

=head1 DESCRIPTION

This L<Mail::Qmail::Filter> plugin exchanges the RFC5321.MailFrom aka the
envelope sender.

=head1 REQUIRED PARAMETERS

=head2 mail_from

What should be used as the new RFC5321.MailFrom.
You should only provide an e-mail address here,
which must be already puny-encoded for IDNs.

=head1 SEE ALSO

L<Mail::Qmail::Filter/COMMON PARAMETERS FOR ALL FILTERS>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Martin Sluka.

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
