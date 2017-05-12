package INSPEC::BibTeX;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

$VERSION = '0.01';

require 5.000;

use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(
	
);


#
# Inspec BibTex.pm  Routines to translate inspec citations
# to bibtex format.
#
sub inspec_su
{
	# recursively cleans out /sup / and /sup / markings
	# returned from INSPEC
	#
	# 0 text to clean
	# 1 sub or sup
	# 2 
	#
	my($string,$su,$rep) = @_;
	
	my ($start_i,$end_i,$text,$pre,$post);
	my $start = "/".$su." ";
	my $end = "/";
	my $count = 0;
	my $new_start = "{\$".$rep."{";
	my $new_end = "}\$}";
	while ($string =~ /\/$su /g) { $count++ };
	for(my $i=1;$i<=$count;$i++)
	{
		$start_i  =  index($string,$start);
		$pre      =  substr($string,0,$start_i);
		
		$start_i  += length($start);
		$end_i    =  index($string,$end,$start_i);

		$text = substr($string,$start_i,$end_i-$start_i);
		$post = substr($string,$end_i+1);

		#print "pre=[".$pre."]\n";
		#print "text=[".$text."]\n";
		#print "post=[".$post."]\n";
		$string = $pre.$new_start.$text.$new_end.$post;
	}
	return $string;
}

sub INSPEC_to_TeX
{
	#
	# converts inspec markups to tex markups for bibtex purposes cant do nested thingies yet!!!
	#
	my($ret) = @_;
	$ret =~ s/\*/\{\$\\times\$\}/g;
	$ret =~ s/\"/\{\"\}/g;
	$ret =~ s/%/\{\\%\}/g;
	#
	# greek letters lowercase
	#
	$ret =~ s/ (alpha) / \{\$\\\1\$\} /g;
	$ret =~ s/ (beta) / \{\$\\\1\$\} /g;
	$ret =~ s/ (gamma) / \{\$\\\1\$\} /g;
	$ret =~ s/ (delta) / \{\$\\\1\$\} /g;
	$ret =~ s/ (epsilon) / \{\$\\\1\$\} /g;
	$ret =~ s/ (varepsilon) / \{\$\\\1\$\} /g;
	$ret =~ s/ (zeta) / \{\$\\\1\$\} /g;
	$ret =~ s/ (eta) / \{\$\\\1\$\} /g;
	$ret =~ s/ (theta) / \{\$\\\1\$\} /g;
	$ret =~ s/ (vartheta) / \{\$\\\1\$\} /g;
	$ret =~ s/ (iota) / \{\$\\\1\$\} /g;
	$ret =~ s/ (kappa) / \{\$\\\1\$\} /g;
	$ret =~ s/ (lambda) / \{\$\\\1\$\} /g;
	$ret =~ s/ (mu) / \{\$\\\1\$\} /g;
	$ret =~ s/ (nu) / \{\$\\\1\$\} /g;
	$ret =~ s/ (xi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (pi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (varpi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (rho) / \{\$\\\1\$\} /g;
	$ret =~ s/ (varrho) / \{\$\\\1\$\} /g;
	$ret =~ s/ (sigma) / \{\$\\\1\$\} /g;
	$ret =~ s/ (varsigma) / \{\$\\\1\$\} /g;
	$ret =~ s/ (tau) / \{\$\\\1\$\} /g;
	$ret =~ s/ (upsilon) / \{\$\\\1\$\} /g;
	$ret =~ s/ (phi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (varphi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (chi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (psi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (omega) / \{\$\\\1\$\} /g;
	$ret =~ s/ (AA) / \{\$\\\1\$\} /g;
	$ret =~ s/ (aa) / \{\$\\\1\$\} /g;
	$ret =~ s/ h\(cross\) / \{\$\\hbar\$\} /g;
	$ret =~ s/approximately=/\{\$\\approx\$\}/g;
	$ret =~ s/ square root /\{\$\\surd\$\}/g;
	$ret =~ s/\+or-/\{\$\\pm\$\}/g;
	$ret =~ s/-or\+/\{\$\\mp\$\}/g;
	$ret =~ s/>or=/\{\$\\geq\$\}/g;
	$ret =~ s/<or=/\{\$\\leq\$\}/g;
	$ret =~ s/not=/\{\$\\neq\$\}/g;
	$ret =~ s/=/\{=\}/g;
	

	$ret =~ s/ (Delta) / \{\$\\\1\$\} /g;
	$ret =~ s/ (Gamma) / \{\$\\\1\$\} /g;
	$ret =~ s/ (Theta) / \{\$\\\1\$\} /g;
	$ret =~ s/ (Lambda) / \{\$\\\1\$\} /g;
	$ret =~ s/ (Xi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (Pi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (Sigma) / \{\$\\\1\$\} /g;
	$ret =~ s/ (Upsilon) / \{\$\\\1\$\} /g;
	$ret =~ s/ (Phi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (Psi) / \{\$\\\1\$\} /g;
	$ret =~ s/ (Omega) / \{\$\\\1\$\} /g;


	$ret =~ s/ degrees C/ \{\$^\{\\circ\}\$\}C/g;
	$ret =~ s/(.)\/sup to \//\{\$\\vec\{\1\}\$\}/g;
	$ret = inspec_su($ret,"sub","_");
	$ret = inspec_su($ret,"sup","^");
	
	return $ret;
}

sub swap_jr
{
	my($aut) = @_;
	# swap Jr.
	#
	# handle 
	# Carl Ventrice, Jr. do nothing
	# Ventrice, C.A., Jr. swap into Ventrice, Jr., C.A.
	#
	if( ($aut =~ tr/,//) > 1 && index($aut,"Jr.") != -1 )
	{
		## has 2 ,'s and a Jr. so must do a swap
		my @subwords = quotewords(",",0,$aut);
		if( $#subwords == 2)
		{
			$aut = $subwords[0].",".$subwords[2].",".$subwords[1];
		}
		else
		{
			print "ERROR Handling $aut\nI thought that it had a Jr. in it but I think I'm wrong!\n";
			return $aut;
		}
	}
	return $aut;
}



sub name_bibtex_to_inspec
{
	#
	# convert a single author name from bibtex to inspec format
	#
	my ($ret) = @_;
	$ret = swap_jr($ret);
	# remove spaces in periods
	$ret =~ s/\. /\./g;
	# replace 2 or more spaces with just one space
	#$_[0] =~ s/ {2,}/ /g;
	# replace ". ," WITH ".,"
	#$_[0] =~ s/. ,/.,/g;
	# remove trailing spaces
	$ret =~ s/^\s+//;
    $ret =~ s/\s+$//;
	return $ret;
}

sub name_inspec_to_bibtex
{
	#
	# convert a single author name from inspec to bibtex format
	#
	my ($ret) = @_;
	$ret = swap_jr($ret);
	# add spaces in periods
	$ret =~ s/\./\. /g;
	# replace 2 or more spaces with just one space
	$ret =~ s/ {2,}/ /g;
	# replace ". ," WITH ".,"
	$ret =~ s/. ,/.,/g;
	# remove trailing spaces
	$ret =~ s/^\s+//;
    $ret =~ s/\s+$//;
	return $ret;
}

sub authors_inspec_to_bibtex
{
	# convert a INPSEC authors string containing single or
	# multiple authors ro bibtex format
	# second argument of retunr in first authors last name FALN
	#
	#
	# must parse the authors a little
	#
	# example author names
	#<b>Author(s)</b>: Hartmut Gau; Herminghaus, S.<br> 
	#<b>Author(s)</b>: Makse, H.A.; Johnson, D.L.; Schwartz, L.M.<br>
	#<b>Author(s)</b>: Zandvliet, H.J.W.<br>  
	# must get first authors last name and put spaces in after periods
	#
	use Text::ParseWords;
	my ($authors) = @_;
	my $FALN = "";
	if(index($authors,";") != -1 )
	{
		# multiple author names split on ";"
		# escape quotes
		$authors=~s/\'/\\\'/g;
		$authors=~s/\`/\\\`/g;
		$authors=~s/\"/\\\"/g;
		my @words = parse_line(";",1,$authors);
		my $i=0;
		$authors = "";
		# rebuild authors string
		foreach my $aut (@words) 
		{
			$aut=~s/\\\'/\'/g;
			$aut=~s/\\\`/\`/g;
			$aut=~s/\\\"/\"/g;
			$aut = name_inspec_to_bibtex($aut);		
			if($i==0)
			{
				# first authors last name
				$FALN = $aut;
				$i++;
				$authors=$aut;
			}
			else
			{
				$authors.=" and ".$aut;
			}
		}
	}
	else
	{
		# single author
		$authors = name_inspec_to_bibtex($authors);
		$FALN = $authors;
	}
	#
	# get first authors last name FALN and clean it up
	#
	# name examples
	# Vincent LaBella
	# V. P. LaBella
	# LaBella, V. P.
	# Carl Ventrice, Jr.
	# Ventrice, Jr., C. A.
	# delete the Jr. part
	$FALN =~ s/, Jr.//g;
	if(index($FALN,",") != -1 )
	{
		# has a comma 
		$FALN = substr($FALN,0,index($FALN,","));
	}
	else
	{
		# no comma get last word
		my @temp_words = quotewords(" ",0, $FALN);
		$FALN = $temp_words[-1];
	}
	#
	# get first authors last name, everything up to first comma and clean it up for key
	#
	$FALN =~ s/\'//g;
	$FALN =~ s/~//g;
	$FALN =~ s/-//g;
	$FALN =~ s/`//g; #`
	$FALN =~ s/ //g;
	$FALN = lc($FALN);	
	return ($authors, $FALN);
}

sub Inspec_to_BibTeX{
	#
	# convert the inspec citation hash to BibTeX citation hash
	#
	# must take in a hash which is the inspec information and
	# returns a hash of bibtex information
	#
	# makes default key the way I like it
	# First authors last name:CODEN:volume:page
	# you can change the key to your liking
	#
	my ($ie) = @_;
	my %ret;
	my ($FALN,$key,$authors);
	foreach $key (keys %$ie) 
	{
		if(uc($key) eq uc("Volume"))
		{
			$ret{"volume"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Start Page"))
		{
			$ret{"pages"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Author affiliation"))
		{
			$ret{"affiliation"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Title"))
		{
			$ret{"title"}=INSPEC_to_TeX($ie->{$key});
		}
		elsif(uc($key) eq uc("Author(s)"))
		{
			($authors,$FALN) = authors_inspec_to_bibtex($ie->{$key});
			$ret{"author"}=$authors;
		}
		elsif(uc($key) eq uc("CODEN"))
		{
			$ret{"coden"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Issue"))
		{
			$ret{"number"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Publication year"))
		{
			$ret{"year"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("ISSN"))
		{
			$ret{"issn"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("INSPEC Abstract number"))
		{
			$ret{"inspec"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Accession number"))
		{
			$ret{"accession"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Number of references"))
		{
			$ret{"num_ref"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Publisher"))
		{
			$ret{"publisher"}=$ie->{$key};
		}
		elsif( index(uc($key),uc("journal title")) != -1)
		{
			$ret{"journal"}=$ie->{$key};
			$ret{"journal_name"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Publication date"))
		{
			$ret{"pub_date"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Inclusive page numbers"))
		{
			$ret{"page_numbers"}=$ie->{$key};
		}
		elsif(uc($key) eq uc("Abstract"))
		{
			$ret{"abstract"}=INSPEC_to_TeX($ie->{$key});
		}
	}
	$ret{"type"}="article";
	$ret{"key"}=$FALN.":".$ret{"coden"}.":".$ret{"volume"}.":".$ret{"pages"};

	return %ret;
}




1;
__END__

=head1 NAME

INSPEC::BibTeX - Perl extensions to convert INSPEC data from INSPEC::Retriever to BibTeX format

=head1 SYNOPSIS

  use INSPEC::BibTeX;

=head1 DESCRIPTION

These routines allow you to to convert INSPEC data from INSPEC::Retriever to BibTeX format

=head1 EXAMPLES


=head1 AUTHOR

Vincent LaBella vlabella@uark.edu

=head1 COPYRIGHT

Copyright (C) 2000 Vincent LaBella.
All rights reserved.  This program is free software; you can 
redistribute it and/or modify it under the same terms as Perl itself.

=head1 WARRANTY

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
PURPOSE.

=head1 SEE ALSO

perl(1).

=cut