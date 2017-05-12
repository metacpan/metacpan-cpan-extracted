#!perl -w
use 5.005;
use strict;
use ExtUtils::MakeMaker;

my $ExtUtils_Depends_required = 0.302; #minimum version that works on Win32+gcc
eval {
	require ExtUtils::Depends;
};
if ( $@ or ExtUtils::Depends->VERSION < $ExtUtils_Depends_required ) {
	print "ExtUtils::Depends $ExtUtils_Depends_required is required to configure this module, please install it manually or upgrade your CPAN/CPANPLUS shell\n";
	exit(0);
}
my $pkg = ExtUtils::Depends->new('Devel::StackBlech');
$pkg->install('DStackBlech.h');
$pkg->add_xs('StackBlech.xs');
$pkg->add_pm( 'lib/Devel/StackBlech.pm' => '$(INST_LIB)/Devel/StackBlech.pm' );
# $pkg->add_typemaps( 'typemap' );
$pkg->save_config('build/IFiles.pm');

WriteMakefile(
    NAME                => 'Devel::StackBlech',
    VERSION_FROM        => 'lib/Devel/StackBlech.pm',
    PREREQ_PM => {
        'Sub::Exporter'     => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'ExtUtils::CBuilder' => 0,
        'IPC::Run' => 0,
        'File::Basename' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::Depends' => $ExtUtils_Depends_required,
        'ExtUtils::CBuilder' => 0,
    },
    ABSTRACT_FROM       => 'lib/Devel/StackBlech.pod',
    AUTHOR              => 'Josh ben Jore <jjore@cpan.org>',
    LICENSE             => 'perl',
    MIN_PERL_VERSION => 5.005,
    META_MERGE => {
	resources => {
            repository => 'http://github.com/jbenjore/Devel-StackBlech/tree',
	},
	keywords => ['perl internals','stack'],
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-StackBlech-*' },
);
