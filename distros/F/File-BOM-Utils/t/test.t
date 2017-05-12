use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use File::BOM::Utils;
use File::Slurper 'read_dir';
use File::Spec;

use Test::More;

# ------------------------------------------------

my($count) = 0;
my(%expect) =
(
	'bom-less.xml' =>
	{
		length  => 0,
		message => 'No BOM found',
		name    => '',
	},
	'bom-UTF-16-BE.xml' =>
	{
		length  => 2,
		message => 'BOM name UTF-16-BE found',
		name    => 'UTF-16-BE',
	},
	'bom-UTF-16-LE.xml' =>
	{
		length  => 2,
		message => 'BOM name UTF-16-LE found',
		name    => 'UTF-16-LE',
	},
	'bom-UTF-32-BE.xml' =>
	{
		length  => 4,
		message => 'BOM name UTF-32-BE found',
		name    => 'UTF-32-BE',
	},
	'bom-UTF-32-LE.xml' =>
	{
		length  => 4,
		message => 'BOM name UTF-32-LE found',
		name    => 'UTF-32-LE',
	},
	'bom-UTF-8.xml' =>
	{
		length  => 3,
		message => 'BOM name UTF-8 found',
		name    => 'UTF-8',
	},
);
my($bommer) = File::BOM::Utils -> new;

$bommer -> action('test');

my($report);

for my $path (read_dir('data') )
{
	$bommer -> input_file(File::Spec -> catfile('data', $path) );

	$report = $bommer -> file_report;

	ok($$report{message} eq $expect{$path}{message}, "Message '$$report{message}'"); $count++;
	ok($$report{name}    eq $expect{$path}{name},    "name '$$report{name}'");       $count++;
	ok($$report{length}  == $expect{$path}{length},  "Length '$$report{length}'");   $count++;
}


done_testing($count);
