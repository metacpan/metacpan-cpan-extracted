use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Mail::DKIM2::Hop;
use Mail::DKIM2::MessageInstance;

# Mail::DKIM2::Hop->next_instance: the Message-Instance a hop adds before it
# signs, and the message it adds it to.

my $BODY = join '', map { "line $_\r\n" } 1 .. 6;
my $base = "From: a\@example.com\r\nSubject: hello\r\n\r\n$BODY";

sub with_mi { my ($mi, $text) = @_; $mi->as_header . "\r\n" . $text }
sub next_instance { Mail::DKIM2::Hop->next_instance(@_) }
sub chain_ok {
    my ($text, $name) = @_;
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($text);
    ok($ok, $name) or diag $why;
}

my $m1      = with_mi(Mail::DKIM2::MessageInstance->calculate($base), $base);
(my $edited = $m1) =~ s/^Subject: hello/Subject: [list] hello/m;
$edited .= "-- \r\nfooter\r\n";

subtest 'no instance yet' => sub {
    my $n = next_instance($base);
    is($n->{reason}, 'first', 'reason');
    is($n->{instance}->get_tag('m'), 1, 'm=1');
    is($n->{message}, $base, 'the message as given');
    is_deeply($n->{removed}, [], 'nothing removed');
    ok(!$n->{matched}, 'not matched');
    chain_ok(with_mi($n->{instance}, $n->{message}), 'and it describes the message');
};

subtest 'unchanged' => sub {
    my $n = next_instance($m1);
    is($n->{reason}, 'unchanged', 'reason');
    is($n->{instance}, undef, 'no instance');
    ok($n->{matched}, 'matched');
    is(next_instance($m1, Outbound => 1)->{reason}, 'unchanged', 'outbound, one matching m=1: unchanged');
};

subtest 'changed, with the snapshot' => sub {
    my $n = next_instance($edited, Snapshot => $m1);
    is($n->{reason}, 'changed', 'reason');
    is($n->{instance}->get_tag('m'), 2, 'm=2');
    is_deeply($n->{instance}->changes, { body => 'changed', headers => ['subject'] },
        'with Recipes for what changed');
    chain_ok(with_mi($n->{instance}, $n->{message}), 'the chain undoes to the snapshot');
};

subtest 'changed, and nothing to say how' => sub {
    my $n = next_instance($edited);
    is($n->{reason}, 'no-snapshot', 'no snapshot');
    is($n->{instance}, undef, 'no instance');

    (my $other = $m1) =~ s/h=sha256:[^:]+:/h=sha256:AAAA:/;
    $n = next_instance($edited, Snapshot => $other);
    is($n->{reason}, 'foreign-snapshot', 'a snapshot of another message');
    like($n->{detail}, qr/m=1 differs/, 'saying which instance differs');
    is($n->{instance}, undef, 'no instance');
};

subtest 'instances a hop between added, and got wrong' => sub {
    my $wrong = "Message-Instance: m=2; h=sha256:AAAA:AAAA;\r\n" . $edited;
    my $n = next_instance($wrong, Snapshot => $m1);
    is($n->{reason}, 'changed', 'reason');
    is_deeply($n->{removed}, [2], 'the wrong m=2 goes');
    unlike($n->{message}, qr/^Message-Instance: m=2;/m, 'from the message');
    is($n->{instance}->get_tag('m'), 2, 'and a right m=2 takes its place');
    ok(!$n->{restart}, 'not a restart');
    chain_ok(with_mi($n->{instance}, $n->{message}), 'the chain undoes');
};

subtest 'outbound: unsigned instances restart as one m=1' => sub {
    my $n2 = next_instance($edited, Snapshot => $m1);
    my $two = with_mi($n2->{instance}, $edited);         # m=1 and m=2, both unsigned

    my $n = next_instance($two, Outbound => 1);
    is($n->{reason}, 'restart', 'reason');
    ok($n->{restart}, 'restart');
    is_deeply($n->{removed}, [1, 2], 'both instances go');
    unlike($n->{message}, qr/^Message-Instance:/m, 'from the message');
    is($n->{instance}->get_tag('m'), 1, 'for one m=1');
    ok($n->{instance}->changes_header('Subject'), 'that records the change');
    chain_ok(with_mi($n->{instance}, $n->{message}), 'and undoes to the original');

    is(next_instance($two)->{reason}, 'unchanged', 'not outbound: left alone');

    # The same from the snapshot, when the top instance does not match.
    $n = next_instance($edited, Outbound => 1, Snapshot => $m1);
    is($n->{reason}, 'restart', 'from the snapshot: restart');
    is_deeply($n->{removed}, [1], 'the m=1 goes');
    chain_ok(with_mi($n->{instance}, $n->{message}), 'and the new one undoes');

    # A signed message is never restarted.
    my $signed = "DKIM2-Signature: i=1; m=1; t=1; d=example.com; mf=PD4=; rt=PD4=; s=s:rsa-sha256:AAAA\r\n" . $two;
    is(next_instance($signed, Outbound => 1)->{reason}, 'unchanged', 'a signed chain is not restarted');
};

subtest 'a chain that cannot be numbered' => sub {
    my $n = next_instance("Message-Instance: m=99999999999999999999; h=sha256:AAAA:AAAA\r\n" . $edited,
        Snapshot => $m1);
    is($n->{reason}, 'bad-chain', 'reason');
    like($n->{detail}, qr/PERMERROR: Message-Instance m=99999999999999999999/, 'detail');
    is($n->{instance}, undef, 'no instance');
};

subtest 'options' => sub {
    (my $rewritten = $m1) =~ s/^line 3\r$/another line\r/m;
    my $n = next_instance($rewritten, Snapshot => $m1, MaxRecipeLiterals => 0);
    is($n->{instance}->changes->{body}, 'unrecoverable', 'MaxRecipeLiterals is passed on');
    $n = next_instance($base, Algs => ['sha512']);
    like($n->{instance}->as_string, qr/h=sha512:/, 'Algs is passed on');
    ok(!eval { next_instance($base, Snapshop => $m1); 1 }, 'an unknown option croaks');
    ok(!eval { next_instance(''); 1 }, 'no message croaks');
};

subtest 'as_header' => sub {
    my $mi = Mail::DKIM2::MessageInstance->calculate($base, undef, Algs => [qw(sha256 sha512)]);
    my $header = $mi->as_header;
    like($header, qr/\AMessage-Instance: m=1;/, 'starts with the field name');
    unlike($header, qr/\r\n\z/, 'no line break at the end');
    ok(!grep({ length > 78 } split /\r\n/, $header), 'folded');
    is($mi->as_header_value, $header =~ s/\AMessage-Instance: //r, 'as_header_value is the value alone');
    my $parsed = Mail::DKIM2::MessageInstance->parse($mi->as_header_value);
    is($parsed->as_string, $mi->as_string, 'and parses back');
    my $any = 'm=2; h=sha256:AAAA:BBBB|sha512:CCCC:DDDD;';
    is(Mail::DKIM2::MessageInstance->parse($any)->as_string, $any, 'a parsed h= keeps its groups');
    is_deeply($mi->changes, { body => 'unchanged', headers => [] }, 'm=1 changes nothing');
};

done_testing;
