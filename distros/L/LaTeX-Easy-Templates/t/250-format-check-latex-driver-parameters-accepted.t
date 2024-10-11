#!/usr/bin/env perl

use strict;
use warnings;

use lib 'blib/lib';

#use utf8;

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

# if for debug you change this make sure that it has path in it e.g. ./shit
my $tmpdir = File::Temp::tempdir(CLEANUP=>1);
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $processor_name = 'complex-on-disk';
my $processors_data = {
	$processor_name => {
	  'latex' => {
		'filename' => undef, # create tmp
	   },
	   'template' => {
		'filepath' => File::Spec->catfile($curdir, 'templates', 'extra-private-sty-files', 'main.tex.tx'),
	   },
	   'output' => {
		'filename' => undef, # it will go somewhere
	   },
	},
};
my @td = map { [
	$_,
	$processors_data->{$_}->{'template'}->{'filepath'},
] } sort keys %$processors_data;

my $template_data = {
	'title' => 'a test title',
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
}; # end template data

my $latter = LaTeX::Easy::Templates->new({
	'debug' => {
		'verbosity' => $VERBOSITY,
	},
	'log' => $log,
	'processors' => $processors_data
});
ok(defined($latter), 'LaTeX::Easy::Templates->new()'." : called and got defined result.") or BAIL_OUT;

my $templater = $latter->templater();
ok(defined($templater), 'read_template_and_update_templater()'." : called with a set of filenames and got good result.") or BAIL_OUT;
is(ref($templater), 'Text::Xslate', 'read_template_and_update_templater()'." : called with a set of filenames and got correct type of result back.") or BAIL_OUT;

my $untemplate_ret = $latter->untemplate({
	'processor' => 'complex-on-disk',
	'template-data' => $template_data
});
ok(defined($untemplate_ret), 'untemplate()'." : called and got good result.") or BAIL_OUT;
is(ref($untemplate_ret), 'HASH', 'untemplate()'." : called and got a scalar back.") or BAIL_OUT;

for my $al ('latex', 'template'){
	for my $ak ('basedir', 'filename', 'filepath'){
		ok(exists($untemplate_ret->{$al}->{$ak}), 'untemplate()'." : called and returned result contains key '$ak'.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
		is(ref($untemplate_ret->{$al}->{$ak}), '', 'untemplate()'." : called and returned result contains key '$ak' and it is a SCALAR.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
	}
	for my $ak ('basedir'){
		ok(-d $untemplate_ret->{$al}->{$ak}, 'untemplate()'." : called and returned output dir (".$untemplate_ret->{$al}->{$ak}.") is a dir.") or BAIL_OUT;
	}
	for my $ak ('filepath'){
		ok(-f $untemplate_ret->{$al}->{$ak}, 'untemplate()'." : called and returned latex output file (".$untemplate_ret->{$al}->{$ak}.") is a filepath and it exists.") or BAIL_OUT;
	}
}
my $lfname = $untemplate_ret->{'latex'}->{'filepath'};

# check the output latex src content for template remains
my ($FH, $latexsrcstr);
ok(open($FH, '<:encoding(utf-8)', $lfname), 'untemplate()'." : opened latex source file for reading.") or BAIL_OUT("no it failed: $!");
{ local $/ = undef; $latexsrcstr = <$FH> } close $FH;
ok($latexsrcstr !~ /<\:.+?\:>/, 'untemplate()'." : called and latex src string returned back does not look to contain templated var remains.") or BAIL_OUT("${latexsrcstr}\n\nno it does, see above.");

my $outdir = File::Spec->catdir($untemplate_ret->{'latex'}->{'basedir'});
my $LI = $latter->loaded_info();
ok(defined($LI), "Loaded info exists in object") or BAIL_OUT;
ok(exists($LI->{$processor_name}), "Loaded info contains processor '$processor_name'.") or BAIL_OUT;
ok(defined($LI->{$processor_name}), "Loaded info contains processor '$processor_name' and it is defined.") or BAIL_OUT;
ok(exists($LI->{$processor_name}->{'latex'}), "Loaded info contains processor '$processor_name', section 'latex'.") or BAIL_OUT;
ok(defined($LI->{$processor_name}->{'latex'}), "Loaded info contains processor '$processor_name', section 'latex', and it is defined.") or BAIL_OUT;
ok(exists($LI->{$processor_name}->{'latex'}->{'latex-driver-parameters'}), "Loaded info contains processor '$processor_name', section 'latex', item 'latex-driver-parameters'.") or BAIL_OUT;
ok(defined($LI->{$processor_name}->{'latex'}->{'latex-driver-parameters'}), "Loaded info contains processor '$processor_name', section 'latex', item 'latex-driver-parameters', and it is defined.") or BAIL_OUT;
my $latex_driver_parameters = $latter->processors()->{$processor_name}->{'latex'}->{'latex-driver-parameters'};
# and format it but IT MUST FAIL if latex driver params are accepted
# because we are changing all the LaTeX::Driver paths to executables:
my $drivobj = eval { LaTeX::Driver->new(
	%$latex_driver_parameters,
	'source' => $untemplate_ret->{'latex'}->{'filepath'}
) };
ok(!$@, 'LaTeX::Driver->new()'." : called via eval and got good results.") or BAIL_OUT(perl2dump($latex_driver_parameters)."no it failed for above parameters and this message: $@");
ok(defined $drivobj, 'LaTeX::Driver->new()'." : called and got good results.") or BAIL_OUT(perl2dump($latex_driver_parameters)."no it failed for above parameters.");
for (keys %{ $drivobj->{_program_path} }){
	$latex_driver_parameters->{'paths'}->{$_} = '/does-not-exist'
}

my $outfile = File::Spec->catfile($tmpdir, 'main.pdf');
my $format_ret = $latter->format({
	'latex-driver-parameters' => $latex_driver_parameters,
	%$untemplate_ret,
	'outfile' => $outfile,
});
ok(!defined($format_ret), 'format()'." : called and got good result.") or BAIL_OUT;

# END
done_testing()
