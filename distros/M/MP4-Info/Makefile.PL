use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME		=> 'MP4::Info',
     VERSION_FROM	=> 'Info.pm',
     ABSTRACT_FROM	=> 'Info.pm',
     AUTHOR		=> 'Jonathan Harris <jhar@cpan.org>',
     PREREQ_PM		=> { 'Encode' => '0',
			     'IO::String' => '0'},
    );
