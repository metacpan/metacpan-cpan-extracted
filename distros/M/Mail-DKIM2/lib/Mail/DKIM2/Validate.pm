package Mail::DKIM2::Validate;
use strict; use warnings; use 5.020;

our $VERSION = '0.13';

use Email::MIME;
use List::Util qw(max);
use Mail::DKIM2::Common qw(extract_mi_version extract_domain relaxed_domain_match parse_dkim_pubkey);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::Signature;

sub _i { my $h = shift // ''; $h =~ /\bi=(\d+)/ ? 0 + $1 : 0 }
sub _m { my $h = shift // ''; $h =~ /\bm=(\d+)/ ? 0 + $1 : 0 }

# --- parsed-tag breakdown for the validator UI ---------------------------
# A compact, human-readable rendering of every tag in a DKIM2-Signature or
# Message-Instance, so the validator can show the full parsed structure.

# Unix timestamp -> "<n> (YYYY-MM-DD HH:MM:SSZ)".
sub _fmt_ts {
    my $t = shift;
    return '' unless defined $t && $t ne '';
    return $t unless $t =~ /^\d+$/;
    my @g = gmtime($t);
    return sprintf('%s (%04d-%02d-%02d %02d:%02d:%02dZ)',
                   $t, $g[5]+1900, $g[4]+1, $g[3], $g[2], $g[1], $g[0]);
}

# Middle-truncate a long base64 blob to keep the structure compact.
sub _trunc {
    my ($s, $keep) = @_;
    $keep //= 16;
    $s //= '';
    return $s if length($s) <= 2*$keep + 1;
    return substr($s, 0, $keep) . '…' . substr($s, -$keep);
}

# Ordered [{tag,label,value}] for every tag present in a DKIM2-Signature.
sub _sig_tags {
    my ($sig) = @_;
    return [] unless $sig;
    my @t;
    push @t, { tag => 'i',  label => 'sequence',   value => ($sig->sequence  // '') };
    push @t, { tag => 'm',  label => 'covers MI',  value => ($sig->version   // '') };
    push @t, { tag => 't',  label => 'timestamp',  value => _fmt_ts($sig->timestamp) };
    push @t, { tag => 'd',  label => 'domain',     value => ($sig->domain    // '') };
    my $nd = $sig->next_domain;
    push @t, { tag => 'nd', label => 'next-domain', value => $nd } if defined $nd;
    my $mf = $sig->mail_from;
    push @t, { tag => 'mf', label => 'MAIL FROM',  value => ($mf // ''), decoded => 1 } if defined $mf;
    my $rt = $sig->rcpt_to;
    push @t, { tag => 'rt', label => 'RCPT TO', value => join(', ', @$rt), decoded => 1 } if $rt && @$rt;
    my $n = $sig->nonce;
    push @t, { tag => 'n',  label => 'nonce', value => $n } if defined $n && length $n;
    my $f = $sig->flags;
    push @t, { tag => 'f',  label => 'flags', value => join(', ', @$f) } if $f && @$f;
    my $cnt = $sig->sig_count || 0;
    for my $idx (0 .. $cnt - 1) {
        my $v = $sig->signature_value($idx) // '';
        push @t, { tag => 's', label => 'signature',
                   value => sprintf('%s : %s : %s (%d bytes b64)',
                                    $sig->selector($idx) // '', $sig->algorithm($idx) // '',
                                    _trunc($v), length $v) };
    }
    return \@t;
}

# Ordered [{tag,label,value}] for a Message-Instance.
sub _mi_tags {
    my ($mi) = @_;
    return [] unless $mi;
    my @t;
    push @t, { tag => 'm', label => 'instance', value => ($mi->get_tag('m') // '') };
    # spec-06 §7.3: h= may carry a hash-set per algorithm -- show each one
    # under its own name rather than assuming sha256.
    my $hashes = $mi->get_tag('hashes') || {};
    for my $alg (sort keys %$hashes) {
        my ($hh, $bh) = @{ $hashes->{$alg} };
        push @t, { tag => 'h', label => 'header hash', value => "$alg:" . ($hh // '') };
        push @t, { tag => 'h', label => 'body hash',   value => "$alg:" . ($bh // '') };
    }
    my $rh = $mi->get_tag('rh');
    my $rb = $mi->get_tag('rb');
    if ($mi->unrecoverable) {
        push @t, { tag => 'r', label => 'recipe', value => 'null (previous state not recoverable)' };
    } elsif ($rh || $rb) {
        my @parts;
        push @parts, 'headers: ' . join(', ', sort keys %$rh) if $rh && %$rh;
        push @parts, 'body: ' . (ref $rb eq 'ARRAY' ? scalar(@$rb) . ' step(s)' : 'changed') if $rb;
        push @t, { tag => 'r', label => 'recipe', value => join('; ', @parts) };
    }
    return \@t;
}

# Default pubkey callback: LIVE DNS. A dns.json override applies only when a
# readable $dns_path is passed in (offline testing) — production passes none,
# so the validator uses real DNS and never masks a broken key record.
sub _default_cb {
    my ($dns_path) = @_;
    my $dns;
    if ($dns_path && -r $dns_path) {
        require JSON;
        if (open my $fh, '<', $dns_path) {
            $dns = eval { JSON::decode_json(do { local $/; <$fh> }) };
            close $fh;
        }
    }
    return sub {
        my ($sig, $idx, $verifier) = @_; $idx //= 0;
        my $sel = $sig->selector($idx); my $dom = $sig->domain;
        if ($dns && $dom && $sel) {
            my $t = $dns->{$dom}{"$sel._domainkey"}[0][1];
            return parse_dkim_pubkey($t) if $t;
        }
        # Real DNS. Not eval'd: a transient failure must stay a TEMPERROR,
        # which the verifier classifies; swallowing it here read as "no key".
        return $verifier->fetch_public_key($sig, $idx);
    };
}

# report($text, %opts) — verify a DKIM2 message and return a structured report.
#
# Prior to spec-06, a receiving MTA's Received-SPF header (Fastmail adds one)
# was covered by the Message-Instance header hash and could break
# verification; this used to retry once with it stripped. spec-06 §4 excludes
# Received-SPF from the hash via the "received-" prefix rule (should_skip()),
# so stripping it can no longer change h_digest()/b_digest() or any verdict —
# the retry was provably a no-op. Removed rather than kept as a "safety net":
# it was hardcoded to the literal name Received-SPF, not a general mechanism,
# so it covered nothing else anyway. Mirrored removal in
# deploy/www/verify/verify.js's verifyMessage().
sub report {
    my ($text, %opts) = @_;
    $text //= '';

    return _report_once($text, %opts);
}

sub _report_once {
    my ($text, %opts) = @_;
    $text //= '';
    $text =~ s/\r?\n/\r\n/g;
    my $cb = $opts{PubkeyCallback} || _default_cb($opts{DnsPath});
    my $skip_ts = $opts{SkipTimestampCheck} ? 1 : 0;

    my %res = (overall => 'none', summary => '',
               counts => { signatures => 0, instances => 0 }, levels => []);

    my $msg = eval { Email::MIME->new($text) };
    return { %res, overall => 'fail', summary => "could not parse message: $@" }
        if $@ || !$msg;

    my @sig_hdrs = $msg->header('DKIM2-Signature');
    my @mi_hdrs  = $msg->header('Message-Instance');
    $res{counts} = { signatures => scalar @sig_hdrs, instances => scalar @mi_hdrs };
    # A Message-Instance with no signature anywhere is spec-06 §11's
    # "PERMERROR Message-Instance m=<x> is not signed", not an absence of
    # DKIM2. Reporting it as 'none' is exactly the answer someone pasting such
    # a message here does not need: it says "nothing to see" about a message
    # that a conforming receiver will reject.
    if (!@sig_hdrs && @mi_hdrs) {
        my ($top_mi) = sort { $b <=> $a }
                       grep { defined }
                       map  { extract_mi_version($_) } @mi_hdrs;
        $top_mi //= '?';
        return { %res, overall => 'fail',
                 summary => "PERMERROR Message-Instance m=$top_mi is not signed" };
    }

    return { %res, overall => 'none', summary => 'no DKIM2-Signature headers found' }
        unless @sig_hdrs;

    # Overall verdict from the full verifier (includes the §10.7 deep MI walk).
    # Timestamp age is graded per-signature as a soft 'warn' below, so it must
    # not hard-fail the crypto verdict here.
    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback($cb);
    eval { $v->PRINT($text); $v->CLOSE; 1 };
    my $ov = $v->result // 'fail';
    $res{summary} = $v->result_detail // '';
    $res{overall} = $ov eq 'pass' ? 'pass' : ($ov eq 'none' ? 'none' : 'fail');

    my %sig_by_i = map { _i($_) => $_ } @sig_hdrs;

    # Descend the chain top-down. At each step: verify every signature whose
    # m= equals the current top Message-Instance (content is at the right level
    # for them), then record that MI level and undo one step. Records a level
    # for every signature and every MI, in chain order (top hop first).
    my @levels;
    my $work = Email::MIME->new($text);
    my $stopped;

    while (1) {
        my %sigmap = map { _i($_) => $_ } $work->header('DKIM2-Signature');
        my %mimap  = map { extract_mi_version($_) => $_ } $work->header('Message-Instance');
        my $num  = %sigmap ? max(keys %sigmap) : 0;
        my $inst = %mimap  ? max(keys %mimap)  : 0;
        last if !$num && !$inst;

        # Signatures covering the current top MI (highest i first).
        while ($num > 0 && _m($sigmap{$num}) == $inst) {
            push @levels, _sig_level($work, $num, \%sig_by_i, $cb, $skip_ts);
            $work->header_raw_set('DKIM2-Signature',
                grep { _i($_) < $num } $work->header('DKIM2-Signature'));
            %sigmap = map { _i($_) => $_ } $work->header('DKIM2-Signature');
            $num = %sigmap ? max(keys %sigmap) : 0;
        }

        last unless $inst;   # no more MIs to record

        my $lvl = _mi_level($work, $inst, $mimap{$inst});
        push @levels, $lvl;

        last if $inst <= 1;                 # base instance recorded; done
        if ($lvl->{undo} eq 'clean') {
            Mail::DKIM2::MessageInstance->undo($work);
            $work = Email::MIME->new($work->as_string);   # reset Email::MIME caches
        } else {
            $stopped = "stopped below m=$inst ($lvl->{undo})";
            last;
        }
    }

    $res{summary} = ($res{summary} ? "$res{summary}; " : '') . $stopped if $stopped;

    # An old/future timestamp is a soft warning, not a hard fail: if the chain
    # otherwise verified, surface it as an amber 'warn' overall.
    if ($res{overall} eq 'pass'
        && grep { ($_->{result} // '') eq 'warn' } @levels) {
        $res{overall} = 'warn';
    }

    $res{levels} = \@levels;
    return \%res;
}

# Level hashref for the top Message-Instance m=$inst of $msg.
sub _mi_level {
    my ($msg, $inst, $mi_raw) = @_;
    my %lvl = (kind => 'mi', m => $inst, result => 'fail',
               header_hash => 'mismatch', body_hash => 'mismatch',
               recipe => 'none', undo => 'n/a', detail => '',
               header_recipes => [], body_recipe => 'none');
    my $mi = eval { Mail::DKIM2::MessageInstance->parse($mi_raw) };
    unless ($mi) { $lvl{detail} = 'unparseable Message-Instance'; return \%lvl; }

    $lvl{tags} = _mi_tags($mi);

    # spec-06 §3.4/§7.3: mirror MessageInstance::verify()'s semantics here --
    # every implemented hash-set must match; an MI naming no implemented
    # algorithm displays as a mismatch (fail-closed), not silently as a
    # sha256-only "no hash".
    my $hashes = $mi->get_tag('hashes') || {};
    my $impl   = Mail::DKIM2::MessageInstance::hash_algs();
    my @usable = sort grep { $impl->{$_} } keys %$hashes;
    my ($h_match, $b_match) = (0, 0);
    if (@usable) {
        $h_match = $b_match = 1;
        for my $alg (@usable) {
            my ($h1, $b1) = @{ $hashes->{$alg} };
            my $hd = Mail::DKIM2::MessageInstance::h_digest($msg, $alg);
            my $bd = Mail::DKIM2::MessageInstance::b_digest($msg, $alg);
            $h_match = 0 unless defined $h1 && $h1 eq $hd;
            $b_match = 0 unless defined $b1 && $b1 eq $bd;
        }
    }
    $lvl{header_hash} = $h_match ? 'match' : 'mismatch';
    $lvl{body_hash}   = $b_match ? 'match' : 'mismatch';
    my $rh = $mi->get_tag('rh');
    my $rb = $mi->get_tag('rb');
    $lvl{recipe} = $mi->unrecoverable ? 'null' : ($rb || $rh) ? 'diff' : 'none';
    $lvl{body_recipe} = $mi->unrecoverable ? 'null' : ($rb ? 'diff' : 'none');

    if ($inst <= 1) {
        $lvl{undo} = 'n/a';
    } elsif ($mi->unrecoverable) {
        $lvl{undo} = 'unrecoverable';
    } else {
        my $clone = Email::MIME->new($msg->as_string);
        my $ok = eval { Mail::DKIM2::MessageInstance->undo($clone) };
        $lvl{undo} = ($ok && !$@) ? 'clean' : 'failed';
        if ($ok && !$@ && $rh) {
            for my $h (sort keys %$rh) {
                my $cur  = join(' / ', $msg->header($h));
                my $prev = join(' / ', $clone->header($h));
                push @{$lvl{header_recipes}}, {
                    name => $h,
                    current  => (length $cur  ? $cur  : '(absent)'),
                    previous => (length $prev ? $prev : '(absent)'),
                };
            }
        }
    }

    $lvl{result} = ($lvl{header_hash} eq 'match' && $lvl{body_hash} eq 'match')
                 ? 'pass' : 'fail';
    return \%lvl;
}

# Signature-level hashref for i=$num, verifying the chain prefix on $work.
sub _sig_level {
    my ($work, $num, $sig_by_i, $cb, $skip_ts) = @_;
    # $sig_by_i values come from Email::MIME->header() — already bare values.
    my $sig = eval { Mail::DKIM2::Signature->parse($sig_by_i->{$num}) };
    my %lvl = (kind => 'signature', i => $num, m => _m($sig_by_i->{$num}),
               domain => ($sig ? ($sig->domain // '') : ''),
               mail_from => '', rcpt_to => [],
               items => [], timestamp => { ok => 1, detail => '' },
               custody => { ok => 1, detail => '' }, result => 'fail', detail => '');

    if ($sig) {
        $lvl{tags} = _sig_tags($sig);
        $lvl{mail_from} = $sig->mail_from // '';
        my $rt = $sig->rcpt_to;
        $lvl{rcpt_to} = [ ref $rt eq 'ARRAY' ? @$rt : (defined $rt ? ($rt) : ()) ];
        my $n = $sig->sig_count || 0;
        for my $idx (0 .. $n - 1) {
            push @{$lvl{items}}, {
                selector  => ($sig->selector($idx)  // ''),
                algorithm => ($sig->algorithm($idx) // ''),
            };
        }
        unless ($skip_ts) {
            my $ts = $sig->timestamp;
            if (defined $ts && $ts > 0) {
                my $now = time();
                if    ($ts > $now + 300)        { $lvl{timestamp} = { ok => 0, status => 'future', detail => 'timestamp in the future' }; }
                elsif ($now > $ts + 14*24*3600) { $lvl{timestamp} = { ok => 0, status => 'old',    detail => 'older than 14 days' }; }
            }
        }
        if ($num > 1 && $sig_by_i->{$num - 1}) {
            my $prev = eval { Mail::DKIM2::Signature->parse($sig_by_i->{$num-1}) };
            if ($prev) {
                my $prev_nd = $prev->next_domain;
                if (defined $prev_nd && length $prev_nd) {
                    # draft-06 §11.4: an nd= "imaginary hop" must name the domain
                    # that signs the next signature; nd= MUST exactly match its d=.
                    my $cur_d = $sig->domain // '';
                    $lvl{custody} = (lc($prev_nd) eq lc($cur_d))
                        ? { ok => 1, detail => "nd=$prev_nd matches d= of i=$num" }
                        # Canonical spec-06 wording (Task 3.1), verbatim "MAIL nd="
                        # typo preserved, keyed on the *previous* hop's i=.
                        : { ok => 0, detail => "DKIM2-Signature i=" . ($num - 1) . " MAIL nd= does not match" };
                } else {
                    my @rts = do { my $rt = $prev->rcpt_to; ref $rt eq 'ARRAY' ? @$rt : ($rt // ()) };
                    my $cur_nd = $sig->next_domain;
                    my $mf = $sig->mail_from;
                    if (defined $cur_nd && length $cur_nd) {
                        # draft-06 §9.3: a bridge after a real hop has no mf=, so
                        # what must match the previous rt= is its d= — the key it
                        # has to be made with. Mirrors Verifier.pm's check so the
                        # report and the verdict cannot disagree.
                        my $cur_d = $sig->domain // '';
                        my $ok = grep { relaxed_domain_match($cur_d, extract_domain($_) // '') } @rts;
                        $lvl{custody} = $ok
                            ? { ok => 1, detail => "nd= hop d=$cur_d matches rt= of i=" . ($num - 1) }
                            : { ok => 0, detail => "DKIM2-Signature i=$num nd= hop d=$cur_d did not match RCPT TO" };
                    }
                    elsif ($mf && $mf ne '<>') {
                        my $mfd = extract_domain($mf);
                        my $ok = grep { relaxed_domain_match($mfd // '', extract_domain($_) // '') } @rts;
                        $lvl{custody} = $ok ? { ok => 1, detail => '' }
                                            # Canonical spec-06 wording (Task 3.1), same
                                            # form as Verifier.pm's Chain of Custody permerror.
                                            : { ok => 0, detail => "DKIM2-Signature i=$num MAIL FROM $mf did not match" };
                    }
                }
            }
        }
    } else {
        $lvl{detail} = 'unparseable DKIM2-Signature';
    }

    # Timestamp age never hard-fails here; it is graded as a soft warn above.
    # mid_process: $work is a partial view (higher DKIM2-Signature headers
    # already stripped for this top-down walk), so its locally-highest i= is
    # not necessarily the true top of the whole chain. Verifier.pm's top-nd=
    # rejection must not fire here; the real top-of-chain check is done
    # separately below against $sig_by_i (the full, original signature set).
    my $vv = Mail::DKIM2::Verifier->new;
    $vv->skip_timestamp_check(1);
    $vv->mid_process(1);
    $vv->set_pubkey_callback($cb);
    eval { $vv->PRINT($work->as_string); $vv->CLOSE; 1 };
    my $r = $vv->result // 'fail';
    my $crypto = ($r eq 'pass') ? 'pass' : 'fail';
    $lvl{result} = $crypto;
    $lvl{detail} = ($vv->result_detail // $lvl{detail}) unless $crypto eq 'pass';
    # Crypto verified but timestamp old/future -> soft amber warning.
    $lvl{result} = 'warn' if $crypto eq 'pass' && !$lvl{timestamp}{ok};
    $_->{result} = $crypto for @{$lvl{items}};

    # Local policy (spec-06 §"Check the Chain of Custody"): the
    # highest-numbered DKIM2-Signature in the *whole* chain MUST NOT carry
    # nd= (mirrors the Verifier.pm permerror from Task 2.1). $sig_by_i is the
    # original, unmodified full signature set for every call in this walk,
    # so max(keys %$sig_by_i) is the true top-of-chain i=, not merely the
    # top of this step's partial $work view (a lower, legitimately-nd=
    # hop can look locally "topmost" once higher signatures are stripped
    # for the walk; that must not trip this check). Checked last so it
    # always wins over the partial-view crypto verdict above.
    if ($sig && $num == max(keys %$sig_by_i)) {
        my $nd = $sig->next_domain;
        if (defined $nd && length $nd) {
            $lvl{result} = 'fail';
            $lvl{detail} = "DKIM2-Signature i=$num unexpected nd= tag";
        }
    }

    return \%lvl;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Validate - structured per-level DKIM2 and Message-Instance report

=head1 SYNOPSIS

    my $report = Mail::DKIM2::Validate::report($message_text,
        PubkeyCallback     => \&lookup,   # optional; default DNS
        DnsPath            => $dns_json,  # optional interop override
        SkipTimestampCheck => 1,
    );
    # $report->{overall}, $report->{summary}, $report->{counts},
    # $report->{levels}: one hashref per DKIM2-Signature and Message-Instance

=head1 DESCRIPTION

Walks a DKIM2 message top-down and returns a breakdown of every
DKIM2-Signature and Message-Instance level, including each undo step, for
the dkim2.com web validator and the C<validate.pl> tool to display. Never
dies. See C<docs/superpowers/specs/2026-06-18-dkim2-web-validator-design.md>.

=head1 FUNCTIONS

=head2 report($message_text, %options)

Options C<PubkeyCallback>, C<DnsPath> and C<SkipTimestampCheck> as above.
Returns the report hashref.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
