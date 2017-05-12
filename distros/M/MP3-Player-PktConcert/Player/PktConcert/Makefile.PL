use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MP3::Player::PktConcert',
    'VERSION_FROM'	=> 'PktConcert.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT	  => 'Perl wrapper to John Seagull\'s C API to the Intel PocketConcert',
       AUTHOR     => 'Mike Wong <mike_w3@pacbell.net>') : ()),
    'LIBS'		=> ['-lusb -lipkc' ],
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> '-I/usr/local/include',
);
