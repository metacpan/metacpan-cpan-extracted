use 5.014;
use warnings;

package Mail::Qmail::Filter;

our $VERSION = '1.71';

use Carp                      qw(confess);
use FindBin                   ();
use IO::Handle                ();
use Mail::Qmail::Filter::Util qw(addresses_to_hash match_address);
use MailX::Qmail::Queue::Message;
use Scalar::Util qw(blessed);

use namespace::clean;

# Must be under namespace::clean for coercion to work:
use Mo qw(coerce default);

my $feedback_fh;    # Open ASAP before the handle gets reused:

BEGIN {
    $feedback_fh = IO::Handle->new_from_fd( 4, 'w' )
      or warn "Cannot open feedback handle: $!";
}

has 'defer_only';
has 'feedback_fh' => $feedback_fh;
has 'filters'     => [];
has 'log_fh';
has 'reject_text' => 'Rejected.';
has 'skip_if';
has 'skip_for_from'   => coerce => \&addresses_to_hash;
has 'skip_for_rcpt'   => coerce => \&addresses_to_hash;
has 'skip_for_sender' => coerce => \&addresses_to_hash;
has 'skip_if_remote_ip_matches';
has 'skip_if_relayclient';

my @debug;

sub debug {
    my $self = shift;
    push @debug, my $message = join ': ', @_;
    if ( $self->log_fh ) {
        my $package = ref($self) . ' ';
        $self->log_fh->say( $message !~ /^\Q$package/ && $package, $message );
    }
}

$SIG{__DIE__} //= sub {
    return if $^S || !defined $^S;
    __PACKAGE__->debug( died => "@_" );
    die @_;
};

sub add_filters {
    my $self = shift;
    while ( defined( my $filter = shift ) ) {
        unless ( blessed($filter) ) {
            my $opt = shift if @_ && 'HASH' eq ref $_[0];
            $filter = __PACKAGE__ . $filter if $filter =~ /^::/;
            eval "use $filter";
            confess $@ if length $@;
            $filter = $filter->new(%$opt);
        }
        push @{ $self->{filters} }, $filter;
    }
    $self;
}

sub defer {
    my $self = shift;
    $self->debug( action => 'defer' );
    $self->_exit( Z => @_ );
}

sub filter {
    my $self = shift;

    $_->run for @{ $self->filters };
}

sub message {
    state $message = MailX::Qmail::Queue::Message->receive
      or die "Invalid message\n";
}

sub reject {
    my $self = shift;
    $self->debug( action => 'reject' );
    $self->_exit( $self->defer_only ? 'Z' : 'D', @_ );
}

sub run {
    my $self = shift;

    my $package = ref $self;

    return if $self->skip_if && $self->skip_if->($self);

    if ( exists $ENV{RELAYCLIENT} && $self->skip_if_relayclient ) {
        $self->debug("$package skipped");
        return;
    }

    if (
        $self->skip_if_remote_ip_matches
        && (
            my $match = $self->skip_if_remote_ip_matches->match_ip(
                $self->message->remote_ip
            )
        )
      )
    {
        $self->debug("$package skipped because remote IP belongs to $match");
        return;
    }

    if ( my $skip_for_sender = $self->skip_for_sender ) {
        if (
            match_address(
                $skip_for_sender, my $sender = $self->message->from
            )
          )
        {
            $self->debug( "$package skipped because of sender", $sender );
            return;
        }
    }

    if (   ( my $skip_for_from = $self->skip_for_from )
        && ( my $from = $self->message->header_from ) )
    {
        if ( match_address( $skip_for_from, $from = $from->address ) ) {
            $self->debug( "$package skipped because of RFC5322.From", $from );
            return;
        }
    }

    if ( my $skip_for_rcpt = $self->skip_for_rcpt ) {
        for ( $self->message->to ) {
            next unless match_address( $skip_for_rcpt, $_ );
            $self->debug( "$package skipped because of rcpt", $_ );
            return;
        }
    }

    $self->debug("$package started");
    $self->filter;
}

sub _exit {
    my $self        = shift;
    my $status      = shift;
    my $reject_text = shift // $self->reject_text;
    $reject_text = $reject_text->(@_)
      if ref $reject_text && 'CODE' eq ref $reject_text;
    $reject_text =~ y/\n/ /;
    $self->feedback_fh->print( $status, $reject_text );

    exit 88;
}

END {
    __PACKAGE__->debug( 'exit code' => $? );
    say STDERR "$FindBin::Script\[$$]: " . join '; ', @debug;
}

__END__

=head1 NAME

Mail::Qmail::Filter - filter e-mails in qmail-queue context

=head1 SYNOPSIS

    use Mail::Qmail::Filter;
    
    Mail::Qmail::Filter->new->add_filter(
        '::LogEnvelope',
        '::DMARC' => {
            skip_if_relayclient => 1,
        },
        '::CheckDeliverability' => {
            match               => qr{/ezmlm-(?:checksub|reject)\b},
            skip_if_relayclient => 1,
        },
        '::SpamAssassin' => {
            skip_if_relayclient => 1,
            reject_score        => 5.2,
            reject_text         => 'I think your message is spam.',
        },
        '::Queue',
    )->run;

=head1 DESCRIPTION

Mail::Qmail::Filter and its submodules are designed to help you filter
incoming e-mails when using L<qmail|http://netqmail.org/> as MTA.

You should use it like so:

=over 4

=item 1.

Write a frontend script to configure your filters,
like the one in the L</SYNOPSIS>.

=item 2.

In the run file for your C<qmail-smtpd> instance,
e.g. C</var/qmail/supervise/qmail-smtpd/run>,

    export QMAILQUEUE=path_to_your_frontend_script

=back

In each filter, you may do various things:

=over 4

=item *

examine and change envelope data (RFC5321.MailFrom and recipients)

=item *

examine and modify the e-mail message (header and/or body)

=item *

L</reject> e-mails (or L<defer|/defer_only> them)

=back

=head1 FILTERS INCLUDED

This distribution ships with the following predefined filters:

=head2 Queueing the message

Usually you want to use L<Mail::Qmail::Filter::Queue> as the last
filter in your chain to pass the message on to C<qmail-queue>,
because if you don't, the message will be discarded.

=head2 Rejecting filters

=over 4

=item L<Mail::Qmail::Filter::CheckDeliverability>

check deliverability according to .qmail files

=item L<Mail::Qmail::Filter::DMARC>

validate message against DMARC policy of the sender domain

=item L<Mail::Qmail::Filter::Graylist>

implements a graylisting which tries to be compatible to
that of L<Spamdyke|https://www.spamdyke.org>

=item L<Mail::Qmail::Filter::RDNS>

checks the reverse DNS of the IP address of the client

=item L<Mail::Qmail::Filter::RequireFrom>

only allow certain RFC322.From addresses

=item L<Mail::Qmail::Filter::SpamAssassin>

spam-check message

=item L<Mail::Qmail::Filter::ClamAV>

scan message for viruses

=item L<Mail::Qmail::Filter::ValidateFrom>

validate RFC5322.From

=item L<Mail::Qmail::Filter::ValidateSender>

validate RFC5321.MailFrom syntactically

=item L<Mail::QMail::Filter::VerifyFrom>

verify RFC5322.From via SMTP callout

=item L<Mail::QMail::Filter::VerifySender>

verify RFC5321.MailFrom via SMTP callout

=back

=head2 Envelope modifying filters

=over 4

=item L<Mail::Qmail::Filter::RewriteSender>

=back

=head2 Header modifying filters

=over 4

=item L<Mail::Qmail::Filter::RewriteFrom>

=back

=head2 Logging-only filters

=over 4

=item L<Mail::Qmail::Filter::Dump>

=item L<Mail::Qmail::Filter::LogEnvelope>

=back

=head2 Experimental filters

=over 4

=item L<Mail::Qmail::Filter::SkipQueue>

=back

=head1 COMMON PARAMETERS FOR ALL FILTERS

=head2 skip_if

When given a sub routine as an argument, executes this sub routine,
passing the filter as only parameter.
If the sub routine returns a true value, the rest of the filter is skipped.

=head2 skip_if_relayclient

When set to a true value, the L</run> method will skip the filter when
the environment variable C<RELAYCLIENT> exists.

=head2 skip_if_remote_ip_matches

Expects a L<Net::IP::Match::Trie> object.
Skips the filter in case the client IP address is matched by that object.

=head2 skip_for_sender

Takes an e-mail address or a reference to a list of such.
The L</run> method will then skip the filter if the RFC5321.MailFrom address
of the L</message> is one of these.

You can use domain names without a localpart to skip any address @ that domain.

=head2 skip_for_from

Takes an e-mail address or a reference to a list of such.
The L</run> method will then skip the filter if the RFC5322.From address
of the L</message> is one of these.

You can use domain names without a localpart to skip any address @ that domain.

=head2 skip_for_rcpt

Takes an e-mail address or a reference to a list of such.
The L</run> method will then skip the filter if at least one of the recipients
in the envelope of the L</message> is one of these.

You can use domain names without a localpart to skip any address @ that domain.

=head2 defer_only

When set to a true value, calls to the L</reject> method will
result in status code C<451>, that is, the message should only
be deferred on the sender side.

=head1 METHODS

=head2 add_filters

Configure the filters you want to use.
Takes a list of filter packages to run in order.

You may pass instances of filter objects here,
but usually it is more convenient to specify filters using their package name,
optionally followed by a hash of options.
C<add_filters> will then construct the filter object for you.
If your filter lives below the C<Mail::Qmail::Filter::> namespace,
you may abbreviate this prefix with C<::>.
Please see example in the L</SYNOPSIS> above.

C<add_filters> may be called several times to add more and more filters,
but you can also just specify them all in one call.

C<add_filters> will return the main L<Mail::Qmail::Filter> object,
so you may chain other methods, like L</run>.

=head2 run

checks if the filter should be skipped by evaluating the
L</OPTIONS COMMON TO ALL FILTERS>.
If not, runs it by calling its L</filter> method.

=head2 filter

Does the actual work:
Reads the message from C<qmail-smtpd>,
runs the filters which where L<added|/-E<gt>add_filters>
and if has not been L</reject>ed,
forwards the message to C<qmail-queue>.

When L</WRITING YOUR OWN FILTERS>, overwrite this method
with what your filter is supposed to do.

=head2 message

returns the L<MailX::Qmail::Queue::Message> to be filtered

=head2 reject

rejects the message with status C<554> (default)
or with C<451> when L</defer_only> is set.
Stops the execution of the script; no further filters will be run,
and the message will I<not> be passed on to C<qmail-queue>.

As first argument, expects the reply text the server should send to the client
or a L<sub|perlfunc/sub>routine which returns this reply text.
Additional arguments will be passed to this L<sub|perlfunc/sub>routine,
which is handy if you for example want to include an e-mail address which
caused the rejection.

Please note that you should only use ASCII characters for the reply text and
that C<qmail-smtpd> usually limits its length to 254 characters.

=head2 defer

defers the message with status C<451>,
just like L</reject> would when L</defer_only> is set.
Everything else that is said above about L</reject> also applies to L</defer>.

=head2 debug

collects logging messages.
When the script finishes,
these will be automatically written to standard error, separated with C<; >s.
You should then find them in the log file of your C<qmail-smtpd>,
prefixed with the name of your frontend script.

When passing several arguments, these will be L<joined|perlfunc/join> with
C<: >.

=head1 WRITING YOUR OWN FILTERS

For the L</COMMON OPTIONS FOR ALL FILTERS> to work properly,
your package has to:

    use Mo 'coerce';
    extends 'Mail::Qmail::Filter';

Apart from that, you only have to define a filter method
which does the actual work.

For further insight, please have a look at the source code of the various
L</FILTERS INCLUDED> in this distribution.

=head1 SEE ALSO

L<MailX::Qmail::Queue::Message> and the L<FILTERS INCLUDED>.

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
