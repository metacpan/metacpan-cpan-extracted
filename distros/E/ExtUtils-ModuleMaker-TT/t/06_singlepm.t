# t/06_singlepm.t -- tests creation of a single .pm in an existing distribution
# tree

#use Test::More qw/no_plan/;
use Test::More tests => 21;
use File::pushd 1;

BEGIN { use_ok( 'ExtUtils::ModuleMaker' ); }

#--------------------------------------------------------------------------#
# Mask any user defaults for the duration of the program
#--------------------------------------------------------------------------#

BEGIN { 
    use_ok( "ExtUtils::ModuleMaker::Auxiliary",
        qw( _save_pretesting_status _restore_pretesting_status )
    );
}

# these add 8 tests
my $pretest_status = _save_pretesting_status();
END { _restore_pretesting_status( $pretest_status ) }

#--------------------------------------------------------------------------#

{
    my $dir = tempd();

    my $MOD;

    ok ($MOD  = ExtUtils::ModuleMaker->new
            (
                NAME		=> 'Sample::Module::Foo',
                ALT_BUILD => 'ExtUtils::ModuleMaker::TT',
                TEST_NAME_DERIVED_FROM_MODULE_NAME => 1,
                INCLUDE_MANIFEST_SKIP => 1,
                COMPACT		=> 1,
                LICENSE		=> 'looselips',
                BUILD_SYSTEM => 'Module::Build'
            ),
        "call ExtUtils::ModuleMaker->new");

    ok ($MOD->complete_build (),
        "call \$MOD->complete_build");
        
    ok (chdir 'Sample-Module-Foo',
        "cd Sample-Module-Foo");

    ok ($MOD->build_single_pm({ NAME => 'Sample::Module::Bar'}),
        "call \$MOD->build_single_pm");

    ok ( -e 'lib/Sample/Module/Bar.pm' ,
        "new module file successfully created");

    ok ( -e 't/Sample_Module_Bar.t',
        "new test file successfully created");

    ###########################################################################

    # test from a deep directory

    my $tgtdir = 'lib/Sample/Module';
    ok (chdir $tgtdir,
        "cd $tgtdir");


    ok ($MOD  = ExtUtils::ModuleMaker->new
            (
                NAME		=> 'Sample::Module::Foo',
                ALT_BUILD => 'ExtUtils::ModuleMaker::TT',
                TEST_NAME_DERIVED_FROM_MODULE_NAME => 1,
                INCLUDE_MANIFEST_SKIP => 1,
                COMPACT		=> 1,
                LICENSE		=> 'looselips',
                BUILD_SYSTEM => 'Module::Build'
            ),
        "call ExtUtils::ModuleMaker->new from deep directory");

    ok ($MOD->build_single_pm({ NAME => 'Sample::Module::Bar'}),
        "call \$MOD->build_single_pm");

    ok ( -e ($MOD->{Base_Dir} . "/lib/Sample/Module/Bar.pm") ,
        "new module file successfully created");

    ok ( -e ($MOD->{Base_Dir} . "/t/Sample_Module_Bar.t"),
        "new test file successfully created");

}
