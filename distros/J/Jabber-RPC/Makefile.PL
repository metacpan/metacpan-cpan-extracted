use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# $Id: Makefile.PL,v 1.2 2001/09/30 19:15:12 dj Exp $

WriteMakefile(
    'NAME'		    => 'Jabber::RPC',
    'VERSION_FROM'=> 'lib/Jabber/RPC.pm',
    'PREREQ_PM'		=> {
                       'Jabber::Connection' => '0.02',
                       'Frontier::RPC2',
                     },
);
