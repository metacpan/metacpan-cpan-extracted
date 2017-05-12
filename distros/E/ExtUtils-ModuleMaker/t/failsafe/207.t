# t/failsafe/207.t
use strict;
use warnings;
use Test::More tests => 13;
use_ok( 'ExtUtils::ModuleMaker' );
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
    my $caller = 'ExtUtils::ModuleMaker';

    failsafe($caller,  [
            'NAME'     => 'ABC::DEF',
            'AUTHOR'   => 'James E Keenan',
            'CPANID'   => 'ABCDEFGHIJ',
        ], 
        "^CPAN IDs are 3-9 characters",
        "Constructor correctly failed due to CPANID > 9 characters"
    );


    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

