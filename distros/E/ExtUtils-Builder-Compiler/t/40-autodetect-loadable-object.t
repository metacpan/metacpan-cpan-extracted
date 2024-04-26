#! perl

use strict;
use warnings;

use Test::More 0.89;

use Config;
use ExtUtils::Builder::Planner;
use File::Basename qw/basename dirname/;
use File::Spec::Functions qw/catfile/;

my $planner = ExtUtils::Builder::Planner->new;
$planner->load_module('ExtUtils::Builder::AutoDetect::C',
	profile => '@Perl', type => 'loadable-object',
);

my $source_file = File::Spec->catfile('t', 'compilet.c');
{
	open my $fh, '>', $source_file or die "Can't create $source_file: $!";
	my $content = <<END;
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

XS(exported) {
#ifdef dVAR
	dVAR;
#endif
	dXSARGS;

	PERL_UNUSED_VAR(cv); /* -W */
	PERL_UNUSED_VAR(items); /* -W */

	XSRETURN_IV(42);
}

#ifndef XS_EXTERNAL
#define XS_EXTERNAL(foo) XS(foo)
#endif

XS_EXTERNAL(boot_compilet) {
#ifdef dVAR
	dVAR;
#endif
	dXSARGS;

	PERL_UNUSED_VAR(cv); /* -W */
	PERL_UNUSED_VAR(items); /* -W */

	newXS("main::exported", exported, __FILE__);
}

END
	print $fh $content or die "Can't write to $source_file: $!";
	close $fh or die "Can't close $source_file: $!";
}
ok(-e $source_file, "source file '$source_file' created");

my $object_file = catfile(dirname($source_file), basename($source_file, '.c') . $Config{obj_ext});
$planner->compile($source_file, $object_file);

my $lib_file = catfile(dirname($source_file), basename($object_file, $Config{obj_ext}) . ".$Config{dlext}");
$planner->link([$object_file], $lib_file);

my $plan = $planner->materialize;
ok $plan;

ok eval { $plan->run($lib_file, logger => \&note); 1 } or diag "Got exception: $@";

ok(-e $object_file, "object file $object_file has been created");
ok(-e $lib_file, "lib file $lib_file has been created");

require DynaLoader;
my $libref = DynaLoader::dl_load_file($lib_file, 0);
ok($libref, 'libref is defined');
my $symref = DynaLoader::dl_find_symbol($libref, "boot_compilet");
ok($symref, 'symref is defined');

my $compilet = DynaLoader::dl_install_xsub("compilet", $symref, $source_file);
is(eval { compilet(); 1 }, 1, 'compilet lives');

is(eval { exported() }, 42, 'exported returns 42');

END { 
	for ($source_file, $object_file, $lib_file) {
		next if not defined;
		1 while unlink;
	}
	if ($^O eq 'VMS') {
		1 while unlink 'COMPILET.LIS';
		1 while unlink 'COMPILET.OPT';
	}
}

done_testing;

