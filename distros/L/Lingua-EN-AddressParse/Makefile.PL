use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


WriteMakefile
(
    'NAME'         => 'Lingua::EN::AddressParse',
    'VERSION_FROM' => 'lib/Lingua/EN/AddressParse.pm',
    'ABSTRACT'     => 'extract components of a street address from free format text',
    'AUTHOR'       => 'Kim Ryan',
    'PREREQ_PM'    =>
    {
        'Test::Pod::Coverage' => 1.04,
        'utf8'                => 1.09,
        'warnings'            => 1.12,
        'Parse::RecDescent'   => 1.00,
        'Locale::SubCountry'  => 1.41,
        'Lingua::EN::NameParse' => 1.24
    },
    'LICENSE'     => 'perl',
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
