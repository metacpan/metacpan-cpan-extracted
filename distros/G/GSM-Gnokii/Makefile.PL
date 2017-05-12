#!/usr/bin/perl

# Copyright (c) 2011-2013 H.Merijn Brand

require 5.008004;
use strict;

use ExtUtils::MakeMaker;
use Config;

my $gnokii_lib = "";
my $gnokii_inc = "";

if (exists $ENV{GNOKII_DIR} && -d $ENV{GNOKII_DIR}) {
    my $gdir = $ENV{GNOKII_DIR};
    $gnokii_lib = join " " => map { "-L$gdir$_" } "", "common/.libs";
    $gnokii_inc = "-I$gdir/include -I$gdir/gnokii";
    }
else {
    my $ext = $Config{dlext};
    grep { -x "$_/libgnokii.$Config{dlext}" ||
	   -x "$_/libgnokii.a"
	 } split m/\s+/ => $Config{libpth} or
	die "libgnokii not found. Unpack and compile, and set \$GNOKII_DIR\n";
    }

WriteMakefile (
    NAME         => "GSM::Gnokii",
    DISTNAME     => "GSM-Gnokii",
    ABSTRACT     => "API to libgnokii",
    AUTHOR       => "H.Merijn Brand <h.merijn\@xs4all.nl>",
    LICENSE      => "perl",
    VERSION_FROM => "lib/GSM/Gnokii.pm",
    PREREQ_PM    => {	"DynaLoader"    => 0,
			"Config"        => 0,
			"Test::More"    => 0,
			"Test::Harness" => 0,
			"Data::Peek"	=> 0.32,
			"JSON"		=> 0,
			},
    LIBS         => [ "$gnokii_lib -lgnokii" ],
    TYPEMAPS     => [ "perlobject.map" ],
    DEFINE       => "",
    INC          => $gnokii_inc,

    macro        => { GCC_WALL => (join " " => qw(
			-Wall -Wextra -Wbad-function-cast -Wcomment -Wcomments
			-Wformat -Wdisabled-optimization -Wmissing-prototypes
			-Werror-implicit-function-declaration -Wmissing-noreturn
			-Wmissing-format-attribute -Wno-cast-qual -Wunused-value
			-Wno-sign-compare -Wpointer-arith -Wreturn-type -Wshadow
			-Wswitch-default -Wuninitialized -Wunreachable-code
			-Wundef -Wunused
			)),	# add -Wunused-but-set-variable for gcc-4.6
		     "#OPTIMIZE" => "-O2 \$(GCC_WALL)",
		      TARFLAGS => "--format=ustar -c -v -f",
		      },
    );

1;

package MY;

sub postamble
{
    my $valgrind = join " ", qw(
	PERL_DESTRUCT_LEVEL=2 PERL_DL_NONLAZY=1
	    valgrind
		--suppressions=sandbox/perl.supp
		--leak-check=yes
		--leak-resolution=high
		--show-reachable=yes
		--num-callers=50
		--log-fd=3
		$(FULLPERLRUN) "-MExtUtils::Command::MM" "-e"
		    "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')"
		    $(TEST_FILES) 3>valgrind.log
		    );

    my $min_vsn = ($] >= 5.010 && -d "xt" && -d "tmp" && ($ENV{AUTOMATED_TESTING} || 0) != 1)
	? join "\n" =>
	    'test ::',
	    '	-@env TEST_FILES="xt/*.t" make -e test_dynamic',
	    ''
	: "";
    join "\n" =>
	'cover test_cover:',
	'	ccache -C',
	'	-@rm -f *.gc??',
	'	cover -test',
	'',
	'leakcheck:',
	"	$valgrind",
	'	-@tail -14 valgrind.log',
	'',
	'leaktest:',
	q{	sandbox/leaktest  $(FULLPERLRUN) "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)},
	'',
	'leaktrace:',
	q{	sandbox/leaktrace $(FULLPERLRUN) "test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)},
	'',
	'spellcheck:',
	'	pod-spell-check --aspell',
	'',
	'checkmeta:	spellcheck',
	'	perl sandbox/genPPPort_h.pl',
	'	perl sandbox/genMETA.pl -c',
	'',
	'fixmeta:	distmeta',
	'	perl sandbox/genMETA.pl',
	'',
	'tgzdist:	checkmeta fixmeta $(DISTVNAME).tar.gz distcheck',
	'	-@mv -f $(DISTVNAME).tar.gz $(DISTVNAME).tgz',
	'	-@cpants_lint.pl $(DISTVNAME).tgz',
	'	-@rm -f Debian_CPANTS.txt',
	'',
	'test_speed: pure_all',
	'	PERL_DL_NONLAZY=1 $(FULLPERLRUN) -I"$(INST_LIB)" -I"$(INST_ARCHLIB)" examples/speed.pl',
	'',
	$min_vsn;
    } # postamble
