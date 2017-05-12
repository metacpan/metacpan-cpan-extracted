#!/usr/bin/perl -w
use strict;
use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Digest::Skein',
	LICENSE      => 'gpl',
	VERSION_FROM => 'lib/Digest/Skein.pm',
	PREREQ_PM    => {
		'Digest'       => 0,
		'MIME::Base64' => 0,
		'Test::More'   => 0,
	},
	ABSTRACT_FROM => 'lib/Digest/Skein.pm',
	AUTHOR        => 'Radoslaw Zielinski <radek@pld-linux.org>',
	clean         => { FILES => 'Optimized_64bit/*.o', },
	dynamic_lib   => { INST_DYNAMIC_DEP => 'subdirs', },
	LDFROM        => '$(OBJECT) Optimized_64bit/*$(OBJ_EXT)',
##	DEFINE        => '',
);

# vim: ts=4 sw=4 noet
