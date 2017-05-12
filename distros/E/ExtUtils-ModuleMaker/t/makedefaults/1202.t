# t/makedefaults/1202.t
# tests of options to make modulemaker selections default personal values
use strict;
use warnings;
use Test::More tests => 38;
use_ok( 'ExtUtils::ModuleMaker' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
        check_MakefilePL 
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with 5.6", 
        (38 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my $cwd = $statusref->{cwd};
    my ($tdir, $topdir, @pred);

    {
        # same test as above, only passing SAVE_AS_DEFAULTS to constructor
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        push @INC, "$cwd/t/testlib";
        require ExtUtils::ModuleMaker::Testing::Defaults;
        my $testing_defaults_ref =
            ExtUtils::ModuleMaker::Testing::Defaults->default_values();
        my $obj1 = ExtUtils::ModuleMaker->new( 
            %{$testing_defaults_ref},
            SAVE_AS_DEFAULTS => 1,
        );
        isa_ok( $obj1, 'ExtUtils::ModuleMaker' );

        ok( $obj1->complete_build(), 'call complete_build()' );

        $topdir = "EU/MM/Testing/Defaults"; 
        ok(-d $topdir, "by default, non-compact top directory created");
        ok(-f "$topdir/$_", "$_ file created")
            for qw| Changes LICENSE MANIFEST Makefile.PL README Todo |;
        ok(-d "$topdir/$_", "$_ directory created")
            for qw| lib t |;
        
        @pred = (
             q{EU::MM::Testing::Defaults},
            qq{lib\/EU\/MM\/Testing\/Defaults\.pm},
            qq{Hilton\\sStallone},
            qq{hiltons\@parliamentarypictures\.com},
            qq{Module\\sabstract\\s\\(<=\\s44\\scharacters\\)\\sgoes\\shere},
        );

        check_MakefilePL($topdir, \@pred);

        ok(-f "$statusref->{mmkr_dir}/$statusref->{pers_file}", 
            "new Personal::Defaults installed");

        my $obj2 = ExtUtils::ModuleMaker->new(
            NAME    => q{Ackus::Frackus},
            AUTHOR  => q{Marilyn Shmarilyn},
            EMAIL   => q{marilyns@nineteenthcenturyfox.com},
            COMPACT => 1,
        );
        isa_ok( $obj2, 'ExtUtils::ModuleMaker' );

        ok( $obj2->complete_build(), 'call complete_build()' );

        $topdir = "Ackus-Frackus"; 
        ok(-d $topdir, "by choice, compact top directory created");
        ok(-f "$topdir/$_", "$_ file created")
            for qw| Changes LICENSE MANIFEST Makefile.PL README Todo |;
        ok(-d "$topdir/$_", "$_ directory created")
            for qw| lib t |;
        
        @pred = (
             q{Ackus::Frackus},
            qq{lib\/Ackus\/Frackus\.pm},
            qq{Marilyn\\sShmarilyn},
            qq{marilyns\@nineteenthcenturyfox\.com},
            qq{Module\\sabstract\\s\\(<=\\s44\\scharacters\\)\\sgoes\\shere},
        );

        check_MakefilePL($topdir, \@pred);

    }

    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

