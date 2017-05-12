# $Id: Makefile.PL,v 1.2 2011/08/01 21:03:09 gunnarh Exp $

use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'HTTP::ProxyTest',
    VERSION_FROM      => 'ProxyTest.pm',
    PREREQ_PM         => { LWP => 0 },
    MIN_PERL_VERSION  => 5.006,
    ABSTRACT_FROM     => 'ProxyTest.pm',
    AUTHOR            => 'Gunnar Hjalmarsson <cpan@gunnar.cc>',
    LICENSE           => 'perl',
    META_MERGE        => {
        resources => {
            repository => 'http://gunnar.cc/cgi-bin/cvsweb.cgi/proxytest/?cvsroot=gunnar',
        },
    },
);

