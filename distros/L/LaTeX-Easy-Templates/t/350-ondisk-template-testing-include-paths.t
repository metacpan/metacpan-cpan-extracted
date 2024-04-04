#!/usr/bin/env perl

###################################################################
#### NOTE env-var TEMP_DIRS_KEEP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use lib 'blib/lib';

#use utf8;

our $VERSION = '0.05';

use Test::More;
use Test::More::UTF8;
use Mojo::Log;
use FindBin;
use File::Temp 'tempdir';
use File::Basename;
use File::Spec;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

use LaTeX::Easy::Templates;

my $VERBOSITY = 2;

my $log = Mojo::Log->new;

my $curdir = $FindBin::Bin;

# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = File::Temp::tempdir(CLEANUP=>1); # will not be erased if env var is set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $template_data = {
	'title' => 'a test title',
	'author' => {
		'name' => 'myname',
		'surname' => 'surname',
	},
	'date' => '2024/12/12',
	'content' => 'blah blah',
};

my ($latex_template_string, $FH);
my $template_filename = File::Spec->catfile($curdir, 'templates', 'simple11', 'main.tex.tx');
ok(-f $template_filename, "template exists: $template_filename") or BAIL_OUT;
my $expected_latex_output_filename = $template_filename; $expected_latex_output_filename =~ s/\.tx$/.expected_output/;
ok(-f $expected_latex_output_filename, "expected output file exists: $expected_latex_output_filename") or BAIL_OUT;

my $latter = LaTeX::Easy::Templates->new({
	'debug' => {
	  'verbosity' => $VERBOSITY,
	  'cleanup' => 1
	},
	'templater-parameters' => {
		'path' => [
			File::Spec->catdir($curdir, 'templates', 'simple12'),
		],
	},
	'processors' => {
	  'mytemplate' => {
		'template' => {
			'filepath' => $template_filename
		},
	  },
	}
});
ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called and got success.") or BAIL_OUT;

my $outfile = File::Spec->catfile($tmpdir, 'xyz.pdf');
my $ret = $latter->format({
	'template-data' => $template_data,
	'output' => {
		'filepath' => $outfile,
	},
	'processor' => 'mytemplate',
});
ok(defined($ret), 'format()'." : called and got good result.") or BAIL_OUT;
ok(-f $outfile, 'format()'." : called and output file ($outfile) exists.") or BAIL_OUT;
my $latexsrcf = $ret->{'latex'}->{'filepath'};
# check if output and expected output of latex source produced from template processing matches
is(File::Compare::compare($latexsrcf, $expected_latex_output_filename), 0, 'format()'." : called and latex output file ($latexsrcf) is exactly the same as the expected output ($expected_latex_output_filename).") or BAIL_OUT("check file '$latexsrcf'");

###########################################################################
# now try with no path, it must fail
# NOTE: you must recreate the object, you can't change on-the-fly
$latter = LaTeX::Easy::Templates->new({
	'debug' => {
	  'verbosity' => $VERBOSITY,
	  'cleanup' => 1
	},
	'templater-parameters' => {
	},
	'processors' => {
	  'mytemplate' => {
		'template' => {
			'filepath' => $template_filename
		},
	  },
	}
});
ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called and got success.") or BAIL_OUT;

$ret = $latter->format({
	'template-data' => $template_data,
	'output' => {
		'filepath' => $outfile,
	},
	'processor' => 'mytemplate',
});
# it must fail:
ok(!defined($ret), 'format()'." : called and got good result.") or BAIL_OUT;

# if you set env var TEMP_DIRS_KEEP=1 when running
# the temp files WILL NOT BE DELETED otherwise
# they are deleted automatically, unless some other module
# messes up with $File::Temp::KEEP_ALL
diag "temp dir: $tmpdir ...";
do {
	$File::Temp::KEEP_ALL = 0;
	File::Temp::cleanup;
	diag "temp files cleaned!";
} unless exists($ENV{'TEMP_DIRS_KEEP'}) && $ENV{'TEMP_DIRS_KEEP'}>0;

# END
done_testing()
