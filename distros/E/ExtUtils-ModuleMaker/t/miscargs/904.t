# t/miscargs/904.t
# tests of miscellaneous arguments passed to constructor
use strict;
use warnings;
use Test::More tests => 16;
use_ok( 'ExtUtils::ModuleMaker' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with 5.6", 
        (16 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my ($tdir, $mod, $testmod);

    ##### Set 4:  Tests of dump_keys_except() method.

    {
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Rho';
        
        ok( $mod = ExtUtils::ModuleMaker->new( 
                NAME           => "Alpha::$testmod",
                COMPACT        => 0,
                VERBOSE        => 1,
            ),
            "call ExtUtils::ModuleMaker->new for Alpha-$testmod"
        );
        
        my $dump;
        ok( $dump = $mod->dump_keys_except(qw| LicenseParts USAGE_MESSAGE |), 
            'call dump_keys_except()' );
        my @dumplines = split(/\n/, $dump);
        my $excluded_keys_flag = 0;
        for my $m ( @dumplines ) {
            $excluded_keys_flag++ if $m =~ /^\s+'(LicenseParts|USAGE_MESSAGE)/;
        } #'
        is($excluded_keys_flag, 0, 
            "keys intended to be excluded were excluded");
        
    }

    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

