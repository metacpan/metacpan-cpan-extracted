# t/05_abstract.t
use strict;
local $^W = 1;
use Test::More tests => 34;
use_ok( 'ExtUtils::ModuleMaker::PBP' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
        read_file_string
        six_file_tests
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with Perl 5.6", 
        (34 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    ########################################################################

    my $mod;
    my $testmod = 'Beta';

    ok( $mod = ExtUtils::ModuleMaker::PBP->new( 
            NAME           => "Alpha::$testmod",
            ABSTRACT       => 'Test of the capacities of EU::MM',
            CHANGES_IN_POD => 1,
            AUTHOR         => 'Phineas T. Bluster',
            CPANID         => 'PTBLUSTER',
            ORGANIZATION   => 'Peanut Gallery',
            WEBSITE        => 'http://www.anonymous.com/~phineas',
            EMAIL          => 'phineas@anonymous.com',
        ),
        "call ExtUtils::ModuleMaker::PBP->new for Alpha-$testmod"
    );

    ok( $mod->complete_build(), 'call complete_build()' );

    ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );

    ok(  -d, "directory $_ exists" ) for ( qw/lib t/);
    ok(! -d, "directory $_ does not exist" ) for ( qw/scripts/);

    ok(  -f $_, "file $_ exists") for (qw/LICENSE Makefile.PL MANIFEST README/);
    ok(! -f $_, "$_ file correctly not created") for (qw/Todo Changes/);

    my ($filetext);
    ok($filetext = read_file_string('Makefile.PL'),
        'Able to read Makefile.PL');
    ok($filetext =~ m|AUTHOR\s+=>\s+.Phineas\sT.\sBluster|,
        'Makefile.PL contains correct author');
    ok($filetext =~ m|AUTHOR.*<phineas\@anonymous\.com>|,
        'Makefile.PL contains correct e-mail');

    six_file_tests(8, $testmod); # first arg is # entries in MANIFEST

    ok(chdir $statusref->{cwd}, "changed back to original directory");

} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

