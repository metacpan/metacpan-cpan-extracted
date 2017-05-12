# t/04_compact.t -- tests a compact build, a different license text and
# a Module::Build build system

#use Test::More qw/no_plan/;
use Test::More tests => 25;
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
	"call ExtUtils::ModuleMaker::TT->new");
	
ok ($MOD->complete_build (),
	"call \$MOD->complete_build");

###########################################################################

ok (chdir 'Sample-Module-Foo',
	"cd Sample-Module-Foo");

#        MANIFEST.SKIP .cvsignore
for (qw( Changes MANIFEST MANIFEST.SKIP Build.PL LICENSE
		README lib lib/Sample/Module/Foo.pm t t/001_Sample_Module_Foo.t )) {
    ok (-e,
		"$_ exists");
}

###########################################################################

ok (open (FILE, 'LICENSE'),
	"reading 'LICENSE'");
my $filetext = do {local $/; <FILE>};
close FILE;

ok ($filetext =~ m/Loose lips sink ships/,
	"correct LICENSE generated");

}
