use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME             => 'GD::SecurityImage::AC',
    VERSION_FROM     => 'lib/GD/SecurityImage/AC.pm',
    MIN_PERL_VERSION => '5.006',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'mit', ) : ()),
    PREREQ_PM      => {
                     'GD::SecurityImage' => '1.60',
                     'Digest::MD5'       => 0,
    }, 
    META_MERGE => {
       'meta-spec' => { version => 2 },
        resources => {
           bugtracker => {
                web  => 'https://github.com/JerilynFranz/perl-GD-SecurityImage-AC/issues',
            },
            homepage => 'https://github.com/JerilynFranz/perl-GD-SecurityImage-AC',
            repository => {
                type => 'git',
                url  => 'https://github.com/JerilynFranz/perl-GD-SecurityImage-AC.git',
                web  => 'https://github.com/JerilynFranz/perl-GD-SecurityImage-AC',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/GD/SecurityImage/AC.pod', # retrieve abstract from module
       AUTHOR         => 'Jerilyn Franz <cpan@jerilyn.info>') : ()),

       PL_FILES       => {},
);
