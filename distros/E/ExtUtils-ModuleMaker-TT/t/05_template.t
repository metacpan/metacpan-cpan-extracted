# t/05_template.t -- tests abilty to create template directory

#use Test::More qw/no_plan/;
use Test::More tests => 24;
use File::pushd 1;

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

BEGIN { use_ok( 'ExtUtils::ModuleMaker::TT' ); }

{
    my $dir = tempd();

    ok (ExtUtils::ModuleMaker::TT->create_template_directory('templates'),
        "create_template_directory");

    ###########################################################################

    ok (chdir 'templates',
        "cd templates");

    #        MANIFEST.SKIP .cvsignore
    for ( keys %ExtUtils::ModuleMaker::TT::templates ) {
        ok (-e,
            "$_ exists");
    }

}
