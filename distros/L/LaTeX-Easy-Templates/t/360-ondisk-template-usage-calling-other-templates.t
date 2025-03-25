#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

# this demonstrates how to use on-disk template which
# calls other on-disk templates

use strict;
use warnings;

use lib 'blib/lib';

#use utf8;

our $VERSION = '1.03';

use Test::More;
use Test::More::UTF8;
use Mojo::Log;
use FindBin;
use Test::TempDir::Tiny;
use File::Basename;
use File::Spec;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

use LaTeX::Easy::Templates;

my $VERBOSITY = 1;

my $log = Mojo::Log->new;

my $curdir = $FindBin::Bin;

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
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

my (%processors, $FH);
for my $atf ('main.tex.tx', 'preamble.tex.tx', 'content.tex.tx'){
	my $templatefile = File::Spec->catfile($curdir, 'templates', 'simple02-included-templates', $atf);
	ok(-f $templatefile, "template exists: $templatefile") or BAIL_OUT;
	ok(open($FH, '<:encoding(UTF-8)', $templatefile), "template file opened for reading : '$templatefile'.") or BAIL_OUT("failed: $!");
	my $con;
	{ local $/ = undef; $con = <$FH> } close $FH;
	$processors{$atf} = {
		'template' => {
			'content' => $con
		}
	};
}

my $expected_latex_output_filename = File::Spec->catfile($curdir, 'templates', 'simple02-included-templates', 'main.tex.expected_output');
ok(-f $expected_latex_output_filename, "expected output file exists: $expected_latex_output_filename") or BAIL_OUT;

my $latter = LaTeX::Easy::Templates->new({
	'debug' => {
	  'verbosity' => $VERBOSITY,
	  'cleanup' => 1
	},
	'processors' => {
	  'main.tex.tx' => {
		'template' => {
			'filename' => 'main.tex.tx',
			'basedir' => File::Spec->catdir($curdir, 'templates', 'simple02-included-templates')
		}
	  }
	} # end processors
});
ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called and got success.") or BAIL_OUT;

my $outfile = File::Spec->catfile($tmpdir, 'xyz.pdf');
my $ret = $latter->format({
	'template-data' => $template_data,
	'output' => {
		'filepath' => $outfile,
	},
	'processor' => 'main.tex.tx',
});
ok(defined($ret), 'format()'." : called and got good result.") or BAIL_OUT;
ok(-f $outfile, 'format()'." : called and output file ($outfile) exists.") or BAIL_OUT;
my $latexsrcf = $ret->{'latex'}->{'filepath'};
# check if output and expected output of latex source produced from template processing matches
is(File::Compare::compare($latexsrcf, $expected_latex_output_filename), 0, 'format()'." : called and latex output file ($latexsrcf) is exactly the same as the expected output ($expected_latex_output_filename).") or BAIL_OUT("check file '$latexsrcf'");

##############################################
###### now repeat above but specify just filepath
##############################################
$latter = LaTeX::Easy::Templates->new({
	'debug' => {
	  'verbosity' => $VERBOSITY,
	  'cleanup' => 1
	},
	'processors' => {
	  'main.tex.tx' => {
		'template' => {
			'filepath' => File::Spec->catfile($curdir, 'templates', 'simple02-included-templates', 'main.tex.tx')
		}
	  }
	} # end processors
});
ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called and got success.") or BAIL_OUT;

$outfile = File::Spec->catfile($tmpdir, 'xyz.pdf');
$ret = $latter->format({
	'template-data' => $template_data,
	'output' => {
		'filepath' => $outfile,
	},
	'processor' => 'main.tex.tx',
});
ok(defined($ret), 'format()'." : called and got good result.") or BAIL_OUT;
ok(-f $outfile, 'format()'." : called and output file ($outfile) exists.") or BAIL_OUT;

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing()
