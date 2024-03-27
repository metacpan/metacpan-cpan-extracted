#!/usr/bin/env perl

use strict;
use warnings;

use lib 'blib/lib';

#use utf8;

our $VERSION = '0.04';

use Test::More;
use Test::More::UTF8;
use Mojo::Log;
use FindBin;
use File::Temp 'tempdir';
use File::Compare;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

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
my ($template_string, $FH);
ok(open($FH, '<', $template_filename), "template filename '$template_filename' opened for reading.") or BAIL_OUT("not it failed with $!");
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
		# 1 in memory string
		'simple05-in-memory' => {
		   'latex' => {
			# untemplate the in-memory template into this latex source file:
			'basedir' => '/tmp/fuck',
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
		# 1 in memory string
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
$latter->max_size_for_filecopy(1);
ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called and got good result.") or BAIL_OUT;

for my $aprocessorname (sort keys %{$latterparams->{'processors'}}){
	my $processor_data = $latterparams->{'processors'}->{$aprocessorname};
	my $create_ret = $latter->untemplate({
		'processor' => $aprocessorname,
		'template-data' => $template_data
	});
	ok(! defined($create_ret), 'untemplate()'." : called for processor '$aprocessorname', and got good result.") or BAIL_OUT;
}

# END
done_testing()
