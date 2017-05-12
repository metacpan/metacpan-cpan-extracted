use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# $Id: Makefile.PL,v 1.1.1.1 2001/10/14 20:47:44 dj Exp $

WriteMakefile(
    'NAME'		    => 'Jabber::RPC::HTTPgate',
    'VERSION_FROM'=> 'lib/Jabber/RPC/HTTPgate.pm',
    'PREREQ_PM'		=> {
                       'Jabber::RPC' => '0.01',
                     },
);
