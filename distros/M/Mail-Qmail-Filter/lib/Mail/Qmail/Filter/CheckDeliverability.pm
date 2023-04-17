use 5.014;
use warnings;

package Mail::Qmail::Filter::CheckDeliverability;

our $VERSION = '1.02';

use Mo qw(coerce default);
extends 'Mail::Qmail::Filter';

has 'reject_text' => 'Recipient unknown.';
has 'run_commands_matching';

sub filter {
    my $self                  = shift;
    my $message               = $self->message;
    my $run_commands_matching = $self->run_commands_matching;

    require Qmail::Deliverable and Qmail::Deliverable->import('dot_qmail')
      unless defined &dot_qmail;

    my ( %done, $reject_text, $valid );
  Recipient: for ( $message->to ) {
        my $dot_qmail = dot_qmail($_);
        unless ( defined $dot_qmail ) {
            $self->debug( 'No .qmail file found for rcpt' => $_ );
            $reject_text = $self->reject_text;
            next;
        }
        next if $done{$dot_qmail}++;
        open my $fh, '<', $dot_qmail
          or return $self->debug( "Cannot read $dot_qmail", $! );
        $self->debug( "Checking .qmail for $_" => $dot_qmail );
        while ( defined( my $line = <$fh> ) ) {

            next if $line =~ /^#/;
            ++$valid;
            chomp $line;
            return $self->debug( "$_ is at least deliverable to" => $line )
              if $line =~ m{^[&/\w]};
            next
              unless $line =~ /^\|/
              && defined $run_commands_matching
              && $line =~ $run_commands_matching;

            require Capture::Tiny
              and Capture::Tiny->import('capture_merged')
              unless defined &capture_merged;
            local $ENV{SENDER} = $message->from;
            my ( $output, $exitcode ) = capture_merged(
                sub {
                    open my $fh, $line
                      or return $self->debug( "Cannot start $line", $! );
                    print $fh $message->body;
                    close $fh;
                    $?;
                }
            );
            $output = join '/', split /\n/, $output;
            $exitcode >>= 8;
            $self->debug( qq("$line") => $exitcode );
            last if $exitcode == 99;
            return $self->debug("Calling $line for $_ resulted in soft failure")
              if $exitcode == 111;
            next unless $exitcode == 100;
            unless ( defined $reject_text ) {
                $reject_text = $output;
            }
            elsif ( $output ne $reject_text ) {
                return $self->debug(
                    qq(Different reject texts: "$reject_text" vs. "$output"));
            }
            next Recipient;
        }
        return $self->debug("might be deliverable to <$_>") if $valid;
    }

    $self->reject($reject_text) if defined $reject_text;
    $self->reject( $self->reject_text ) unless $valid;
}

1;

__END__

=head1 NAME

Mail::Qmail::Filter::CheckDeliverabilty -
check deliverability according to .qmail files

=head1 SYNOPSIS

    use Mail::Qmail::Filter;
    
    Mail::Qmail::Filter->new->add_filter(
        '::CheckDeliverability' => {
            run_commands_matching => qr{/ezmlm-(?:checksub|reject)\b},
            skip_if_relayclient   => 1,
        },
        '::Queue',
    )->run;

=head1 DESCRIPTION

This L<Mail::Qmail::Filter> plugin tries to find the appropriate C<.qmail> file
for all envelope recipients and optionally
L<runs commands|/run_commands_matching> mentioned in these files to check the
deliverability of the message.

L<Rejects|Mail::Qmail::Filter/reject> the message if it would be I<equally>
undeliverable to I<all> recipients.

For each recipient address, deliverability is checked as follows:

=over 4

=item *

The appropriate C<.qmail> file is searched using L<Qmail::Deliverable>.
If none is found, the address is considered undeliverable,
with the L</reject_text> as reason.

=item *

Otherwise the C<.qmail> file is evaluated line by line in a similar fashion
as C<qmail-local> would:

=item *

Comment lines are skipped.

=item *

When a forward, maildir or mbox line is found, the recipient is considered
deliverable, and the filter stops.

=item *

When a command line is found, it is executed only if L</run_commands_matching>
is set and the line matches the given L<regular expression|perlre>.

When it returns with exit code 100, the filter saves its output as possible
reject text, and the evaluation of this C<.qmail> file stops.

=item *

The message is rejected only if the evaluation of each C<.qmail> file resultet
with status 100 and the same reject text or if absolutely no valid C<.qmail>
files could be found.

=back

=head1 NOTE

Please note that it is usually preferable to check deliverability directly after
each C<RCPT TO> command within the SMTP transaction, because only then you can
reject single recipients individually.
To achieve this, you may want to use tools like
L<spamdyke-qrv|https://www.spamdyke.org/documentation/README_spamdyke_qrv.html>.

But: These tools do have limitations, e.g. they usually do not call external
commands and inherent to the sequence of SMTP commands they cannot take message
content into account.
And this is where this filters comes in handy.

I use it to reject messages to mailing lists which do not come from a subscriber
of these lists.
Often these are spam messages with forged sender addresses, and by already
rejecting them during the SMTP transaction, one can avoid to produce collateral
spam.

=head1 OPTIONAL PARAMETERS

=head2 run_commands_matching

expects a L<regular expression|perlre> as argument against which command
lines in the C<.qmail> files are to be matched.
Only commands matching this regular expression will be called.
You should take care to call only commands which do not deliver the message
itself, lest you want to shoot yourself in the foot.

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
