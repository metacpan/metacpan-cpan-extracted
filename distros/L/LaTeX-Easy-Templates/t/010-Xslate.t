#!/usr/bin/env perl

#################################################################################################
# A test file doing sanity checks for Text::Xslate
# and testing what it expects regarding paths and template files and included template files
# the gist of it is the following
# T::X accepts 'path' in its constructor. This is an array or a single path (as a string scalar)
# Each item of the array can be either:
#   a scalar denoting a template dir
#     in which case you can render any file under this path, i.e. render('anyfile', ...)
#     or even any file under subdir as long as you specify
#        the subdir in the filename, i.e. render('subdir/subdir2/anyfile', ...)
# OR
#   a hashref of just ONE key/value pair, in which case:
#     key: is a template alias which you can refer to
#          when you want to render it, i.e. render('myalias', ...)
#     value: is the template string content
#   This case is for in-memory templates
#
# NOTE: it is possible that an in-memory template includes disk-based (not in-memory) templates
#
#################################################################################################

use strict;
use warnings;

use lib 'blib/lib';

#use utf8;

our $VERSION = '0.05';

use Test::More;
use Test::More::UTF8;
use FindBin;
use File::Spec;
use Text::Xslate;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

my $DEBUG = 1;

my $curdir = $FindBin::Bin;

my $templatesdir = File::Spec->catdir($curdir, 'templates', 'Xslate');
ok(-d $templatesdir, "Templates parent dir '$templatesdir' exists.") or BAIL_OUT;

my ($FH, $content, $tfile, $rendered, $expected, $tdir, $tx, %vars);

############################################################################
# the simple case of a main template (not including others)
############################################################################

$tdir = File::Spec->catdir($templatesdir, 'simple');
$tfile = File::Spec->catfile($tdir, 'hello.txt.tx');
ok(-f $tfile, "Template file '$tfile' exists.") or BAIL_OUT;
ok(open($FH, '<:utf8', $tfile), "template file '$tfile' opened for reading") or BAIL_OUT("failed with : $!");
{ local $/ = undef; $content = <$FH> } close $FH;

$tx = Text::Xslate->new(
	type => 'text',
	path => [
		# The path is an array of paths which main contain template files
		# AND/OR hashrefs which contain just one pair of
		#   template-alias => string-content
		# the latter can be rendered with 'template-alias'
		# and the former with just a filename (not full path)
		# which exists just inside the path specified
		# or a filepath relative to the path specified
		$tdir,
		{ 'in-memory::simple' => $content }
	],
);
%vars = (
	'name' => 'ali bongo'
);

# a file inside the specified search path above:
$rendered = $tx->render('hello.txt.tx', \%vars);
ok(defined $rendered, 'render()'." : called and got defined result for disk-based template.") or BAIL_OUT;
$expected = 'Hello there ali bongo !'."\n";
is($rendered, $expected, 'render()'." : called and got defined result and its value is as expected.") or BAIL_OUT;

# a file inside a subdir of the specified search path above
$rendered = $tx->render('subdir/hello-in-subdir.txt.tx', \%vars);
ok(defined $rendered, 'render()'." : called and got defined result for disk-based template.") or BAIL_OUT;
$expected = 'Hello there ali bongo !'."\n";
is($rendered, $expected, 'render()'." : called and got defined result and its value is as expected.") or BAIL_OUT;

# and now the inmemory
$rendered = $tx->render('in-memory::simple', \%vars);
ok(defined $rendered, 'render()'." : called and got defined result for in-memory template.") or BAIL_OUT;
$expected = 'Hello there ali bongo !'."\n";
is($rendered, $expected, 'render()'." : called and got defined result and its value is as expected.") or BAIL_OUT;

############################################################################
# now the complex case of a main template which includes other templates
############################################################################

$tdir = File::Spec->catdir($templatesdir, 'with-include');
$tfile = File::Spec->catfile($tdir, 'hellos.txt.tx');
ok(-f $tfile, "Template file '$tfile' exists.") or BAIL_OUT;
ok(open($FH, '<:utf8', $tfile), "template file '$tfile' opened for reading") or BAIL_OUT("failed with : $!");
{ local $/ = undef; $content = <$FH> } close $FH;

$tx = Text::Xslate->new(
	type => 'text',
	path => [
		# The path is an array of paths which main contain template files
		# AND/OR hashrefs which contain just one pair of
		#   template-alias => string-content
		# the latter can be rendered with 'template-alias'
		# and the former with just a filename (not full path)
		# which exists just inside the path specified
		# or a filepath relative to the path specified
		$tdir,
		{ 'in-memory::complex' => $content }
	],
);
%vars = (
	'data' => {
		'names' => ['ali bongo', 'bongo johnson', 'the clown']
	}
);

# a file inside the specified search path above:
$rendered = $tx->render('hellos.txt.tx', \%vars);
ok(defined $rendered, 'render()'." : called and got defined result for disk-based template.") or BAIL_OUT;
$expected = <<'EOC';
Many hellos:

Hello there ali bongo !
Hello there bongo johnson !
Hello there the clown !

this is the end.
EOC
is($rendered, $expected, 'render()'." : called and got defined result and its value is as expected.") or BAIL_OUT;

# a file inside a subdir of the specified search path above
$rendered = $tx->render('hellos-in-subdir.txt.tx', \%vars);
ok(defined $rendered, 'render()'." : called and got defined result for disk-based template.") or BAIL_OUT;
is($rendered, $expected, 'render()'." : called and got defined result and its value is as expected.") or BAIL_OUT;

# and now the inmemory
$rendered = $tx->render('in-memory::complex', \%vars);
ok(defined $rendered, 'render()'." : called and got defined result for in-memory template.") or BAIL_OUT;
is($rendered, $expected, 'render()'." : called and got defined result and its value is as expected.") or BAIL_OUT;

# END

done_testing();
