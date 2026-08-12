use ExtUtils::MakeMaker;
use Config;

# $^X can contain spaces (Windows), so quote it
my $xpk_flags = `"$^X" -MXS::Parse::Keyword::Builder -e "print XS::Parse::Keyword::Builder->extra_compiler_flags"`;
die "XS::Parse::Keyword::Builder is required to configure this module\n" if $?;

# -std=c99 and -O3 are gcc/clang spellings; passing them to a compiler that
# does not know them (MSVC-built perls) fails the build outright. Both can
# still be overridden on the command line: perl Makefile.PL OPTIMIZE=-O2
my $gcc_like = $Config{gccversion} || $Config{cc} =~ /\b(?:gcc|clang|cc)\b/;

my %compiler = (
    CCFLAGS => join(' ', grep { length }
                    $Config{ccflags}, ($gcc_like ? '-std=c99' : ()), $xpk_flags),
    ($gcc_like ? (OPTIMIZE => '-O3') : ()),
);

WriteMakefile(
    NAME          => 'JSON::YY',
    VERSION_FROM  => 'lib/JSON/YY.pm',
    ABSTRACT_FROM => 'lib/JSON/YY.pm',
    AUTHOR        => 'vividsnow',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.014',
    OBJECT        => 'YY$(OBJ_EXT) yyjson$(OBJ_EXT)',
    INC           => '-I.',
    %compiler,
    CONFIGURE_REQUIRES => {
        'XS::Parse::Keyword::Builder' => '0.40',
    },
    PREREQ_PM => {
        'XS::Parse::Keyword' => '0.40',
        'Scalar::Util'       => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
        'File::Temp' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        # a runtime handle class living in JSON/YY.pm, not separately loadable
        no_index    => { package => ['JSON::YY::Doc'] },
        provides    => {
            'JSON::YY' => {
                file    => 'lib/JSON/YY.pm',
                version => MM->parse_version('lib/JSON/YY.pm'),
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-json-yy.git',
                web  => 'https://github.com/vividsnow/perl5-json-yy',
            },
        },
    },
);
