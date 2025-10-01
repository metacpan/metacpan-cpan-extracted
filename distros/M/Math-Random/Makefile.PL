#! perl

use ExtUtils::MakeMaker;

#--- Original or revised phrtsd?
my $OPT = $ARGV[0];
my $def = q{};
$def = '-DPHRTSD_ORIG'
  if $OPT =~ /phrtsd_orig/i;

WriteMakefile(
    NAME         => 'Math::Random',
    VERSION      => '0.75',
    XS_VERSION   => '0.75',
    # VERSION_FROM => 'Random.pm',
    OBJECT       => '$(O_FILES)',
    LIBS         => ['-lm'],
    DEFINE       => $def,
    MIN_PERL_VERSION => '5.10.0',
    TEST_REQUIRES => {
        'Test2::V0' => '1.302200',  # a somewhat recent version will do
    },

    META_ADD => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/djerius/Math-Random.git',
                web  => 'https://github.com/djerius/Math-Random',
            },
            bugtracker => {
                mailto => 'bug-math-random@rt.cpan.org',
                web    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Random',
            },
        },
    },

);

