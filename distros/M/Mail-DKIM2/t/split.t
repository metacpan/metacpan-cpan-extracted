#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More; use lib 'lib';
use Mail::DKIM2::Split qw(plan_copies disclosed_addresses);

# Helper: given a plan, return a hash of envelope-rcpt -> [co-recipients in its copy].
sub cohorts {
    my ($copies) = @_;
    my %co;
    for my $c (@$copies) {
        for my $r (@{$c->{rcpts}}) { $co{$r} = $c->{rcpts}; }
    }
    return \%co;
}

my $msg = "From: Sender <s\@ex.com>\r\n"
        . "To: Alice <alice\@a.com>, bob\@b.com\r\n"
        . "Cc: carol\@c.com\r\n"
        . "Subject: hi\r\n\r\nbody\r\n";

# --- disclosed_addresses ----------------------------------------------------
my $d = disclosed_addresses($msg);
ok($d->{'alice@a.com'}, 'To <alice> disclosed');
ok($d->{'bob@b.com'},   'To bare bob disclosed');
ok($d->{'carol@c.com'}, 'Cc carol disclosed');
ok(!$d->{'eve@e.com'},  'Bcc eve not disclosed');

# --- plan_copies: disclosed grouped, Bcc separated --------------------------
{
    my $copies = plan_copies($msg, ['<alice@a.com>', '<bob@b.com>', '<carol@c.com>', '<eve@e.com>']);
    # one copy for the three disclosed, one for the Bcc'd eve
    is(scalar(@$copies), 2, 'two copies: disclosed group + one Bcc');
    my ($disc) = grep { @{$_->{rcpts}} > 1 } @$copies;
    my ($bcc)  = grep { @{$_->{rcpts}} == 1 } @$copies;
    is_deeply([sort @{$disc->{rcpts}}],
              ['<alice@a.com>', '<bob@b.com>', '<carol@c.com>'],
              'disclosed recipients share one copy');
    is_deeply($bcc->{rcpts}, ['<eve@e.com>'], 'Bcc recipient gets its own copy');
}

# --- the no-leak invariant: no copy pairs a Bcc addr with anyone else -------
{
    my @env = ('<alice@a.com>', '<eve@e.com>', '<mallory@m.com>');   # eve, mallory Bcc'd
    my $copies = plan_copies($msg, \@env);
    my $co = cohorts($copies);
    is(scalar(@{$co->{'<eve@e.com>'}}),     1, 'Bcc eve is alone in its copy');
    is(scalar(@{$co->{'<mallory@m.com>'}}), 1, 'Bcc mallory is alone in its copy');
    ok(!(grep { /eve|mallory/ } @{$co->{'<alice@a.com>'}}),
       'no Bcc address appears in the disclosed copy (no leak)');
    is(scalar(@$copies), 3, 'disclosed(1) + eve + mallory = three copies');
}

# --- no To/Cc at all: every recipient is its own copy (always safe) ---------
{
    my $bare = "From: s\@ex.com\r\nSubject: x\r\n\r\nb\r\n";
    my $copies = plan_copies($bare, ['<a@x.com>', '<b@y.com>']);
    is(scalar(@$copies), 2, 'no To/Cc -> one copy per recipient');
    is(scalar(@{$_->{rcpts}}), 1, 'each copy has exactly one recipient') for @$copies;
}

# --- case-insensitive matching + bracket-agnostic ---------------------------
{
    my $m2 = "To: Bob <BOB\@B.com>\r\nSubject: x\r\n\r\nb\r\n";
    my $copies = plan_copies($m2, ['<bob@b.com>', '<sneaky@s.com>']);
    my ($disc) = grep { grep { /bob/i } @{$_->{rcpts}} } @$copies;
    is_deeply($disc->{rcpts}, ['<bob@b.com>'], 'case-insensitive: bob is disclosed (own group)');
    my ($bcc) = grep { grep { /sneaky/ } @{$_->{rcpts}} } @$copies;
    is_deeply($bcc->{rcpts}, ['<sneaky@s.com>'], 'sneaky (not in To/Cc) treated as Bcc');
}

done_testing;
