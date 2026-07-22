use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

my $has_xsmulti = eval { ExtUtils::MakeMaker->VERSION('7.12'); 1 };

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
    clean => { FILES => 'Eshu-* lib/*.o lib/*.c lib/*.bs Install/Files.pm' },
    %dep_vars,
);

if ($has_xsmulti) {
    $WriteMakefileArgs{XSMULTI} = 1;
    $WriteMakefileArgs{XS}      = { 'lib/Eshu.xs' => 'lib/Eshu.c' };
    $WriteMakefileArgs{OBJECT}  = 'lib/Eshu$(OBJ_EXT)';
} else {
    $WriteMakefileArgs{XS}     = { 'lib/Eshu.xs' => 'lib/Eshu.c' };
    $WriteMakefileArgs{OBJECT} = 'lib/Eshu$(OBJ_EXT)';
}

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

sub MY::postamble {
    return '' if $has_xsmulti;
    return <<'MAKE';
lib/Eshu$(OBJ_EXT): lib/Eshu.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $< -o $@
MAKE
}
