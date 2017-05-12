use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Log::Procmail',
    'VERSION_FROM' => 'lib/Log/Procmail.pm',
    'PREREQ_PM'    => { Test::More => 0 },
    'EXE_FILES'    => [ 'scripts/mailstat.pl' ],
    'AUTHOR'       => 'Philippe "BooK" Bruhat <book@cpan.org>',
    'PL_FILES'     => {},
    META_MERGE => {
        resources => {  
            repository => 'http://github.com/book/Log-Procmail',
        },
    },      

);
