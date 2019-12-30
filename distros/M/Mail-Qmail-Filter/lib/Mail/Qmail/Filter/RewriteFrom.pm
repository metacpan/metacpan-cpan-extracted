use 5.014;
use warnings;

package Mail::Qmail::Filter::RewriteFrom;

our $VERSION = '1.0';

use Mo qw(coerce required);
extends 'Mail::Qmail::Filter';

has from => required => 1;

sub filter {
    my $self    = shift;
    my $message = $self->message;
    my $header  = $message->header;

    if ( my $from = $header->get('From') ) {
        chomp $from;
        if ( my $reply_to = $header->get('Reply-To') ) {
            chomp $reply_to;
            $self->debug( 'Reply-To already set', $reply_to );
        }
        else {
            $header->replace( 'Reply-To' => $from );
            $self->debug( 'set Reply-To to From', $from );
        }
        $header->replace( From => $self->from );
        $self->debug( 'set RFC5322.From', $self->from );
        $message->replace_header($header);
    }
}

1;

__END__

=head1 NAME

Mail::Qmail::Filter::RewriteFrom -
exchange From header line

=head1 SYNOPSIS

    use Mail::Qmail::Filter;

    Mail::Qmail::Filter->new->add_filters(
        '::RewriteFrom' => {
            skip_for_from => [$mydomain],
            from          => 'noreply@' . $mydomain,
        },
        '::Queue',
    )->run;

=head1 DESCRIPTION

This L<Mail::Qmail::Filter> plugin rewrites the C<From> header line.
If the message has no C<Reply-To> yet,
the former contents of the C<From> header line will be set as C<Reply-To>.

=head1 REQUIRED PARAMETERS

=head2 from

What should be put in the C<From> header line of the message.
Please provide a string which is already properly encoded to be used
in an e-mail header.

=head1 SEE ALSO

L<Mail::Qmail::Filter/COMMON PARAMETERS FOR ALL FILTERS>,
L<Encode::MIME::Header>

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
