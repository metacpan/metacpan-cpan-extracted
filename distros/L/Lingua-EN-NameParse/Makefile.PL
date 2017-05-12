use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
    'NAME'         => 'Lingua::EN::NameParse',
    'VERSION_FROM' => 'lib/Lingua/EN/NameParse.pm',
    'ABSTRACT'    => "extract the components of a person or couples full name, presented as a text string",
    'AUTHOR'      => 'Kim Ryan',
    'LICENSE'     => 'perl',
    'PREREQ_PM'   =>  { 'Parse::RecDescent' => 0 },
    
    META_MERGE => {
    'meta-spec' => { version => 2 },
     resources => {
         repository => {
             type => 'git',
             url  => 'https://github.com/dwimperl/Task-DWIM.git',
             web  => 'https://github.com/dwimperl/Task-DWIM',
         },
     },
    }
);
