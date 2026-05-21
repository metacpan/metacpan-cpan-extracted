use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
    NAME => 'Minima',
    VERSION_FROM => 'lib/Minima.pm',
    ABSTRACT_FROM => 'lib/Minima.pm',
    AUTHOR => 'Cesar Tessarin, <cesar@tessarin.com.br>',
    EXE_FILES => [ glob 'bin/*' ],

    MIN_PERL_VERSION => 'v5.40',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7',
        'File::ShareDir::Install' => '0.14',
    },
    PREREQ_PM => {
        'Data::Dumper' => '2.1',
        'File::Share' => '0.27',
        'Hash::MultiValue', '0.16',
        'JSON' => '4.10',
        'Path::Tiny' => '0.142',
        'Plack' => '1.0050',
        'Router::Simple' => '0.17',
        'Template' => '3.100',
        'YAML::XS' => '0.904.0',
    },
    TEST_REQUIRES => {
        'HTTP::Request::Common' => '6.0',
    },

    META_MERGE => {
        dynamic_config => 0,
        resources => {
            repository => 'https://github.com/tessarin/Minima',
            bugtracker => 'https://github.com/tessarin/Minima/issues',
        },
    },
    LICENSE => 'mit',

    clean => { FILES => 'cover_db' },
);

package MY;
use File::ShareDir::Install 'postamble';
