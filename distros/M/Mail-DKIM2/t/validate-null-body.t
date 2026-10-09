#!/usr/bin/perl
# A null body Recipe ("b": null) loses the previous body, not the header
# history: Validate must report the chain as passing when the header history
# below it checks out, evaluate the lower levels on the header-only-undone
# message, and still fail a history forged below the null.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Validate;
use DKIM2TestKeys;

my $MI  = 'Mail::DKIM2::MessageInstance';
my $EOL = "\r\n";
my $cb  = DKIM2TestKeys::pubkey_callback();

sub with_mi { my ($mi, $msg) = @_; "Message-Instance: " . $mi->as_string . $EOL . $msg }

sub sign {
    my ($msg, %o) = @_;
    my $s = Mail::DKIM2::Signer->new(
        Domain => $o{domain}, Selector => 'rsa1024',
        Key => DKIM2TestKeys::private_key($o{domain}, 'rsa1024'),
        MailFrom => $o{from}, RcptTo => [$o{to}], Timestamp => 1740000000);
    $s->PRINT($msg); $s->CLOSE;
    return $s->as_string . $EOL . $msg;
}

my $orig = join($EOL, 'From: a@test1.dkim2.com', 'To: list@test2.dkim2.com',
    'Subject: hello', 'Message-ID: <x@test1.dkim2.com>', '', 'body one', 'body two', '');
my $m1 = sign(with_mi($MI->calculate($orig), $orig),
    domain => 'test1.dkim2.com', from => 'a@test1.dkim2.com', to => 'list@test2.dkim2.com');

# m=2: the list prefixed the Subject and rewrote the body; body Recipe null.
# $forge hides a To change from the header Recipe.
sub list_hop {
    my ($prev, $forge) = @_;
    my $cur = $prev;
    $cur =~ s/^Subject: /Subject: [list] /m;
    $cur =~ s/^To: list\@test2\.dkim2\.com/To: other\@test2.dkim2.com/m if $forge;
    $cur .= "rewritten by list$EOL";
    my $mi = $MI->calculate($cur, $prev);
    $mi->set_null_body_recipe;
    delete $mi->{bits}{rh}{$_} for grep { /^to$/i } keys %{ $mi->{bits}{rh} || {} };
    my $hop = with_mi($mi, $cur);
    return sign($hop, domain => 'test2.dkim2.com', from => 'list-bounces@test2.dkim2.com',
                to => 'sub@test1.dkim2.com');
}

sub rep { Mail::DKIM2::Validate::report($_[0], PubkeyCallback => $cb, SkipTimestampCheck => 1) }
sub mi_lvl { my ($r, $m) = @_; (grep { $_->{kind} eq 'mi' && $_->{m} == $m } @{$r->{levels}})[0] }

{
    my $r = rep(list_hop($m1));
    is($r->{overall}, 'pass', 'null body over signed m=1: overall pass') or diag $r->{summary};
    my $l2 = mi_lvl($r, 2);
    is($l2->{body_recipe}, 'null', 'm=2 body recipe null');
    is($l2->{undo}, 'unrecoverable', 'm=2 undo unrecoverable');
    my $l1 = mi_lvl($r, 1);
    ok($l1, 'm=1 level reported') or diag explain [map { "$_->{kind}:" . ($_->{m}//$_->{i}) } @{$r->{levels}}];
    is($l1->{header_hash}, 'match', 'm=1 header hash match');
    is($l1->{body_hash}, 'not-checked', 'm=1 body hash not checkable below the null');
    is($l1->{result}, 'pass', 'm=1 level passes');
    my ($s1) = grep { $_->{kind} eq 'signature' && $_->{i} == 1 } @{$r->{levels}};
    is($s1 && $s1->{result}, 'pass', 'i=1 signature level passes');
}

{
    my $r = rep(list_hop($m1, 1));
    isnt($r->{overall}, 'pass', 'forged history below null: not a pass');
    my $l1 = mi_lvl($r, 1);
    is($l1 && $l1->{header_hash}, 'mismatch', 'm=1 header hash mismatch reported') ;
    is($l1 && $l1->{result}, 'fail', 'm=1 level fails');
}

done_testing;
