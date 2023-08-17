use File::ShareDir::Install;
use ExtUtils::MakeMaker;

# Install shared files
File::ShareDir::Install::install_share('share');

WriteMakefile(
    NAME             => 'LogFilter',
    VERSION_FROM     => 'lib/LogFilter.pm',
    ABSTRACT         => 'A simple log filter',
    AUTHOR           => 'Kawamura Shingo <pannakoota@gmail.com>',
    LICENSE          => 'artistic_2',
    PREREQ_PM        => {
        'perl'                    => '5.026',
        'File::Tail'              => 0,
        'IO::File'                => 0,
        'File::Spec'              => 0,
        'File::ShareDir'          => '1.116',
        'File::ShareDir::Install' => '0.13',
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
     ? ('LICENSE'=> 'perl')
     : ()
    ),
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/kawamurashingo/LogFilter.git',
                web  => 'https://github.com/kawamurashingo/LogFilter.git',
            },
        },
    },
    BUILD_REQUIRES   => {
        'File::ShareDir::Install' => 0.13,
    },
    CONFIGURE_REQUIRES => {
        'File::ShareDir::Install' => 0.13,
    },
);
