use 5.014;
use warnings;

package Mail::Qmail::Filter::DMARC;

our $VERSION = '1.0';

sub domain {
    shift =~ s/.*\@//r;
}

sub if_set {
    my ( $key, $value ) = @_;
    return unless defined $value && length $value;
    $key => $value;
}

sub spf_query {
    require Mail::SPF;
    my $request = Mail::SPF::Request->new(@_);
    state $server = Mail::SPF::Server->new;
    $server->process($request);
}

use namespace::clean;

use Mo qw(coerce default);
extends 'Mail::Qmail::Filter';

has 'dry_run';
has 'reject_text' => 'Failed DMARC test.';

sub filter {
    my $self    = shift;
    my $message = $self->message;

    require Mail::DKIM::Verifier;    # lazy load because filter might be skipped
    my $dkim = Mail::DKIM::Verifier->new;
    $dkim->PRINT( $message->body =~ s/\cM?\cJ/\cM\cJ/gr );
    $dkim->CLOSE;
    $self->debug( 'DKIM result' => $dkim->result );

    if ( $dkim->result ne 'pass' ) {

        $self->debug( 'Remote IP' => $ENV{TCPREMOTEIP} );

        my %spf_query = ( ip_address => $ENV{TCPREMOTEIP} );

        $self->debug( helo => $spf_query{helo_identity} = $message->helo );

        my $header_from = $message->header_from;
        my $header_from_domain;
        if ($header_from) {
            $self->debug( 'RFC5322.From' => $spf_query{identity} =
                  $header_from->address );
            $header_from_domain = $header_from->host;
            $spf_query{scope} = 'mfrom';
        }
        else {
            $spf_query{scope} = 'helo';

            # identity required by Mail::SPF:
            $spf_query{identity} = $spf_query{helo_identity};
        }

        $self->debug( 'SPF result' => my $spf_result = spf_query(%spf_query) );
        $message->add_header( $spf_result->received_spf_header );

        require Mail::DMARC::PurePerl;
        my $dmarc_text = (
            my $dmarc_result = Mail::DMARC::PurePerl->new(
                source_ip   => $ENV{TCPREMOTEIP},
                envelope_to => domain( ( $message->to )[0] ),
                if_set( envelope_from => domain( $message->from ) ),
                if_set( header_from   => $header_from_domain ),
                dkim => $dkim,
                spf  => {
                    if_set( domain => $header_from_domain ),
                    scope  => $spf_query{scope},
                    result => $spf_result->code,
                },
            )->validate
        )->result;
        $self->debug( 'DMARC result' => $dmarc_text );
        $message->add_header("DMARC-Status: $dmarc_text");

        if ( $dmarc_result->result ne 'pass' ) {
            my $disposition = $dmarc_result->disposition;
            $self->debug( 'DMARC disposition' => $disposition );
            $self->reject( $self->reject_text )
              if $disposition eq 'reject' && !$self->dry_run;
        }
    }
}

1;

__END__

=head1 NAME

Mail::Qmail::Filter::DMARC - verify DMARC policy of mail message

=head1 SYNOPSIS

    use Mail::Qmail::Filter;

    Mail::Qmail::Filter->new->add_filters(
        '::DMARC' => {
            skip_if_relayclient => 1,
        },
        '::Queue',
    )->run;

=head1 DESCRIPTION

This L<Mail::Qmail::Filter> plugin verifies if the incoming e-mail message
conforms to the DMARC policy of its sender domain:

=over 4

=item 1.

The plugin is skipped if imported with feature C<:skip_for_relayclient>
and the message comes from a relay client.

=item 2.

We check if the message contains a valid DKIM signature
matching the domain of the C<From:> header field.
If this is the case, the e-mail is passed on.

=item 3.

If not, a SPF check is done, and a C<Received-SPF:> header field is added to
the message.
Then we check if the message is aligned with its sender's DMARC policy.
A C<DMARC-Status:> header field is added.

If the message does not align to the policy, the policy advises to reject such
messages and when the plugin is C<use>d with the C<:reject> feature or the
environment variable C<DMARC_REJECT> is set to a true value, the message will
be rejected with C<554 Failed DMARC test.>

=back

=head1 OPTIONAL PARAMETERS

=head2 dry_run

When set to a true value, the message is only marked, not rejected.

=head2 reject_text

Reply text to send to the client when the message is rejected.

Default: C<Failed DMARC test.>

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
