use ExtUtils::MakeMaker;
use Config;

my $xpk_flags = `$^X -MXS::Parse::Keyword::Builder -e "print XS::Parse::Keyword::Builder->extra_compiler_flags"`;
die "XS::Parse::Keyword::Builder is required to configure this module\n" if $?;

WriteMakefile(
    NAME          => 'JSON::YY',
    VERSION_FROM  => 'lib/JSON/YY.pm',
    ABSTRACT_FROM => 'lib/JSON/YY.pm',
    AUTHOR        => 'vividsnow',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.014',
    OBJECT        => 'YY$(OBJ_EXT) yyjson$(OBJ_EXT)',
    INC           => '-I.',
    CCFLAGS       => "$Config{ccflags} -std=c99 $xpk_flags",
    OPTIMIZE      => '-O3',
    CONFIGURE_REQUIRES => {
        'XS::Parse::Keyword::Builder' => '0.40',
    },
    PREREQ_PM => {
        'XS::Parse::Keyword' => '0.40',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-json-yy.git',
                web  => 'https://github.com/vividsnow/perl5-json-yy',
            },
        },
    },
);
