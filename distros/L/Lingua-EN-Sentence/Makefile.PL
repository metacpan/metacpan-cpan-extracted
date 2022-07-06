use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::EN::Sentence',
    'ABSTRACT'  => 'Split text into sentences',
    'VERSION_FROM'	=> 'lib/Lingua/EN/Sentence.pm', # finds $VERSION
    'PREREQ_PM'    =>
    {
        'perl' => '5.10.0',
        'warnings' => '1.06'
     },    
    'AUTHOR'        => 'Shlomo Yona, Kim Ryan',
    'LICENSE'       => 'perl',
    META_MERGE => {
    'meta-spec' => { version => 2 },
     resources => {
         repository => {
             type => 'git',
             url  => 'https://github.com/kimryan/Lingua-EN-Sentence.git',
             web  => 'https://github.com/kimryan/Lingua-EN-Sentence'
         },
     },
    }        
);

