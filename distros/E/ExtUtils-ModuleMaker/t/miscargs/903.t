# t/miscargs/903.t
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

    ##### Set 3:  Tests of dump_keys() method.

    {
        $tdir = tempdir( CLEANUP => 1);

        ok(chdir $tdir, 'changed to temp directory for testing');
        $testmod = 'Tau';
        
        ok( $mod = ExtUtils::ModuleMaker->new( 
                NAME           => "Alpha::$testmod",
                COMPACT        => 0,
                VERBOSE        => 1,
                ABSTRACT       => "Tau's the time for Perl",
            ),
            "call ExtUtils::ModuleMaker->new for Alpha-$testmod"
        );
        
        my $dump;
        ok( $dump = $mod->dump_keys(qw| NAME ABSTRACT |), 
            'call dump_keys()' );
        my @dumplines = split(/\n/, $dump);
        my $keys_shown_flag = 0;
        for my $m ( @dumplines ) {
            $keys_shown_flag++ if $m =~ /^\s+'(NAME|ABSTRACT)/;
        } #'
        is($keys_shown_flag, 2, 
            "keys intended to be shown were shown");
        
    }

    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

