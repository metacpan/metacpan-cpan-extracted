use 5.8.0;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my @REQUIRES = (
    'HTTP::Lite' => 0,
    'Carp'       => 0,
    'strict'     => 0,
    'warnings'   => 0,
);

my @TEST_REQUIRES = (
    'LWP::Online' => 0,
    'Test::More'  => 0.88,
);

push(@REQUIRES, @TEST_REQUIRES) if $mm_ver < 6.64;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTTP::Client',
    VERSION_FROM      => 'lib/HTTP/Client.pm', # finds $VERSION
    PREREQ_PM         => { @REQUIRES },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTTP/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Lincoln Ombelets <lincdog85@gmail.com>') : ()),

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Client',
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/neilbowers/HTTP-Client',
                    url  => 'git://github.com/neilbowers/HTTP-Client.git',
                },
            },
          })
    ),

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => { @TEST_REQUIRES })
        : ()
    ),

);
