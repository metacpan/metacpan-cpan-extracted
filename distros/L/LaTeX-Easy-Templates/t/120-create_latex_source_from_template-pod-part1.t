#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use lib 'blib/lib';

#use utf8;

our $VERSION = '1.02';

use Test::More;
use Test::More::UTF8;
use Mojo::Log;
use FindBin;
use Test::TempDir::Tiny;
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
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $template_data = {
	'title' => 'aaaatitle',
	'author' => {
		'name' => 'author name',
		'surname' => 'author surname'
	},
	'date' => '10/12/2021',
	'content' => 'kapote kapou kapoios ...'
};

my $latex_template_string =<<'EOLA';
% basic LaTeX document
\documentclass[a4,12pt]{article}
\begin{document}

\title{ <: $data.title :> }
\author{ <: $data.author.name :> <: $data.author.surname :> }
\date{ <: $data.date :> }
\maketitle
<: $data.content :>
\end{document}
EOLA

my $latte = LaTeX::Easy::Templates->new({
  debug => {verbosity=>2, cleanup=>1},
  'processors' => {
    'mytemplate' => {
      'template' => {
        'content' => $latex_template_string,
      },
      'output' => {
        'filepath' => 'output.pdf'
      }
    }
  }
});
ok(defined $latte, 'LaTeX::Easy::Templates->new()'." : called and got good result.") or BAIL_OUT;

my $untemplate_ret = $latte->untemplate({
	'processor' => 'mytemplate',
	'template-data' => $template_data
});
ok(defined $untemplate_ret, 'LaTeX::Easy::Templates->new()'." : called and got good result.") or BAIL_OUT;
is(ref($untemplate_ret), 'HASH', 'untemplate()'." : called and got a scalar back.") or BAIL_OUT;

for my $ak ('template', 'latex'){
	ok(exists($untemplate_ret->{$ak}), 'untemplate()'." : called and returned result contains key '$ak'.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
	is(ref($untemplate_ret->{$ak}), 'HASH', 'untemplate()'." : called and returned result contains key '$ak' and it is a SCALAR.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
}

for my $ak ('filename', 'filepath', 'basedir'){
	ok(exists($untemplate_ret->{'latex'}->{$ak}), 'untemplate()'." : called and returned result contains key 'latex'->'$ak'.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
	is(ref($untemplate_ret->{'latex'}->{$ak}), '', 'untemplate()'." : called and returned result contains key 'latex'->'$ak' and it is a SCALAR.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
	ok($untemplate_ret->{'latex'}->{$ak} !~ /^\s*$/, 'untemplate()'." : called and returned result contains key 'latex'->'$ak' and it is a SCALAR and it is not empty.") or BAIL_OUT(perl2dump($untemplate_ret)."no, above is what was returned.");
}

ok(-d $untemplate_ret->{'latex'}->{'basedir'}, 'untemplate()'." : called and returned output dir (".$untemplate_ret->{'latex'}->{'basedir'}.") is a dir.") or BAIL_OUT;
ok(-f $untemplate_ret->{'latex'}->{'filepath'}, 'untemplate()'." : called and returned latex output file (".$untemplate_ret->{'latex'}->{'filepath'}.") is a filepath and it exists.") or BAIL_OUT;
# open the latex source and check if there any templated vars
my ($FH, $content);
ok(open($FH, '<:encoding(utf-8)', $untemplate_ret->{'latex'}->{'filepath'}), "Output latex source '".$untemplate_ret->{'latex'}->{'filepath'}."' opened for reading.") or BAIL_OUT("failed: $!");
{ local $/ = undef; $content = <$FH> } close $FH;
ok($content !~ /<\:.+?\:>/, 'untemplate()'." : called and latex source (content of file '".$untemplate_ret->{'latex'}->{'filepath'}."') does not look to contain templated var remains.") or BAIL_OUT($content."\n\nno see above latex source content.");

# format
my $format_ret = $latte->format({
	'template-data' => $template_data,
	'processor' => 'mytemplate',
	'output' => {
		'filepath' => File::Spec->catfile($tmpdir, 'xyz.pdf'),
	}
});
ok(defined($format_ret), 'format()'." : called and got good results.") or BAIL_OUT;
my $outfile = exists($format_ret->{'output'}) && exists($format_ret->{'output'}->{'filepath'}) && defined($format_ret->{'output'}->{'filepath'})
	? $format_ret->{'output'}->{'filepath'} : undef
;
ok(defined($outfile), 'format()'." : called and output file ($outfile) exists on the returned output data.") or BAIL_OUT;
ok(-f $outfile, 'format()'." : called and output file ($outfile) exists on disk.") or BAIL_OUT;

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing()
