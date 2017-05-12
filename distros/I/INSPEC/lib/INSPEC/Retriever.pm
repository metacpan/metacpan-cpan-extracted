package INSPEC::Retriever;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AXIOM_userid $AXIOM_password $AXIOM_code);

$VERSION = '0.01';

require 5.000;

use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(
retrieve
);

# global package variables, user must assign these in
# calling code
#$AXIOM_userid		= "";
#$AXIOM_password		= "";
#$AXIOM_code			= "";



	

#
# Routines used for the INPSEC service through AXIOM
# By:  Vincent P. LaBella copyright (c) 2000 vlabella@uark.edu
#
#  You are free to use this code but not make money from it ;-)
#        --If you make money from it, give me some.
#

sub get_AXIOM_URL
{
	#
	# returns the axiom leading url with the user id and all
	#
	my $AXIOM_home_page		= "axiom.iop.org";
	return "http://".$AXIOM_userid.":".$AXIOM_password."\@".$AXIOM_home_page."/P/".$AXIOM_code."/searchres?Action=Search&Srch=E&src=01";
}

sub uuencode
{
	#
	# returns the uuencoded string  use this for forming search strings
	#
	#translation table
	#%28 = (
	#%22 = "
	#%29 = )
	#+ =  (space)
	#%3C = <
	#%3E = <
	my $ret = $_[0];
	$ret =~ s/ /\+/g;
	$ret =~ s/\"/\%22/g;
	$ret =~ s/</\%3C/g;
	$ret =~ s/>/\%3E/g;
	$ret =~ s/\(/\%28/g;
	$ret =~ s/\)/\%29/g;
	return $ret;
}

sub get_INSPEC_search
{
	#
	# short and easy takes the coden and the vol and page number and returns search string
	# must appeand to end of QueryText=
	#
	my($ID,$vol,$page,@extra_ids) = @_;
	#
	# decide wheter or not it is a CODEN or ISSN
	#
	my($id_search)="";
	if(index($ID,"-") == -1)
	{
		$id_search="CN";
	}
	else
	{
		$id_search="IS";
	}
	#
	my $ret = "(".$ID.")+<in>+(".$id_search.")";
	#print @extra_ids."\n";
	foreach my $ids (@extra_ids) 
	{
		$ret .= "+<or>+(".$ids.")+<in>+(".$id_search.")";
	}
	if( @extra_ids != 0)
	{
		$ret = "(".$ret.")";
	}

	$ret.="+<and>+(".$vol.")+<in>+(VV)+<and>+(".$page.")+<in>+(PS)&insp=1";
	
	return uuencode($ret);
}


sub pull_info
{
	#
	# pulls the info from the inspec search return
	#
	# 0 the text to pull the infor from
	# 1.. the name of the info
	#
	# info is in the form
	#<b>Accession number</b>: 6420680<br>
	# in this case 1 would be "Accession number"
	# and the return value would be "6420680"
	#
	my ($text,$name) = @_;
	my $ret = "";

	my $start_idx = index($text,"<b>".$name."</b>:");
	my $end_idx = index($text,"<br>",$start_idx);
	$ret = substr($text,$start_idx,$end_idx-$start_idx);

	$ret =~ s/\Q<b>$name<\/b>://;
	$ret =~ s/^\s+//;
	$ret =~ s/\s+$//;	
		
	return $ret;
}



sub retrieve{
	#
	# get_cite - gets the citation from the INSPEC database
	#
	# Agruments
	#=====================================================================
	# 0..............CODEN or ISSN
	# 1..............volume numer
	# 2..............starting page number
	# 3-n............multiple CODENS or ISSN will search all 
	# if you are not sure or if journal has changed CODEN or ISSN in past
	#
	# Returns
	#=====================================================================
	# returns hash with the keys as inspec field names and 
	# the content is the info as recieved from INSPEC
	#
	# If there is an error then the hash will only have one key called "ERROR" 
	# which will equal 1
	#
	# internal variable for bug testing
	my $dump    = 0;  # this will dump all info to files if 1
	my $testing = 0;  # this will load the files for parse testing if 1
	my $page1   = ""; # storage buffer
	my %ret;		  # the return hash
	use LWP::Simple;
	my($ID,$volume,$page) = @_;
	#
	# see if there is more than one CODEN or ISSN on the end
	#
	my @extra_ids;
	if( @_ > 3 ){
		my $j=0;
		for(my $i=3;$i<@_;$i++)
		{
			if(@_[$i] ne "")
			{
				$extra_ids[$j]=@_[$i];
				$j++;
			}
		}
	}
	#
	# FORM the URL to search AXIOM's INSPEC database
	#
	# sample url to get our 2x4 paper
	#
	#http://getcite:getcite1@axiom.iop.org/P/ARKAN/searchres?Action=Search&Srch=E&
	#QueryText=%28PRLTAO%29+%3Cin%3E+%28CN%29+%3Cand%3E+%2883%29+%3Cin%3E+%28VV%29+%3Cand%3E+%282989%29+%3Cin%3E+%28PS%29&src=01
	#
	my $URL = get_AXIOM_URL()."&QueryText=".get_INSPEC_search($ID,$volume,$page,@extra_ids);
	if($dump) {	# dump URL
		open (fhout,"+>url");
		print fhout $URL."\n";
		close fhout;
	}
	if(!$testing)
	{
		#
		# get to web and get it
		#
		$page1=get($URL);
		if($dump){	# dump page1 to page1.html
			open (fhout,"+>page1.html");
			print fhout $page1;
			close fhout;
			print "\nDumped page to page1.html\n";
		}
	}
	else
	{	#
		# this is for pratice parsing load it from a file
		#
		open(fh,"page1.html");
		$page1="";
		foreach my $line (<fh>) {$page1.=$line;}
		close(fh);
		print "\nLoading from file page1.html\n";
	}
	if($page1 eq "")
	{
		#
		# error
		#
		#print "ERROR page1 contains no text.\n URL=[".$URL."]\nExiting.\n";
		$ret{'ERROR'}=1;
		return %ret;
	}
	#
	# get everything after 	"Record 1 of" if it doesn't exist then there is error
	#
	my $start_text="Record 1 of";
	my $idx=index($page1,$start_text);
	if( $idx == -1 )
	{
		#
		# error
		#
		$ret{'ERROR'}=1;
		#print %ret;
		#print "ERROR no search results found.\nURL=[".$URL."]\nExiting.\n";
		return %ret;
	}
	$page1 = substr($page1,$idx);
	# clean it out some more
	#$page1 =~ m/Number of references:<\/B>.+<BR>/g;
	$page1 =~ m/Number of references:/g;
	my $end_text="Number of references:";
	my $end_idx = index($page1,$end_text);
	$end_idx = index($page1,"<BR>",$end_idx)+length("<BR>");
	#print $end_idx."\n";
	$start_text = "<B>Accession number:</B>";
	$page1 = substr($page1,index($page1,$start_text),$end_idx-index($page1,$start_text));
	$page1 =~ s/\s{2,}/ /g;
	$page1 =~ s/\n/ /g;
	$page1 =~ s/\t/ /g;
	$page1 =~ s/<b>/<B>/g;
	$page1 =~ s/<br>/<BR>/g;
	$page1 =~ s/<\\b>/<\\B>/g;
	#$page1 =~ s/\s+$//;	
	#$page1 =~ s/\s+//;	
	if($dump)
	{
		#
		# dump page1 to page2.html
		#
		open (fhout,"+>page2.html");
		print fhout $page1;
		close fhout;
		print "\nDumped parsed text to page2.html\n";
	}
	#
	# Fill Hash with raw information from INSPEC
	#
	# format of inspec stuff is
	# <b>key text</b>: entry text<br>
	#
	$end_idx   = 0;
	my $start_idx = 0;
	while( $end_idx + length("<BR>") < length($page1) )
	{
		$start_idx = index($page1,"<B>",$end_idx);
		$end_idx   = index($page1,"<BR>",$start_idx);
		my $text   = substr($page1,$start_idx,$end_idx-$start_idx);
		my $key    = substr($text,length("<B>"),index($text,"</B>")-length("</B>")+1);
		my $value  = substr($text,index($text,"</B>")+length("</B>"));
		$key =~ s/^\s+//;
		$key =~ s/:$//;
		$key =~ s/\s+$//;
		$value =~ s/://;
		$value =~ s/^\s+//;
		$value =~ s/\s+$//;
		$ret{$key}=$value;
	}
	return %ret;
}

1;
__END__

=head1 NAME

INSPEC::Retriever - Perl extensions to extract information from the INSPEC database provided by AXIOM

=head1 SYNOPSIS

  use INSPEC::Retriever;

=head1 DESCRIPTION

These routines allow you to extract information about a citation or paper from a 
the INSPEC database provided by AXIOM

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