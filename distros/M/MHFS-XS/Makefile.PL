use 5.020002;
use ExtUtils::MakeMaker;
use File::Basename;
use Cwd qw(abs_path);
use Alien::Base::Wrapper ();

my %stuff = Alien::Base::Wrapper->new('Alien::libFLAC')->mm_args2(
    NAME              => 'MHFS::XS',
    VERSION_FROM      => 'lib/MHFS/XS.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/MHFS/XS.pm',
    AUTHOR            => "Gavin Hayes <gahayes\@cpan.org>",
    LICENSE           => 'perl_5',
    CCFLAGS           => '-Wall -std=c11',
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MHFS-XS-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/G4Vi/MHFS.git',
                web  => 'https://github.com/G4Vi/MHFS',
            },
            bugtracker => {
                web => 'https://github.com/G4Vi/MHFS/issues'
            },
            homepage   => 'https://github.com/G4Vi/MHFS',
        },
    },
);
WriteMakefile(%stuff);