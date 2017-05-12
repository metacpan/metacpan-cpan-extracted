use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile( 'NAME'		=> 'Language::XSB::xsblib',
	       'PREREQ_PM'		=> {},
	       'AUTHOR'     => 'Salvador Fandiño <sfandino@yahoo.com>',
	       'PM'         => { 'perlcallxsb.xwam' =>
				 '$(INST_LIBDIR)/xsblib/perlcallxsb.xwam' },
);
