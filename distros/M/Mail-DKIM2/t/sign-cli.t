#!/usr/bin/perl -w
#
# bin/dkim2sign -- the standalone signer CLI.
#
# The library's signing path otherwise only exists behind the milter and the
# reflector; this CLI exists so a cross-implementation matrix can drive Perl the
# same way it drives the Python, Go and C signers.

use 5.020;
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use lib "$FindBin::Bin/lib";
use Email::MIME;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::MessageInstance;
use DKIM2TestKeys;

my $keyfile = 't/data/keys/sel1._domainkey.test1.dkim2.com.pem';
plan skip_all => 't/data/keys not available' unless -e $keyfile;
my $keyfile2 = 't/data/keys/sel1._domainkey.test2.dkim2.com.pem';
plan skip_all => 't/data/keys not available' unless -e $keyfile2;

# The CLI verifies an upstream chain before extending it; answer key lookups
# from the shared dns.json rather than the network.
$ENV{DKIM2_DNS_JSON} = DKIM2TestKeys::dns_json();

my $dir = tempdir(CLEANUP => 1);
my $src = path($dir)->child('base.eml');
$src->spew_raw(join('',
    "From: sender\@test1.dkim2.com\r\n",
    "To: rcpt\@test2.dkim2.com\r\n",
    "Subject: sign cli test\r\n",
    "Date: Fri, 24 Jul 2026 12:00:00 +0000\r\n",
    "Message-ID: <signcli\@test1.dkim2.com>\r\n",
    "\r\n",
    "Hello signer.\r\n",
));

sub sign {
    my ($in, @args) = @_;
    my @cmd = ($^X, '-Ilib', 'bin/dkim2sign', @args, "$in");
    open my $fh, '-|', @cmd or die "cannot run signer: $!";
    binmode $fh;
    my $data = do { local $/; <$fh> };
    close $fh;
    return ($data, $? >> 8);
}

# As sign(), but with the usage/error text suppressed -- for the cases where a
# non-zero exit is what we are asserting.
sub sign_quietly {
    my @args = @_;
    open my $olderr, '>&', \*STDERR or die $!;
    open STDERR, '>', File::Spec->devnull or die $!;
    my @r = sign(@args);
    open STDERR, '>&', $olderr or die $!;
    return @r;
}

# --- originator: adds Message-Instance m=1 and DKIM2-Signature i=1 ---
my ($signed, $rc) = sign($src,
    '-s' => 'sel1', '-d' => 'test1.dkim2.com', '-k' => $keyfile,
    '--mailfrom' => '<sender@test1.dkim2.com>',
    '--rcptto'   => '<rcpt@test2.dkim2.com>',
    '--timestamp' => 1740000000);
is($rc, 0, 'signer exits 0');
like($signed, qr/^DKIM2-Signature: i=1; m=1; t=1740000000;/m,
    'emits DKIM2-Signature i=1 m=1 with the fixed timestamp');
is(scalar(() = $signed =~ /^Message-Instance:/mg), 1,
    'emits exactly one Message-Instance');
like($signed, qr/^Message-Instance: m=1;/m, 'the instance is m=1');
like($signed, qr/\r\n/, 'output uses CRLF line endings');

# The original headers survive.
like($signed, qr/^Subject: sign cli test\r$/m, 'original headers preserved');

# --- unmodified re-sign: reuses the instance, adds no new one (§9.1/§9.2.5) ---
my $hop1 = path($dir)->child('hop1.eml');
$hop1->spew_raw($signed);

my ($resigned, $rc2) = sign($hop1,
    '-s' => 'sel1', '-d' => 'test2.dkim2.com', '-k' => $keyfile2,
    '--mailfrom' => '<sender@test2.dkim2.com>',
    '--rcptto'   => '<final@test3.dkim2.com>',
    '--ignore-timestamps',   # the hop1 fixture carries a fixed old t=
    '--timestamp' => 1740000100);
is($rc2, 0, 're-signer exits 0');
is(scalar(() = $resigned =~ /^Message-Instance:/mg), 1,
    'an unmodified hop adds no Message-Instance');
is(scalar(() = $resigned =~ /^DKIM2-Signature:/mg), 2,
    'but does add a second DKIM2-Signature');
like($resigned, qr/^DKIM2-Signature: i=2; m=1;/m,
    'the new signature references the reused instance m=1');

# --- nd= hop omits mf=/rt= (§9.3) ---
my ($nd, $rc3) = sign($src,
    '-s' => 'sel1', '-d' => 'test1.dkim2.com', '-k' => $keyfile,
    '--next-domain' => 'test2.dkim2.com',
    '--timestamp' => 1740000000);
is($rc3, 0, 'nd= signer exits 0');
like($nd, qr/nd=test2\.dkim2\.com/, 'nd= hop carries nd=');
unlike($nd, qr/\bmf=/, 'nd= hop omits mf=');
unlike($nd, qr/\brt=/, 'nd= hop omits rt=');

# --- missing required options fail rather than producing garbage ---
my (undef, $rc4) = sign_quietly($src, '-d' => 'test1.dkim2.com', '-k' => $keyfile);
isnt($rc4, 0, 'missing --selector is an error');

# --- the gate: an existing DKIM2 chain must check out before we extend it ---
#
# Same decision as bin/dkim2-milter (Mail::DKIM2::Gate). The library Signer
# stays ungated; the front ends refuse.
{
    my $EOL = "\r\n";
    my $plain = $src->slurp_raw;

    my $originator = sub {
        my $mi  = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($plain));
        my $msg = "Message-Instance: " . $mi->as_string . $EOL . $plain;
        my $s = Mail::DKIM2::Signer->new(
            Domain => 'test1.dkim2.com', Selector => 'sel1',
            Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
            MailFrom => 'sender@test1.dkim2.com', RcptTo => ['rcpt@test2.dkim2.com'],
            Timestamp => time());
        $s->PRINT($msg); $s->CLOSE;
        return $s->as_string . $EOL . $msg;
    };
    my $null_top = sub {
        my (%o) = @_;
        my $signed = $originator->();
        my $mod = $signed;
        $mod =~ s/^Subject: /Subject: [list] /m;
        $mod =~ s/^To: .*$/To: tampered\@example.net/m if $o{forge};
        $mod .= "--$EOL" . "rewritten$EOL";
        my $mi = Mail::DKIM2::MessageInstance->calculate(
            Email::MIME->new($mod), Email::MIME->new($signed));
        $mi->set_null_body_recipe;
        if ($o{forge}) {
            my $rh = $mi->{bits}{rh};
            delete $rh->{$_} for grep { lc($_) eq 'to' } keys %$rh;
        }
        return "Message-Instance: " . $mi->as_string . $EOL . $mod;
    };

    my @me = ('-s' => 'sel1', '-d' => 'test2.dkim2.com', '-k' => $keyfile2,
              '--mailfrom' => '<list@test2.dkim2.com>',
              '--rcptto'   => '<sub@test3.dkim2.com>');
    my $run = sub {
        my ($text, @extra) = @_;
        my $f = path($dir)->child('gate-' . ++$main::n . '.eml');
        $f->spew_raw($text);
        my $err = path($dir)->child("gate-$main::n.err");
        my @cmd = ($^X, '-Ilib', 'bin/dkim2sign', @me, @extra, "$f");
        open my $fh, '-|', "@{[map { quotemeta } @cmd]} 2>$err" or die $!;
        binmode $fh; my $out = do { local $/; <$fh> }; close $fh;
        return ($out, $? >> 8, $err->slurp);
    };

    my ($out, $rc) = $run->($originator->());
    is($rc, 0, 'gate: valid upstream chain is extended');
    like($out, qr/^DKIM2-Signature: i=2;/m, 'gate: new signature is i=2');

    my $bad = $originator->();
    $bad =~ s/(DKIM2-Signature: i=1; m=1; t=)(\d+)/$1 . ($2 + 1)/e or die 'no t=';
    my $err;
    ($out, $rc, $err) = $run->($bad);
    isnt($rc, 0, 'gate: broken upstream signature refused');
    is($out, '', 'gate: nothing written on refusal');
    like($err, qr/not signing: upstream DKIM2 chain/, 'gate: reason names the upstream chain');

    # Corrupt the m=1 body hash: the chain no longer checks out.
    my $mi_broken = $originator->();
    $mi_broken =~ s/(Message-Instance: m=1; h=sha256:)(.)/$1 . ($2 eq 'A' ? 'B' : 'A')/e or die 'no h=';
    ($out, $rc, $err) = $run->($mi_broken);
    isnt($rc, 0, 'gate: broken Message-Instance chain refused');
    is($out, '', 'gate: nothing written for a broken MI chain');
    like($err, qr/not signing:/, 'gate: MI refusal explains itself');

    ($out, $rc, $err) = $run->($null_top->());
    isnt($rc, 0, 'gate: null body Recipe refused by default');
    is($out, '', 'gate: nothing written for null body Recipe');
    like($err, qr/null body Recipe/, 'gate: reason names the null body Recipe');
    like($err, qr/--allow-null-body-recipe not set/, 'gate: CLI message names its own flag');
    like($err, qr/unsigned top Message-Instance m=2/, 'gate: and says the null top is unsigned');

    ($out, $rc) = $run->($null_top->(), '--allow-null-body-recipe');
    is($rc, 0, 'gate: null body Recipe signed with --allow-null-body-recipe');
    like($out, qr/^DKIM2-Signature: i=2;/m, 'gate: and the signature is i=2');

    ($out, $rc) = $run->($null_top->(forge => 1), '--allow-null-body-recipe');
    isnt($rc, 0, 'gate: forged null-top refused even with the option');

    # The list domain test2 signed its own null m=2 (i=2, m=2); test3 forwards
    # it unchanged and signs i=3 without the option.
    {
        my $s = Mail::DKIM2::Signer->new(
            Domain => 'test2.dkim2.com', Selector => 'sel1',
            Key => DKIM2TestKeys::private_key('test2.dkim2.com', 'sel1'),
            MailFrom => 'list@test2.dkim2.com', RcptTo => ['sub@test3.dkim2.com'],
            Timestamp => time());
        my $m = $null_top->();
        $s->PRINT($m); $s->CLOSE;
        my $f = path($dir)->child('gate-signed-null.eml');
        $f->spew_raw($s->as_string . $EOL . $m);
        my $e = path($dir)->child('gate-signed-null.err');
        my @cmd = ($^X, '-Ilib', 'bin/dkim2sign', '-s', 'sel1', '-d', 'test3.dkim2.com',
            '-k', 't/data/keys/sel1._domainkey.test3.dkim2.com.pem',
            '--mailfrom', '<fwd@test3.dkim2.com>', '--rcptto', '<user@test4.dkim2.com>', "$f");
        open my $fh, '-|', "@{[map { quotemeta } @cmd]} 2>$e" or die $!;
        binmode $fh; my $o = do { local $/; <$fh> }; close $fh;
        is($? >> 8, 0, 'gate: a null top the list already signed is extended without the option')
            or diag($e->slurp);
        like($o, qr/^DKIM2-Signature: i=3; m=2;/m, 'gate: forwarder signs i=3 over the signed m=2');
    }

    # nd= bridge: a top signature carrying nd= may be extended only by the
    # domain it names.
    my $nd_top = sub {
        my ($nd) = @_;
        my $mi  = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($plain));
        my $msg = "Message-Instance: " . $mi->as_string . $EOL . $plain;
        my $s = Mail::DKIM2::Signer->new(
            Domain => 'test1.dkim2.com', Selector => 'sel1',
            Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
            NextDomain => $nd, Timestamp => time());
        $s->PRINT($msg); $s->CLOSE;
        return $s->as_string . $EOL . $msg;
    };
    ($out, $rc) = $run->($nd_top->('test2.dkim2.com'));
    is($rc, 0, 'gate: top nd= naming our d= is extended');
    like($out, qr/^DKIM2-Signature: i=2;/m, 'gate: nd= bridge gets i=2');
    (my $ws = $nd_top->('test2.dkim2.com')) =~ s/\bnd=/nd = /
        or die 'no nd=';
    ($out, $rc) = $run->($ws, '--ignore-timestamps');
    is($rc, 0, 'gate: "nd = x" with whitespace around "=" is recognised and signed');
    # Not a tampering hole: spec-06 canonicalises a DKIM2-Signature field by
    # removing all whitespace before hashing it, so adding FWS around "=" does
    # not change what i=1's b= covers. The countersigned chain verifies, while
    # changing the domain really does break i=1 (next test).
    {
        my $v = Mail::DKIM2::Verifier->new;
        $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
        $v->PRINT($out); $v->CLOSE;
        is($v->result, 'pass', 'gate: whitespace-in-nd= chain, countersigned, verifies')
            or diag($v->result_detail);
        (my $changed = $out) =~ s/\bnd = test2\.dkim2\.com/nd = test9.dkim2.com/ or die 'no nd';
        my $v2 = Mail::DKIM2::Verifier->new;
        $v2->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
        $v2->PRINT($changed); $v2->CLOSE;
        is($v2->result, 'fail', 'gate: changing the nd= domain does break i=1');
    }
    ($out, $rc) = $run->($nd_top->('TEST2.dkim2.com'));
    is($rc, 0, 'gate: nd= match is case-insensitive');
    ($out, $rc, $err) = $run->($nd_top->('test3.dkim2.com'));
    isnt($rc, 0, 'gate: top nd= naming another domain refused');
    is($out, '', 'gate: nothing written for an nd= mismatch');
    like($err, qr/not signing: top signature nd=test3\.dkim2\.com names another domain/,
        'gate: reason names the nd= domain');

    # Old fixtures: --ignore-timestamps and --dns-json
    {
        local $ENV{DKIM2_DNS_JSON};
        ($out, $rc) = $run->($originator->(), '--dns-json' => DKIM2TestKeys::dns_json());
        is($rc, 0, 'gate: --dns-json supplies the verification keys');
    }
    # Fixtures from the past: --ignore-timestamps is accepted.
    ($out, $rc) = $run->($originator->(), '--ignore-timestamps');
    is($rc, 0, 'gate: --ignore-timestamps accepted');
}

done_testing();
