#!/usr/bin/env perl

###################################################################
#### NOTE env-var TEMP_DIRS_KEEP=1 will stop erasing tmp files
###################################################################

###################################################################
#### WARNING: this specific test can fail if
#### required latex style files or fonts are missing.
#### That is why it lives in the author-tests-only section.
#### It must succeed once you install all prerequisitives.
#### Please report any issues because I had the chance to
#### run this only on my systems.
###################################################################

###################################################################
# Run me with
#   perl Makefile.PL && make all && make authortest
# or
#   prove -bl xt/810-format-complex.t 
###################################################################

use strict;
use warnings;

use lib 'blib/lib';

use utf8; # we have hardcoded unicode strings

our $VERSION = '1.01';

use Test::More;
use Test::More::UTF8;
use Mojo::Log;
use FindBin;
use File::Temp 'tempdir';
use File::Basename;
use File::Spec;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

use LaTeX::Easy::Templates;

my $VERBOSITY = 1;

my $log = Mojo::Log->new;

my $curdir = $FindBin::Bin;

# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./defecat
my $tmpdir = File::Temp::tempdir(CLEANUP=>1); # will not be erased if env var is set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $tests = create_test_data();
ok(defined($tests), 'create_test_data()'." : called and got test data") or BAIL_OUT;
is(ref($tests), 'ARRAY', 'create_test_data()'." : called and got test data as an ARRAY") or BAIL_OUT;
ok(scalar(@$tests)>0, 'create_test_data()'." : called and got test data and it is not empty") or BAIL_OUT;

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
};

my $template_data_unicode = {
	'title' => 'Ένας Τίτλος για το πείραμα μας',
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
			'title' => 'Ένα κεφάλαιο στο σύγγραμμα μας',
			'label' => 'label:sec1',
			# paragraphs are placed before all the subsections
			'paragraphs' => [
						'section 1 paragraph 1',
						'section 1 παράγραφος 2',
			],
			'subsections' => [
				{
					'title' => 'a section 1 υποκεφάλαιο title 1',
					'label' => 'label:sec1:subsec1',
					'paragraphs' => [
						'section 1, υποκεφάλαιο 1 paragraph 1',
						'section 1, υποκεφάλαιο 1 paragraph 2',
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
					'title' => 'a section 1, υποκεφάλαιο title 3',
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
};

####################################################
# firstly, do produce-latex and then format explicitly
####################################################
for my $atest (@$tests){
	my $result = $atest->{'result'};
	my $is_unicode = exists($atest->{'unicode'}) && defined($atest->{'unicode'}) && $atest->{'unicode'}=~/^y(?:es)?$/i;
	my $pars = $atest->{'params'};
	my $name = $atest->{'name'};

	my $latter = LaTeX::Easy::Templates->new({
		'debug' => {
			'verbosity' => $VERBOSITY,
		},
		%$pars
	});
	if( $result =~ /^success/ ){
		ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called for test '${name}' and got success.") or BAIL_OUT;
	} else {
		ok(!defined($latter), 'LaTeX::Easy::Templates->new()'." : called for test '${name}' and got failure (as it was expected, all good).") or BAIL_OUT;
		next;
	}

	# now see if template was loaded
	my $loaded = $latter->loaded_info();
	ok(defined($loaded), 'loaded_info()'." : called for test '${name}' and got good result.") or BAIL_OUT;
	is(ref($loaded), 'HASH', 'loaded_info()'." : called for test '${name}' and got good result which is a HASH.") or BAIL_OUT;

	my $templater = $latter->templater();
	ok(defined($templater), '_init_processors_data()'." : called for test '$name' with a set of filenames and got good result.") or BAIL_OUT;
	is(ref($templater), 'Text::Xslate', '_init_processors_data()'." : called for test '$name' with a set of filenames and got correct type of result back.") or BAIL_OUT;

	my $fd = $atest->{'params'}->{'processors'};
	for my $ak (sort keys %$fd){ # $ak is like 'simple20-in-memory'
		my $subfd = $fd->{$ak};
		ok(exists($loaded->{$ak}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result contains key '$ak'.") or BAIL_OUT(perl2dump($loaded)."no, see above data.");
		ok(defined($loaded->{$ak}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result contains key '$ak' and it is defined.") or BAIL_OUT(perl2dump($loaded)."no, see above data.");
		my $subloaded = $loaded->{$ak};
		for my $entry ('template', 'latex', 'output'){
			ok(exists($subloaded->{$entry}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result contains key '$entry'.") or BAIL_OUT(perl2dump($subloaded)."no, see above data.");
			ok(defined($subloaded->{$entry}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result contains key '$entry' and it is defined.") or BAIL_OUT(perl2dump($subloaded)."no, see above data.");
			my $entryval = $subloaded->{$entry};
			for my $af ('basedir', 'filename', 'filepath'){
				ok(exists($entryval->{$af}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result under key '$ak'->'$entry' contains key '$af'.") or BAIL_OUT(perl2dump($entryval)."no, see above data.");
			}
			for my $af ('filename'){
				# some are in memory, so this will be undef
				#ok(defined($entryval->{$af}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result under key '$ak'->'$entry' contains key '$af' and it is defined.") or BAIL_OUT(perl2dump($entryval)."no, see above data.");
				if( exists($subfd->{$entry}->{$af}) && defined($subfd->{$entry}->{$af}) ){
					is($entryval->{$af}, $subfd->{$entry}->{$af}, 'loaded_info()'." : called for test '${name}', processor '${ak}', and result under key '$ak' contains key '$af' (".$entryval->{$af}.") and it is the same as that in the parameters used to create it (".$subfd->{$entry}->{$af}.").") or BAIL_OUT(perl2dump($entryval)."no, see above data.");
				}
			}
		}
	}

	my @td = map { [
		$_,
		$atest->{'params'}->{'processors'}->{$_}->{'template'}->{'filepath'},
		$atest->{'params'}->{'processors'}->{$_},
	] } sort keys %{ $atest->{'params'}->{'processors'} };
	my $idx = 0;
	for my $atd (@td){
		my ($processor_name, $tfname, $tdata) = @$atd;
		$idx++;

		# first call the produce-latex and check its results
		my $template_basedir = defined($tfname) ? File::Basename::dirname($tfname) : undef;
		my $untemplate_ret = $latter->untemplate({
			'processor' => $processor_name,
			'template-data' => $template_data
		});
		ok(defined($untemplate_ret), 'untemplate()'." : called for test '$name' and got good result.") or BAIL_OUT;
		is(ref($untemplate_ret), 'HASH', 'untemplate()'." : called for test '$name' and got a scalar back.") or BAIL_OUT;

		for my $al ('latex', 'template'){
			for my $ak ('basedir', 'filename', 'filepath'){
				ok(exists($untemplate_ret->{$al}->{$ak}), 'untemplate()'." : called for test '$name', processor '$processor_name', and returned result contains key '$ak'.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
				is(ref($untemplate_ret->{$al}->{$ak}), '', 'untemplate()'." : called for test '$name', processor '$processor_name', and returned result contains key '$ak' and it is a SCALAR.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
			}
			for my $ak ('basedir'){
				ok(-d $untemplate_ret->{$al}->{$ak}, 'untemplate()'." : called for test '$name', processor '$processor_name', and returned output dir (".$untemplate_ret->{$al}->{$ak}.") is a dir.") or BAIL_OUT;
			}
			for my $ak ('filepath'){
				ok(-f $untemplate_ret->{$al}->{$ak}, 'untemplate()'." : called for test '$name', processor '$processor_name', and returned latex output file (".$untemplate_ret->{$al}->{$ak}.") is a filepath and it exists.") or BAIL_OUT;
			}
		}
		my $lfname = $untemplate_ret->{'latex'}->{'filepath'};

		if( defined $template_basedir ){
			# only for on-disk tests
			# we have an main.tex.expected_output file in the templates dir
			# compare its content with returned
			my $latexsrcf = $untemplate_ret->{'latex'}->{'filepath'};
			ok(-f $latexsrcf, 'untemplate()'." : called for test '$name', processor '$processor_name', compare1 file ($latexsrcf) exists.") or BAIL_OUT;

			my $template_main_basename = File::Basename::basename($template_basedir, '.tx');
			my $expectedf = $lfname . '.expected_output';
			ok(-f $expectedf, 'untemplate()'." : called for test '$name', processor '$processor_name', compare2 file ($expectedf) exists.") or BAIL_OUT;
			is(File::Compare::compare($latexsrcf, $expectedf), 0, 'untemplate()'." : called for test '$name', processor '$processor_name', and latex output file ($latexsrcf) is exactly the same as the expected output ($expectedf).") or BAIL_OUT;
		}

		my $LI = $latter->loaded_info();
		ok(defined($LI), "Loaded info exists in object") or BAIL_OUT;
		ok(exists($LI->{$processor_name}), "Loaded info contains processor '$processor_name'.") or BAIL_OUT;
		ok(defined($LI->{$processor_name}), "Loaded info contains processor '$processor_name' and it is defined.") or BAIL_OUT;
		ok(exists($LI->{$processor_name}->{'latex'}), "Loaded info contains processor '$processor_name', section 'latex'.") or BAIL_OUT;
		ok(defined($LI->{$processor_name}->{'latex'}), "Loaded info contains processor '$processor_name', section 'latex', and it is defined.") or BAIL_OUT;
		ok(exists($LI->{$processor_name}->{'latex'}->{'latex-driver-parameters'}), "Loaded info contains processor '$processor_name', section 'latex', item 'latex-driver-parameters'.") or BAIL_OUT;
		ok(defined($LI->{$processor_name}->{'latex'}->{'latex-driver-parameters'}), "Loaded info contains processor '$processor_name', section 'latex', item 'latex-driver-parameters', and it is defined.") or BAIL_OUT;
		my $latex_driver_parameters = $latter->processors()->{$processor_name}->{'latex'}->{'latex-driver-parameters'};

		my $outfile = File::Spec->catfile($tmpdir, 'main.pdf');
		my $format_ret = $latter->format({
			'latex-driver-parameters' => $latex_driver_parameters,
			%$untemplate_ret,
			'output' => {
				'filepath' => $outfile,
			},
			'processor' => $processor_name,
		});
		ok(defined($format_ret), 'format()'." : called for test '$name', processor '$processor_name' and got good result for '$tfname'.") or BAIL_OUT;

		for my $al ('latex', 'template'){
			for my $ak ('basedir', 'filename', 'filepath'){
				ok(exists($format_ret->{$al}->{$ak}), 'format()'." : called for test '$name', processor '$processor_name', and returned result contains key '$ak'.") or BAIL_OUT(perl2dump($format_ret)."no, above is what was returned.");
				is(ref($format_ret->{$al}->{$ak}), '', 'format()'." : called for test '$name', processor '$processor_name', and returned result contains key '$ak' and it is a SCALAR.") or BAIL_OUT(perl2dump($format_ret)."no, above is what was returned.");
			}
			for my $ak ('basedir'){
				ok(-d $format_ret->{$al}->{$ak}, 'format()'." : called for test '$name', processor '$processor_name', and returned output dir (".$format_ret->{$al}->{$ak}.") is a dir.") or BAIL_OUT;
			}
			for my $ak ('filepath'){
				ok(-f $format_ret->{$al}->{$ak}, 'format()'." : called for test '$name', processor '$processor_name', and returned latex output file (".$format_ret->{$al}->{$ak}.") is a filepath and it exists.") or BAIL_OUT;
			}
		}

		is($format_ret->{'latex'}->{'basedir'}, $untemplate_ret->{'latex'}->{'basedir'}, 'format()'." : returned output dir (".$format_ret->{'latex'}->{'basedir'}.") is the same as the one specified when called (".$untemplate_ret->{'latex'}->{'basedir'}.").") or BAIL_OUT;
		ok(-d $format_ret->{'latex'}->{'basedir'}, 'format()'." : returned output dir (".$format_ret->{'latex'}->{'basedir'}.") is a dir.") or BAIL_OUT;
		ok(-f $format_ret->{'latex'}->{'filepath'}, 'format()'." : returned latex output file (".$format_ret->{'latex'}->{'filepath'}.") is a filepath and it exists.") or BAIL_OUT;
		# open the latex source and check if there any templated vars
		my ($FH, $content);
		ok(open($FH, '<encoding(utf-8)', $format_ret->{'latex'}->{'filepath'}), 'format()'." : returned latex source '".$format_ret->{'latex'}->{'filepath'}."' opened for reading.") or BAIL_OUT("failed: $!");
		{ local $/ = undef; $content = <$FH> } close $FH;
		ok($content !~ /<\:.+?\:>/, 'format()'." : called for test '$name', processor '$processor_name', and latex source (content of file '".$format_ret->{'latex'}->{'filepath'}."') does not look to contain templated var remains.") or BAIL_OUT($content."\n\nno see above latex source content.");

		ok(-f $outfile, 'format()'." : called and output file '$outfile' exists.") or BAIL_OUT;
		ok(-d $untemplate_ret->{'latex'}->{'basedir'}, 'format()'." : called and output dir '".$untemplate_ret->{'latex'}->{'basedir'}."' exists.") or BAIL_OUT;
		for my $auxext ('.log', '.aux'){
			my $afi = File::Spec->catfile($untemplate_ret->{'latex'}->{'basedir'}, 'main' . $auxext);
			ok(-f $afi, 'format()'." : called and aux output file '$afi' exists.") or BAIL_OUT;
		}
	}
}

####################################################
# secondly, do a format and let it do produce-latex internally
####################################################
for my $atest (@$tests){
	my $result = $atest->{'result'};
	my $is_unicode = exists($atest->{'unicode'}) && defined($atest->{'unicode'}) && $atest->{'unicode'}=~/^y(?:es)?$/i;
	my $pars = $atest->{'params'};
	my $name = $atest->{'name'};

	my $latter = LaTeX::Easy::Templates->new({
		'debug' => {
			'verbosity' => $VERBOSITY,
		},
		%$pars
	});
	if( $result =~ /^success/ ){
		ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called for test '${name}' and got success.") or BAIL_OUT;
	} else {
		ok(!defined($latter), 'LaTeX::Easy::Templates->new()'." : called for test '${name}' and got failure (as it was expected, all good).") or BAIL_OUT;
		next;
	}

	# now see if template was loaded
	my $loaded = $latter->loaded_info();
	ok(defined($loaded), 'loaded_info()'." : called for test '${name}' and got good result.") or BAIL_OUT;
	is(ref($loaded), 'HASH', 'loaded_info()'." : called for test '${name}' and got good result which is a HASH.") or BAIL_OUT;

	my $templater = $latter->templater();
	ok(defined($templater), '_init_processors_data()'." : called for test '$name' with a set of filenames and got good result.") or BAIL_OUT;
	is(ref($templater), 'Text::Xslate', '_init_processors_data()'." : called for test '$name' with a set of filenames and got correct type of result back.") or BAIL_OUT;

	my $fd = $atest->{'params'}->{'processors'};
	for my $ak (sort keys %$fd){ # $ak is like 'simple20-in-memory'
		my $subfd = $fd->{$ak};
		ok(exists($loaded->{$ak}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result contains key '$ak'.") or BAIL_OUT(perl2dump($loaded)."no, see above data.");
		ok(defined($loaded->{$ak}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result contains key '$ak' and it is defined.") or BAIL_OUT(perl2dump($loaded)."no, see above data.");
		my $subloaded = $loaded->{$ak};
		for my $entry ('template', 'latex', 'output'){
			ok(exists($subloaded->{$entry}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result contains key '$entry'.") or BAIL_OUT(perl2dump($subloaded)."no, see above data.");
			ok(defined($subloaded->{$entry}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result contains key '$entry' and it is defined.") or BAIL_OUT(perl2dump($subloaded)."no, see above data.");
			my $entryval = $subloaded->{$entry};
			for my $af ('basedir', 'filename', 'filepath'){
				ok(exists($entryval->{$af}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result under key '$ak'->'$entry' contains key '$af'.") or BAIL_OUT(perl2dump($entryval)."no, see above data.");
			}
			for my $af ('filename'){
				# some are in memory, so this will be undef
				#ok(defined($entryval->{$af}), 'loaded_info()'." : called for test '${name}', processor '${ak}', and result under key '$ak'->'$entry' contains key '$af' and it is defined.") or BAIL_OUT(perl2dump($entryval)."no, see above data.");
				if( exists($subfd->{$entry}->{$af}) && defined($subfd->{$entry}->{$af}) ){
					is($entryval->{$af}, $subfd->{$entry}->{$af}, 'loaded_info()'." : called for test '${name}', processor '${ak}', and result under key '$ak' contains key '$af' (".$entryval->{$af}.") and it is the same as that in the parameters used to create it (".$subfd->{$entry}->{$af}.").") or BAIL_OUT(perl2dump($entryval)."no, see above data.");
				}
			}
		}
	}

	my @td = map { [
		$_,
		$atest->{'params'}->{'processors'}->{$_}->{'template'}->{'filepath'},
		$atest->{'params'}->{'processors'}->{$_},
	] } sort keys %{ $atest->{'params'}->{'processors'} };
	my $idx = 0;
	for my $atd (@td){
		my ($processor_name, $tfname, $tdata) = @$atd;
		$idx++;

		my $template_basedir = defined($tfname) ? File::Basename::dirname($tfname) : undef;

		# Do the format
		my $outfile = File::Spec->catfile($tmpdir, 'main.pdf');
		unlink $outfile;
		$tmpdir = File::Temp::tempdir(CLEANUP=>1);
		ok(-d $tmpdir, "output dir exists ($tmpdir)");
		my $latex_src_outdir = File::Spec->catdir($tmpdir, 'latex-src');

		my $LI = $latter->loaded_info();
		ok(defined($LI), "Loaded info exists in object") or BAIL_OUT;
		ok(exists($LI->{$processor_name}), "Loaded info contains processor '$processor_name'.") or BAIL_OUT;
		ok(defined($LI->{$processor_name}), "Loaded info contains processor '$processor_name' and it is defined.") or BAIL_OUT;
		ok(exists($LI->{$processor_name}->{'latex'}), "Loaded info contains processor '$processor_name', section 'latex'.") or BAIL_OUT;
		ok(defined($LI->{$processor_name}->{'latex'}), "Loaded info contains processor '$processor_name', section 'latex', and it is defined.") or BAIL_OUT;
		ok(exists($LI->{$processor_name}->{'latex'}->{'latex-driver-parameters'}), "Loaded info contains processor '$processor_name', section 'latex', item 'latex-driver-parameters'.") or BAIL_OUT;
		ok(defined($LI->{$processor_name}->{'latex'}->{'latex-driver-parameters'}), "Loaded info contains processor '$processor_name', section 'latex', item 'latex-driver-parameters', and it is defined.") or BAIL_OUT;

		my $latex_driver_parameters = exists($tdata->{'latex'}) && exists($tdata->{'latex'}->{'latex-driver-parameters'}) && defined($tdata->{'latex'}->{'latex-driver-parameters'})
		  ? $tdata->{'latex'}->{'latex-driver-parameters'}
		  : $latter->processors()->{$processor_name}->{'latex'}->{'latex-driver-parameters'}
		;
		my $format_ret = $latter->format({
			'latex-driver-parameters' => $latex_driver_parameters,
			'latex' => {
				'basedir' => $latex_src_outdir,
			},
			# the default out pdf is where main.tex->main.pdf
			# use this to move that to this file:
			'output' => {
				'filepath' => $outfile,
			},
			'processor' => $processor_name,
			'template-data' => $template_data,
		});
		ok(defined($format_ret), 'format()'." : called and got good result.") or BAIL_OUT;

		ok(-f $outfile, 'format()'." : called and output file '$outfile' exists.") or BAIL_OUT;
		for my $al ('latex', 'template'){
			for my $ak ('basedir', 'filename', 'filepath'){
				ok(exists($format_ret->{$al}->{$ak}), 'format()'." : called for test '$name', processor '$processor_name', and returned result contains key '$ak'.") or BAIL_OUT(perl2dump($format_ret)."no, above is what was returned.");
				is(ref($format_ret->{$al}->{$ak}), '', 'format()'." : called for test '$name', processor '$processor_name', and returned result contains key '$ak' and it is a SCALAR.") or BAIL_OUT(perl2dump($format_ret)."no, above is what was returned.");
			}
			for my $ak ('basedir'){
				ok(-d $format_ret->{$al}->{$ak}, 'format()'." : called for test '$name', processor '$processor_name', and returned output dir (".$format_ret->{$al}->{$ak}.") is a dir.") or BAIL_OUT;
			}
			for my $ak ('filepath'){
				ok(-f $format_ret->{$al}->{$ak}, 'format()'." : called for test '$name', processor '$processor_name', and returned latex output file (".$format_ret->{$al}->{$ak}.") is a filepath and it exists.") or BAIL_OUT;
			}
		}
		my $lfname = $format_ret->{'latex'}->{'filepath'};
		my ($FH, $latexsrcstr);
		ok(open($FH, '<encoding(utf-8)', $lfname), 'format()'." : opening output latex source file ($lfname) for reading.") or BAIL_OUT("no it failed: $!");
		{ local $/ = undef; $latexsrcstr = <$FH> } close $FH;
		ok($latexsrcstr !~ /<\:.+?\:>/, 'format()'." : called and latex src string returned back does not look to contain templated var remains.") or BAIL_OUT("${latexsrcstr}\n\nno see above latex content returned");

		ok(-d $latex_src_outdir, 'format()'." : called and output latex source dir (${latex_src_outdir}) exists.") or BAIL_OUT;
		ok(-d $latex_src_outdir, 'format()'." : called and output dir '$latex_src_outdir' exists.") or BAIL_OUT;
		for my $auxext ('.log', '.aux'){
			my $afi = File::Spec->catfile($latex_src_outdir, 'main' . $auxext);
			ok(-f $afi, 'format()'." : called and aux output file '$afi' exists.") or BAIL_OUT;
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
		'unicode' => 'no',
		'name' => 'test1',
		'params' => {
		  'processors' => {
			# 2 on disk
			'simple20-in-memory' => {
			   'latex' => {
				'filename' => undef, # create tmp
			   },
			   'template' => {
				'filepath' => File::Spec->catfile($curdir, '..', 't', 'templates', 'simple20', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catdir($curdir, '..', 't', 'templates', 'simple20') ],
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
				'filepath' => File::Spec->catfile($curdir, '..', 't', 'templates', 'extra-private-sty-files', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catdir($curdir, '..', 't', 'templates', 'extra-private-sty-files') ],
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
		'unicode' => 'no',
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
				'filepath' => File::Spec->catfile($curdir, '..', 't', 'templates', 'simple20', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catfile($curdir, '..', 't', 'templates', 'simple20', 'main.tex.expected_output') ],
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
		'unicode' => 'no',
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
				'filepath' => File::Spec->catfile($curdir, '..', 't', 'templates', 'simple20', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catfile($curdir, '..', 't', 'templates', 'simple20', 'main.tex.expected_output') ],
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
				'filepath' => File::Spec->catfile($curdir, '..', 't', 'templates', 'extra-private-sty-files', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catdir($curdir, '..', 't', 'templates', 'extra-private-sty-files') ],
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
		# this must fail
		'result' => 'fail',
		'unicode' => 'no',
		'name' => 'test5',
		'params' => {},
	  },
	);

	# if we have XeLaTeX installed we will also do the test with
	#  t/templates/multi-language-xelatex
	# this is provisional to supporting xelatex

	my $exe = LaTeX::Easy::Templates::latex_driver_executable('xelatex');
	if( defined $exe ){
	  diag "${exe} detected, running some extra tests ...";
	  push @tests, {
		'result' => 'success',
		'unicode' => 'yes',
		'name' => 'test4-xelatex',
		'params' => {
		  'processors' => {
			# 1 in memory string and 1 on disk
			'xelatex-in-memory' => {
			   'latex' => {
				'filename' => undef, # create tmp
				'latex-driver-parameters' => {
					# specific format and executable
					'format' => 'pdf(xelatex)'
				}
			   },
			   'template' => {
				# content will be read from file and set and filename will be deleted
				'filepath' => File::Spec->catfile($curdir, '..', 't', 'templates', 'multi-language-xelatex', 'main.tex.tx'),
				'auxfiles' => [ File::Spec->catdir($curdir, '..', 't', 'templates', 'multi-language-xelatex') ],
				'content' => undef,
			   },
			   'output' => {
				'filename' => undef, # it will go somewhere
			   },
			},
		  },
		},
	  };
	}

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
