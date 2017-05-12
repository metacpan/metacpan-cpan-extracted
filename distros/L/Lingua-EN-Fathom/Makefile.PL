use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
    'NAME'         => 'Lingua::EN::Fathom',
    'VERSION_FROM' => 'lib/Lingua/EN/Fathom.pm',
    'ABSTRACT'     => 'Measure readability of English text',
    'AUTHOR'       => 'Kim Ryan <kimryan at cpan org>',
    'LICENSE'      => 'perl',                                
    'PREREQ_PM'    =>
    { 
        locale => 1.00,
        strict => 1.04,
        warnings => 0,
        'Lingua::EN::Syllable' => 0.28   
    },
    
    TEST_REQUIRES =>
    {
        Test::More => 0.94,
        Test::Pod  => 1.04,
    },
    
    META_MERGE => {
    'meta-spec' => { version => 2 },
     resources => {
         repository => {
             type => 'git',
             url  => 'https://github.com/dwimperl/Task-DWIM.git',
             web  => 'https://github.com/dwimperl/Task-DWIM',
         },
     }
    }
);   
