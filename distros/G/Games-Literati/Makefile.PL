use ExtUtils::MakeMaker;
require 5.006;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%mm_args = (
    'NAME'		    => 'Games::Literati',
    'VERSION_FROM'	=> 'Literati.pm',
    'PREREQ_PM'		=> {'Exporter' => 0},
    'ABSTRACT_FROM' => 'Literati.pm',
    'AUTHOR'        => 'Peter C. jones <petercj AT cpan.org>, Chicheng Zhang',
    'META_MERGE'    => {
        resources => {
            bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Games-Literati',
            repository => 'https://github.com/pryrt/Games-Literati',
        },
        keywords => [ 'Scrabble', 'Literati', 'Words with Friends', 'tile', 'word', 'game' ],
    },
);

{
    no warnings;
    if( $ExtUtils::MakeMaker::VERSION >= '6.31' ) {
        $mm_args{LICENSE} = 'perl_5';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.48' ) {
        $mm_args{MIN_PERL_VERSION} = '5.6.0';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.64' ) {
        $mm_args{TEST_REQUIRES} = {
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0,
            'File::Basename' => 0,
            'Cwd' => 0,
            'IO::String' => 0,
        };
    }
}

WriteMakefile( %mm_args );
