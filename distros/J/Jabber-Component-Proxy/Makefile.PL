use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# $Id: Makefile.PL,v 1.1.1.1 2001/12/16 20:19:50 dj Exp $

WriteMakefile(
    'NAME'		    => 'Jabber::Component::Proxy',
    'VERSION_FROM'=> 'lib/Jabber/Component/Proxy.pm',
    'PREREQ_PM'		=> {
                       'Jabber::Connection' => '0.02',
                       'XML::XPath' => '1.02',
                     },
);
