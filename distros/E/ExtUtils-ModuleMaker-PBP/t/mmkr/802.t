# t/mmkr/802.t
use strict;
local $^W = 1;
use Test::More tests => 26;
use_ok( 'ExtUtils::ModuleMaker::PBP' );
use_ok( 'ExtUtils::ModuleMaker::PBP::Auxiliary', qw( check_MakefilePL ) );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with 5.6", 
        (26 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    # Simple tests of mmkrpbp utility in non-interactive mode

    my $cwd = $statusref->{cwd};
    my ($tdir, $topdir, @pred);

    {
        # suppress Personal::Defaults for duration of test
        # do not provide -t option
        # hence, you are testing against EU::MM::Defaults, which means you
        # must supply a NAME; you must also suppress interactive mode

        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        ok(! system(qq{$^X -I"$cwd/blib/lib" "$cwd/blib/script/mmkrpbp" -In My::Research::Module }), 
            "able to call mmkrpbp utility");

        $topdir = "My-Research-Module"; 
        ok(-d $topdir, "by default, compact top directory created");

        ok(  -d "$topdir/$_", "$_ directory created") for qw| lib t |;
        ok(! -d "$topdir/scripts", "scripts directory correctly not created");
        ok(  -f "$topdir/$_", "$_ file created")
            for qw| Changes LICENSE MANIFEST Makefile.PL README      |;
        ok(! -f "$topdir/Todo", "Todo file correctly not created");
        
        @pred = (
            "My::Research::Module",
            "A\.\\sU\.\\sThor",
            "a\.u\.thor\@a\.galaxy\.far\.far\.away",
            "lib\/My\/Research\/Module\.pm",
            "lib\/My\/Research\/Module\.pm",
        );

        check_MakefilePL($topdir, \@pred);
    }

    ok(chdir $statusref->{cwd}, "changed back to original directory");

} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}
