# t/05_abstract.t
use strict;
use warnings;
use Test::More tests =>  35;
use_ok( 'ExtUtils::ModuleMaker' );
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
        (35 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    ########################################################################

    my $mod;
    my $testmod = 'Beta';

    ok( $mod = ExtUtils::ModuleMaker->new( 
            NAME           => "Alpha::$testmod",
            ABSTRACT       => 'Test of the capacities of EU::MM',
            COMPACT        => 1,
            CHANGES_IN_POD => 1,
            AUTHOR         => 'Phineas T. Bluster',
            CPANID         => 'PTBLUSTER',
            ORGANIZATION   => 'Peanut Gallery',
            WEBSITE        => 'http://www.anonymous.com/~phineas',
            EMAIL          => 'phineas@anonymous.com',
        ),
        "call ExtUtils::ModuleMaker->new for Alpha-$testmod"
    );

    ok( $mod->complete_build(), 'call complete_build()' );

    ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );

    for ( qw/LICENSE Makefile.PL MANIFEST README Todo/) {
        ok( -f, "file $_ exists" );
    }
    ok(! -f 'Changes', 'Changes file correctly not created');
    for ( qw/lib scripts t/) {
        ok( -d, "directory $_ exists" );
    }

    my ($filetext);
    ok($filetext = read_file_string('Makefile.PL'),
        'Able to read Makefile.PL');
    ok($filetext =~ m|AUTHOR\s+=>\s+.Phineas\sT.\sBluster|,
        'Makefile.PL contains correct author');
    ok($filetext =~ m|AUTHOR.*\(phineas\@anonymous\.com\)|,
        'Makefile.PL contains correct e-mail');
    ok($filetext =~ m|ABSTRACT\s+=>\s+'Test\sof\sthe\scapacities\sof\sEU::MM'|,
        'Makefile.PL contains correct abstract');

    six_file_tests(7, $testmod); # first arg is # entries in MANIFEST

    ok(chdir $statusref->{cwd}, "changed back to original directory");

} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

