#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename; # For basename().

use MarpaX::Languages::SVG::Parser::Utils;

# ------------------------------------------------

my($attribute);
my($in_file_name);
my($out_file_name);
my(@params);

for my $file (MarpaX::Languages::SVG::Parser::Utils -> new -> get_files('data', 'bnf') )
{
	$attribute     = basename($file);
	$attribute     =~ s/^(\w+)(\..+)$/$1/;
	$in_file_name  = "data/$attribute.bnf";
	$out_file_name = "html/$attribute.svg";

	print "$in_file_name => $out_file_name. \n";

	push @params, '../MarpaX-Grammar-GraphViz2/scripts/bnf2graph.pl';
	push @params, '-legend', '1';
	push @params, '-marpa', '../MarpaX-Grammar-GraphViz2/share/metag.bnf';
	push @params, '-o', $out_file_name;
	push @params, '-user', $in_file_name;

	system($^X, @params);
}
