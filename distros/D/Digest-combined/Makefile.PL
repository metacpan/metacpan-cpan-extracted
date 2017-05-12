### Makefile.PL --- Build the Digest::combined package  -*- Perl -*-

## FIXME: just don't know how portable this code is
require 5.010;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Digest::combined',
    VERSION_FROM => 'lib/Digest/combined.pm',
    # ABSTRACT_FROM => 'lib/Digest/combined.pm',
    ## FIXME: insists on a hyphen in the NAME section
    ABSTRACT => 'Calculate multiple message digests simultaneously',
    AUTHOR => 'Ivan Shmakov <oneingray@gmail.com>',
    LICENSE => "public domain",
    ## FIXME: just don't know how portable this code is
    MIN_PERL_VERSION => 5.010
);

### Makefile.PL ends here
