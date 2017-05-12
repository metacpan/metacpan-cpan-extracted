#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurp; # For read_file(), write_file().
use File::Spec;

use MarpaX::Languages::SVG::Parser::Utils;

# ------------------------------------------------

my($data_dir_name) = 'data';

my($out_file_name);
my(@params);
my(@result);

for my $in_file_name (MarpaX::Languages::SVG::Parser::Utils -> new -> get_files($data_dir_name, 'svg') )
{
	$out_file_name  = $in_file_name;
	$out_file_name  =~ s/svg$/log/;

	print "$in_file_name => $out_file_name. \n";

	# Warning: Can't use '-maxlevel debug' as an option, since the first line
	# is the OS-dependent version of the input file's name.

	@params = ();

	push @params, '-Ilib';
	push @params, 'scripts/parse.file.pl';
	push @params, '-i', $in_file_name;
	push @params, '-max', 'info';

	@result  = `$^X @params`;

	write_file($out_file_name, {binmode => ':raw'}, @result);
}
