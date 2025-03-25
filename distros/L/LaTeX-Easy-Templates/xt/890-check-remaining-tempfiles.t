#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

# NOTE: what we are trying to test here is whether we have remaining temp files/dirs
# after running the pipeline successfully and un-successfully
# the tempdir should disappear on >>program exit<< which we need to simulate
# so we run the test in a system(). We can't do it in an eval $prog because
# it keeps only one state for done_testing()!
# So, 1) count tmp files if any, 2) system($prog), 3) count tmp files if any and compare.

use strict;
use warnings;

our $VERSION = '1.03';

use Test::More;
use Test::More::UTF8;
use File::Find::Rule;
use Capture::Tiny qw/capture/;

my $erase_tmp_prog =<<'EOEV';
use Test::TempDir::Tiny;
my $tmpdir = tempdir('xx');
EOEV

my $prog =<<'EOEV';
use strict;
use warnings;

use lib 'blib/lib';

our $VERSION = '1.03';

use Test::More;
use Test::More::UTF8;
use Mojo::Log;
use FindBin;
use Test::TempDir::Tiny;
use File::Compare;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

use LaTeX::Easy::Templates;

my $VERBOSITY = 100;

my $log = Mojo::Log->new;

my $curdir = $FindBin::Bin;

# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir($$); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $template_dir = File::Spec->catdir($curdir, 't', 'templates', 'simple05');
my $template_filename = File::Spec->catfile($template_dir, 'main.tex.tx');
my $expected_latex_output_filename = $template_filename; $expected_latex_output_filename =~ s/\.tx$/.expected_output/;
my ($template_string, $FH);
ok(open($FH, '<:encoding(utf-8)', $template_filename), "template filename '$template_filename' opened for reading.") or BAIL_OUT("not it failed with $!");
{ local $/ = undef; $template_string = <$FH> } close $FH;

my $template_data = {
	'title' => 'there are 3 articles here!',
	'articles' => [
		{
			'author' => 'author1',
			'title' => 'title1',
			'content' => 'content1',
		},
		{
			'author' => 'author2',
			'title' => 'title2',
			'content' => 'content2',
		},
		{
			'author' => 'author3',
			'title' => 'title3',
			'content' => 'content3',
		},
	]
};

my $latterparams = {
	'debug' => {
		'verbosity' => $VERBOSITY,
	},
	'log' => $log,
	'processors' => {
		'simple05-in-memory' => {
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
		'simple05-on-disk' => {
		   'latex' => {
			'filename' => undef, # create tmp
		   },
		   'template' => {
			'basedir' => $template_dir,
			'filename' => File::Basename::basename($template_filename),
			'auxfiles' => [ $template_dir ],
		   },
		   'output' => {
			'basedir' => File::Spec->catdir($tmpdir, 'tmp', 'bbb'),
			'filename' => 'ondisk.pdf',
		   },
		},
	},
};

my $latter = LaTeX::Easy::Templates->new($latterparams);
ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called and got good result.") or BAIL_OUT;

for my $aprocessorname (sort keys %{$latterparams->{'processors'}}){
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

	if( $aprocessorname =~ /on-disk/ ){
		# only for on-disk tests
		# we have an main.tex.expected_output file in the templates dir
		# compare its content with returned
		my $latexsrcf = $untemplate_ret->{'latex'}->{'filepath'};
		ok(-f $latexsrcf, 'untemplate()'." : called for processor '$aprocessorname', compare1 file ($latexsrcf) exists.") or BAIL_OUT;
		ok(-f $expected_latex_output_filename, 'untemplate()'." : called for processor '$aprocessorname', compare2 file ($expected_latex_output_filename) exists.") or BAIL_OUT;
		is(File::Compare::compare($latexsrcf, $expected_latex_output_filename), 0, 'untemplate()'." : called for processor '$aprocessorname', and latex output file ($latexsrcf) is exactly the same as the expected output ($expected_latex_output_filename).") or BAIL_OUT;
	}

	# format
	my $format_ret = $latter->format({
		'template-data' => $template_data,
		'processor' => $aprocessorname
	});
	ok(defined($format_ret), 'format()'." : called for processor '$aprocessorname' and got good results.") or BAIL_OUT;
	my $outfile = exists($processor_data->{'output'}) && exists($processor_data->{'output'}->{'filepath'}) && defined($processor_data->{'output'}->{'filepath'})
		? $processor_data->{'output'}->{'filepath'} : undef
	;
	if( defined $outfile ){
		ok(-f $outfile, "ouput PDF file exists '$outfile'") or BAIL_OUT;
	}
}

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;
# make me bomb: BAIL_OUT("bombing be design");
done_testing();
EOEV

# WARNING: we need to capture the output from the system()'s
# executing perl test code because it messes the TAP output
# and make test gets confused.
# so use Capture::Tiny

my ($tmpfiles_at_start, $tmpfiles_at_end);

# first erase any tmp dir
capture { system($^X, '-e', $erase_tmp_prog); };
is($?, 0, "system command OK, any tmp dir was erased for a fresh start.") or BAIL_OUT("system command has failed, your logic is faulty. report this.");
# no tmp dir should now exist

$tmpfiles_at_start = scalar @{ [ File::Find::Rule->name("*")->in("tmp") ]};
  # run the above program:
  capture { system($^X, '-e', $prog); };
  is($?, 0, "system command OK.") or BAIL_OUT("system command has failed, your logic is faulty. report this.");
  # no tmp dir should now exist
$tmpfiles_at_end = scalar @{ [ File::Find::Rule->name("*")->in("tmp") ]};
is($tmpfiles_at_start, $tmpfiles_at_end, "there are no remaining temp files in ./tmp, before $tmpfiles_at_start, after $tmpfiles_at_end.") or BAIL_OUT("no the number of temp files is not the same as when we started, there is a temp files leak in dir ./tmp. Any temp files created should have been erased because the test succeeded.");

# NOW, run the above program but make it bomb
$prog =~ s/# make me bomb: //;

# and repeat
$tmpfiles_at_start = scalar @{ [ File::Find::Rule->name("*")->in("tmp") ]};
  # run the above program:
  capture { system($^X, '-e', $prog); };
  ok($?!=0, "system command bombed OK as expected.") or BAIL_OUT("system command has not failed, your logic is faulty. report this.");
$tmpfiles_at_end = scalar @{ [ File::Find::Rule->name("*")->in("tmp") ]};
ok($tmpfiles_at_start < $tmpfiles_at_end, "there are remaining temp files in ./tmp, before $tmpfiles_at_start, after $tmpfiles_at_end.") or BAIL_OUT("no the number of temp files is the same, it seems temp files are not kept when test bails out.");

# at this stage there is tmp dir, erase it.
capture { system($^X, '-e', $erase_tmp_prog); };
is($?, 0, "system command OK, any tmp dir was erased for a fresh start.") or BAIL_OUT("system command has failed, your logic is faulty. report this.");
# no tmp dir should now exist

# and now there is no tmp.

done_testing;
