package Mail::DKIM2::Reflector;
use strict; use warnings;

our $VERSION = '0.10';
use 5.020;

use Email::MIME;
use Carp;
use POSIX qw(strftime);
use Mail::DKIM2::Verifier;
use Mail::DKIM2::Signer;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::DSN;
use Mail::DKIM2::Common qw(fold_header should_skip DKIM2_DRAFT DKIM2_REPO DKIM2_DATE);

our $SUBJECT_PREFIX = '[DKIM2] ';
our $FOOTER         = "-- \r\nReflected and signed by the DKIM2 reflector at dkim2.com\r\n";
our $DAMAGE_LINE    = "damage line, breaks the signature\r\n";

# X-DKIM2-Info provenance, per ../spec/draft-gondwana-dkim2-debug-header-01:
# one field per action (verify, mi-m=<N>, sign), each directly above the
# header it describes. The spec version constants come from Mail::DKIM2::Common.
use constant DKIM2_SOFTWARE => 'dkim2-reflector.pl';

# The value is a tag-list in the DKIM2 syntax: every tag, the last included,
# is followed by ";". A ";" has no escape and ends a tag, so one inside a
# value becomes ",".
sub _dkim2_info {
    my ($action, %extra) = @_;
    my @tags = ("draft=" . DKIM2_DRAFT, "repo=" . DKIM2_REPO,
                "date=" . DKIM2_DATE, "sw=" . DKIM2_SOFTWARE, "action=$action");
    push @tags, "$_=$extra{$_}" for grep { defined $extra{$_} } sort keys %extra;
    return join ' ', map { (my $t = $_) =~ s/;/,/g; "$t;" } @tags;
}

# A complete, folded "X-DKIM2-Info: ..." line with trailing CRLF, ready to
# prepend directly above the header field the action added. Folded only after
# a ";" or a "," (Section 5), never inside a token.
sub _info_line {
    my ($action, %extra) = @_;
    (my $xi = fold_header("X-DKIM2-Info: " . _dkim2_info($action, %extra), undef, delimiters_only => 1))
        =~ s/\r?\n\z//;
    return "$xi\r\n";
}

# "sign d=<domain> a=<algorithm>" for a DKIM2-Signature made with %sa.
sub _sign_info_line {
    my (%sa) = @_;
    return _info_line("sign d=$sa{Domain} a=" . ($sa{Algorithm} // 'rsa-sha256'));
}

# (count, comma-separated-names) of the headers a Message-Instance hash covers,
# matching dkim2-milter's hc=/hn= fields.
sub _header_list_for_hash {
    my ($msg) = @_;
    my @fields;
    for my $h (sort { lc($a) cmp lc($b) } $msg->header_names) {
        next if should_skip($h);
        my @vals = $msg->header_raw($h);
        push @fields, (lc $h) x scalar(@vals);
    }
    return (scalar(@fields), join(',', @fields));
}

# RFC 5322 date string (always UTC) for the given epoch.
sub _rfc2822_date {
    my ($epoch) = @_;
    return POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime($epoch));
}

# Low-level: sign $text with explicit Signer args, return the DKIM2-Signature
# header (folded, no trailing CRLF). i= is auto-assigned from existing sigs.
sub _sign_with {
    my ($text, %sa) = @_;
    my $signer = Mail::DKIM2::Signer->new(%sa);
    $signer->PRINT($text); $signer->CLOSE;
    croak "signing failed: " . ($signer->result_detail // 'no result')
        unless ($signer->result // '') eq 'signed';
    return $signer->as_string;   # "DKIM2-Signature: ..."
}

# Build a fresh message (headers + body) and prepend its m=1 Message-Instance.
# No signature. Used by generate() and generate_brand().
sub _fresh_message_text {
    my (%a) = @_;
    my $now  = $a{now} // time();
    my $mid  = $a{message_id} // sprintf('<fresh-%d-%d@%s>', $now, $$, $a{domain});
    my $date = _rfc2822_date($now);
    my $text =
        "From: $a{from}\r\n"
      . "To: $a{to}\r\n"
      . "Subject: $a{subject}\r\n"
      . "Date: $date\r\n"
      . "Message-ID: $mid\r\n"
      . "MIME-Version: 1.0\r\n"
      . "Content-Type: text/plain; charset=utf-8\r\n"
      . "\r\n"
      . $a{body};
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($text));
    (my $miv = fold_header("Message-Instance: " . $mi->as_string)) =~ s/^Message-Instance:\s*//;
    my ($hc, $hn) = _header_list_for_hash(Email::MIME->new($text));
    return _info_line('mi-m=1', hc => $hc, hn => $hn)
         . "Message-Instance: $miv\r\n" . $text;
}

# Default explainer body for the fresh generator.
sub _fresh_body {
    my ($domain, $sender, $date) = @_;
    return
        "Hello,\r\n\r\n"
      . "This is a freshly-originated DKIM2 message from $domain, generated\r\n"
      . "because you sent mail to reflector-fresh\@$domain.\r\n\r\n"
      . "Unlike the other reflector addresses, this is NOT a forward of your\r\n"
      . "message: it is a brand-new message with a single Message-Instance (m=1)\r\n"
      . "and a single DKIM2-Signature (i=1), and no forwarding chain.\r\n\r\n"
      . "Paste it into https://$domain/validate/ to see it verify.\r\n\r\n"
      . "Requested by: $sender\r\n"
      . "Generated at: $date\r\n\r\n"
      . "-- \r\n"
      . "The DKIM2 reflector at $domain\r\n";
}

# generate(%args) — ORIGINATE a brand-new DKIM2 message back to the sender:
# a single Message-Instance (m=1) and a single DKIM2-Signature (i=1), no chain.
# Unlike reflect(), the incoming message is not used (the caller passes only the
# reply target as `sender`). From is a <domain> identity so DMARC aligns and the
# message lands in the inbox. An optional `body` overrides the default explainer
# (used by generate_brand()'s not-delegated path). See
# docs/superpowers/specs/2026-06-20-dkim2-reflector-fresh-design.md.
sub generate {
    my (%a) = @_;
    croak "need a sender" unless $a{sender};
    $a{domain}   //= 'dkim2.com';
    $a{selector} //= 'sel1';
    $a{mailfrom} //= "reflector-bounces\@$a{domain}";
    my $now = $a{now} // time();
    $a{timestamp} //= $now;
    my $body = $a{body} // _fresh_body($a{domain}, $a{sender}, _rfc2822_date($now));

    my $text = _fresh_message_text(
        from => "\"DKIM2 Generator\" <fresh\@$a{domain}>",
        to => $a{sender}, subject => 'Freshly generated DKIM2 message',
        body => $body, now => $now, message_id => $a{message_id}, domain => $a{domain},
    );

    # i=1 DKIM2-Signature (mf= relaxed-matches d=; rt = [sender]; no predecessor).
    my %sa = (Domain => $a{domain}, Selector => $a{selector},
              MailFrom => $a{mailfrom}, RcptTo => [ $a{sender} ], Timestamp => $a{timestamp});
    $sa{Key} = $a{key} if $a{key};
    $sa{KeyFile} = $a{keyfile} if $a{keyfile} && !$a{key};
    $text = _sign_with($text, %sa) . "\r\n" . $text;
    return _sign_info_line(%sa) . $text;
}

# generate_dsn(%args) — return a Delivery Status Notification for the incoming
# message, addressed back to the sender. Used by the reflector-dsn address,
# which bounces every message regardless of whether it arrived DKIM2-signed
# (draft-06 §12.1). The DSN is a fresh DKIM2 message signed as new: MAIL FROM
# <>, one Message-Instance and one DKIM2-Signature on the top message,
# embedding the original as a message/rfc822 part.
sub generate_dsn {
    my (%a) = @_;
    croak "need a sender" unless $a{sender};
    croak "need the incoming message" unless defined $a{message};
    $a{domain}   //= 'dkim2.com';
    $a{selector} //= 'sel1';
    my $now = $a{now} // time();

    my %sa = (Domain => $a{domain}, Selector => $a{selector}, MailFrom => '<>',
              Timestamp => $now);
    $sa{Key}     = $a{key}     if $a{key};
    $sa{KeyFile} = $a{keyfile} if $a{keyfile} && !$a{key};
    my $signer = Mail::DKIM2::Signer->new(%sa);

    my $out = Mail::DKIM2::DSN->generate(
        Message      => $a{message},
        Signer       => $signer,
        To           => $a{sender},
        ReportingMTA => $a{domain},
        Reason       => $a{reason}
            // 'message accepted then returned by the reflector-dsn demo address',
    );
    return $out->{raw};
}

# Domain part of an email address.
sub _addr_domain { my ($a) = @_; $a =~ /\@([^>]+?)>?\s*$/ ? $1 : $a }

# True iff dkim2test._domainkey.$domain is a CNAME to dkim2test._domainkey.dkim2.com.
# Live DNS (kept out of generate_brand so the message logic is testable offline).
sub _dkim2test_cname_ok {
    my ($domain) = @_;
    require Net::DNS::Resolver;
    my $r = Net::DNS::Resolver->new;
    my $q = $r->query("dkim2test._domainkey.$domain", 'CNAME') or return 0;
    for my $rr ($q->answer) {
        next unless $rr->type eq 'CNAME';
        (my $t = $rr->cname) =~ s/\.\z//;
        return 1 if lc($t) eq 'dkim2test._domainkey.dkim2.com';
    }
    return 0;
}

# sign_dkim1($text, @specs) — prepend a classic DKIM1 DKIM-Signature per spec.
# Each spec: { domain, selector, keyfile } or { domain, selector, key => <PEM> }.
# rsa-sha256 / relaxed-relaxed. Composable post-step: only prepends headers,
# never touches the body or the DKIM2/MI headers. See
# docs/superpowers/specs/2026-06-21-dkim2-reflector-dkim1-signing-design.md.
sub sign_dkim1 {
    my ($text, @specs) = @_;
    require Mail::DKIM::Signer;
    require Mail::DKIM::PrivateKey;
    for my $s (@specs) {
        # Mail::DKIM::PrivateKey's Data=> path does not parse a PEM string; only
        # File=> does. So an in-memory PEM (key=>) goes via a temp file.
        my ($key, $tmp);
        if (defined $s->{key}) {
            require File::Temp;
            $tmp = File::Temp->new(SUFFIX => '.pem');
            print {$tmp} $s->{key};
            close $tmp;
            $key = Mail::DKIM::PrivateKey->load(File => "$tmp");
        } else {
            $key = Mail::DKIM::PrivateKey->load(File => $s->{keyfile});
        }
        my $signer = Mail::DKIM::Signer->new(
            Algorithm => 'rsa-sha256',
            Method    => 'relaxed/relaxed',
            Domain    => $s->{domain},
            Selector  => $s->{selector},
            Key       => $key,
        );
        $signer->PRINT($text);
        $signer->CLOSE;
        (my $sig = $signer->signature->as_string) =~ s/\r?\n/\r\n/g;
        $sig =~ s/\r\n\z//;
        $text = "$sig\r\n" . $text;
    }
    return $text;
}

# generate_brand(%args) — the reflector-brand behaviour. With delegated=1, build a
# fresh message From the brand and sign it twice (i=1 as the brand via the
# delegated key, i=2 as <domain>), on one Message-Instance. With delegated=0, fall
# back to the fresh generator carrying a CNAME-setup error body. See
# docs/superpowers/specs/2026-06-20-dkim2-reflector-brand-design.md.
sub generate_brand {
    my (%a) = @_;
    croak "need a sender" unless $a{sender};
    $a{domain}   //= 'dkim2.com';
    $a{selector} //= 'sel1';
    $a{mailfrom} //= "reflector-bounces\@$a{domain}";
    $a{brand_selector} //= 'dkim2test';
    my $now = $a{now} // time();
    my $bd  = _addr_domain($a{sender});

    unless ($a{delegated}) {
        my $err =
            "Hello,\r\n\r\n"
          . "You asked for the DKIM2 brand demo, but dkim2test._domainkey.$bd is not\r\n"
          . "a CNAME to dkim2test._domainkey.$a{domain}. Publish that CNAME and try\r\n"
          . "again to get a brand-signed (two-signature) message.\r\n\r\n"
          . "In the meantime, here is a plain freshly-generated DKIM2 message.\r\n\r\n"
          . "-- \r\n"
          . "The DKIM2 reflector at $a{domain}\r\n";
        return generate(sender => $a{sender}, domain => $a{domain}, selector => $a{selector},
                        key => $a{key}, keyfile => $a{keyfile}, mailfrom => $a{mailfrom},
                        now => $now, message_id => $a{message_id}, body => $err);
    }

    my $rcpt = "reflector-brand\@$a{domain}";
    my $from = "dkim2demo\@$bd";
    my $i1_desc = $a{nd}
      ? "  i=1  d=$bd  (the brand hop; instead of mf=/rt= it carries\r\n"
      . "       nd=$a{domain}, naming the domain that signs the next hop --\r\n"
      . "       the \"imaginary hop\" encoding from draft-06 Section 9.3)\r\n"
      : "  i=1  d=$bd  (signed with the key you delegated via the\r\n"
      . "       dkim2test._domainkey.$bd CNAME to dkim2test._domainkey.$a{domain})\r\n";
    my $body =
        "Hello,\r\n\r\n"
      . "This is a brand-signed DKIM2 message, sent for $bd by an ESP that does\r\n"
      . "not show its own identity in the visible headers. It is freshly\r\n"
      . "originated (a single Message-Instance, m=1) but carries TWO DKIM2-Signatures:\r\n\r\n"
      . $i1_desc
      . "  i=2  d=$a{domain}  (the ESP/platform hop out to you)\r\n\r\n"
      . "Paste it into https://$a{domain}/validate/ to see both signatures verify.\r\n\r\n"
      . "-- \r\n"
      . "The DKIM2 reflector at $a{domain}\r\n";

    my $subject = $a{nd}
      ? 'Brand-signed DKIM2 message (nd= imaginary hop)'
      : 'Brand-signed DKIM2 message';
    my $text = _fresh_message_text(
        from => $from, to => $a{sender}, subject => $subject,
        body => $body, now => $now, message_id => $a{message_id}, domain => $a{domain},
    );

    # i=1: sign AS the brand using the delegated key. With nd=>1 this hop uses
    # the nd= "imaginary hop" encoding (nd=<platform domain>) instead of mf=/rt=
    # (draft-06 §9.3); the chain still validates because nd= must equal the d=
    # of the next signature (i=2).
    my %b = (Domain => $bd, Selector => $a{brand_selector}, Timestamp => $now);
    if ($a{nd}) {
        $b{NextDomain} = $a{domain};
    } else {
        $b{MailFrom} = $from;
        $b{RcptTo}   = [ $rcpt ];
    }
    $b{Key} = $a{brand_key} if $a{brand_key};
    $b{KeyFile} = $a{brand_keyfile} if $a{brand_keyfile} && !$a{brand_key};
    $text = _sign_info_line(%b) . _sign_with($text, %b) . "\r\n" . $text;

    # i=2: the dkim2.com hop out to the sender.
    my %d = (Domain => $a{domain}, Selector => $a{selector},
             MailFrom => $a{mailfrom}, RcptTo => [ $a{sender} ], Timestamp => $now);
    $d{Key} = $a{key} if $a{key};
    $d{KeyFile} = $a{keyfile} if $a{keyfile} && !$a{key};
    return _sign_info_line(%d) . _sign_with($text, %d) . "\r\n" . $text;
}

my %VALID = map { $_ => 1 } qw(raw subject body both redacted damage);

# reflect(%args) — verify an incoming message, transform it per mode, and
# return the message to send back to the sender (signed only if the incoming
# DKIM2 chain verified).  Works on raw text throughout (Email::MIME is used
# only to compute hashes/Recipes, where body_raw/header_raw preserve the
# original bytes) so upstream signatures are never invalidated by reserialising.
sub reflect {
    my (%a) = @_;
    croak "unknown mode " . ($a{mode} // '(undef)') unless $VALID{ $a{mode} // '' };
    my $mode = $a{mode};
    $a{domain}   //= 'dkim2.com';
    $a{selector} //= 'sel1';
    $a{mailfrom} //= 'reflector-bounces@dkim2.com';

    (my $incoming = $a{message}) =~ s/\r?\n/\r\n/g;

    # Strip the Unix mailbox "From sender timestamp" envelope line that Postfix
    # local(8) prepends when piping a message to an alias command. It has no
    # colon, so if it survived into the reflected message it would prematurely
    # terminate the header block when the reply is re-injected (RFC 5322),
    # dumping every real header into the body. A genuine header is "From:";
    # only the mbox line is "From " followed by a space.
    $incoming =~ s/\AFrom [^\r\n]*\r\n//;

    # Strip any Delivered-To: header Postfix local(8) prepends when piping the
    # message to this alias command. It is a per-hop delivery header (renamed to
    # X-Remote-Delivered-To / dropped before the reply is delivered), so it is
    # not seen by verifiers — but it is NOT an IANA trace header, so it is not in
    # should_skip(). If we left it in, _build_mi would hash it into our
    # Message-Instance and the resulting header hash could never be verified.
    # Remove it from the header block only, before we hash or sign anything.
    {
        my $hend = index($incoming, "\r\n\r\n");
        $hend = length($incoming) if $hend < 0;
        my $head = substr($incoming, 0, $hend);
        my $tail = substr($incoming, $hend);
        $head =~ s/^Delivered-To:[^\r\n]*(?:\r\n[ \t][^\r\n]*)*(?:\r\n|\z)//img;
        $incoming = $head . $tail;
    }

    # 1. DKIM2 verdict (computed here) + DKIM1 verdict (read from A-R).
    my ($auth, $auth_detail) = _verify($incoming, $a{pubkey_cb}, $a{skip_timestamp_check});
    my $from_domain = _from_domain($incoming);
    my $dkim1_d = _dkim1_aligned($incoming, $from_domain, $a{authserv_id});
    my $dkim1   = $dkim1_d ? 'pass' : 'none';

    # 2. Three-tier signing basis: DKIM2 chain, else DKIM1 bridge (only when no
    #    chain present — a broken chain, dkim2=fail, does NOT fall back).
    my $basis = ($auth eq 'pass')                  ? 'dkim2'
              : ($auth eq 'none' && $dkim1_d)      ? 'dkim1'
              :                                       'none';
    my $will_sign = ($basis ne 'none');

    # 3. Transform (always, except damage which mutates after signing).
    my $prev_text = $incoming;
    my $cur_text  = ($mode eq 'damage') ? $incoming : _transform_text($incoming, $mode);

    # 4. Message-Instance for our change — ALWAYS for changing modes (raw/damage
    #    reuse the top m=). Emitted whether or not we sign.
    my $mi = _build_mi($cur_text, $prev_text, $mode);
    if ($mi) {
        my $val = fold_header("Message-Instance: " . $mi->as_string);
        $val =~ s/^Message-Instance:\s*//;
        my ($hc, $hn) = _header_list_for_hash(Email::MIME->new($cur_text));
        $cur_text = _info_line("mi-m=" . $mi->get_tag('m'), hc => $hc, hn => $hn)
                  . "Message-Instance: $val\r\n" . $cur_text;
    }

    # 5. Sign when we have a basis; for damage, break the body AFTER signing.
    my $signed = 0;
    if ($will_sign) {
        my $sig = _sign($cur_text, %a);
        $cur_text = _sign_info_line(Domain => $a{domain}) . "$sig\r\n" . $cur_text;
        $signed = 1;
        $cur_text .= $DAMAGE_LINE if $mode eq 'damage';
    }

    # 6. Explanation headers (excluded from the DKIM2 header hash by
    #    should_skip(): ^x- and authentication-results). Safe to prepend last.
    # Flatten the verifier's explanation to one line with no parens or
    # backslashes, so it can sit in an RFC 8601 comment and in X-DKIM2-Info.
    my $why = '';
    if (defined $auth_detail && length $auth_detail) {
        ($why = $auth_detail) =~ s/[()\\\r\n]+/ /g;
        $why =~ s/\s+/ /g;
        $why =~ s/\A\s+|\s+\z//g;
    }
    my $ar = "Authentication-Results: $a{domain}; dkim2=$auth";
    $ar .= " ($why)" if $auth ne 'pass' && length $why;
    $ar .= "; dkim=pass header.d=$dkim1_d" if $dkim1_d;
    $ar .= "\r\n";
    my $xr = "X-DKIM2-Reflector: mode=$mode; auth=$auth; dkim1=$dkim1; "
           . "basis=$basis; signed=" . ($signed ? 'yes' : 'no')
           . "; note=reflected-to-sender\r\n";

    # X-DKIM2-Info for the verification, directly above Authentication-Results.
    # The mi-m=<N> and sign fields were added above their own headers in steps
    # 4 and 5.
    my $xi = _info_line("verify=$auth" . (length $why ? " ($why)" : ''));

    $cur_text = $xi . $ar . $xr . $cur_text;

    return {
        message => $cur_text, auth => $auth, dkim1 => $dkim1,
        basis => $basis, signed => $signed, mode => $mode,
    };
}

# Returns ($result, $detail).  The detail explains a non-pass result and is
# echoed to the sender in Authentication-Results -- for a temperror that is the
# only way they can tell an unfetchable key from a bad signature.
sub _verify {
    my ($text, $cb, $skip_ts) = @_;
    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1) if $skip_ts;
    # The inbound milter stamps a Message-Instance on non-DKIM2 mail, so a
    # message reaching us can legitimately carry an MI with no signature over
    # it. Verified mail from outside would make that spec-06 §11's "is not
    # signed" PERMERROR, but here it is our own header on our own side of the
    # trust boundary, and the whole point of this path is to then bridge-sign
    # it -- which is what makes the instance legal on the wire again. Without
    # this the result would be permerror instead of 'none' and we would refuse
    # to sign the very mail we are here to sign.
    $v->allow_unsigned_mi(1);
    $v->set_pubkey_callback($cb) if $cb;
    $v->PRINT($text); $v->CLOSE;
    return ($v->result // 'none', $v->details);
}

# Split a message into (headers-without-trailing-CRLF, body).
sub _split {
    my ($text) = @_;
    my $i = index($text, "\r\n\r\n");
    return ($text, '') if $i < 0;
    return (substr($text, 0, $i), substr($text, $i + 4));
}

# Relaxed, PSL-free domain alignment: equal, or one a subdomain of the other.
sub _domains_align {
    my ($f, $d) = @_;
    return 0 unless defined $f && defined $d && length $f && length $d;
    $f = lc $f; $d = lc $d;
    return 1 if $f eq $d;
    return 1 if $f =~ /\.\Q$d\E\z/;   # f is a subdomain of d
    return 1 if $d =~ /\.\Q$f\E\z/;   # d is a subdomain of f
    return 0;
}

# Lowercased domain of the message's From: header, or undef.
sub _from_domain {
    my ($text) = @_;
    my $from = eval { Email::MIME->new($text)->header('From') };
    return undef unless defined $from && length $from;
    my $addr = ($from =~ /<([^>]+)>/) ? $1 : $from;
    my ($dom) = $addr =~ /\@([A-Za-z0-9.\-]+)/;
    return defined $dom ? lc $dom : undef;
}

# The aligned header.d of a dkim=pass result in our authserv-id's
# Authentication-Results, or undef. Only A-R bearing $authserv_id are trusted.
sub _dkim1_aligned {
    my ($text, $from_domain, $authserv_id) = @_;
    return undef unless defined $from_domain && defined $authserv_id;
    my @ar = eval { Email::MIME->new($text)->header_raw('Authentication-Results') };
    for my $ar (@ar) {
        $ar =~ s/\r?\n[ \t]+/ /g;             # unfold
        1 while $ar =~ s/\([^()]*\)//g;       # strip CFWS comments (may hold ';')
        my ($id, $rest) = split /;/, $ar, 2;
        next unless defined $rest;
        $id =~ s/^\s+|\s+$//g;
        $id =~ s/\s.*\z//;                     # drop optional version after authserv-id
        next unless lc($id) eq lc($authserv_id);
        # The first A-R bearing our authserv-id is OpenDKIM's genuine result
        # (it prepends on top of any sender-forged copy). Trust ONLY this one.
        for my $chunk (split /;/, $rest) {     # one resinfo per chunk
            next unless $chunk =~ /\bdkim\s*=\s*pass\b/i;
            next unless $chunk =~ /header\.d\s*=\s*([A-Za-z0-9.\-]+)/i;
            my $d = lc $1;
            return $d if _domains_align($from_domain, $d);
        }
        return undef;                          # ignore any lower A-R headers
    }
    return undef;
}

sub _transform_text {
    my ($text, $mode) = @_;
    return $text if $mode eq 'raw';
    my ($head, $body) = _split($text);
    if ($mode eq 'subject' || $mode eq 'both') {
        $head =~ s/^(Subject:[ \t]*)/$1$SUBJECT_PREFIX/mi;
    }
    if ($mode eq 'body' || $mode eq 'both' || $mode eq 'redacted') {
        $body .= "\r\n" if length($body) && $body !~ /\r\n\z/;
        $body .= $FOOTER;
    }
    return "$head\r\n\r\n$body";
}

# Returns a MessageInstance object (new MI) or undef (reuse top m=).
sub _build_mi {
    my ($cur_text, $prev_text, $mode) = @_;
    return undef if $mode eq 'raw' || $mode eq 'damage';
    my $mi = Mail::DKIM2::MessageInstance->calculate(
        Email::MIME->new($cur_text), Email::MIME->new($prev_text));
    $mi->set_null_body_recipe if $mode eq 'redacted';
    return $mi;
}

sub _sign {
    my ($text, %a) = @_;
    my %sa = (
        Domain   => $a{domain},
        Selector => $a{selector},
        MailFrom => $a{mailfrom},
        RcptTo   => [ $a{sender} ],
    );
    $sa{Key}       = $a{key}       if $a{key};
    $sa{KeyFile}   = $a{keyfile}   if $a{keyfile} && !$a{key};
    $sa{Timestamp} = $a{timestamp} if $a{timestamp};
    my $signer = Mail::DKIM2::Signer->new(%sa);
    $signer->PRINT($text); $signer->CLOSE;
    croak "signing failed: " . ($signer->result_detail // 'no result')
        unless ($signer->result // '') eq 'signed';
    return $signer->as_string;   # "DKIM2-Signature: ..."
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Reflector - verify-and-reflect DKIM2 demonstration logic for dkim2.com

=head1 DESCRIPTION

The logic behind the dkim2.com reflector addresses: verify an incoming
message's DKIM2 chain, apply a per-mode transformation, and return the
message to send back to the sender. A reflector DKIM2-Signature is added
only when the incoming chain verified. This is demonstration glue, not part
of the library API, and its functions take lowercase named arguments.
See C<docs/superpowers/specs/2026-06-18-dkim2-reflector-design.md>.

=head1 FUNCTIONS

=head2 reflect(%args)

Verifies and transforms C<message> per C<mode>, signing as C<domain> /
C<selector> with C<key> or C<keyfile>. Returns a hashref with C<message>,
C<auth>, C<dkim1>, C<basis>, C<signed> and C<mode>.

=head2 generate(%args)

A fresh signed message to C<sender>.

=head2 generate_dsn(%args)

A signed DSN returning C<message> to C<sender>, via L<Mail::DKIM2::DSN>.

=head2 generate_brand(%args)

A two-signature brand demonstration message, or an explanatory one when
the sender's domain has not delegated a key.

=head2 sign_dkim1($text, @specs)

Adds classic DKIM signatures, one per C<< { domain, selector, key } >>.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
