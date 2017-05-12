#!perl
use strict;
use warnings;

use lib '.'; use lib 't';
use SATest;
use Test::More;

require 'acceptance-base.pl';

use constant TEST_ENABLED => conf_bool('run_net_tests');
use constant HAS_GPGCLIENT => eval { require Mail::GPG; };
use constant DO_RUN     => TEST_ENABLED && HAS_GPGCLIENT;

BEGIN {
  plan tests => (DO_RUN ? 9 : 0);
};
exit unless (DO_RUN);

acceptance_setup();

our %patterns = ();
our %anti_patterns = (
    'OPENPGP_SIGNED' => 'signed',
    'OPENPGP_SIGNED_BAD' => 'signed_bad',
    'OPENPGP_SIGNED_GOOD' => 'signed_good',
);
sarun("-t < data/pks_signed.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

sarun("-t < data/plain.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

# TODO make this OPENPGP_PART_SIGNED
sarun("-t < data/gpg_part_signed.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

