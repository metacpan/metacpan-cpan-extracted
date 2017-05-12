# t/failsafe/210.t
use strict;
local $^W = 1;
use Test::More tests => 13;
use_ok( 'ExtUtils::ModuleMaker::PBP' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
    failsafe
    _save_pretesting_status
    _restore_pretesting_status
) ); 

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "failsafe requires File::Temp, core with Perl 5.6", 
        (13 - 10) if $@;
    use warnings;
    my $caller = 'ExtUtils::ModuleMaker::PBP';

    failsafe($caller,  [
            'NAME'     => 'ABC::XYZ',
            'AUTHOR'   => 'James E Keenan',
            'WEBSITE'   => 'ftp://ftp.perl.org',
        ], 
        "^WEBSITEs should start with an \"http:\" or \"https:\"",
        "Constructor correctly failed; websites start 'http' or 'https'"
    );


    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

