#!perl -T

use strict;
use warnings;

use Test::More tests => 12;
use Test::MockObject::Extends;

use Error qw(:try);
use HTTP::Daemon;
use HTTP::Status;

BEGIN {
    use_ok('Mail::SpamAssassin::Plugin::Konfidi');
}

# make a Mail::SpamAssassin::Plugin::Konfidi that doesn't inherit from Mail::SpamAssassin::Plugin
# and doesn't use the regular constructor
# so that we can test just the check_konfidi() method
@Mail::SpamAssassin::Plugin::Konfidi::ISA = qw();

# redefine the 'dbg' method so to use Test's diag
sub Mail::SpamAssassin::Plugin::Konfidi::dbg {
    use Test::Harness qw($verbose);
    # only when in verbose mode (e.g. `prove -v ...`, `./Build test verbose=1 ...`)
    diag @_ if ($ENV{TEST_VERBOSE} or $ENV{HARNESS_VERBOSE} or $verbose);
};

my $k = {};
bless $k, 'Mail::SpamAssassin::Plugin::Konfidi';
isa_ok($k, "Mail::SpamAssassin::Plugin::Konfidi", 'constructed');


# give it a fake konfidi::client
my $konfidi_client = Test::MockObject->new();
$konfidi_client->set_always('query',{'Rating'=>0.75});
$k->{konfidi_client} = $konfidi_client;

# and a fake perMsgStatus
my $perMsgStatus = Test::MockObject->new();
$perMsgStatus->set_true('set_tag');
$perMsgStatus->set_true('got_hit');
$perMsgStatus->{conf} = {
    konfidi_rating1_becomes_score => -20,
    konfidi_rating0_becomes_score => 0,
    scoreset => [{}, {}, {}, {}],
};


# no openpgp signature
$k->check_konfidi($perMsgStatus);
is($perMsgStatus->{conf}->{scoreset}->[0]->{"KONFIDI_TRUST_VALUE"}, undef, 'KONFIDI_TRUST_VALUE score should not be set');
is($perMsgStatus->{conf}->{scoreset}->[1]->{"KONFIDI_TRUST_VALUE"}, undef, 'KONFIDI_TRUST_VALUE score should not be set');
is($perMsgStatus->{conf}->{scoreset}->[2]->{"KONFIDI_TRUST_VALUE"}, undef, 'KONFIDI_TRUST_VALUE score should not be set');
is($perMsgStatus->{conf}->{scoreset}->[3]->{"KONFIDI_TRUST_VALUE"}, undef, 'KONFIDI_TRUST_VALUE score should not be set');

# good openpgp signature
$perMsgStatus->{openpgp_signed_good} = 1;
$k->check_konfidi($perMsgStatus);
cmp_ok($perMsgStatus->{conf}->{scoreset}->[0]->{"KONFIDI_TRUST_VALUE"}, '==', -15, 'KONFIDI_TRUST_VALUE score should be set');
cmp_ok($perMsgStatus->{conf}->{scoreset}->[1]->{"KONFIDI_TRUST_VALUE"}, '==',  -15, 'KONFIDI_TRUST_VALUE score should be set');
cmp_ok($perMsgStatus->{conf}->{scoreset}->[2]->{"KONFIDI_TRUST_VALUE"}, '==',  -15, 'KONFIDI_TRUST_VALUE score should be set');
cmp_ok($perMsgStatus->{conf}->{scoreset}->[3]->{"KONFIDI_TRUST_VALUE"}, '==',  -15, 'KONFIDI_TRUST_VALUE score should be set');
is($perMsgStatus->called('set_tag'), 1, 'set_tag(..) was invoked');
is($perMsgStatus->called('got_hit'), 1, 'got_hit(..) was invoked');

