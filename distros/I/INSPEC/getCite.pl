#!/usr/bin/perl
#
# getCite.pl by Vincent LaBella vlabella@uark.edu
#
use LWP::Simple;
use Text::ParseWords;
use INSPEC::Retriever;
use INSPEC::BibTeX;

my $program = "getCite";
my $filedate="1/30/2001";
my $fileversion="1.0 R0.1";
my $copyright = "Copyright 2001 by Vincent P. LaBella";
my $title = "\U$program\E $fileversion, $filedate - $copyright\n";

### options
$::opt_dump=0;
$::opt_noprescan=0;
$::opt_debug=0;
$::opt_bibfile=STDOUT;

#
# adjust these package globals for your site
#
$INSPEC::Retriever::AXIOM_userid		= "getcite" ;  # default username
$INSPEC::Retriever::AXIOM_password		= "getcite1";  # default password, you may want to make your own
$INSPEC::Retriever::AXIOM_code			= "ARKAN"   ;  # for the University of Arkansas


### usage
my @bool = ("false", "true");
my $usage = <<"END_OF_USAGE";
${title}Syntax:  $program <CODEN or ISSN> <Volume> <Starting Page Number> [options]
---------------------------------------------------------------------------
Options:
  --help:           print usage
  --bib	file        append entry to "file" (defualt: $::opt_bibfile)
                    will search BIBINPUTS dirs too
  --(no)debug:      debug information  (default: $bool[$::opt_debug])
  --(no)dump:       Dump HTML output to page1.html page2.html page3.html url
                    (default: $bool[$::opt_dump])
  --noprescan       Omit prescanning of the database (default: $bool[$::opt_prescan])

Examples for getting Phys. Rev. Lett. Volume 83 Page 2989 into mycite.bib
  * $program PRLTAO 83 2989 --bib mycite
  or
  * $program PRLTAO 83 2989 --bib mycite.bib
  or (using ISSN)
  * $program 0031-9007 83 2989 --bib mycite
  or
  * $program 0031-9007 83 2989 --bib mycite.bib
END_OF_USAGE

sub print_bibtex_citation
{
	# takes a bibtex entry hash and 
	# returns it in a single string with no newline characters
	# for output to a file or whatever
	# opposite of parse_bibtex_citation
	# append keys not to be enclosed in {}
	my ($ret,$i,$key) = "";
	my ($cite) = @_;

	my %omits;
	if( @_ > 1 ){
		for( $i=1;$i<@_;$i++)
		{
			if(@_[$i] ne "")
			{
			$omits{@_[$i]}=1;
			}
		}
	}

	$ret = "\@".$cite->{"type"}."{".$cite->{"key"}.",\n";

	foreach $key (keys %$cite) 
	{	
		if($key ne "key" && $key ne "type")
		{
		if( exists $omits{$key})
		{
			$ret.=$key."=".$cite->{$key}.",\n";
		}
		else
		{
			$ret.=$key."={".$cite->{$key}."},\n";
		}
		}
	}
	$ret =~ s/,$/}/;
	return $ret;
}


### process options
use Getopt::Long;
GetOptions (
  "help!",
  "debug!",
  "dump!",
  "noprescan!",
  "bib=s" => \$::opt_bibfile,
) or die $usage;

### option help
die $usage if $::opt_help;
die $usage if @ARGV == 0 ;

my ($journal,$volume,$page) = @ARGV;
print "Looking up ==> $journal, Vol: $volume, Page: $page  Please Wait..";

%entry = INSPEC::Retriever::retrieve($journal,$volume,$page);

if(! (exists $entry{'ERROR'}) )
{
	print "Done\n";
	%bibtexentry = INSPEC::BibTeX::Inspec_to_BibTeX(\%entry);
	if($::opt_bibfile eq "STDOUT")
	{
		print print_bibtex_citation(\%bibtexentry,"key","type")."\n";
	}
	elsif($::opt_bibfile ne "")
	{
	open(fh,">>".$::opt_bibfile);
	print fh print_bibtex_citation(\%bibtexentry,"key","type")."\n";
	close(fh);
	}
	else
	{
	print "ERROR cant open 	$::opt_bibfile\n";
	}
}
else
{
	print "ERROR!!\n";
	print "Couldn't find the citation in INSPEC databse]--!!\n";
	print "Reasons:\n(1) The citation is too old (i.e older than 1968).\n";
	print "(2) The journal [".$jname."] is not contained in the INSPEC database.\n";
	print "(3) The volume[".$volume."], page number[".$page."], and journal code[".$journal."] were incorrectly specified.\n";
	print "(4) The AXION INPSEC server is down or too busy.  Goto axiom.iop.org/S/ARKAN/search and try a manual search to see.\n";
}