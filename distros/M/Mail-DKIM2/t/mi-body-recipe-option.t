use strict; use warnings;
use Test::More;
use lib 'lib';
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Common qw(parse_mime);
use MIME::Base64 qw(encode_base64);

my $orig_body = "line one\r\nline two\r\n";
my $prev = "From: a\@example.com\r\nSubject: hi\r\n\r\n$orig_body";
my $m1 = Mail::DKIM2::MessageInstance->calculate($prev);
my $mi1 = "Message-Instance: " . $m1->as_string . "\r\n";
$prev = $mi1 . $prev;

# Wrapped body: 2 preamble lines, original at lines 3-4, 1 trailer line.
my $cur = $mi1 . "From: a\@example.com\r\nSubject: [list] hi\r\n\r\n"
        . "pre1\r\npre2\r\n$orig_body" . "post\r\n";

my $headers_only_prev = $prev; $headers_only_prev =~ s/\r\n\r\n.*\z/\r\n\r\n/s;

subtest 'array Recipe, previous body ignored' => sub {
    my $mi = Mail::DKIM2::MessageInstance->calculate($cur, $headers_only_prev,
        BodyRecipe => [[3, 4]]);
    like $mi->as_string, qr/^m=2; /, 'm=2';
    my $msg = "Message-Instance: " . $mi->as_string . "\r\n" . $cur;
    my ($ok, $err) = Mail::DKIM2::MessageInstance->chain_verifies($msg);
    ok $ok, 'chain verifies' or diag $err;

    # empty original body
    my $e1 = "From: a\@example.com\r\n\r\n";
    my $em1 = Mail::DKIM2::MessageInstance->calculate($e1);
    my $ehdr = "Message-Instance: " . $em1->as_string . "\r\n";
    my $ecur = $ehdr . "From: a\@example.com\r\n\r\nwrapped\r\n";
    my $emi = Mail::DKIM2::MessageInstance->calculate($ecur, $ehdr . $e1,
        BodyRecipe => []);
    my $p = Mail::DKIM2::MessageInstance->parse($emi->as_string);
    is_deeply $p->{bits}{rb}, [], 'empty b recipe';
    ($ok, $err) = Mail::DKIM2::MessageInstance->chain_verifies(
        "Message-Instance: " . $emi->as_string . "\r\n" . $ecur);
    ok $ok, 'empty-body chain verifies' or diag $err;
};

subtest 'null' => sub {
    my $mi = Mail::DKIM2::MessageInstance->calculate($cur, $headers_only_prev,
        BodyRecipe => 'null');
    my $p = Mail::DKIM2::MessageInstance->parse($mi->as_string);
    ok $p->unrecoverable, 'b is null';
};

subtest 'none' => sub {
    my $same = $cur; $same =~ s/\r\n\r\n.*\z/\r\n\r\n$orig_body/s;
    my $mi = Mail::DKIM2::MessageInstance->calculate($same, $headers_only_prev,
        BodyRecipe => 'none');
    ok !exists Mail::DKIM2::MessageInstance->parse($mi->as_string)->{bits}{rb},
        'no b key';
    my $msg = "Message-Instance: " . $mi->as_string . "\r\n" . $same;
    my ($ok, $err) = Mail::DKIM2::MessageInstance->chain_verifies($msg);
    ok $ok, 'chain verifies' or diag $err;
};

subtest 'malformed BodyRecipe croaks' => sub {
    for my $bad ([[0, 1]], [[3, 2]], [[3, 4], [1, 2]], {}, 'bogus') {
        eval { Mail::DKIM2::MessageInstance->calculate($cur, $headers_only_prev,
            BodyRecipe => $bad) };
        ok $@, 'croaks on ' . (ref $bad ? 'ref' : $bad);
    }
};

subtest 'body_hash and body_digest_raw' => sub {
    for my $b ("a\nb\n", "a\r\nb\r\n", "a\nb", "", "\n\n\n", "x\r\n\r\n") {
        (my $crlf = $b) =~ s/\r?\n/\r\n/g;
        my $want = Mail::DKIM2::MessageInstance::b_digest(parse_mime("H: v\r\n\r\n$crlf"));
        is(Mail::DKIM2::MessageInstance::body_digest_raw($b), $want, 'digest matches');
    }
    is(Mail::DKIM2::MessageInstance->parse($m1->as_string)->body_hash,
       Mail::DKIM2::MessageInstance::b_digest(parse_mime($prev)), 'body_hash');
};

subtest 'BodyHash: header block only, same instance' => sub {
    my $mp = "Content-Type: multipart/mixed; boundary=\"zz\"\r\n";
    my $wrapped = "pre1\r\npre2\r\n$orig_body" . "post\r\n";
    for my $c (
        [ 'plain',     $cur ],
        [ 'multipart', $mi1 . "From: a\@example.com\r\n$mp\r\n"
                     . "--zz\r\n\r\n" . $orig_body . "--zz--\r\n\r\n\r\n" ],
    ) {
        my ($name, $full) = @$c;
        my ($hdr, $body) = split /\r\n\r\n/, $full, 2;
        $hdr .= "\r\n\r\n";
        # 'none' declares the body unchanged, so it is checked separately.
        for my $br ([[3, 4]], 'null') {
            my $want = Mail::DKIM2::MessageInstance->calculate($full,
                $headers_only_prev, BodyRecipe => $br)->as_string;
            my $got = Mail::DKIM2::MessageInstance->calculate($hdr,
                $headers_only_prev, BodyRecipe => $br,
                BodyHash => Mail::DKIM2::MessageInstance::body_digest_raw($body)
            )->as_string;
            is $got, $want, "$name, " . (ref $br ? 'copy' : $br);
        }
    }

    # Both algorithms, as a hashref; and m=1 (no previous).
    my ($hdr, $body) = split /\r\n\r\n/, $cur, 2;
    $hdr .= "\r\n\r\n";
    my %bh = map { $_ => Mail::DKIM2::MessageInstance::body_digest_raw($body, $_) }
        qw(sha256 sha512);
    is(Mail::DKIM2::MessageInstance->calculate($hdr, $headers_only_prev,
            BodyRecipe => [[3, 4]], Algs => [qw(sha256 sha512)],
            BodyHash => \%bh)->as_string,
        Mail::DKIM2::MessageInstance->calculate($cur, $headers_only_prev,
            BodyRecipe => [[3, 4]], Algs => [qw(sha256 sha512)])->as_string,
        'sha256 and sha512 from a hashref');
    my $orig = "From: a\@example.com\r\nSubject: hi\r\n\r\n";
    is(Mail::DKIM2::MessageInstance->calculate($orig, undef,
            BodyHash => Mail::DKIM2::MessageInstance::body_digest_raw($orig_body)
        )->as_string, $m1->as_string, 'm=1');
};

subtest 'BodyHash with none: the body must be unchanged' => sub {
    my $hdr = $cur; $hdr =~ s/\r\n\r\n.*\z/\r\n\r\n/s;
    my $same = $hdr . $orig_body;
    my $want = Mail::DKIM2::MessageInstance->calculate($same,
        $headers_only_prev, BodyRecipe => 'none')->as_string;
    is(Mail::DKIM2::MessageInstance->calculate($hdr, $headers_only_prev,
            BodyRecipe => 'none',
            BodyHash => Mail::DKIM2::MessageInstance::body_digest_raw($orig_body)
        )->as_string, $want, 'unchanged body: same instance');
    eval { Mail::DKIM2::MessageInstance->calculate($hdr, $headers_only_prev,
        BodyRecipe => 'none',
        BodyHash => Mail::DKIM2::MessageInstance::body_digest_raw("other\r\n")) };
    like $@, qr/body changed/, 'changed body croaks';
};

subtest 'BodyHash: header block with or without its final line break' => sub {
    my $bh = Mail::DKIM2::MessageInstance::body_digest_raw($orig_body);
    my @got = map {
        Mail::DKIM2::MessageInstance->calculate($_, undef, BodyHash => $bh)->as_string
    } "From: a\@example.com\r\nSubject: hi",
      "From: a\@example.com\r\nSubject: hi\r\n",
      "From: a\@example.com\r\nSubject: hi\r\n\r\n";
    is $got[0], $got[2], 'no final CRLF';
    is $got[1], $got[2], 'no blank line';
    is $got[2], $m1->as_string, 'same as the full message';
};

subtest 'BodyHash values are validated' => sub {
    my $good = Mail::DKIM2::MessageInstance::body_digest_raw("x\r\n");
    my $good512 = Mail::DKIM2::MessageInstance::body_digest_raw("x\r\n", 'sha512');
    my @bad = (
        [ 'not a digest',  'deadbeef' ],
        [ 'header injection', "$good\r\nX-Injected: yes" ],
        [ 'wrong length',  $good512 ],
        [ 'sha512 wrong length', { sha256 => $good, sha512 => $good } ],
        [ 'unknown algorithm', { sha256 => $good, md5 => $good } ],
        [ 'undef value', { sha256 => undef } ],
    );
    for my $c (@bad) {
        my ($name, $bh) = @$c;
        my $algs = ref $bh && exists $bh->{sha512} ? [qw(sha256 sha512)] : ['sha256'];
        eval { Mail::DKIM2::MessageInstance->calculate($cur, $headers_only_prev,
            BodyRecipe => 'null', Algs => $algs, BodyHash => $bh) };
        like $@, qr/BodyHash/, $name;
    }
    ok eval { Mail::DKIM2::MessageInstance->calculate($cur, $headers_only_prev,
        BodyRecipe => 'null', Algs => [qw(sha256 sha512)],
        BodyHash => { sha256 => $good, sha512 => $good512 }); 1 },
        'valid sha256 and sha512' or diag $@;
};

subtest 'BodyRecipe misuse croaks' => sub {
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    for my $c (
        [ 'undef',             undef ],
        [ 'undef step',        [[3, 4], undef] ],
        [ 'literal with CRLF', ["a\r\nX-Injected: yes"] ],
        [ 'literal with LF',   ["a\nb"] ],
        [ 'literal with CR',   ["a\rb"] ],
    ) {
        my ($name, $br) = @$c;
        eval { Mail::DKIM2::MessageInstance->calculate($cur, $headers_only_prev,
            BodyRecipe => $br) };
        like $@, qr/BodyRecipe/, $name;
    }
    eval { Mail::DKIM2::MessageInstance->calculate("From: a\@example.com\r\n\r\nx\r\n",
        undef, BodyRecipe => 'null') };
    like $@, qr/BodyRecipe needs a previous message/, 'no previous';
    is_deeply \@warn, [], 'no warnings';
};

subtest 'BodyHash misuse croaks' => sub {
    my $bh = Mail::DKIM2::MessageInstance::body_digest_raw("x\r\n");
    my @bad = (
        [ 'alg missing', BodyRecipe => 'null', Algs => [qw(sha256 sha512)],
          BodyHash => { sha256 => $bh } ],
        [ 'not b64 or hash', BodyRecipe => 'null', BodyHash => [] ],
        [ 'body diff', BodyHash => $bh ],
        [ 'epilogue', UseEpilogue => 1, BodyHash => $bh ],
        [ 'threshold', EpilogueThreshold => 3, BodyHash => $bh ],
    );
    for my $c (@bad) {
        my ($name, @opts) = @$c;
        eval { Mail::DKIM2::MessageInstance->calculate($cur, $headers_only_prev, @opts) };
        like $@, qr/BodyHash/, $name;
    }
};

subtest 'body_digest_raw: large bodies, chunk and tail edges' => sub {
    # The obvious implementation, for comparison.
    my $ref = sub {
        my ($b, $alg) = @_;
        (my $c = $b) =~ s/\r?\n/\r\n/g;
        $c =~ s/(\r\n)+\z//;
        my $fn = Mail::DKIM2::MessageInstance::hash_algs()->{$alg // 'sha256'};
        encode_base64($fn->("$c\r\n"), '');
    };
    my $line = "0123456789abcdef" x 4;
    my @cases = (
        [ 'LF',            ("$line\n") x 70000 ],
        [ 'CRLF',          ("$line\r\n") x 70000 ],
        [ 'mixed, lone CR', map { $_ % 3 ? "$line\r\n" : $_ % 5 ? "$line\n" : "$line\r" } 1 .. 70000 ],
        [ 'one long line', 'x' x 3_000_000 ],
        [ 'CR before each chunk edge', ('x' x 1048575) . "\r\n" . ('y' x 1048574) . "\r\r\n" . "z\n" ],
        [ 'long trailing run', "a\n" . ("\r\n" x 5000) . ("\n" x 5000) ],
        [ 'trailing run ending in CR', "a\n" . ("\n" x 5000) . "\r" ],
        [ 'trailing CR before LF', "a\r" . ("\r\n" x 2047) . "\n" ],
        [ 'all newlines', "\r\n" x 9000 ],
    );
    for my $c (@cases) {
        my ($name, @parts) = @$c;
        my $b = join '', @parts;
        is Mail::DKIM2::MessageInstance::body_digest_raw($b), $ref->($b), $name;
    }
    my $b = join '', ("$line\n") x 70000;
    is Mail::DKIM2::MessageInstance::body_digest_raw($b, 'sha512'), $ref->($b, 'sha512'), 'sha512';
};

done_testing;
