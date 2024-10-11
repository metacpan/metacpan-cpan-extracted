#!/usr/bin/env perl

###################################################################
#### NOTE env-var TEMP_DIRS_KEEP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use lib 'blib/lib';

use utf8;

our $VERSION = '1.01';

use Test::More;
use Test::More::UTF8;
use Mojo::Log;
use FindBin;
use File::Temp 'tempdir';
use File::Compare;

use Data::Roundtrip qw/perl2dump perl2json json2perl jsonfile2perl no-unicode-escape-permanently/;

use LaTeX::Easy::Templates;

my $VERBOSITY = 1;

my $log = Mojo::Log->new;

my $curdir = $FindBin::Bin;

# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = File::Temp::tempdir(CLEANUP=>1); # will not be erased if env var is set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $template_dir = File::Spec->catdir($curdir, 'templates', 'simple05');
my $template_filename = File::Spec->catfile($template_dir, 'main.tex.tx');
my $expected_latex_output_filename = $template_filename; $expected_latex_output_filename =~ s/\.tx$/.expected_output/;
# let's see if myfunc() defined in perl will be supported in the template
my $template_string = ': perl2json($data);';

my $template_data = {"aηήή"=>"αβγ"};

my $latterparams = {
	'debug' => {
		'verbosity' => $VERBOSITY,
	},
	'log' => $log,
	'templater-parameters' => {
		'function' => {
			'myfunc' => \& myfunc,
		},
		'module' => [
			'File::Basename' => [],
			'Data::Roundtrip' => ['perl2dump', 'perl2json', 'json2perl', 'jsonfile2perl', 'no-unicode-escape-permanently'],
		],
	},
	'processors' => {
		# 1 in memory string
		'test-module' => {
		   'latex' => {
			# untemplate the in-memory template into this latex source file:
			'basedir' => File::Spec->catdir($tmpdir, 'adir'),
			# this must end in .tex
			'filename' => 'aaa.tex',
		   },
		   'template' => {
			'content' => $template_string,
			'auxfiles' => [ $template_dir ],
		   },
		   'output' => {
			#'filename' => File::Spec->catfile($tempdir, 'inmemory.pdf'),
			'basedir' => File::Spec->catdir($tmpdir, 'tmp', 'aaa'),
			'filename' => 'inmemory.pdf',
		   },
		},
	},
};
my $latter = LaTeX::Easy::Templates->new($latterparams);
ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called and got good result.") or BAIL_OUT;

for my $aprocessorname ('test-module'){
	my $processor_data = $latterparams->{'processors'}->{$aprocessorname};
	my $untemplate_ret = $latter->untemplate({
		'processor' => $aprocessorname,
		'template-data' => $template_data
	});
	ok(defined($untemplate_ret), 'untemplate()'." : called for processor '$aprocessorname', and got good result.") or BAIL_OUT;
	is(ref($untemplate_ret), 'HASH', 'untemplate()'." : called for processor '$aprocessorname', and got a scalar back.") or BAIL_OUT;

	for my $ak ('template', 'latex'){
		ok(exists($untemplate_ret->{$ak}), 'untemplate()'." : called for processor '$aprocessorname', and returned result contains key '$ak'.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
		is(ref($untemplate_ret->{$ak}), 'HASH', 'untemplate()'." : called for processor '$aprocessorname', and returned result contains key '$ak' and it is a SCALAR.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
	}

	for my $ak ('filename', 'filepath', 'basedir'){
		ok(exists($untemplate_ret->{'latex'}->{$ak}), 'untemplate()'." : called for processor '$aprocessorname', and returned result contains key 'latex'->'$ak'.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
		is(ref($untemplate_ret->{'latex'}->{$ak}), '', 'untemplate()'." : called for processor '$aprocessorname', and returned result contains key 'latex'->'$ak' and it is a SCALAR.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
		ok($untemplate_ret->{'latex'}->{$ak} !~ /^\s*$/, 'untemplate()'." : called for processor '$aprocessorname', and returned result contains key 'latex'->'$ak' and it is a SCALAR and it is not empty.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
	}

	ok(-d $untemplate_ret->{'latex'}->{'basedir'}, 'untemplate()'." : called for processor '$aprocessorname', and returned output dir (".$untemplate_ret->{'latex'}->{'basedir'}.") is a dir.") or BAIL_OUT;
	ok(-f $untemplate_ret->{'latex'}->{'filepath'}, 'untemplate()'." : called for processor '$aprocessorname', and returned latex output file (".$untemplate_ret->{'latex'}->{'filepath'}.") is a filepath and it exists.") or BAIL_OUT;
	# open the latex source and check if there any templated vars
	my ($FH, $content);
	ok(open($FH, '<:encoding(utf-8)', $untemplate_ret->{'latex'}->{'filepath'}), "Output latex source '".$untemplate_ret->{'latex'}->{'filepath'}."' opened for reading.") or BAIL_OUT("failed: $!");
	{ local $/ = undef; $content = <$FH> } close $FH;
	ok($content !~ /<\:.+?\:>/, 'untemplate()'." : called for processor '$aprocessorname', and latex source (content of file '".$untemplate_ret->{'latex'}->{'filepath'}."') does not look to contain templated var remains.") or BAIL_OUT($content."\n\nno see above latex source content.");

	my $expected = perl2json($template_data, {terse=>1});
	is($content, $expected, 'untemplate()'." : called for processor '$aprocessorname', and latex source (content of file '".$untemplate_ret->{'latex'}->{'filepath'}."') contains what is expected '${expected}'.") or BAIL_OUT("no it contains '$content'.");

	if( $aprocessorname =~ /on-disk/ ){
		# only for on-disk tests
		# we have an main.tex.expected_output file in the templates dir
		# compare its content with returned
		my $latexsrcf = $untemplate_ret->{'latex'}->{'filepath'};
		ok(-f $latexsrcf, 'untemplate()'." : called for processor '$aprocessorname', compare1 file ($latexsrcf) exists.") or BAIL_OUT;
		ok(-f $expected_latex_output_filename, 'untemplate()'." : called for processor '$aprocessorname', compare2 file ($expected_latex_output_filename) exists.") or BAIL_OUT;
		is(File::Compare::compare($latexsrcf, $expected_latex_output_filename), 0, 'untemplate()'." : called for processor '$aprocessorname', and latex output file ($latexsrcf) is exactly the same as the expected output ($expected_latex_output_filename).") or BAIL_OUT;
	}
}

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
done_testing();

sub myfunc { return "BINGO:".$_[0]->{'aηήή'} }
