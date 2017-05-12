# $Id: Makefile.PL,v 1.8 2006/10/03 01:02:20 grantm Exp $

use ExtUtils::MakeMaker;

my $make_params = {
    'NAME'          => 'Domain::Register::DomainShare',
    'VERSION_FROM'  => 'lib/Domain/Register/DomainShare.pm',
    'DISTNAME'      => 'Domain-Register-DomainShare',
    'PREREQ_PM'     => {
			 XML::Simple =>                   2.18,
			 URI::Escape =>                   3.29,
			 REST::Client =>                  164,
                       },
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    'AUTHOR'        => 'Dot TK Limited <payments@dot.tk>',
};

WriteMakefile(%$make_params);
