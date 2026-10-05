package Mail::DKIM2::DSN;
use strict;
use warnings;

our $VERSION = '0.13';

use Email::MIME;
use Carp;
use List::Util qw(max);

use Mail::DKIM2::Common qw(extract_domain relaxed_domain_match);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signature;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;

# Mail::DKIM2::DSN - propagate a DKIM2-signed DSN upstream (RFC 6522 DSN
# structure; DKIM2 draft-06 §12.1.1 propagation procedure).
#
# When a Forwarder receives a Delivery Status Notification for a message it
# forwarded, it may propagate that DSN back towards the original sender. The
# propagated DSN is a *new* message: the Forwarder rebuilds the enclosed
# original to the state it was in when forwarded outward (undoing its own
# Message-Instance modification and removing the DKIM2-Signature and
# Message-Instance it added), then re-signs the whole DSN with MAIL FROM <>
# so that it carries exactly one Message-Instance and one DKIM2-Signature.

# Return the highest-sequence DKIM2-Signature (parsed) of an Email::MIME msg.
sub _top_sig {
    my ($msg) = @_;
    my @sigs = map { Mail::DKIM2::Signature->parse($_) } $msg->header_raw('DKIM2-Signature');
    return unless @sigs;
    my ($top) = sort { $b->sequence <=> $a->sequence } @sigs;
    return $top;
}

# Remove the Forwarder's hop from an Email::MIME: the highest-sequence
# DKIM2-Signature, and then any nd= signature left on top, since a §9.3
# bridge belongs to the hop it was made for and an nd= signature is never
# valid as the top of a chain. (header_filter mishandles long folded values,
# so filter on header_raw and re-set the survivors.)
sub _strip_top_sig {
    my ($msg) = @_;
    my @sigs = $msg->header_raw('DKIM2-Signature');
    return unless @sigs;
    my @parsed = sort { $a->[1]->sequence <=> $b->[1]->sequence }
                 map  { [ $_, Mail::DKIM2::Signature->parse($_) ] } @sigs;
    my $maxi = $parsed[-1][1]->sequence;
    pop @parsed;
    while (@parsed) {
        my $nd = $parsed[-1][1]->next_domain;
        last unless defined $nd && length $nd;
        pop @parsed;
    }
    $msg->header_raw_set('DKIM2-Signature', map { $_->[0] } @parsed);
    return $maxi;
}

# Extract the Email::MIME of the embedded original from a message/rfc822 (or
# text/rfc822-headers) part.
sub _embedded {
    my ($part) = @_;
    my @sub = $part->subparts;
    return $sub[0] if @sub;
    return Email::MIME->new($part->body);
}

# Re-sign a rebuilt/created DSN as a NEW message: prepend one Message-Instance
# (v=1) and one DKIM2-Signature (the supplied signer is configured with
# MailFrom => '<>'). Returns the final raw message.
sub _sign_as_new {
    my ($signer, $dsn) = @_;
    my $dsn_text = $dsn->as_string;
    $dsn_text =~ s/\r?\n/\r\n/g;
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($dsn_text));
    my $with_mi = "Message-Instance: " . $mi->as_string . "\r\n" . $dsn_text;
    $signer->PRINT($with_mi);
    $signer->CLOSE;
    my $sig_hdr = $signer->as_string;
    $sig_hdr =~ s/\r?\n$//;
    return $sig_hdr . "\r\n" . $with_mi;
}

# Build a text/rfc822-headers embedded-original part: the headers only (no
# body) of $orig, an Email::MIME. Used by propagate() when the original body
# is unrecoverable (a "null Recipe" upstream) and so must not be carried.
sub _headers_only_part {
    my ($orig) = @_;
    return Email::MIME->create(
        attributes => { content_type => 'text/rfc822-headers', encoding => '7bit' },
        body => $orig->header_obj->as_string,
    );
}

# Build the multipart/report Content-Type (with report-type) by reading the
# boundary Email::MIME chose for a freshly-created multipart object.
sub _set_report_type {
    my ($msg) = @_;
    my $ct = $msg->header('Content-Type') // '';
    return if $ct =~ /report-type=/i;
    $ct =~ s{^(multipart/report)}{$1; report-type=delivery-status}i;
    $msg->header_str_set('Content-Type', $ct);
}

# Generate a fresh DKIM2-signed DSN for an inbound message, sent back to the
# original sender (RFC 6522 three-part multipart/report structure; DKIM2
# draft-06 §12.1). Used by the reflector-dsn address, which
# bounces every message regardless of whether it arrived DKIM2-signed.
#
# Args: Message (inbound message), Signer (MailFrom => '<>'), To (envelope
# sender to bounce to; if omitted, derived from the top DKIM2-Signature mf= or
# From:), ReportingMTA, Status, Reason.
sub generate {
    my ($class, %args) = @_;
    my $raw    = $args{Message}    or croak "generate: need Message";
    my $signer = $args{Signer} or croak "generate: need Signer";
    my $mta    = $args{ReportingMTA} // 'dkim2.com';
    my $status = $args{Status}        // '5.7.1';
    my $reason = $args{Reason}        // 'message rejected by reflector-dsn (demo bounce)';

    my $orig = Email::MIME->new($raw);

    # Where to send the bounce: explicit envelope sender, else top sig mf=,
    # else the From: header.
    my $to = $args{To};
    if (!defined $to || !length $to || $to eq '<>') {
        my $top = _top_sig($orig);
        $to = $top->mail_from if $top;
    }
    if (!defined $to || !length $to || $to eq '<>') {
        $to = $orig->header('From');
    }
    croak "generate: cannot determine bounce destination" unless defined $to && length $to;

    my $final_rcpt = $args{FinalRecipient} // $orig->header('To') // $to;

    # Part 1: human-readable explanation.
    my $human = Email::MIME->create(
        attributes => { content_type => 'text/plain', charset => 'UTF-8', encoding => '7bit' },
        body_str => "This is a DKIM2 demonstration Delivery Status Notification.\n\n"
                  . "Your message was received by the reflector-dsn address and a\n"
                  . "DKIM2-signed DSN has been returned to you.\n\n"
                  . "Reason: $reason\n",
    );

    # Part 2: machine-readable delivery status.
    my $ds = Email::MIME->create(
        attributes => { content_type => 'message/delivery-status', encoding => '7bit' },
        body => "Reporting-MTA: dns; $mta\r\n"
              . "\r\n"
              . "Final-Recipient: rfc822; $final_rcpt\r\n"
              . "Action: failed\r\n"
              . "Status: $status\r\n"
              . "Diagnostic-Code: smtp; $status $reason\r\n",
    );

    # Part 3: the original message.
    my $orig_part = Email::MIME->create(
        attributes => { content_type => 'message/rfc822', encoding => '7bit' },
        body => $orig->as_string,
    );

    # Use verbatim `header` (not `header_str`) for these plain-ASCII fields:
    # header_str runs the address encoder, which warns "empty host portion" on
    # a bare addr-spec in some Email::MIME versions. The values are already
    # well-formed, so emit them as-is.
    my $dsn = Email::MIME->create(
        attributes => { content_type => 'multipart/report', encoding => '7bit' },
        header => [
            From    => "Mail Delivery System <postmaster\@$mta>",
            To      => $to,
            Subject => 'Delivery Status Notification (Failure)',
        ],
        parts => [ $human, $ds, $orig_part ],
    );
    _set_report_type($dsn);

    # The new DSN's envelope is MAIL FROM <> RCPT TO <bounce destination>.
    $signer->{MailFrom} = '<>';
    $signer->{RcptTo}   = [$to];
    return { raw => _sign_as_new($signer, $dsn), send_to => $to };
}

# Parse a raw DSN and validate the RFC 6522 three-part multipart/report
# structure: part[0] is human-readable text, one part is machine-readable
# delivery-status, and one part is the returned original (message/rfc822 or,
# when the body is unrecoverable, text/rfc822-headers). A bare part count is
# not enough -- e.g. a report with two text/plain parts and an embedded
# original would pass a ">=3" check without being a valid DSN.
# Returns ($dsn, $orig_idx, $orig_part); croaks with $who as the prefix.
sub _parse_report {
    my ($raw, $who) = @_;
    my $dsn = Email::MIME->new($raw);
    my $ct = $dsn->content_type // '';
    croak "$who: not a multipart/report DSN" unless $ct =~ m{multipart/report}i;

    my @parts = $dsn->subparts;
    croak "$who: DSN must have at least three parts" unless @parts >= 3;

    my $part0_ct = $parts[0]->content_type // '';
    croak "$who: DSN part 1 is not human-readable text (text/plain)"
        unless $part0_ct =~ m{^text/plain}i;

    my $has_delivery_status = grep { ($_->content_type // '') =~ m{^message/delivery-status}i } @parts;
    croak "$who: DSN has no message/delivery-status part"
        unless $has_delivery_status;

    my ($orig_idx, $orig_part);
    for my $i (0 .. $#parts) {
        my $pct = $parts[$i]->content_type // '';
        if ($pct =~ m{^message/rfc822}i || $pct =~ m{^text/rfc822-headers}i) {
            $orig_idx = $i; $orig_part = $parts[$i]; last;
        }
    }
    croak "$who: no embedded original message part" unless defined $orig_idx;
    return ($dsn, $orig_idx, $orig_part);
}

# Return the LOWEST-sequence DKIM2-Signature (parsed) of an Email::MIME msg.
# For a DSN that is the signature of the system that generated it: §12.1.1
# makes a DSN a new message with exactly one signature, and if that DSN is
# itself forwarded onwards, i=1 is still its originator.
sub _origin_sig {
    my ($msg) = @_;
    my @sigs = map { Mail::DKIM2::Signature->parse($_) } $msg->header_raw('DKIM2-Signature');
    return unless @sigs;
    my ($bottom) = sort { $a->sequence <=> $b->sequence } @sigs;
    return $bottom;
}

# spec-06 §12.1.2 point 1: "The DSN's DKIM2-Signature will have a signing
# domain that is aligned with the recipient of the message that is being
# returned. The recipient's address is located in the rt= tag of the last
# (highest i= tag) DKIM2-Signature in the returned message."
#
# This is the check that says the bounce came from the place we handed the
# message to, and it is worth nothing unless the DSN's own signature has been
# verified -- anyone can write d=. authenticate() therefore verifies the DSN
# as well, and only compares the d= it has proved.
#
# The direction is §9.4's: labels come off the left of the ADDRESS domain, so
# d= may be equal to or a parent of the rt= domain, never a child of it. A
# system with a dedicated bounce domain signs as its organizational domain
# (d=example.com) and puts the bounce address on the subdomain
# (<...@bounces.example.com>) -- the subdomain belongs in the address, not in
# the signing domain -- so nothing legitimate needs the other direction.
#
# Returns ('pass'|'fail'|'none', $detail).
sub _check_alignment {
    my ($dsn_sig, $orig_top) = @_;
    return ('none', 'DSN carries no DKIM2-Signature of its own') unless $dsn_sig;

    my $d = $dsn_sig->domain // '';
    return ('none', 'DSN signature has no d=') unless length $d;

    my $rt = $orig_top ? $orig_top->rcpt_to : undef;
    my @rts = ref($rt) eq 'ARRAY' ? @$rt : (defined $rt ? ($rt) : ());
    return ('none', "returned message's top signature has no rt= to align with")
        unless @rts;

    for my $r (@rts) {
        my $rd = extract_domain($r) // '';
        next unless length $rd;
        return ('pass', "DSN d=$d is aligned with rt= $r")
            if relaxed_domain_match($rd, $d);
    }
    return ('fail', "DSN d=$d is not aligned with the returned message's rt= ("
                  . join(', ', @rts) . ')');
}

# Authenticate an inbound DSN before propagating it (spec-06 §12.1.2):
#
#   * the returned original's DKIM2 chain must verify, from its headers alone
#     when the DSN carries only headers (point 3);
#   * the DSN's own signature must verify, and its d= must be aligned with the
#     rt= of the returned original's top signature -- i.e. the bounce came
#     from the system the message was handed to (point 1);
#   * deciding whether that top signature is one the CALLER made (d= and mf=)
#     is left to the caller (point 2), since only it knows its own domains.
#
# A DSN that carries no DKIM2-Signature at all is not what §12.1.2 is about
# ("When a system receives a DKIM2 signed DSN"), so it is reported as
# dsn_result 'none' with alignment 'none' rather than failed: a caller that
# wants to insist on a signed DSN can require them, and one still handling
# legacy bounces can see that this was one.
#
# Args: raw (the DSN), pubkey_callback (as for Verifier), and optionally
# skip_timestamp_check. Returns a hashref:
#   ok               1 iff every check above that could run did pass
#   result, details  the returned original's Verifier verdict
#   top              the returned original's highest DKIM2-Signature, if any
#   dsn_result,
#   dsn_details      the DSN's own Verifier verdict ('none' if unsigned)
#   dsn_sig          the DSN's originating (i=1) DKIM2-Signature, if any
#   alignment,
#   alignment_detail point 1: 'pass', 'fail' or 'none' (not checkable)
#   headers_only     the DSN carried header fields only
#   embedded         the returned original as an Email::MIME
# Croaks, as propagate does, when the message is not an RFC 6522 DSN.
sub authenticate {
    my ($class, %args) = @_;
    my $raw = $args{Message} or croak "authenticate: need Message";
    my $cb  = $args{PubkeyCallback} or croak "authenticate: need PubkeyCallback";

    my (undef, undef, $orig_part) = _parse_report($raw, 'authenticate');
    my $headers_only = ($orig_part->content_type // '') =~ m{text/rfc822-headers}i;
    my $embedded = _embedded($orig_part);
    my $top = _top_sig($embedded);

    my $v = Mail::DKIM2::Verifier->new;
    $v->set_pubkey_callback($cb);
    $v->headers_only(1) if $headers_only;
    $v->skip_timestamp_check(1) if $args{SkipTimestampCheck};
    (my $text = $embedded->as_string) =~ s/\r?\n/\r\n/g;
    $v->PRINT($text);
    $v->CLOSE;

    # The DSN itself, from the bytes as they arrived: re-serializing the
    # Email::MIME we parsed could move a byte the body hash covers.
    my $dv = Mail::DKIM2::Verifier->new;
    $dv->set_pubkey_callback($cb);
    $dv->skip_timestamp_check(1) if $args{SkipTimestampCheck};
    (my $dsn_text = $raw) =~ s/\r?\n/\r\n/g;
    $dv->PRINT($dsn_text);
    $dv->CLOSE;
    my $dsn_result = $dv->result;

    my $dsn_sig = _origin_sig(Email::MIME->new($dsn_text));
    my ($alignment, $alignment_detail) =
        ($dsn_result eq 'pass') ? _check_alignment($dsn_sig, $top)
      : ($dsn_result eq 'none') ? ('none', 'DSN carries no DKIM2-Signature of its own')
      :                           ('none', "DSN's own signature did not verify");

    my $ok = (($v->result // '') eq 'pass')
          && ($dsn_result eq 'pass' || $dsn_result eq 'none')
          && ($alignment ne 'fail');

    return {
        ok               => $ok ? 1 : 0,
        result           => $v->result,
        details          => $v->result_detail,
        top              => $top,
        dsn_result       => $dsn_result,
        dsn_details      => $dv->result_detail,
        dsn_sig          => $dsn_sig,
        alignment        => $alignment,
        alignment_detail => $alignment_detail,
        headers_only     => $headers_only ? 1 : 0,
        embedded         => $embedded,
    };
}

# Propagate a received DSN upstream (spec-06 §12.1.1).
#
# §12.1.2 is not optional here: "If the verification fails then the DSN MUST
# NOT be propagated any further", so propagate authenticates first and croaks
# rather than re-signing a DSN it could not authenticate as ours. That needs a
# PubkeyCallback; a caller that has authenticated already (or is exercising
# the rebuild machinery on a fixture, as t/dsn.t does) passes
# SkipAuthentication => 1 to say so.
sub propagate {
    my ($class, %args) = @_;
    my $raw = $args{Message}              or croak "propagate: need Message";
    my $fwd = $args{ForwarderDomain} or croak "propagate: need ForwarderDomain";
    my $signer = $args{Signer}        or croak "propagate: need Signer";

    unless ($args{SkipAuthentication}) {
        croak "propagate: need PubkeyCallback to authenticate the DSN (§12.1.2), "
            . "or SkipAuthentication if it has been authenticated already"
            unless $args{PubkeyCallback};
        my $auth = $class->authenticate(
            Message            => $raw,
            PubkeyCallback     => $args{PubkeyCallback},
            SkipTimestampCheck => $args{SkipTimestampCheck},
        );
        unless ($auth->{ok}) {
            croak "propagate: DSN did not authenticate (§12.1.2), not propagating: "
                . ($auth->{alignment} eq 'fail' ? $auth->{alignment_detail}
                                                : ($auth->{details} // $auth->{result}));
        }
    }

    my ($dsn, $orig_idx, $orig_part) = _parse_report($raw, 'propagate');
    my @parts = $dsn->subparts;

    my $headers_only = ($orig_part->content_type // '') =~ m{text/rfc822-headers}i;
    my $embedded = _embedded($orig_part);

    # 1. Undo the Forwarder's outward modification (reverses the highest MI and
    #    removes that Message-Instance header). If the body cannot be
    #    regenerated, fall back to headers-only.
    my $body_recoverable = 1;
    {
        # Determine whether the top MI declares an unrecoverable body.
        my @mis = $embedded->header_raw('Message-Instance');
        if (@mis) {
            my ($high) = sort { ($b =~ /m=(\d+)/)[0] <=> ($a =~ /m=(\d+)/)[0] } @mis;
            my $mi_obj = Mail::DKIM2::MessageInstance->parse($high);
            $body_recoverable = 0 if $mi_obj->unrecoverable;
        }
        my $undone = Mail::DKIM2::MessageInstance->undo($embedded);
        $embedded = $undone if $undone;   # undo() returns undef if no MI present
    }

    # 2. Remove the DKIM2-Signature the Forwarder added on the outward journey.
    _strip_top_sig($embedded);

    # 3. The propagated DSN is addressed to the MAIL FROM of the now-highest
    #    DKIM2-Signature of the rebuilt original.
    my $top = _top_sig($embedded);
    my $upstream = $top ? $top->mail_from : undef;
    croak "propagate: no remaining DKIM2-Signature to derive upstream MAIL FROM"
        unless defined $upstream;

    # 4. Rebuild the embedded part. If the body is unrecoverable, emit
    #    text/rfc822-headers (headers only); otherwise message/rfc822.
    my $rebuilt_original;
    if ($headers_only || !$body_recoverable) {
        # headers only — strip the body
        $rebuilt_original = _headers_only_part($embedded);
    } else {
        $rebuilt_original = Email::MIME->create(
            attributes => { content_type => 'message/rfc822', encoding => '7bit' },
            body => $embedded->as_string,
        );
    }

    # 5. Replace the original part; leave the human-readable and
    #    delivery-status parts in place (a fuller implementation would rewrite
    #    the human-readable text to remove destination-specific detail).
    $parts[$orig_idx] = $rebuilt_original;
    $dsn->parts_set(\@parts);

    # 6. The propagated DSN is a NEW message: one Message-Instance (v=1) and one
    #    DKIM2-Signature, signed by the Forwarder with MAIL FROM <>. So the
    #    inbound DSN's OWN instance and signature go: they belong to the DSN we
    #    received, which we have already authenticated (§12.1.2) and are not
    #    continuing. Leaving them makes the new instance m=2 on a chain whose
    #    i=1 is somebody else's, which is not a chain at all.
    $dsn->header_raw_set('Message-Instance');
    $dsn->header_raw_set('DKIM2-Signature');

    $signer->{MailFrom} = '<>';
    $signer->{RcptTo}   = [$upstream];
    return { raw => _sign_as_new($signer, $dsn), upstream_mailfrom => $upstream };
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::DSN - DKIM2-signed Delivery Status Notifications

=head1 SYNOPSIS

    use Mail::DKIM2::DSN;

    # A DSN for a message we are bouncing, signed with MAIL FROM <>.
    my $out = Mail::DKIM2::DSN->generate(
        Message      => $inbound_bytes,
        Signer       => Mail::DKIM2::Signer->new(..., MailFrom => '<>'),
        ReportingMTA => 'mx.example.com',
        Status       => '5.7.1',
        Reason       => 'rejected by policy',
    );
    # $out->{raw}, $out->{to}

    # Is this DSN about a message we forwarded, and genuine?
    my $auth = Mail::DKIM2::DSN->authenticate(
        Message        => $dsn_bytes,
        PubkeyCallback => \&lookup,      # or omit to use DNS
    );
    # $auth->{ok}, $auth->{top} (our signature), $auth->{alignment}

    # Send it on towards the original sender.
    my $out = Mail::DKIM2::DSN->propagate(
        Message         => $dsn_bytes,
        ForwarderDomain => 'fwd.example',
        Signer          => $signer,       # MailFrom => '<>'
        PubkeyCallback  => \&lookup,
    );
    # $out->{raw}, $out->{upstream_mailfrom}

=head1 DESCRIPTION

Spec-06 section 12 describes how a DSN (RFC 3464, structured per RFC 6522)
is signed, checked and passed back along the chain. A forwarder that
receives a DSN for a message it forwarded rebuilds the enclosed original
to the state it was in when it went out (undoing its own Message-Instance
and removing the signature and instance it added), then re-signs the whole
DSN as a new message with MAIL FROM C<< <> >>, so it carries exactly one
Message-Instance and one DKIM2-Signature.

This module implements draft-ietf-dkim-dkim2-spec-06; see L<Mail::DKIM2/STATUS>
for what that means for the wire format and the API, and
L<Mail::DKIM2/CONVENTIONS> for the option, input and error conventions every
module here follows.

=head1 CLASS METHODS

Each takes named arguments and returns a hashref. Each croaks on a
message that is not an RFC 6522 DSN or on a missing required argument.

=head2 generate(%args)

Builds a three-part C<multipart/report> DSN returning C<Message>, signed
by C<Signer> (which must have C<< MailFrom => '<>' >>). C<To> is the
envelope sender to bounce to; if omitted it is taken from the top
DKIM2-Signature's C<mf=>, failing that from C<From:>. C<ReportingMTA>,
C<Status> (default C<5.7.1>) and C<Reason> fill the delivery-status part.
Returns C<< { raw => $bytes, to => $address } >>.

=head2 authenticate(%args)

Checks C<Message>, a DSN, per section 12.1.2: the returned original's
chain verifies (from its headers alone if that is all the DSN carries),
the DSN's own signature verifies, and the DSN's C<d=> is aligned with the
returned original's top C<rt=>. C<PubkeyCallback>, C<Resolver> and
C<SkipTimestampCheck> are passed to the verifiers. Returns a hashref with
C<ok>; C<top>, the returned original's highest signature, for the caller
to recognise as its own by C<d=> and C<mf=>; C<result>, C<details>,
C<dsn_result>, C<dsn_details>, C<dsn_sig>; C<alignment> (C<pass>, C<fail>
or C<none>) and C<alignment_detail>; C<headers_only>; and C<embedded>,
the returned original as an L<Email::MIME>.

=head2 propagate(%args)

Authenticates C<Message> as above (pass C<< SkipAuthentication => 1 >> if
the caller already has), then rebuilds and re-signs it as described. Croaks
rather than propagate a DSN that does not authenticate: section 12.1.2
says such a DSN MUST NOT be propagated. C<ForwarderDomain> is the C<d=>
of the hop to strip. Returns C<< { raw => $bytes, upstream_mailfrom =>
$address } >>.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
