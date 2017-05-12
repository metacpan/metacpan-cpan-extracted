# t/failsafe/206.t
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

    failsafe($caller,  
        [
            'NAME'     => 'ABC::XYZ',
            'ABSTRACT' => '123456789012345678901234567890123456789012345',
        ], 
        "^ABSTRACTs are limited to 44 characters",
        "Constructor correctly failed due to ABSTRACT > 44 characters"
    );


    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

