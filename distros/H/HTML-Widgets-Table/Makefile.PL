#!/usr/bin/perl

# Creation date: 2003-09-06 12:51:45
# Authors: Don
# Change log:
# $Id: Makefile.PL,v 1.3 2003/09/10 04:54:23 don Exp $

use strict;
use Carp;

# main
{
    local($SIG{__DIE__}) = sub { &Carp::cluck(); exit 0 };

    use ExtUtils::MakeMaker;

    WriteMakefile(
                  NAME => 'HTML::Widgets::Table',
                  DISTNAME => 'HTML-Widgets-Table',
                  VERSION_FROM => 'Table.pm',
                  ABSTRACT => 'HTML Table Class',
                  AUTHOR => 'DON OWENS <don@owensnet.com>',
                  PM => { 'Table.pm' => '$(INST_LIBDIR)/Table.pm',
                          'Table/Row.pm' => '$(INST_LIBDIR)/Table/Row.pm',
                          'Table/Cell.pm' => '$(INST_LIBDIR)/Table/Cell.pm',
                          'Table/Core.pm' => '$(INST_LIBDIR)/Table/Core.pm',
                        },
                  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
                  DIR => [],
                  EXE_FILES => [],
                  );

}

exit 0;

###############################################################################
# Subroutines

