use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
 	      'NAME'		=> 'Games::IL2Device::Link.pm',
	      'DISTNAME'        => 'Games-IL2Device-Link',
 	      'VERSION_FROM'	=> 'lib/Games/IL2Device/Link.pm', 
 	      'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
 	      ($] >= 5.005 ? 
 	       (ABSTRACT => 'Perl client interface to IL2 Forgotten Battles.',
 		AUTHOR     => 'Mathias Jansson <mj@pfy.nu>') : ()),
 	      'LIBS'		=> [''], # e.g., '-lm'
 	      'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
 	      'INC'		=> '', # e.g., '-I/usr/include/other'
 	     );
