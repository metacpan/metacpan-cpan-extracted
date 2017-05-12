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
  plan tests => (DO_RUN ? 31 : 0);
};
exit unless (DO_RUN);

acceptance_setup();

our %patterns = (
    'OPENPGP_SIGNED' => 'signed',
    'OPENPGP_SIGNED_GOOD' => 'signed_good',
);
our %anti_patterns = (
    'OPENPGP_SIGNED_BAD' => 'signed_bad',
);

sarun("-t < data/gpg_thunderbird.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

sarun("-t < data/gpg_evolution.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

$patterns{'EAB0FABEDEA81AD4086902FE56F0526F9BB3CE70'} = 'openpgp fingerprint';
sarun("-t < data/gpg_subkey.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern
delete $patterns{'EAB0FABEDEA81AD4086902FE56F0526F9BB3CE70'};

sarun("-t < data/gpg_signed_attachment2.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

sarun("-t < data/gpg_signed_binary_attachment.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

sarun("-t < data/gpg_signed_8bit.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

sarun("-t < data/signed_inline.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

# email address is not the primary one on the key
sarun("-t < data/email2.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern


# TODO make this OPENPGP_PART_SIGNED
sarun("-t < data/signed_inline_firstpart.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

# TODO make this OPENPGP_PART_SIGNED
sarun("-t < data/signed_inline_secondpart.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern
