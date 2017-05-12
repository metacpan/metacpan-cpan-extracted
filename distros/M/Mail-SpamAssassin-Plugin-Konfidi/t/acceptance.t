#!perl
use strict;
use warnings;

use lib '.'; use lib 't';
use SATest;
use Test::More;

require 'acceptance-base.pl';

use constant TEST_ENABLED => conf_bool('run_net_tests');
use constant HAS_KONFIDICLIENT => eval { require Konfidi::Client; };
use constant DO_RUN     => TEST_ENABLED && HAS_KONFIDICLIENT;

BEGIN {
  plan tests => (DO_RUN ? 3 : 0);
};
exit unless (DO_RUN);

acceptance_setup();

our %patterns = (
    q{ KONFIDI_TRUST_VALUE }, 'konfidi trust value',
);
our %anti_patterns = (
);

sarun("-t < data/gpg_thunderbird.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

%patterns = (
);
%anti_patterns = (
    q{ KONFIDI_TRUST_VALUE }, 'konfidi trust value',
);

sarun("-t < data/plain.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern

# make Konfidi::Client throw an exception
tstprefs (q{
    konfidi_service_url http://unreachable.server/
}   );
sarun("-t < data/gpg_thunderbird.eml", \&patterns_run_cb);
ok_all_patterns(); # one test per pattern & anti-pattern
