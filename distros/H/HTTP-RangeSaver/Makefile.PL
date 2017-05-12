use ExtUtils::MakeMaker;
WriteMakefile
    (NAME		=> 'HTTP-RangeSaver',
     VERSION_FROM	=> 'lib/HTTP/RangeSaver.pm',
     ABSTRACT_FROM	=> 'lib/HTTP/RangeSaver.pm',
     AUTHOR		=> 'Bo Lindbergh <blgl@stacken.kth.se>',
     PREREQ_PM		=> {
	 LWP	=> "5.805",
     });

