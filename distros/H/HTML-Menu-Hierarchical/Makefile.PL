#!/usr/bin/env perl

# Creation date: 2003-02-25 22:25:01
# Authors: Don
# Change log:
# $Id: Makefile.PL,v 1.4 2003/03/06 06:26:15 don Exp $

use strict;
use Carp;

# main
{
    local($SIG{__DIE__}) = sub { &Carp::cluck(); exit 0 };

    use ExtUtils::MakeMaker;

    WriteMakefile(
                  NAME => 'HTML::Menu::Hierarchical',
                  DISTNAME => 'HTML-Menu-Hierarchical',
                  VERSION_FROM => 'Hierarchical.pm',
                  ABSTRACT => 'HTML Hierarchical Menu Generator',
                  AUTHOR => 'Don Owens <don@owensnet.com>',
                  PM => { 'Hierarchical.pm' => '$(INST_LIBDIR)/Hierarchical.pm',
                          'Hierarchical/Item.pm' => '$(INST_LIBDIR)/Hierarchical/Item.pm',
                          'Hierarchical/ItemInfo.pm' => '$(INST_LIBDIR)/Hierarchical/ItemInfo.pm',
                        },
                  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
                  DIR => [],
                  EXE_FILES => [],
                 );

}

exit 0;

###############################################################################
# Subroutines

