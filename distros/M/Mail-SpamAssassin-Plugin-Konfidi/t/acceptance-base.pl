#!perl

# based on SpamAssassin's own spf.t

use strict;
use warnings;

use lib '.'; use lib 't';
use File::Copy;

# TODO: refactor to NOT use SATest, but something that invokes SA modules directly (not a separate process), so that test coverage can be measured; and to make it much simpler and straightforward (SATest.pm doesn't work the greatest for a 3rd-party module like ours)
# maybe make a Test::Mail::SpamAssassin::Plugin module

# this runs first
sub acceptance_init() {
    diag "Make sure you set environment variable SCRIPT to point to your spamassassin executable (used by SATest.pm)";
    if ($ENV{'SCRIPT'}) {
        diag "Currently, SCRIPT=" . $ENV{'SCRIPT'};
    } else {
        $ENV{'SCRIPT'} = `which spamassassin`;
        chomp $ENV{'SCRIPT'};
        diag "Setting SCRIPT=" . $ENV{'SCRIPT'};
    }
    
    # just to quiet a warning from SATest.pm
    $ENV{'SPAMC_SCRIPT'} =  `which spamc`;
    chomp $ENV{'SPAMC_SCRIPT'};
    
    
    use Test::Harness qw($verbose);
    # only when in verbose mode (e.g. `prove -v ...`, `./Build test verbose=1 ...`)
    if (! $ENV{'SA_ARGS'} and ($ENV{TEST_VERBOSE} or $ENV{HARNESS_VERBOSE} or $verbose)) {
        $ENV{'SA_ARGS'} = '-D openpgp,konfidi,generic,config,plugin,check,rules';
        diag "Setting SA_ARGS=" . $ENV{'SA_ARGS'};
    }
    
    # SATest.pm expects t/data/01_test_rules.cf
    copy 'etc/61_konfidi.cf', 't/data/01_test_rules.cf' or die "couldn't copy 61_konfidi.cf $!" ;

    sa_t_init("konfidi");
}

sub acceptance_setup() {
    # add lines to test-local rules
    tstlocalrules (q{
    ## no 'score' setting since a dynamic score is set from within the plugin
    add_header all Konfidi-Trust-Value _KONFIDITRUSTVALUE_
}   );

    tstprefs (q{
    konfidi_service_url http://test-server.konfidi.org/
    konfidi_my_pgp_fingerprint EAB0FABEDEA81AD4086902FE56F0526F9BB3CE70
}   );

};

acceptance_init();