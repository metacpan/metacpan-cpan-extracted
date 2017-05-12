#!/usr/bin/perl

use strict;
use lib "./t"; use MakeMakerFix;

my $postamble = '

inc_dir = $(INST_LIB)/$(FULLEXT)

$(inc_dir)/.exists: Makefile
	@ $(MKPATH) $(inc_dir) && $(TOUCH) $(inc_dir)/.exists
	@ $(CC) `./t/configure.sh $(CC)` \
		t/gen-stat.c -o t/gen-stat
	@ t/gen-stat > $(inc_dir)/stat.ph
	@ $(TOUCH) $(inc_dir)/.exists

pure_all::   $(inc_dir)/.exists

';

WriteMakefile('Bits.pm', 'VERSION_FROM' => 'VERSION', 'NO_META' => 1,
	      'clean' => {'FILES' => "t/gen-stat"},
	      'postamble' => $postamble);

