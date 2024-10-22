use 5.020002;
use ExtUtils::MakeMaker;
use Config;
use Alien::Base::Wrapper ();

my %stuff = Alien::Base::Wrapper->new('Alien::libFLAC')->mm_args2(
    NAME              => 'MHFS::XS',
    VERSION_FROM      => 'lib/MHFS/XS.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/MHFS/XS.pm',
    AUTHOR            => "Gavin Hayes <gahayes\@cpan.org>",
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION => '5.020002',
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
        prereqs => {
            configure => {
                requires => {
                    "Alien::libFLAC" => "v0.2.0",
                }
            }
        },
    },
);

# 32-bit arm needs -latomic for miniaudio
if(($Config{archname} =~ /arm/) && ($Config{archname} !~ /64/)) {
    $stuff{LIBS} //= [''];
    print "adding atomic ".$Config{archname}."\n";
    $stuff{LIBS}[0] .= ' -latomic';
}

WriteMakefile(%stuff);
