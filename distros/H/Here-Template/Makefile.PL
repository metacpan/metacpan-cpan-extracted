
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Here::Template',
    VERSION_FROM  => 'lib/Here/Template.pm',
    ABSTRACT_FROM => 'lib/Here/Template.pm',
    AUTHOR        => 'Alexandr Gomoliako <zzz@zzz.org.ua>',
    PREREQ_PM     => {
        'Test::More' => 0,
    },

    (eval $ExtUtils::MakeMaker::VERSION >= 6.46
         ? ( 'META_MERGE' => { 
                 'no_index' => { 
                     'directory' => ['eg'] 
                 } 
             } ) : ()),

);

