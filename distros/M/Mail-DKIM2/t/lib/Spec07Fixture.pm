package Spec07Fixture;
# Messages for the draft -07 shared behaviour tests (the U1..D1 table every
# implementation in the interop repository writes). The table fixes the
# domains (example.com, example.org, lists.example.org, fwd.example.net, ...),
# so instead of DNS entries for each, every signature here is made with
# test1.dkim2.com's sel1 RSA key whatever its d= says, and pubkey_cb() answers
# that key for every domain and selector.
#
# add_sig() builds the DKIM2-Signature by hand, so a test can make any chain
# it likes -- a broken Chain of Custody, an mf= in odd case, a From that is
# not Authentic -- which Mail::DKIM2::Signer would refuse or normalise.
use strict;
use warnings;
use MIME::Base64 qw(encode_base64);
use Crypt::PK::RSA;
use Mail::DKIM2::Common qw(parse_mime build_signing_input extract_mi_version);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signature;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

sub key { return DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1') }

# A PubkeyCallback answering the one test key for any domain.
sub pubkey_cb {
    my $der = key()->export_key_der('public');
    my $pub = Crypt::PK::RSA->new(\$der);
    return sub { return $pub };
}

# message(%o): a plain message, CRLF throughout. Options from, to, subject,
# extra (more header fields, each ending in CRLF) and body.
sub message {
    my (%o) = @_;
    return 'From: ' . ($o{from} // 'A <a@example.com>') . "\r\n"
         . 'To: ' . ($o{to} // 'list@lists.example.org') . "\r\n"
         . 'Subject: ' . ($o{subject} // 'test') . "\r\n"
         . ($o{extra} // '')
         . "\r\n" . ($o{body} // "body\r\n");
}

# add_mi($cur[, $prev]): $cur with a new top Message-Instance -- m=1 over
# $cur, or, given $prev ($cur before this hop's change, carrying the same
# instances and signatures), the next m= with the Recipes back to $prev.
sub add_mi {
    my ($cur, $prev) = @_;
    my $mi = defined $prev
        ? Mail::DKIM2::MessageInstance->calculate(parse_mime($cur), parse_mime($prev))
        : Mail::DKIM2::MessageInstance->calculate(parse_mime($cur));
    return 'Message-Instance: ' . $mi->as_string . "\r\n" . $cur;
}

# mi_with_recipe($text, $json): $text with a hand-made next Message-Instance
# whose hashes match $text and whose r= is base64($json), verbatim.
sub mi_with_recipe {
    my ($text, $json) = @_;
    my $msg = parse_mime($text);
    my @v = map { extract_mi_version($_) } $msg->header_raw('Message-Instance');
    my ($top) = sort { $b <=> $a } @v;
    my $m = ($top // 0) + 1;
    my $h = Mail::DKIM2::MessageInstance::h_digest($msg, 'sha256');
    my $b = Mail::DKIM2::MessageInstance::b_digest($msg, 'sha256');
    return "Message-Instance: m=$m; h=sha256:$h:$b; r=" . encode_base64($json, '')
         . ";\r\n" . $text;
}

# The decoded r= JSON of the top Message-Instance of $text.
sub top_recipe_json {
    my ($text) = @_;
    my @mi = parse_mime($text)->header_raw('Message-Instance');
    my ($top) = sort { extract_mi_version($b) <=> extract_mi_version($a) } @mi;
    my ($r) = $top =~ /\br=([^;]*)/ or return;
    $r =~ s/\s//g;
    return MIME::Base64::decode_base64($r);
}

# add_sig($text, %o): $text with a new DKIM2-Signature on top, i= the next
# one. Options: d (required), mf (a raw path, e.g. '<a@example.com>'), rt
# (arrayref of raw paths), nd, t (default now), f (arrayref of flags), m
# (default the top Message-Instance's m=). mf and rt go in exactly as given.
sub add_sig {
    my ($text, %o) = @_;
    my $msg = parse_mime($text);
    my @mi = sort { $a->{v} <=> $b->{v} }
             map  { { v => extract_mi_version($_), raw => "Message-Instance: $_\r\n" } }
             $msg->header_raw('Message-Instance');
    my @sigs = sort { $a->{i} <=> $b->{i} }
               map  { my $s = Mail::DKIM2::Signature->parse($_);
                      { i => $s->sequence, raw => "DKIM2-Signature: $_\r\n", sig => $s } }
               $msg->header_raw('DKIM2-Signature');
    my $i = @sigs ? $sigs[-1]{i} + 1 : 1;
    my $m = $o{m} // (@mi ? $mi[-1]{v} : undef);

    my $s = Mail::DKIM2::Signature->new(
        Sequence  => $i,
        (defined $m ? (Version => $m) : ()),
        Timestamp => $o{t} // time,
        Domain    => $o{d},
        (defined $o{nd} ? (NextDomain => $o{nd}) : ()),
        ($o{f} ? (Flags => $o{f}) : ()));
    $s->set_tag('mf', encode_base64($o{mf}, '')) if defined $o{mf};
    $s->set_tag('rt', join ',', map { encode_base64($_, '') } @{$o{rt}}) if $o{rt};
    $s->set_tag('s', 'sel1:rsa-sha256:');

    my $input = build_signing_input(
        mi_headers     => [ grep { $_->{v} <= ($m // 0) } @mi ],
        dk2_headers    => [ @sigs, { i => $i, sig => $s } ],
        signing_i      => $i,
        signature      => $s,
        signing_header => $s->as_folded_string_without_data);
    my $value = encode_base64(key()->sign_message($input, 'SHA256', 'v1.5'), '');
    $s->set_tag('s', "sel1:rsa-sha256:$value");
    return $s->as_folded_string . "\r\n" . $text;
}

# verify($text, %opts): a Verifier (keys from pubkey_cb) after reading $text.
sub verify {
    my ($text, %opts) = @_;
    my $v = Mail::DKIM2::Verifier->new(PubkeyCallback => pubkey_cb(), %opts);
    $v->load($text);
    return $v;
}

1;
