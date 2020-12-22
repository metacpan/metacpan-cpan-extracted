use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'File::TVShow::Organize',
    VERSION_FROM      => 'lib/File/TVShow/Organize.pm', # finds $VERSION
    MIN_PERL_VERSION => '5.10.0',
    PREREQ_PM         => { 'File::TVShow::Info' => 0,
                           'File::Path' => 0,
                           'File::Copy' => 0,
                           'IPC::Cmd' => 0,
                           'Carp' => 0 }, # e.g., Module::Name => 1.1
    TEST_REQUIRES    => {
                          'Test::More' => 0,
                          'File::chdir' => 0,
                          'Test::Carp' => 0,
                          'Cwd' => 0,
                          'Data::Dumper' => 0,
                          'Archive::Tar' => 0,

    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46)} ? (META_MERGE => {
    	'meta-spec' => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'https://github.com/Bas-Man/File-TVShow-Organize.git',
          web => 'https://github.com/Bas-Man/File-TVShow-Organize',
        },
        bugtracker => {
          web => 'https://github.com/Bas-Man/File-TVShow-Organize/issues',
        },
        homepage => 'https://bas-man.github.io',
      },
    })
      : ()
    ),
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/TVShow/Organize.pm', # retrieve abstract from module
       AUTHOR         => 'Adam Spann <bans@cpan.org>') : ()),
)
