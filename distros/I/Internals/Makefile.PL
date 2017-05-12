
###############################################################################
##                                                                           ##
##    Copyright (c) 2001 by Steffen Beyer.                                   ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use ExtUtils::MakeMaker;

#use Config;

WriteMakefile(
    'NAME'              => 'Internals',
    'VERSION_FROM'      => 'Internals.pm',
#   ($] >= 5.005 ?
#       ('ABSTRACT'     => 'Write-protect variables, manipulate refcounts',
#        'AUTHOR'       => 'Steffen Beyer (sb@engelschall.com)') : ()),
#   ($] >= 5.005 && $^O eq 'MSWin32' && $Config{archname} =~ /-object\b/i ?
#       ('CAPI'         => 'TRUE') : ()),
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" }
);

