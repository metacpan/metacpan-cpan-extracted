package Mail::DKIM2;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.17';

use Mail::DKIM2::Common ();
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2 - DKIM2 signing and verification for email

=head1 SYNOPSIS

    use Mail::DKIM2;

    # Sign: record the message in a Message-Instance (an originating hop
    # adds m=1; a hop that changed a message adds the next m= with a Recipe,
    # see Mail::DKIM2::MessageInstance), then add a DKIM2-Signature over it.
    my $mi = Mail::DKIM2::MessageInstance->calculate($message);
    $message = Mail::DKIM2::Common::fold_header('Message-Instance: ' . $mi->as_string)
             . "\r\n" . $message;
    my $signer = Mail::DKIM2::Signer->new(
        Domain   => 'example.com',
        Selector => 'sel1',
        KeyFile  => '/etc/dkim2/sel1.pem',
        MailFrom => '<sender@example.com>',
        RcptTo   => ['<recipient@example.net>'],
    )->load($message);
    die $signer->result_detail unless $signer->result eq 'signed';
    my $header = $signer->as_string;   # "DKIM2-Signature: i=1; ..."

    # Verify: check every signature in the chain and the Message-Instance
    # chain beneath it.
    my $verifier = Mail::DKIM2::Verifier->new->load($message);
    print $verifier->result_detail, "\n";   # pass (i=1..2 verified)

    # Streaming, for a milter or other filter that sees the message in
    # pieces (CRLF line endings); one object per message:
    my $v = Mail::DKIM2::Verifier->new;
    $v->PRINT($chunk) for @chunks;
    $v->CLOSE;

=head1 DESCRIPTION

DKIM2 is a successor to DKIM in which every hop that handles a message
signs it, each signature covers all the signatures before it, and a
Message-Instance header records hashes of the message at each hop together
with a Recipe for undoing that hop's changes. A recipient can therefore
tell who handled a message, in what order, and what each of them changed.

This distribution implements signing and verification for
draft-ietf-dkim-dkim2-spec-06 (see L</STATUS>). The modules:

=over 4

=item L<Mail::DKIM2::Signer>

Adds a DKIM2-Signature header for this hop.

=item L<Mail::DKIM2::Verifier>

Verifies the chain of DKIM2-Signature headers and the Message-Instance
chain, reporting C<pass>, C<fail>, C<none>, C<permerror> or C<temperror>.

=item L<Mail::DKIM2::MessageInstance>

Computes, verifies and undoes Message-Instance headers, including the
Recipes that describe a hop's changes.

=item L<Mail::DKIM2::Signature>

Parses and builds one DKIM2-Signature header.

=item L<Mail::DKIM2::DSN>

Generates, authenticates and propagates DKIM2-signed Delivery Status
Notifications (spec-06 section 12).

=item L<Mail::DKIM2::Gate>

The verify-before-sign decision shared by C<bin/dkim2sign> and
C<bin/dkim2-milter>: whether the upstream chain is worth extending, and
whether a top C<nd=> names the domain about to sign.

=item L<Mail::DKIM2::Common>

Canonicalization, hashing, folding and key-loading functions shared by the
above.

=item L<Mail::DKIM2::HeaderParser>, L<Mail::DKIM2::TagValueList>

The streaming message parser the Signer and Verifier are built on, and the
tag=value list a DKIM2-Signature is built on.

=back

L<Mail::DKIM2::MessageStore>, L<Mail::DKIM2::Reflector>,
L<Mail::DKIM2::Validate> and L<Mail::DKIM2::Split> support the
C<authentication_milter> handlers
(L<Mail::Milter::Authentication::Handler::DKIM2Sign>,
L<Mail::Milter::Authentication::Handler::DKIM2Verify>) and the dkim2.com
demonstration server, and are not needed to sign or verify mail.

The command-line tools C<dkim2sign> and C<dkim2verify> sign and verify a
message from a file or standard input.

=head1 CONVENTIONS

The whole distribution follows these rules; each module's documentation
assumes them.

=head2 Options and methods

Constructor options and the options of class methods are C<CamelCase>
(C<SkipTimestampCheck>, C<IgnorePrefixes>). Methods are C<snake_case>
(C<skip_timestamp_check>). Where an option can also be set after
construction, the method has the same name as the option in snake_case
and acts as a getter with an optional setter argument (a code-reference
option has a C<set_> method instead). A constructor
refuses an option it does not know, so a misspelling is an error rather
than a silently ignored setting.

=head2 Feeding a message

The Signer and Verifier are streaming parsers. C<PRINT($bytes)> feeds any
amount of the message, in chunks of any size, and C<CLOSE()> finishes it.
Line endings must be CRLF, as they are on the wire; every hash in DKIM2 is
defined over CRLF text. C<load($input)> is the one-shot form: it takes the
message as a string, a reference to one, a filehandle or an L<Email::MIME>,
normalises bare LF to CRLF, and calls C<PRINT> then C<CLOSE>. A Signer or
Verifier can also be tied to a filehandle, which routes C<print> and
C<close> to C<PRINT> and C<CLOSE>.

A Signer or Verifier object handles one message. Make a new one for the
next.

=head2 Results and errors

A mistake in how the library is called, such as a missing required option
or an unknown one, is reported by C<croak> from the call that made it.

The outcome of processing a message is never an exception. The Verifier
reports it through C<result()> (one of C<pass>, C<fail>, C<none>,
C<permerror>, C<temperror>) and C<details()> (the reason); the Signer
through C<result()> (C<signed> or C<fail>) and C<details()>. Both have a
C<result_detail()> combining the two for display. C<PRINT> and C<CLOSE>
return normally whatever the verdict. The L<Mail::DKIM2::MessageInstance>
class methods follow the same split: C<verify> and C<chain_verifies> return
a status, while C<calculate> and C<undo> die when the message they are
handed cannot be processed, which a caller treats as a configuration
error.

The library only ever dies with a plain string. Any exception that is a
reference, such as an object a milter framework throws to signal a timeout,
passes through every C<eval> in the library untouched and reaches the
host.

=head2 Public keys

The Verifier fetches public keys from DNS through a L<Net::DNS::Resolver>
(the C<Resolver> option, created on demand if not given). A C<PubkeyCallback>
replaces the lookup entirely, and is handed the verifier so it can fall
back to the standard fetch for keys it does not know. A DNS failure that
is not a definite "no such record" is a C<temperror>.

=head2 Operator-local header fields

Fields an operator's own systems add after a message is signed and strip
before it leaves are named by prefix with C<IgnorePrefixes>, on a Verifier
and on each L<Mail::DKIM2::MessageInstance> call. They are local policy
and are never process-wide state.

=head1 STATUS

This implements draft-ietf-dkim-dkim2-spec-06, an Internet-Draft that is
still changing. The wire format follows the draft, so a message signed by
this version may not verify with a version tracking a later draft, and the
other way round. It is in production use: Fastmail signs outbound mail
with it, and the dkim2.com interoperability server runs it. The API is at
0.x and may still change in incompatible ways between releases; the
C<Changes> file records every such change.

=head1 SEE ALSO

L<https://github.com/dkim2wg/interop/blob/master/docs/dkim2-postfix-list-host-guide.md>,
the guide to running a Postfix mailing-list host with this distribution,
Mailman 3 or Sympa.

L<https://datatracker.ietf.org/doc/draft-ietf-dkim-dkim2-spec/>,
L<https://github.com/dkim2wg/interop>, L<https://dkim2.com/>,
L<Mail::DKIM>.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
