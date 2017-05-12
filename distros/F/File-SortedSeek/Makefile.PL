use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'File::SortedSeek',
    'VERSION_FROM'  => 'lib/File/SortedSeek.pm',
    'PREREQ_PM'     => {'Time::Local' => 0,},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/File/SortedSeek.pm',
       AUTHOR         => 'Dr James Freeman') :
      ()
    ),
    'LICENSE'       => 'artistic_2',
);
