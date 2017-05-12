use 5.006001;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'Devel::Dependencies',
    AUTHOR         => 'Neil Bowers <neil@bowers.com>',
    VERSION_FROM   => 'lib/Devel/Dependencies.pm',
    ABSTRACT_FROM  => 'lib/Devel/Dependencies.pm',
    PREREQ_PM      => { 'Time::HiRes' => 0 }, # e.g., Module::Name => 1.1

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Dependencies',
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/neilb/Devel-Dependencies',
                    url  => 'git://github.com/neilb/Devel-Dependencies.git',
                },
            },
          })
    ),

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006001)
        : ()
    ),

);
