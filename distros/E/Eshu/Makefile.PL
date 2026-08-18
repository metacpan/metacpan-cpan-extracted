use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# Eshu.xs lives at the top of the dist, not under lib/, and the build is
# the plain single-extension one MakeMaker defaults to. An XSMULTI build
# from lib/Eshu.xs writes its linker export list to lib/Eshu.def, while
# the import-library rule Strawberry adds for MinGW reads $(EXPORT_LIST),
# which is always $(BASEEXT).def in the top directory - the two names
# never met and dlltool failed the build (CPAN Testers, 5.42 Strawberry).
my $pkg = ExtUtils::Depends->new('Eshu');
$pkg->set_inc('-I. -Iinclude');
$pkg->install(map { "include/$_" } qw(
    eshu.h
    eshu_bash.h
    eshu_c.h
    eshu_css.h
    eshu_diff.h
    eshu_file.h
    eshu_go.h
    eshu_hl.h
    eshu_hl_util.h
    eshu_java.h
    eshu_js.h
    eshu_json.h
    eshu_lua.h
    eshu_php.h
    eshu_pl.h
    eshu_pod.h
    eshu_py.h
    eshu_ruby.h
    eshu_rust.h
    eshu_sql.h
    eshu_ts.h
    eshu_xml.h
    eshu_xs.h
    eshu_yaml.h
    dirent_win.h
));

mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep_vars = $pkg->get_makefile_vars;
$dep_vars{PM}{'lib/Eshu.pm'} = '$(INST_LIB)/Eshu.pm';

my %WriteMakefileArgs = (
    NAME             => 'Eshu',
    AUTHOR           => 'LNATION <email@lnation.org>',
    VERSION_FROM     => 'lib/Eshu.pm',
    ABSTRACT         => 'Indentation fixer for C, Perl, XS, XML, HTML, CSS, JavaScript and POD source files',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Getopt::Long' => '0',
    },
    EXE_FILES => ['bin/eshu'],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Eshu-* Eshu.c Eshu.o Eshu.def Install/Files.pm' },
    %dep_vars,
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
