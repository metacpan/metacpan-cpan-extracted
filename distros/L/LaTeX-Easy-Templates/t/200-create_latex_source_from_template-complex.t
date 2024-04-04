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
use File::Compare;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

use LaTeX::Easy::Templates;

my $VERBOSITY = 1;

my $log = Mojo::Log->new;

my $curdir = $FindBin::Bin;

# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./abc
my $tmpdir = File::Temp::tempdir(CLEANUP=>1); # will not be erased if env var is set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $tests = create_test_data();
ok(defined($tests), 'create_test_data()'." : called and got test data") or BAIL_OUT;
is(ref($tests), 'ARRAY', 'create_test_data()'." : called and got test data as an ARRAY") or BAIL_OUT;
ok(scalar(@$tests)>0, 'create_test_data()'." : called and got test data and it is not empty") or BAIL_OUT;

# this template data applies to all the tests' templates
my $template_data = {
	'title' => 'a test title',
	'authors' => [
	  {
		'name' => 'bozo',
		'surname' => 'johnson',
		'organisation' => 'nuthaus uk',
		'email' => 'bozo at circus.eu',
		'bio' => 'after extensive work in the circus, Bozo has moved up.',
		'picture' => 'sigai.png', # a filename which must be in the same dir
	  },
	  {
		'name' => 'Ali',
		'surname' => 'Bongo',
		'organisation' => 'Democratic Elections Corp',
		'email' => 'bongo at elysee',
		'bio' => 'inherited the democratic votes from his dadio and has been elected ever since.',
		'picture' => 'shakey.jpg', # a filename which must be in the same dir
	  },
	],
	'sections' => [
		{
			'title' => 'a section title 1',
			'label' => 'label:sec1',
			# paragraphs are placed before all the subsections
			'paragraphs' => [
						'section 1 paragraph 1',
						'section 1 paragraph 2',
			],
			'subsections' => [
				{
					'title' => 'a section 1 subsection title 1',
					'label' => 'label:sec1:subsec1',
					'paragraphs' => [
						'section 1, subsection 1 paragraph 1',
						'section 1, subsection 1 paragraph 2',
					],
				},
				{
					'title' => 'a section 1 subsection title 2',
					'label' => 'label:sec1:subsec2',
					'paragraphs' => [
						'section 1, subsection 2 paragraph 1',
						'section 1, subsection 2 paragraph 2',
					],
				},
				{
					'title' => 'a section 1, subsection title 3',
					'label' => 'label:sec1:subsec3',
					'paragraphs' => [
						'section 1, subsection 3 paragraph 1',
						'section 1, subsection 3 paragraph 2',
					],
				},
			],
		}, # end section 1
		{
			'subsections' => [
				{
					'title' => 'a section 2 subsection title 1',
					'label' => 'label:sec2:subsec1',
					'paragraphs' => [
						'section 2, subsection 1 paragraph 1',
						'section 2, subsection 1 paragraph 2',
					],
				},
				{
					'title' => 'a section 2 subsection title 2',
					'label' => 'label:sec2:subsec2',
					'paragraphs' => [
						'section 2, subsection 2 paragraph 1',
						'section 2, subsection 2 paragraph 2',
					],
				},
				{
					'title' => 'a section 2, subsection title 3',
					'label' => 'label:sec2:subsec3',
					'paragraphs' => [
						'section 2, subsection 3 paragraph 1',
						'section 2, subsection 3 paragraph 2',
					],
				},
			],
		}, # end section 2
	], # end sections
}; # end template_data

for my $atest (@$tests){
	my $result = $atest->{'result'};
	my $name = $atest->{'name'};

	my $latterparams = {
		'debug' => {
			'verbosity' => $VERBOSITY,
		},
		'log' => $log,
		%{ $atest->{'params'} }
	};
	my $latter = LaTeX::Easy::Templates->new($latterparams);
	if( $result =~ /^success/ ){
		ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called for test '$name' and got defined result.") or BAIL_OUT(perl2dump($latterparams)."no it failed for above parameters.");
	} else { 
		ok(!defined($latter), 'LaTeX::Easy::Templates->new()'." : called for test '$name' and got failure AS EXPECTED, all is good.") or BAIL_OUT("no it should have failed!");
		next;
	}

	my $templater = $latter->templater();
	ok(defined($templater), '_init_processors_data()'." : called for test '$name' with a set of filenames and got good result.") or BAIL_OUT;
	is(ref($templater), 'Text::Xslate', '_init_processors_data()'." : called for test '$name' with a set of filenames and got correct type of result back.") or BAIL_OUT;

	# all the processors
	my @td = map { [
		# processor name:
		$_,
		# template filepath:
		$atest->{'params'}->{'processors'}->{$_}->{'template'}->{'filepath'}
	] } sort keys %{ $atest->{'params'}->{'processors'} };
	my $idx = 0;
	for (@td){
		my ($aprocessorname, $tfname) = @$_;
		$idx++;
		my $template_basedir = defined($tfname) ? File::Basename::dirname($tfname) : undef;
		my $ret = $latter->untemplate({
			'processor' => $aprocessorname,
			'template-data' => $template_data
		});
		ok(defined($ret), 'untemplate()'." : called for test '$name', processor '$aprocessorname', and got good result.") or BAIL_OUT;
		is(ref($ret), 'HASH', 'untemplate()'." : called for test '$name', processor '$aprocessorname', and got a scalar back.") or BAIL_OUT;

		for my $al ('latex', 'template'){
			for my $ak ('basedir', 'filename', 'filepath'){
				ok(exists($ret->{$al}->{$ak}), 'untemplate()'." : called for test '$name', processor '$aprocessorname', and returned result contains key '$ak'.") or BAIL_OUT(perl2dump($ret)."no, above is what was returned.");
				is(ref($ret->{$al}->{$ak}), '', 'untemplate()'." : called for test '$name', processor '$aprocessorname', and returned result contains key '$ak' and it is a SCALAR.") or BAIL_OUT(perl2dump($ret)."no, above is what was returned.");
			}
			for my $ak ('basedir'){
				ok(-d $ret->{$al}->{$ak}, 'untemplate()'." : called for test '$name', processor '$aprocessorname', and returned output dir (".$ret->{$al}->{$ak}.") is a dir.") or BAIL_OUT;
			}
			for my $ak ('filepath'){
				ok(-f $ret->{$al}->{$ak}, 'untemplate()'." : called for test '$name', processor '$aprocessorname', and returned latex output file (".$ret->{$al}->{$ak}.") is a filepath and it exists.") or BAIL_OUT;
			}
		}
		my $lfname = $ret->{'latex'}->{'filepath'};
		my ($FH, $latexsrcstr);
		ok(open($FH, '<', $lfname), 'untemplate()'." : opening output latex source file ($lfname) for reading.") or BAIL_OUT("no it failed: $!");
		{ local $/ = undef; $latexsrcstr = <$FH> } close $FH;
		ok($latexsrcstr !~ /<\:.+?\:>/, 'untemplate()'." : called and latex src string returned back does not look to contain templated var remains.") or BAIL_OUT("${latexsrcstr}\n\nno see above latex content returned");

		if( defined $template_basedir ){
			# only for on-disk tests
			# we have an main.tex.expected_output file in the templates dir
			# compare its content with returned
			my $latexsrcf = $ret->{'latex'}->{'filepath'};
			ok(-f $latexsrcf, 'untemplate()'." : called for test '$name', processor '$aprocessorname', compare1 file ($latexsrcf) exists.") or BAIL_OUT;

			my $template_main_basename = File::Basename::basename($template_basedir, '.tx');
			my $expectedf = $lfname . '.expected_output';
			ok(-f $expectedf, 'untemplate()'." : called for test '$name', processor '$aprocessorname', compare2 file ($expectedf) exists.") or BAIL_OUT;
			is(File::Compare::compare($latexsrcf, $expectedf), 0, 'untemplate()'." : called for test '$name', processor '$aprocessorname', and latex output file ($latexsrcf) is exactly the same as the expected output ($expectedf).") or BAIL_OUT;
		}
	}
}

# returns an array of tests to do
sub create_test_data {
	# the following controls all the tests, one test is one array item
	# if params->processors->template->content exists (but undef)
	# and also params->processors->template->filepath exists (and defined)
	# then the 'filepath' will be read into a string,
	# filename will be erased and 'content' added.
	my @tests = (
	  {
		# specify templates as real, existing filenames (key), value is undef
		'result' => 'success',
		'name' => 'test1',
		'params' => {
		  'processors' => {
			# 2 on disk
			'simple20-in-memory' => {
			   'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				'filepath' => File::Spec->catfile($curdir, 'templates', 'simple20', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catfile($curdir, 'templates', 'simple20', 'main.tex.expected_output') ],
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
			'complex-on-disk' => {
			  'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				'filepath' => File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files', 'main.tex.expected_output') ],
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
			'complex-on-disk-with-included-templates' => {
			  'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				'filepath' => File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files-with-included-templates', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files-with-included-templates', 'main.tex.expected_output') ],
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
		  },
		},
	  },
	  {
		# specify templates as real, existing filenames (key), value is undef
		'result' => 'success',
		'name' => 'test2',
		'params' => {
		  'processors' => {
			# 1 in memory string
			'simple20-in-memory' => {
			   'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				# content will be read from file and set and filename will be deleted
				'filepath' => File::Spec->catfile($curdir, 'templates', 'simple20', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catfile($curdir, 'templates', 'simple20', 'main.tex.expected_output') ],
				'content' => undef,
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
		  },
		},
	  },
	  {
		'result' => 'success',
		'name' => 'test3',
		'params' => {
		  'processors' => {
			# 1 in memory string and 1 on disk
			'simple20-in-memory' => {
			   'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				# content will be read from file and set and filename will be deleted
				'filepath' => File::Spec->catfile($curdir, 'templates', 'simple20', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catfile($curdir, 'templates', 'simple20', 'main.tex.expected_output') ],
				'content' => undef,
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
			'complex-on-disk' => {
			  'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				# content will be read from file and set and filename will be deleted
				'filepath' => File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files', 'main.tex.expected_output') ],
				'content' => undef,
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
			'complex-on-disk-with-included-templates' => {
			  'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				'filepath' => File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files-with-included-templates', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files-with-included-templates', 'main.tex.expected_output') ],
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
		  },
		},
	  },
	  {
		# this must fail
		'result' => 'fail',
		'name' => 'test5',
		'params' => {},
	  },
	);

	# create the in-memory strings
	for my $atest (@tests){
		if( exists($atest->{'params'}->{'processors'}) && defined($atest->{'params'}->{'processors'})
		 && exists($atest->{'params'}->{'processors'}->{'template'}) && defined($atest->{'params'}->{'processors'}->{'template'})
		 && exists($atest->{'params'}->{'processors'}->{'template'}->{'content'})
		 && ! defined($atest->{'params'}->{'processors'}->{'template'}->{'content'})
		 && exists($atest->{'params'}->{'processors'}->{'template'}->{'filepath'})
		 && defined($atest->{'params'}->{'processors'}->{'template'}->{'filepath'})
		){
			# read file into content
			my $FH;
			ok(open($FH, '<:utf8', $atest->{'params'}->{'processors'}->{'template'}->{'filepath'}), "Opened template file '".$atest->{'params'}->{'processors'}->{'template'}->{'filepath'}."' for reading.") or BAIL_OUT("no: $!");
			{ local $/ = undef; $atest->{'params'}->{'processors'}->{'template'}->{'content'} = <$FH> } close $FH;
			delete $atest->{'params'}->{'processors'}->{'template'}->{'filepath'};
		}
	}

	return \@tests
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
done_testing()
