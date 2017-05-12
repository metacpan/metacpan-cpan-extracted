# -*- perl -*-
# $Id: Makefile.PL,v 0.02 1998/28/9 09:45:13 kmeltz Exp $
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'HTML::PageIndex',
   VERSION_FROM  => 'PageIndex.pm',
   'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   'clean'       => { FILES => q[*% *.bak *.old *.test]},
);

