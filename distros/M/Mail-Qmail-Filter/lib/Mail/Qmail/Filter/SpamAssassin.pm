use 5.014;
use warnings;

package Mail::Qmail::Filter::SpamAssassin;

our $VERSION = '1.0';

use Mo qw(coerce default);
extends 'Mail::Qmail::Filter';

has 'dump_spam_to';
has 'mark';
has 'reject_score';
has 'reject_text' => 'I think this message is spam.';

sub filter {
    my $self     = shift;
    my $message  = $self->message;
    my $body_ref = $message->body_ref;

    require Mail::SpamAssassin;    # lazy load because filter might be skipped
    my $sa     = Mail::SpamAssassin->new;
    my $mail   = $sa->parse($body_ref);
    my $status = $sa->check($mail);
    $self->debug( 'spam score' => my $score = $status->get_score );

    if ( $status->is_spam ) {
        if ( defined( my $dir = $self->dump_spam_to ) ) {
            require Path::Tiny and Path::Tiny->import('path')
              unless defined &path;
            path( $dir, my $file = join '_', $^T, $$, $score )
              ->spew($$body_ref);
            $self->debug( 'dumped message to' => $file );
            path( $dir, $file . '_report' )->spew( $status->get_report );
        }
        $self->reject( $self->reject_text =~ y/\n/ /r )
          if $self->reject_score && $score >= $self->reject_score;
        $$body_ref = $status->rewrite_mail if $self->mark;
    }
}

1;

__END__

=head1 NAME

Mail::Qmail::Filter::SpamAssassin -
check if message is spam

=head1 SYNOPSIS

    use Mail::Qmail::Filter;
    
    Mail::Qmail::Filter->new->add_filter(
        '::SpamAssassin' => {
            skip_if_relayclient => 1,
            skip_for_rcpt       => [ 'postmaster', 'postmaster@' . $mydomain ],
            dump_spam_to        => '/var/tmp/spam',
            reject_score        => 5.2,
        },
        '::Queue',
    )->run;

=head1 DESCRIPTION

This L<Mail::Qmail::Filter> plugin checks if the incoming e-mail message
is probably spam.

=head1 OPTIONAL PARAMETERS

=head2 dump_spam_to

If the message is spam, copy it into a file in the given directory.
The file will be named 
C<E<lt>epoch_time_when_script_startedE<gt>_E<lt>pidE<gt>_E<lt>spam_score<gt>>

A spam report will be written to another file named
C<E<lt>epoch_time_when_script_startedE<gt>_E<lt>pidE<gt>_E<lt>spam_score<gt>_report>

=head2 mark

Mark the message if it is spam and is not rejected.

=head2 reject_score

To reject the message if it has at least the spam score given.

=head2 reject_text

Reply text to send to the client when the message is rejected.

Default: C<I think this message is spam.>

=head1 SEE ALSO

L<Mail::Qmail::Filter/COMMON OPTIONS FOR ALL FILTERS>, L<Mail::SpamAssassin>

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
