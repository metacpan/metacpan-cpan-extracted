use 5.008009;
use ExtUtils::MakeMaker;

my @V8_CC_OPTS;
my @V8_WARNINGS;
my @V8_INCS;
my @V8_LIBS;

# these apply always
push @V8_CC_OPTS, qw< -O2 --std=c++11 >;
push @V8_WARNINGS, qw< all extra no-unused-parameter >;
push @V8_LIBS, qw< v8 v8_libbase v8_libplatform icuuc icui18n >;

if ($^O eq 'linux') {
    # these apply only on linux, where the V8 build required to ignore standard
    # include files and instead look at their own internal libc++ files
    push @V8_CC_OPTS, qw< -nostdinc++ >;
    push @V8_INCS, map { "/usr/include/$_/include" } qw< v8/libc++ v8/libc++abi >;
}

my $CC = 'c++';
my $LD = 'c++';

my $CC_OPTS = join(' ',
    (@V8_CC_OPTS),
    (map { "-W$_" } @V8_WARNINGS),
    (map { "-I$_" } @V8_INCS),
);
my $LD_OPTS = join(' ',
    map { "-l$_" } @V8_LIBS,
);

WriteMakefile(
    NAME           => 'JavaScript::V8::XS',
    VERSION_FROM   => 'lib/JavaScript/V8/XS.pm',
    ABSTRACT_FROM  => 'lib/JavaScript/V8/XS.pm',
    LICENSE        => 'mit',
    MIN_PERL_VERSION => 5.018000,
    PREREQ_PM      => {
        'JSON::PP'        => 0,
        'Text::Trim'      => 0,
        'XSLoader'        => 0,
        'ExtUtils::XSpp'  => '0.11',
    },
    TEST_REQUIRES  => {
        'Data::Dumper'    => 0,
        'JSON::PP'        => 0,
        'Path::Tiny'      => 0,
        'Scalar::Util'    => 0,
        'Test::More'      => 0,
        'Test::Output'    => 0,
        'Test::Exception' => 0,
        'Text::Trim'      => 0,
        'Time::HiRes'     => 0,
    },
    AUTHOR         => [
        'Gonzalo Diethelm (gonzus@cpan.org)',
    ],

    # compiler settings
    CC                 => "$CC $CC_OPTS",
    DEFINE             => '',
    depend             => { 'v8-perl.c' => 'JavaScript-V8-XS-Context.xsp' },

    # linker settings
    LD                 => "$LD $LD_OPTS",
    OBJECT             => '$(O_FILES)',

    # precompiler settings
    XSOPT              => '-C++ -hiertype',
    TYPEMAPS           => ['perlobject.map'],

    # repo settings
    META_MERGE         => {
        'meta-spec'    => { version => 2 },
        resources      => {
            repository => {
                type   => 'git',
                url    => 'git@github.com:gonzus/JavaScript-V8-XS',
                web    => 'https://github.com/gonzus/JavaScript-V8-XS',
            },
        },
    },
);
