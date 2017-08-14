#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurper qw/read_dir write_binary/;
use File::Spec;

use MarpaX::Languages::SVG::Parser::Utils;

# ------------------------------------------------

my($data_dir_name) = 'data';

my($in_file_name);
my($out_file_name);
my(@params);
my(@result);

for my $file_name (sort grep{/svg$/} read_dir($data_dir_name) )
{
	$in_file_name	= File::Spec -> catfile($data_dir_name, $file_name);
	$out_file_name	= $in_file_name;
	$out_file_name	=~ s/svg$/log/;

	print "$in_file_name => $out_file_name. \n";

	# Warning: Can't use '-maxlevel debug' as an option, since the first line
	# is the OS-dependent version of the input file's name.

	@params = ();

	push @params, '-Ilib';
	push @params, 'scripts/parse.file.pl';
	push @params, '-i', $in_file_name;
	push @params, '-max', 'info';

	@result  = `$^X @params`;

	write_binary($out_file_name, join('', @result) );
}
