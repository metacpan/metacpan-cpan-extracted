# Makefile.PL -- Makefile template for Hook::PrePostCall.
#
# Copyright (C) 1997 Philippe Verdret. All rights reserved.
# This file is part of Hook::PrePostCall module. 
# Hook::PrePostCall is free software.
# You can redistribute it and/or modify it under the same
# terms as Perl itself.
#

use ExtUtils::MakeMaker;

WriteMakefile(
	      'dist'  => { COMPRESS => "gzip", SUFFIX => "gz" },
	      NAME         => "Hook::PrePostCall",
	      DISTNAME     => "PrePostCall",
	      VERSION_FROM => "Hook/PrePostCall.pm",
	      INSTALLDIRS  => 'perl',
);
