#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use MIME::Base64 qw(encode_base64);
use Mail::DKIM2::Common qw(parse_mime);
use Mail::DKIM2::MessageInstance;
use Spec07Fixture;

# Contract C9 (interop docs/superpowers/specs/2026-10-18-dkim2-spec-07-design.md):
# when a message has more than one fault, every verifier reports the same
# primary error. Each case here has exactly two faults, and pins which one
# is primary: within -07 section 14.2, structure (the fields' names and
# m=/i= numbers) before content, in the contract's fixed sequence; within
# section 14.7, every header hash before any body hash.

sub one_hop {
    my $m = Spec07Fixture::add_mi(Spec07Fixture::message());
    return Spec07Fixture::add_sig($m, d => 'example.com', mf => '<a@example.com>',
        rt => ['<list@lists.example.org>']);
}

sub two_hop {
    my $prev = one_hop();
    (my $cur = $prev) =~ s/^Subject: test/Subject: [list] test/m;
    $cur = Spec07Fixture::add_mi($cur, $prev);
    return Spec07Fixture::add_sig($cur, d => 'example.org', mf => '<l@lists.example.org>',
        rt => ['<r@dest.example>']);
}

# The header fields of $text as whole (folded) fields, and back.
sub fields {
    my ($text) = @_;
    my ($head, $body) = split /\r\n\r\n/, $text, 2;
    my @f;
    for my $line (split /\r\n/, $head) {
        if ($line =~ /\A[ \t]/ && @f) { $f[-1] .= "\r\n$line" } else { push @f, $line }
    }
    return (\@f, $body);
}
sub join_fields { my ($f, $body) = @_; return join("\r\n", @$f) . "\r\n\r\n" . $body }

# The one field named $name whose number tag ($tag) is $n.
sub field_index {
    my ($f, $name, $tag, $n) = @_;
    for my $k (0 .. $#$f) {
        next unless $f->[$k] =~ /\A\Q$name\E:/i;
        (my $flat = $f->[$k]) =~ s/\r\n[ \t]+/ /g;
        return $k if $flat =~ /[:;\s]\Q$tag\E=\s*\Q$n\E\s*;/;
    }
    die "no $name $tag=$n";
}
sub drop { my ($text, @which) = @_; my ($f, $b) = fields($text);
    my %gone = map { field_index($f, @$_) => 1 } @which;
    return join_fields([ map { $f->[$_] } grep { !$gone{$_} } 0 .. $#$f ], $b) }
sub edit { my ($text, $which, $code) = @_; my ($f, $b) = fields($text);
    my $k = field_index($f, @$which); local $_ = $f->[$k]; $code->(); $f->[$k] = $_;
    return join_fields($f, $b) }
sub copy_field { my ($text, $which, $where) = @_; my ($f, $b) = fields($text);
    my $k = field_index($f, @$which); my $dup = $f->[$k];
    if ($where eq 'top') { unshift @$f, $dup } else { splice @$f, $k + 1, 0, $dup }
    return join_fields($f, $b) }

my $MI1  = ['Message-Instance', 'm', 1];
my $MI2  = ['Message-Instance', 'm', 2];
my $SIG1 = ['DKIM2-Signature',  'i', 1];

sub primary {
    my ($text, $want, $name) = @_;
    my $v = Spec07Fixture::verify($text, SkipTimestampCheck => 1);
    is($v->details, $want, $name);
}

# ---- section 14.2: structure (a..h) before content ----

primary(drop(two_hop(), $SIG1),
        'PERMERROR: DKIM2-Signature i=1 missing', 'a check passes before the faults');

primary(edit(drop(two_hop(), $SIG1), $MI2, sub { s/r=[^;]*/r=!!!!/ }),
        'PERMERROR: DKIM2-Signature i=1 missing',
        'h before content: a signature gap before a Recipe that is not JSON');

primary(drop(two_hop(), $MI1, $SIG1),
        'PERMERROR: Message-Instance m=1 missing',
        'f before h: an instance gap before a signature gap');

primary(copy_field("Message-Instance: h=sha256:AAAA:BBBB;\r\n" . one_hop(), $SIG1, 'after'),
        'PERMERROR: Message-Instance m= tag=m missing',
        'b before e: an instance with no m= before a signature i= given twice');

primary(copy_field("DKIM2-Signature: m=1; d=example.com;\r\n" . one_hop(), $MI1, 'after'),
        'PERMERROR: Message-Instance m=1 appears more than once',
        'c before d: an instance m= given twice before a signature with no i=');

primary(copy_field(copy_field(two_hop(), $MI2, 'top'), $MI1, 'after'),
        'PERMERROR: Message-Instance m=1 appears more than once',
        'c: the lowest m= given twice, not the first met');

primary(copy_field(copy_field(two_hop(), ['DKIM2-Signature', 'i', 2], 'top'), $SIG1, 'after'),
        'PERMERROR: DKIM2-Signature i=1 appears more than once',
        'e: the lowest i= given twice, not the first met');

primary("DKIM2-Signature: i=1;\r\n" . copy_field(one_hop(), $MI1, 'after'),
        'PERMERROR: Message-Instance m=1 appears more than once',
        'a..e: structure before a gap: an instance m= given twice');

# A message with no signature: "none" only when there is no DKIM2 field at
# all. A gap in the instances is a fault even for an outbound signer
# (AllowUnsignedMI) or a partial view (MidProcess), which used to read it
# as "none".
{
    my $only_m2 = Spec07Fixture::mi_with_recipe(
        Spec07Fixture::add_mi(Spec07Fixture::message()), '{"h":{"subject":[{"d":["x"]}]}}');
    $only_m2 = drop($only_m2, $MI1);
    for my $opts ([], [AllowUnsignedMI => 1], [MidProcess => 1]) {
        my $v = Spec07Fixture::verify($only_m2, SkipTimestampCheck => 1, @$opts);
        is($v->details, 'PERMERROR: Message-Instance m=1 missing',
            "f before g: only m=2, no signature (@$opts): the gap, not none");
    }
}

# ---- section 14.2 content: instances by ascending m=, then signatures ----

primary(edit(edit(two_hop(), $MI2, sub { s/h=(sha256:[^;]*)/h=$1,$1/ }),
             $MI1, sub { s/;\s*\z/;;/ }),
        'PERMERROR: Message-Instance m=1 syntax error',
        'content by ascending m=: m=1 syntax before m=2 duplicate hash algorithm');

primary(edit(two_hop(), $MI2, sub { s/h=(sha256:[^;]*)/h=$1,$1/; s/r=[^;]*/r=!!!!/ }),
        'PERMERROR: Message-Instance m=2 has a duplicate hash algorithm',
        'within one instance: duplicate hash algorithm before its Recipe');

primary(edit(edit(one_hop(), $MI1, sub { s/;\s*\z/;;/ }),
             $SIG1, sub { s/s=(sel1:rsa-sha256:)/s=sel1:rsa-sha256:AAAA,$1/ }),
        'PERMERROR: Message-Instance m=1 syntax error',
        'instances before signatures');

# ---- section 14.7: every header hash before any body hash ----
{
    my $text = Spec07Fixture::message();
    my $mi = Mail::DKIM2::MessageInstance->calculate(parse_mime($text), undef,
        Algs => ['sha256', 'sha512']);
    my $value = $mi->as_string;
    my $flip = sub { my ($b64) = @_; substr($b64, 0, 1) = substr($b64, 0, 1) eq 'A' ? 'B' : 'A'; $b64 };
    # sha256's body hash and sha512's header hash both wrong.
    $value =~ s{sha256:([^:]+):([^,;]+)}{"sha256:$1:" . $flip->($2)}e;
    $value =~ s{sha512:([^:]+):([^,;]+)}{"sha512:" . $flip->($1) . ":$2"}e;
    my $signed = Spec07Fixture::add_sig("Message-Instance: $value\r\n$text",
        d => 'example.com', mf => '<a@example.com>', rt => ['<list@lists.example.org>']);
    primary($signed, 'FAIL: Message-Instance m=1 header hash sha512 mismatch',
        'header hashes (in h= order) before body hashes');
}

done_testing;
