#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME   => 'libskein',
	OBJECT => 'SHA3api_ref.o skein_block.o skein.o skein_debug.o',
	SKIP   => [qw(all dynamic dynamic_lib)],
	clean  => { 'FILES' => 'libmylib$(LIB_EXT)' },
);

sub MY::postamble {
	'
all: static

dynamic: static

dynamic_lib: static
';
}
