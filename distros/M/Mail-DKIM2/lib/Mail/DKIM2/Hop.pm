package Mail::DKIM2::Hop;
use strict;
use warnings;

our $VERSION = '0.36';

use Carp ();
use Mail::DKIM2::Util ();
use Mail::DKIM2::Common qw(parse_mime strip_mi_versions);
use Mail::DKIM2::Canon qw(check_ignore_prefixes);
use Mail::DKIM2::Chain;
use Mail::DKIM2::MessageInstance;

# What one hop does to a message's Message-Instance fields before it signs:
# the decision the milter, the authentication_milter handler and dkim2sign
# each used to make for themselves.

sub next_instance {
    my ($class, $message, %o) = @_;
    Mail::DKIM2::Util::check_options("$class->next_instance", \%o,
        qw(Snapshot Outbound IgnorePrefixes MaxRecipeLiterals Algs));
    Carp::croak("next_instance needs a message") unless defined $message && length $message;
    check_ignore_prefixes($o{IgnorePrefixes});
    my @ignore = defined $o{IgnorePrefixes} ? (IgnorePrefixes => $o{IgnorePrefixes}) : ();
    my @calc   = (@ignore, map { defined $o{$_} ? ($_ => $o{$_}) : () } qw(MaxRecipeLiterals Algs));

    my %r = (instance => undef, message => $message, removed => [],
             restart => 0, matched => 0);
    my $done = sub {
        @r{qw(reason detail)} = @_;
        return \%r;
    };

    my $chain   = Mail::DKIM2::Chain->from_message($message);
    my $has_mi  = $chain->count('Message-Instance');
    my $has_sig = $chain->count('DKIM2-Signature');
    my $msg     = parse_mime($message);

    # Does the top instance still describe the message?
    $r{matched} = ($has_mi && Mail::DKIM2::MessageInstance->verify($msg, @ignore)) ? 1 : 0;

    # Outbound, with instances and no signature: every instance is this
    # host's own and unsigned, and the message leaves with ONE m=1 (-09
    # section 12.1) -- unless that is what it already has.
    my $restart = $o{Outbound} && $has_mi && !$has_sig && !($r{matched} && $has_mi == 1);

    return $done->('unchanged', 'the top Message-Instance describes the message')
        if $r{matched} && !$restart;

    # A chain no verifier can number (the Gate refuses it): add nothing, and
    # never use one of its numbers as a bound.
    if (my $e = $chain->numbering_error(Signatures => 0)) {
        return $done->('bad-chain', "not computing a Message-Instance: $e");
    }

    # No instance yet: this hop starts the chain, m=1 over everything.
    unless ($has_mi) {
        $r{instance} = Mail::DKIM2::MessageInstance->calculate($msg, undef,
            @ignore, (defined $o{Algs} ? (Algs => $o{Algs}) : ()));
        return $done->('first', 'no Message-Instance yet: m=1');
    }

    # What the message was before this hop changed it: the message itself
    # when its instances already say (a list manager that recorded its own
    # change), else the snapshot this host took of this very message. Only
    # that can say what changed; anything else would book someone else's
    # change as this hop's.
    my $previous;
    if ($restart && $r{matched}) {
        $previous = $message;
    } else {
        return $done->('no-snapshot', 'top Message-Instance does not match the '
            . 'content and no snapshot of ours describes it') unless defined $o{Snapshot};
        if (defined(my $m = _foreign_instance($chain, $o{Snapshot}))) {
            return $done->('foreign-snapshot',
                "snapshot does not belong to this message (m=$m differs)");
        }
        $previous = $o{Snapshot};
    }

    my @numbers = $chain->instance_numbers;
    if ($restart) {
        # Only a chain that undoes cleanly says what the message was.
        my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($previous, @ignore);
        return $done->('bad-chain', "not restarting the unsigned instances as m=1: $why")
            unless $ok;
        $r{instance} = Mail::DKIM2::MessageInstance->calculate_first($message, $previous, @calc);
        @r{qw(removed restart)} = (\@numbers, 1);
        $r{message} = strip_mi_versions($message, @numbers);
        return $done->('restart', 'restarting unsigned '
            . join(',', map { "m=$_" } @numbers) . ' as one m=1');
    }

    # The message has instances the snapshot does not: a hop between added
    # them, and since the top one does not match they are wrong. Drop them
    # and describe the change from the snapshot, rather than build on a
    # broken chain.
    my $snap_top = Mail::DKIM2::Chain->from_message($previous)->top_instance // 0;
    my $detail = 'the message changed since the snapshot';
    if ($numbers[-1] > $snap_top) {
        my @strip = ($snap_top + 1 .. $numbers[-1]);
        $r{removed} = \@strip;
        $r{message} = strip_mi_versions($message, @strip);
        $msg = parse_mime($r{message});
        $detail = 'stripping broken MI versions ' . join(',', map { "m=$_" } @strip)
                . " (snapshot at m=$snap_top): broken chain detected";
    }
    $r{instance} = Mail::DKIM2::MessageInstance->calculate($msg, parse_mime($previous), @calc);
    return $done->('changed', $detail);
}

# snapshot_vouches($message, $snapshot): is the snapshot one of this very
# message? True when the message has exactly the snapshot's DKIM2-Signature
# fields and, under them, the Message-Instance fields they cover (white space
# apart: neither is hashed with it). What a signature was verified over on
# arrival is then what is on the message now. Instances above the signatures
# are this host's own, and next_instance and the Gate judge those.
sub snapshot_vouches {
    my ($class, $message, $snapshot) = @_;
    Carp::croak("snapshot_vouches needs a message and a snapshot")
        unless defined $message && length $message && defined $snapshot && length $snapshot;
    my ($msg, $snap) = map { Mail::DKIM2::Chain->from_message($_) } $message, $snapshot;
    for my $c ($msg, $snap) {
        my $e = $c->numbering_error(Signatures => 1) // next;
        return (0, "the snapshot is not of this message: $e");
    }
    my $same = sub {
        my ($x, $y) = map { my $v = $_ // ''; $v =~ s/\A[^:]*://; $v =~ s/\s+//g; $v } @_;
        return length $x && $x eq $y;
    };
    my %i = map { $_ => 1 } $msg->signature_numbers, $snap->signature_numbers;
    for my $i (sort { $a <=> $b } keys %i) {
        return (0, "the snapshot is not of this message: DKIM2-Signature i=$i differs")
            unless $same->(scalar $msg->signature_field($i), scalar $snap->signature_field($i));
    }
    my $covered = $snap->covered_m;
    for my $m (grep { $_ <= $covered } $snap->instance_numbers) {
        return (0, "the snapshot is not of this message: Message-Instance m=$m differs")
            unless $same->(scalar $msg->instance_field($m), scalar $snap->instance_field($m));
    }
    return (1, undef);
}

# The lowest m= at which a snapshot's Message-Instance fields are not the
# message's own (white space apart), or undef when they all are. A snapshot
# whose own fields cannot be numbered is nobody's.
sub _foreign_instance {
    my ($chain, $snapshot) = @_;
    my $snap = Mail::DKIM2::Chain->from_message($snapshot);
    return 0 if $snap->numbering_error(Signatures => 0);
    for my $m ($snap->instance_numbers) {
        my ($x, $y) = map {
            my $v = $_ // '';
            $v =~ s/\A[^:]*://;
            $v =~ s/\s+/ /g;
            $v =~ s/\A | \z//g;
            $v;
        } $snap->instance_field($m), $chain->instance_field($m);
        return $m if $x ne $y;
    }
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Hop - What a hop adds to a message's Message-Instance fields before it signs

=head1 SYNOPSIS

    use Mail::DKIM2::Hop;

    my $next = Mail::DKIM2::Hop->next_instance($message,
        Snapshot => $as_it_arrived,    # if this host kept one
        Outbound => 1,                 # this hop is about to sign
    );
    if (my $mi = $next->{instance}) {
        $message = $mi->as_header . "\r\n" . $next->{message};
    }
    # ... then Mail::DKIM2::Gate->check and Mail::DKIM2::Signer

=head1 DESCRIPTION

A hop that signs a message first has to say what it is signing: a
Message-Instance for the message as it now is, with Recipes back to what it
was. Whether one is needed, which C<m=> it gets and what it is a change
from depend on what the message already carries and on what this host
remembers of it. This module makes that decision in one place, for
C<bin/dkim2-milter>, L<Mail::Milter::Authentication::Handler::DKIM2Sign>
and C<bin/dkim2sign>. It changes nothing: it returns the instance to add
and the message to add it to. New in 0.31.

See L<Mail::DKIM2/CONVENTIONS> for the conventions every module follows.

=head1 CLASS METHODS

=head2 next_instance($message, %options)

C<$message> is the whole message as a string with CRLF line endings.
Options:

=over 4

=item Snapshot

The message as this host last vouched for it -- as it arrived, typically --
as a string. It must be a snapshot of this very message: its
Message-Instance fields have to be the message's own lower ones. Without
one, a message whose top instance no longer matches gets no instance: only
this host's own record can say what this hop changed.

=item Outbound

True for the hop that is about to sign. A message with instances and no
DKIM2-Signature then leaves with a single C<m=1> (-09 section 12.1): every
instance it carries is this host's own and unsigned, so they are replaced
by one whose Recipes go back to the message as it was before the first of
them.

=item IgnorePrefixes, MaxRecipeLiterals, Algs

As for L<Mail::DKIM2::MessageInstance/calculate($msg, [$previous], %options)>.

=back

Returns a hashref:

=over 4

=item instance

The L<Mail::DKIM2::MessageInstance> to add, or undef when none is needed
or none can be justified.

=item message

The message the instance describes and is to be added to: C<$message>,
less any Message-Instance fields that have to go (C<removed>).

=item removed

An arrayref of the C<m=> numbers of the Message-Instance fields removed
from C<message>; empty when none were.

=item restart

True when C<removed> is every instance the message had and C<instance> is
the single C<m=1> that replaces them.

=item matched

True when the top instance already described the message.

=item reason, detail

Why, as a word and as a sentence for a log. C<first>: the message had no
instance, and gets C<m=1>. C<unchanged>: the top instance describes the
message; nothing to add. C<changed>: the message differs from the
snapshot; the instance has the Recipes back to it (and if the message had
instances above the snapshot's, they were wrong and are in C<removed>).
C<restart>: see C<Outbound>. And with no instance: C<no-snapshot> (the top
instance does not match and there is no snapshot to explain it),
C<foreign-snapshot> (the snapshot is of another message) and C<bad-chain>
(the instances cannot be numbered, or do not undo). A message left
without an instance for one of those is one L<Mail::DKIM2::Gate> refuses.

=back

Dies, as C<calculate> does, if the instance cannot be computed.

=head2 snapshot_vouches

    my ($ok, $why) = Mail::DKIM2::Hop->snapshot_vouches($message, $snapshot);

Is C<$snapshot> a snapshot of this very message? True when the message has
exactly the snapshot's DKIM2-Signature fields, and the Message-Instance
fields those signatures cover, each the same apart from white space.
Instances above the signatures are not compared: they are this host's own,
and C<next_instance> and L<Mail::DKIM2::Gate> judge them.

A host that took the snapshot only of a message whose chain verified can
then take the message's signatures as verified, and pass
C<< VerifyResult => 'pass' >> to the Gate. When it is false, C<$why> says
which field differs; such a message is not one to sign.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
