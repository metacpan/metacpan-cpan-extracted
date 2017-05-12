######################################################################
#
# LaTeX::Authors
#
######################################################################
#
#  LaTeX::Authors is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  LaTeX::Authors is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with ParaTools; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#######################################################################
#
# LaTeX::Authors try to find the authors and laboratories in a LaTeX file
# and return the information with xml tags.  
#
# Author: Christian Rossi 
#         CCSD/CNRS (rossi@in2p3.fr) and LORIA/INRIA Lorraine (rossi@loria.fr)    
#
# Based on latex.pm by José João Almeida (jj@di.uminho.py)
# http://natura.di.uminho.pt/~jj/perl/
#
# 2003/03/10 : version 0.8 
# 2005/03/29 : version 0.81 (correct documentation Latex to LaTeX)
#
########################################################################


package LaTeX::Authors;

use strict;

use vars qw($VERSION);
use Exporter ();

our @ISA = qw(Exporter);

our  @EXPORT      = qw(&un_archive &find_tex_file &load_file_string &router 
                       &string_byauthors_xml &string_byauthors_html &author_to_lab 
                       &string_bylabs_html &string_bylabs_xml &string_onlyauthors_xml &string_onlylabs_xml);

use Text::Balanced qw (extract_bracketed); 

our $VERSION = '0.81';

=pod 

=head1 NAME

LaTeX::Authors - Perl extension to extract authors and laboratories in a LaTeX file  

=head1 SYNOPSIS
	

Extraction from a string with latex commands:
	
	use LaTeX::Authors;
	use strict;        
	my $tex_string = "\documentclass...";
	my @article = router($tex_string);
	my $string_xml =  string_byauthors_xml(@article);
	print $string_xml;
	
	
Extraction from a latex file:

 use LaTeX::Authors;
	use strict;        
	my $file = shift;
	my $tex_string = load_file_string($file);
	my @article = router($tex_string);
	my $string_xml =  string_byauthors_xml(@article);
	print $string_xml;
	
	
Extraction from a directory with latex files:
			
	use LaTeX::Authors;
	use strict;        
	my $directory = shift;
	#my $error= un_archive($directory);
	my $file = find_tex_file($directory);
	my $tex_string = load_file_string($file);
	my @article = router($tex_string);
	my $string_xml =  string_byauthors_xml(@article);
	print $string_xml;

		
=head1 DESCRIPTION 
		
LaTeX::Authors try to find the authors and laboratories in a LaTex file.
The output is an xml or html string. This is an example of the xml output: 
  	 		
<article>
     <item>
        <author>author1</author>
        <labo>lab1</labo>
        <labo>lab2</labo>
     </item>
     <item> 
        ...
     </item>
 </article>

The module try to found something like the \author and \affiliation latex command on the file.
With articles about physics try to found a collaboration name to work with more exotic way to show authors list.
It is especially design for article about physics where there is hundreds of authors.

It can work on input with:
 - an archiv file (tar, zip...), it's useful for arXiv file (function un_archiv)
 - a directory with latex file (function find_tex_file)
 - a latex file (function load_file_string)
 - a string (function router)  

For the output it can produce:
 - an xml string
     - by author: author1 lab1 lab2 (string _byauthors_xml)
     - by laboratory: lab1 author1 author2 (string_bylabs_xml) 
 - an html string
     - by author (string_byauthors_html)
     - by lab (string_bylabs_html)
  
  
=cut

###################################################

=head1 FUNCTION 

=head2 C<un_archive> - uncompress, untar or unzip file in a directory

Take the archive file and uncompress (useful for arXiv files)
   
my $error = un_archive($directory);
 
=cut

					
sub un_archive
{
    my ($directory) = @_;
    my $filename; 
    my @listfile;
    my $error ="";
   
    if (!(chdir($directory))) {
	$error = "dir"; 
        return $error;
    }

    @listfile = <*.uu>;
    foreach $filename (@listfile) {
	my $code = system("/bin/csh $filename >/dev/null 2>&1");
	$error = "uu " if ($code);
    }
    foreach $filename (@listfile) {
	unlink($filename); 
    }

    @listfile = <*.tar.gz>;
    foreach $filename (@listfile) {
	my $code = system("gzip -cd $filename | tar x >/dev/null 2>&1");
	$error .= "tar.gz " if ($code);	   
    }
    foreach $filename (@listfile) {
	unlink($filename); 
    }

    @listfile = <*.tgz>;
    foreach $filename (@listfile) {
	my $code = system("gzip -cd $filename | tar x >/dev/null 2>&1");
	$error .= "tgz " if ($code); 
    }
    foreach $filename (@listfile) {
	unlink($filename); 
    }

    @listfile = <*.tar>;
    foreach $filename (@listfile) {
	my $code = system("tar xf $filename >/dev/null 2>&1");
	$error .= "tar " if ($code);
    }
    foreach $filename (@listfile) {
	unlink($filename)  ; 
    }

    @listfile = <*.gz>;
    foreach $filename (@listfile) {
	my $code = system("gzip -d $filename");
	$error .= "gz " if ($code);
    }
    foreach $filename (@listfile) {
	unlink($filename) ; 
    }

    @listfile = <*.zip>;
    foreach $filename (@listfile) {
	my $code = system("unzip $filename");
	$error .= "zip " if ($code);
    }
    foreach $filename (@listfile) {
	unlink($filename); 
    }

    return $error;
}


###################################################


=head2 C<find_tex_file> - Try to find the main tex file on a directory with multiple files

my $texfile = find_tex_file($directory);

=cut
    
sub find_tex_file
{
    my $directory = $_[0];

    if ($directory eq "") {
	# Error: No working directory. 
	return "";
    }
    if (!(-d $directory)) {
	# Error: Working directory doesn't exist. 
	return "";
    } 

    if (!(chdir($directory))) {
	# Error: Can't cd to source directory. 
	return "";
    }

    my @list_file_dir = <*.tex>;
    my @list_file_sdir = <*/*.tex>;
    my @list_file = (@list_file_dir,@list_file_sdir);
    my $nbr_file = @list_file;
 
    my $tex_file;
 
    if ($nbr_file == 1) {
	$tex_file = $list_file[0];
    } elsif ($nbr_file > 1) {
	foreach (@list_file) {
	    open(FILEGREP,"$_");
	    my $tempo_file = $_;
	    while (<FILEGREP>) { 
		s/(^\s*|[^\\])%.*/$1/g;
		s/^\s*\n$//g;
		if ((/\\begin\{document\}/) || (/\\bye/) || (/\\documentstyle/) ) {
		    $tex_file  = $tempo_file;
		    last;
		}
	    }

	}
    } else {
 
	my @list_file_dir = <*>;
	my @list_file_sdir = <*/*>;		
	my @list_file = (@list_file_dir,@list_file_sdir);
		
	foreach (@list_file) { 
	    open(FILEGREP,"$_");
	    my $tempo_file = $_;
	
	    while (<FILEGREP>) { 
		s/(^\s*|[^\\])%.*/$1/g;
		s/^\s*\n$//g;
	   
		if ((/\\begin\{document\}/) || (/\\bye/) || (/\\documentstyle/)) {
		    $tex_file  = $tempo_file;
		    last;
		}
	    }
	}
    }

    return $tex_file;

}


###################################################


=head2 C<load_file_string> - Load a file and put the content to a string 

my $string = load_file_string($file);

Also delete the latex comments (%...). 

=cut 

sub load_file_string
{
    my $file = $_[0];
    my $string;
    open(TEXFILE,$file) or die "Error: can't open $file\n";   
    while (<TEXFILE>) {
	s/(^\s*|[^\\])%.*/$1/g;
	s/^\s*\n$//g;
	$string .=  $_;
    }
    return $string;
}


###################################################


=head2 C<router> - Try to qelect the good function to extract the authors and laboratories and return an array 
with the authors and the laboratories in the latex file.

@article = router($string);

=cut 

sub router  
    {
	my $string= $_[0];
	my ($aut,$aff,$add,$addeq,$ins,$and,$math_in_add,$math_in_aut,$altaff,$input_file,$report_fermilab);
	my ($string_aut,$string_lab);
	$string_aut = ""; $string_lab= "";
	my @tab_chaine = split(/\n/,$string);
	my @input;my @include;
	foreach (@tab_chaine) {
	    if (/\\author/) {
		$aut = 1; $string_aut = "author";
	    }
  
	    if (/\\affiliation/) {
		$aff = 1; $string_lab = "affiliation";
	    }
	    # aastex
	    if (/\\affil\{/) { 
		$aff = 1; $string_lab = "affil";
	    }
	    if (/\\address/) {
		$add = 1 ; $string_lab = "address";
	    }

	    if (/\\address\{(\s*(\\\w+ )+|\s*)\$\^/) {
		$add= 1; $string_lab = "address"; $math_in_add = 1;
	    }
	    if (/address=/) {
		$addeq = 1 ; $string_lab = "address";
	    }
	    if (/\\institute/) {
		$ins = 1; $string_lab = "institute";
	    }
	    if (/\\altaffilmark/) {
		$altaff = 1; 
	    }
	    # na59			 
	    #if ((/\\input/) && ($chaine1 eq "") && ($chaine2 eq "")) { 
	    if (/\\input/) {
		my $sed_string = $string;		
		# delete space \input xyz -> \input{xyz} 
                $sed_string =~ s/\\input\s+([\.\/\w]+)/\\input\{$1\}/g if (@input == 0); 
  		@input =  greplatexcom("input",["t"],$sed_string) if (@input == 0); 

		#	    my	    $input_file = $input[0]->{t}; bichop($input_file); 
		# L3 : \input toto.tex
		#	    if ($input_file eq  "") {
		# space    
		#	    		/\\input\s+(.*)/; $input_file = $1;
		#	    }
		#	    $input_file .= ".tex" if ((! -f $input_file) && ($input_file ne "")); 

		#my $chaine_l = load_file_string($input_file);
		#my  @out = router($chaine_l);
		#if (@out > 0) {return @out;}
	    }
	    if (/\\include/) {
	    @include =  greplatexcom("include",["t"],$string) if (@include == 0);
	    }
   	    if (/report.*Fermilab/) {
		$report_fermilab = 1;		  
            }
	}

	my $coll_name = found_collaboration($string);

	$coll_name =~ tr/A-Z/a-z/;

	#print "aut=$aut aff=$aff add=$add addeq=$addeq ins=$ins coll = $coll_name ";

	#$coll_name ="H1";

	my @aut = greplatexcom("author",[["arg"],"t"],$string);

	if (bichop($aut[0]->{t}) =~ /\\and/) {
	    $and = 1;
	}
	if (bichop($aut[0]->{t}) =~ /\$\^/) {
	    $math_in_aut = 1;
	}

	#print bichop($aut[0]->{t});

	my @addr=  greplatexcom("address",[["arg"],"t"],bichop($aut[0]->{t}));
 
	# print "1= $addr[0]->{t} \n";
	my  $imbri;

	$imbri= 1 if ((defined $addr[0]->{t}) && ($addr[0]->{t} ne ""));
	
	#print "imbri = $imbri and= $and input = ". @input ." include = ". @include. "\n"; 
	#print "math_in_aut = $math_in_aut math_in_add = $math_in_add <br>\n";

	my @doc;

	if (($string_aut ne "") && ($string_lab eq "") && ($coll_name ne "l3")) {
	    if ($math_in_aut) {
		@doc = grepaut_math("$string_aut",$string);
	    } elsif ($altaff) {
		@doc = grep_aut_altaff($string);
	    } else {
		@doc = grepaut("$string_aut",$string);
	    }
	
	} elsif (($string_aut ne "") && ($string_lab ne "") && ($coll_name ne "zeus")) {
	    if ($imbri == 1) {
		@doc=  grepautadd("$string_aut","$string_lab",$string);
	    } elsif ($addeq == 1) {
		@doc=  grepautadd_eq("$string_aut","$string_lab",$string);
	    } elsif (($math_in_aut == 1) && ($math_in_add == 1)) {
		@doc=  grepautadd_math("$string_aut","$string_lab",$string);

	    } else {
		@doc=  grepautaff("$string_aut","$string_lab",$string);
	    }
	} elsif ($coll_name ne "") {
	    #my $function = "grep_article_" . $coll_name;
	    #print "$function\n";
	    if (@input != 0) { 	 
	        foreach my $input_t (@input) {
		    $input_file = $input_t->{t}; bichop($input_file); 
		    # L3 : \input toto.tex					
		    #		 if ($input_file eq  "") {
		    #		    # space    
		    #	    		/\\input\s+(.*)/; $input_file = $1;
		    #	       
		    $input_file .= ".tex" if ((! -f $input_file) && ($input_file ne "")); 
		    my $string_input = load_file_string($input_file);
		#print "<br>f1=$input_file ";
		    #	       @doc = router($string_l);
		    @doc = func_by_coll($string_input,$coll_name);
		    last if (@doc > 0);
		}
		
	    }
	    @doc = func_by_coll($string,$coll_name) if (@doc == 0);		
	} elsif ($report_fermilab == 1) {
	@doc = extract_report_fermilab($string);  
	} elsif ((@input != 0) || (@include != 0)){    
		my @infile = (@input,@include);
	    foreach my $input_t (@infile) {
		$input_file = $input_t->{t}; bichop($input_file); 
		# L3 : \input toto.tex					
		# if ($input_file eq  "") {
		# space    
		#	    		/\\input\s+(.*)/; $input_file = $1;
		#	    }
		$input_file .= ".tex" if ((! -f $input_file) && ($input_file ne ""));
		#print "<br>f2=$input_file ";
		my $string_l = load_file_string($input_file);
		@doc = router($string_l);
		last if (@doc > 0);
	    }	
	}
	return(@doc);
    }


##################################################
#
# Tools functions 
#
# Useful if you want to complete the module
# with others author/lab pattern  
#
#################################################


=head2 C<found_collaboration> - Try to found a collaboration name

Useful for physics articles whrere there often a collaboration name. The authors list format can be found with the collaboration name. Used by the router function.

=cut 

sub found_collaboration
  {
    my $string = $_[0];
    my (@tex_line) = split(/\n/,$string);
    foreach (@tex_line) {
        last if ((/thebibliogeraphie/) || (/\\bibitem/));  
        /(?:\s+|{\s*)([^\s]+)\s+collaboration/i;
	my $collaboration = "";
	$collaboration = $1 if ((defined $1) && ($1 ne ""));
	if ($collaboration ne "") { 
	  # for: (name collaboration) -> return name and not (name
	  $collaboration =~ s/^\(//;
	  # \name\ -> name
	  $collaboration =~ s/\\//g;
	  return $collaboration;
	}
      }
    }
   

##################################################


=head2 C<delete_comment> - Delete tex comment (%) on a string

my $string_out = delete_comment($string_in);

=cut

sub delete_comment
{
    my $string = $_[0];
    $string =~ s/(^\s*|[^\\])%.*/$1/g;
    $string =~ s/^\s*\n$//g;
    return $string;
}


##################################################


=head2 C<bichop> - Double end chop

With 

my $string_in = bichop("{aaa}") 

in $string_in there is: 

"aaa"

=cut

sub bichop
  {   
    chop $_[0];
    substr($_[0],0,1)="";	
    $_[0];
  }


##################################################


=head2 C<greplatexcom> - To get all the ocurrences of a latex command

   @l_section = greplatexcom("section",["title"],$string);
   for $s (@l_section) {print $s->{title} };

Optional arguments can be described with "[name]". See this example:

   @class = greplatexcom("documentclass",[["args"],"class"],$string);
   print $class[0]->{class} ;

With \documentclass[xyz]{abc}

  $class[0]->{args} = xyz
  $class[0]->{class} = abc

=cut

sub greplatexcom
  {
    my ($name,$listofargnames,$string) = @_ ;
    my @rf=();
    my ($begin, @list) = split(/\\$name\b/,$string);
    foreach (@list) {
      chomp;
      my %r = ();
      
      ###STRICT
      my $n;
      ###
      for $n (@$listofargnames) {
        if (ref($n) eq "ARRAY") {
	  ($r{$n->[0]},$_) = extract_bracketed($_,"[");
	  delete $r{$n->[0]} unless (defined $r{$n->[0]});
        } else {
	  ($r{$n},$_) = extract_bracketed($_,"{");
	}
      }
      push(@rf,\%r);
    }
    return @rf;
  }


###################################################


=head2 C<theenv> - To get a latex environment contents

   $abstract_string = theenv("abstract",$string);

C<theenv> returns the contents of the environment "abstract".

For example if:

$string ="\begin{abstract}
            xyz...
          \end{abstract}";

after theenv in $abstract_string there is the string: 

xyz...

=cut

sub theenv
{ 
    my($a,$b) = @_;
    my @r = greplatexenv($a,[],$b);
    return $r[0]->{'env'};
}


###################################################


=head2 C<theenvs> - To get all the latex environments contents

   @array = theenvs("sloppypar",$string);

C<theenvs> returns the contents of all the environment "sloopypar".

=cut

sub theenvs
{ 
    my($a,$b)= @_;
    my @string;
    my @r=greplatexenv($a,[],$b);
    foreach my $env (@r) { 
	#  $r[0]->{'env'};
	push(@string,$env->{'env'}); 
    }
    return(@string);
}


###################################################


=head2 C<greplatexenv> - To get all ocurrences of a latex environment

   @a = greplatexenv("letter",["to"],$string) ; 

C<greplatexenv> returns a list of all the ocurrences of environment "letter",
reading its first argument to the "to" field and saving its content in the 
"env" field;

=cut 

sub greplatexenv
{
    my ($name,$listofargnames,$string) = @_ ;
    my @rf=();
    my ($begin, @list) = split(/\\begin{$name}/,$string);
    foreach (@list) { 
	chomp;
	if (/\\end{$name}/) {
	    $_=$`;
	} else {
	    next;
	}
	my %r = ();
	###STRICT
	my $n;
	###
	for $n (@$listofargnames) {
	    if (ref($n) eq "ARRAY") {
		($r{$n->[0]},$_) = extract_bracketed($_,"[");
		delete $r{$n->[0]} unless (defined $r{$n->[0]});
	    } else {
		($r{$n},$_) = extract_bracketed($_,"{");
	    }
	}
	$r{'env'} = $_;
	push(@rf,\%r);
    }
    return @rf;
}


###################################################


=head2 C<newcommand> - Return a hash with all the "newcommand" occurrences

%listnewcom = newcommand($string);

If you have 

$string="\newcommand[xyz]{abc}";

so after newcommand:

$listnewcom{xyz} = "abc";

=cut
 
sub newcommand
{
    my $string = $_[0];
    my %listnewcom;
    my @newcom=  greplatexcom("newcommand",["args","val"],$string);

    for my $s (@newcom) {
	$s->{args} = bichop($s->{args});
	$listnewcom{$s->{args}} = bichop($s->{val}); 
    }
    return %listnewcom;
}


###################################################


=head2 C<list_index> - Return a hash with all the command occurences

For example with: 

my $command_name = "command";
%list = list_index($command_name,$string);

 \command[index]{xyz...} -> $list{index} = "xyz...";

Generalize the function newcommand with any command. 

=cut 

sub list_index
  {
    my ($command,$string) = @_;
    my %listnewcom;

    my @newcom = greplatexcom($command,[["args"],"val"],$string);

    for my $s (@newcom) {

      $s->{args} = bichop($s->{args});

      $s->{args} =~ s/^\s*//g;
      $s->{args} =~ s/\s*$//g;
 
      $s->{val} =~ s/^\s*//g;
      $s->{val} =~ s/\s*$//g;
 
      $listnewcom{$s->{args}} = bichop($s->{val}); 
    }
    return %listnewcom;
  }
 

###################################################


=head2 C<accent> - Transform the latex caracters with accent to standard caracters 

my $string_out = accent($string_in);
 
=cut 

sub accent
{
    ($_) = @_;

    s/{\\`a}/à/g;
    s/{\\'a}/á/g;
    s/{\\^a}/â/g ;
    s/{\\"a}/ä/g;
    s/{\\\*a}/å/g;
    s/{\\ae}/æ/g;

    s/{\\`A}/À/g;
    s/{\\'A}/Á/g;
    s/{\\"A}/Ä/g; 
    s/{\\\*A}/Å/g;
    s/{\\~A}/Ã/g;
    s/{\\AE}/Æ/g;

    s/\\`{\\?a}/à/g ;
    s/\\'{\\?a}/á/g ;
    s/\\^{\\?a}/â/g ;
    s/\\"{\\?a}/ä/g ;
    s/\\\*{\\?a}/å/g ;
    s/\\{ae}/æ/g ;

    s/\\`a/à/g ;
    s/\\'a/á/g ;
    s/\\^a/â/g ;
    s/\\"a/ä/g ;
    s/\\\*a/å/g ;
    s/\\ae/æ/g ;
    s/\\~a/ã/g ;

    s/\\`A/À/g ;
    s/\\'A/Á/g ;
    s/\\"A/Ä/g ; 
    s/\\\*A/Å/g ;
    s/\\~A/Ã/g;
    s/\\AE/Æ/g;

    s/\\c{c}/ç/g ;
    s/\\c{C}/Ç/g ;

#    s/{\\,c}/ç/g ;
#    s/{\\,C}/Ç/g ;
#    s/\\,c/ç/g ;
#    s/\\,C/Ç/g ;

    s/{\\'e}/é/g ;
    s/{\\`e}/è/g ;
    s/{\\^e}/ê/g ;
    s/{\\"e}/ë/g ;

    s/\\'e/é/g ;
    s/\\`e/è/g ;
    s/\\^e/ê/g ;

    s/\\'{\\?e}/é/g ;
    s/\\`{\\?e}/è/g ; 
    s/\\"{\\?e}/ë/g ;      
            
    s/{\\'E}/É/g ;
    s/{\\"E}/Ë/g ;

    s/\\'E/É/g ;
    s/\\"E/Ë/g ;

    s/{\\^i}/î/g ;
    s/{\\'i}/í/g ;
    s/{\\"I}/Ï/g ;
    s/{\\'I}/Í/g ;

    s/\\'\\?i ?/í/g ;
    s/{?\\'{\\?i}}?/í/g ; 

    s/\\^i/î/g ;
    s/\\"I/Ï/g ;
    s/\\'I/Í/g ;

    s/{\\'O}/Ó/g;

    s/{\\"O}/Ö/g;
    s/\\"{O}/Ö/g;
 
    s/{\\'o}/ó/g;
    s/{\\^o}/ô/g ;
    s/{\\"o}/ö/g ;
    s/{\\`o}/ò/g ;
    s/{\\~o}/õ/g ;

    s/\\^o/ô/g ;
    s/\\"o/ö/g ;
    s/\\`o/ò/g ;
    s/\\~o/õ/g ;

    s/\\'o/ó/g;
    s/\\'O/Ó/g;
    s/\\"O/Ö/g;
    
    s/\\`{\\?o}/ò/g ;

    s/{\\~n}/ñ/g ;
   
    s/\\~n/ñ/g ;

    s/{\\`u}/ù/g ;
    s/{\\^u}/û/g ;
    s/{\\^u}/û/g ;
    s/{\\"u}/ü/g ;

    s/\\`u/ù/g ;
    s/\\^u/û/g ;
    s/\\^u/û/g ;
    s/\\"u/ü/g ;
    
    s/\\"{\\?u}/ü/g ;

    s/{\\'y}/ý/g ;
    s/{\\'Y}/Ý/g ;
    
    s/\\'y/ý/g ;
    s/\\'Y/Ý/g;
	     
    s/\\.{I}/&#304;/g;
    s/\\c{S}/&#350;/g;
    s/\\c{s}/&#351;/g; 
    s/\\v{c}/&#269;/g;
 
    s/\\'c/&#263;/g;
    s/\\'C/&#262;/g; 
    
    s/\\v c/&#269;/g;
 
    s/\\v{C}/&#268;/g;  
    s/\\v{S}/&#352;/g; 
    s/\\v{s}/&#353;/g;
    s/\\v{Z}/&#381;/g; 
    s/\\v Z/&#381;/g;
    
    s/\\v{z}/&#382;/g;
    s/\\v z/&#382;/g;
		    
    s/\\.Z/&#x17b;/g;	 
    s/\\.z/&#x17c;/g;	    
    
    s/\\'{N}/&#x143;/g;    
  
    s/\\L /&#x141;/g;
    s/\\l /&#x142;/g;
    s/{\\l}/&#x142;/g;		    
    
    s/\\'{N}/&#x143;/g;
    s/\\'{n}/&#x144;/g;
   
    s/\\'N/&#x144;/g;
    s/\\'n/&#x144;/g;
		    		    		    
    s/{\\ss}/ß/g;

    # delete tex command 	     
    # \{\xyz text\} -> text
    s/\{\\\w+ ([^\}]*)\}/$1/g;

    # \xyz{text} -> ""
    s/\\\w+\{[^\}]+\}//g;
 
    # \xyz text -> text   
    s/\\\w+ / /g;
	    
    # space and ,
    s/[\n\t\s]+/ /g; 
    s/^\s*//g;
    s/\s*$//g;

    s/~/ /g ;
    s/\\\\/,/g ;

    s/\\ / /g ;

    s/on leave from//g;
    s/Also with //g;
    s/Also at //g;	    
    # ,, -> , 
    s/,+/,/g ;

    # ,  , -> , 
    s/,\s*,/,/g ;
 
    s/^, and / /g;
    s/^,\s*//g;
    s/^and\s//g;
    
    # IN^2P^3 -> IN2P3 
    s/IN\$\^\{2\}\$P\$\^\{3\}\$/IN2P3/g;

    s/\\&/and/g;  
  
    # s/[\n\t\s]+/ /g; 

    # , at the begin and at the end
    s/^\s*,\s*//g;   
    s/\s*,\s*$//g; 

    # space begin end
    s/^\s*//g;
    s/\s*$//g;

    return $_;

}
  

######################################################################
#
# output function 
#
#####################################################################


=head2 C<string_byauthors_xml> - Retrun a string with xml tags all the authors and lab found in an article 
 
 my $string = string_byauthors_xml(@article);

 <article>
   <item>
      <author>author1</author>
      <labo>lab1</labo>
      <labo>lab2</labo>
   </item>
   <item> 
     ...  
   </item>   
 </article>

=cut 

##
#
# @article in an array with ($ref_item1, $ref_item2,...)
#
# @$item is an array with (author, lab1, lab2,...) 
# 
## 

sub string_byauthors_xml 
{
	my (@article) = @_;
	my $string;
	$string =  "<article>\n" if (@article > 0);
	foreach my $item (@article) {
	  $string .= "  <item>\n";
	  my ($author,@labo) = @$item;
	  $string .= "    <author>" . accent($author) . "</author>\n";
	  foreach my $lab (@labo) { 
	   $string .= "    <labo>" . accent($lab) . "</labo>\n";
	  }
	  $string .= "  </item>\n";
	}
	$string .= "</article>\n" if (@article > 0);
        return $string;
}

#######################################################################  

=head2 C<string_onlyauthors_xml> - Retrun a string with xml tags all the authors found in an article 
 
 my $string = string_onlyauthors_xml(@article);
 
 <article>
     <author>author1</author>
     <author>author2</author>
     ...   
 </article>

=cut

sub string_onlyauthors_xml 
{
	my (@article) = @_;
	my $string;
	$string =  "<article>\n" if (@article > 0);
	foreach my $item (@article) {
	  my ($author,@labo) = @$item;
	  $string .= "    <author>" . accent($author) . "</author>\n";
  	}
	$string .= "</article>\n" if (@article > 0);
        return $string;
}


#######################################################################


=head2 C<author_to_lab> - Convert the author array to a lab array 

my @array_lab = author_to_lab(@array_author);

(author1, lab1, lab2)(author2, lab1, lab3) -> (lab1,author1,author2)(lab2,author1)(lab3,author2)
 
=cut 

sub author_to_lab 
  {
    my (@article) = @_;
    my %author; 
    my @article_lab;

    foreach my $item (@article) {
      my ($author,@labo) = @$item;
      foreach my $lab (@labo) {
	my @lab_authors;
	# for the sort
	$lab = accent($lab);
	@lab_authors = @{$author{$lab}} if  defined($author{$lab});
	push( @lab_authors,$author);
	$author{$lab} = \@lab_authors;
      }
    }
    foreach my $lab (sort keys %author) {
      unshift(@{$author{$lab}}, $lab);
      push( @article_lab, $author{$lab});
    }
    return @article_lab; 
  }


############################################################


=head2 C<string_bylabs_xml> - Return a string with xml tags all the lab and authors found in an article 
 
my $xml_string = string_bylabs_xml(@article);

 <article>
   <item>
      <labo>lab1</labo>
      <author>authors1</author>
      <author>authors2</author>
   </item>  
   <item>   
     ...  
   </item>  
 </article>  

=cut

##
#
# @article in an array with ($ref_item1, $ref_item2,...)
#
# @$item is an array with (lab1, author1, author2,...) 
#
##

sub string_bylabs_xml
{ 
    my (@article) = @_; 
    my $string;
    my @article_bylab = author_to_lab(@article);
    $string = "<article>\n" if  (@article > 0); 
    foreach my $item (@article_bylab) {
	$string .= " <item>\n"; 
	my ($lab,@authors) = @$item; 
	$string .= " <labo>" . accent($lab) . "</labo>\n"; 
	foreach my $author (@authors) {
	    $string .= " <author>"	. accent($author) . "</author>\n";
	}							     
	$string .= " </item>\n";
    }
    $string .=  "</article>\n" if (@article > 0);
    return $string;
}


############################################################


=head2 C<string_onlylabs_xml> - Return a string with xml tags all the lab found in an article 
 
my $string = string_onlylabs_xml(@article);

 <article>
     <labo>lab1</labo>
     <labo>lab2</labo> 
     ...  
 </article> 

=cut

sub string_onlylabs_xml
{ 
    my (@article) = @_; 
    my $string;
    my @article_bylab = author_to_lab(@article);
    $string = "<article>\n" if  (@article > 0); 
    foreach my $item (@article_bylab) {
	
	my ($lab,@authors) = @$item; 
	$string .= " <labo>" . accent($lab) . "</labo>\n"; 								     	
    }
    $string .=  "</article>\n" if (@article > 0);
    return $string;
}


########################################################


=head2 C<string_byauthors_html> - Return a string with all the authors and lab using html tags 

my $string_out = string_by_authors_html(@article);
		
		<hr>
		author1 
		<p>
		<ul>
		  <li> lab1
		  <li> lab2
		</ul>
		<p>
		 
=cut 

sub string_byauthors_html 
{
    my (@article) = @_;
    my $string;
    my $number = @article;
    $string = "<p>Number of authors: $number<p>\n";
    my $i = 1;
    foreach my $item (@article) {
	$string .= "<hr>\n";
	my ($author,@labs) = @$item;
	$string .= "$i <p>";
	$string .= "<p>" . accent($author) . "\n<ul>";
	foreach my $lab (@labs) { 
	    $string .= "<li> " . accent($lab) . "</li>\n";
	}
	$string .=  "</ul><p>\n";
	$i = $i + 1;
    }
    $string .= "</hr>\n";
    return $string;
}


#############################


=head2 C<string_bylabs_html> - PrintReturn a string with all the laboratories with authors using html tags 
	
		<hr>
		lab1 
		<p>
		<ul>
		  <li> author1
		  <li> author2
		</ul>
		<p>
		
=cut 

sub string_bylabs_html 
{
  my (@article) = @_;
  my $string;
  my @article_bylab = author_to_lab(@article);
  my $number = @article_bylab;
  $string = "<p>Number of labs: $number<p>\n";
  my $i = 1;
  foreach my $item (@article_bylab) {
    $string .= "<hr>\n";
    my ($lab,@authors) = @$item;
    $string .= "$i <p>";
    $string .= "<p>" . accent($lab) . "\n<ul>";
    foreach my $author (@authors) { 
      $string .=  "<li> " . accent($author) . "</li>\n";
    }
    $string .= "</ul><p>\n";
    $i = $i + 1;
  }
  $string .= "</hr>\n";
  return $string;
  }


#######################################################################
#
# Generic functions to extract the authors and laboratories in a latex string 
#
# In these function $name1 is the string command for author list (author)
# and $name2 the string command for laboratory (institution).
# Don't use \ in the command name.   
#
# eg: grepautaff("author,"adr",$tex_string);
# 
#######################################################################

########################################################################
#
# pattern 1:
#
# \auteur 
# \adr 
#  
# \author[ref_adr1]{name1} 
# \adr[ref_adr1]{name1} 
# \thanksref \thanks 
#
#######################################################################

sub grepautaff
  {
    my ($name1,$name2,$string_tex) = @_ ;

    my @article_t=();
  
    # get lab name in \newcommand 
  
    my %list_index_author;
    my %list_index_labo;
  
    #

    my $and;

    my %laliste;
 
    #  for $file (@mfile){
    #  print "file: $file \n";
    %laliste = newcommand($string_tex);
 
    my %thanks;
    my %thanks_index = list_index("thanks",$string_tex);

    my ($debut_string,@texte_tex) = split(/\\$name1/,$string_tex);
 
    #   open(A,$file) or die "cant open $file\n";
    #   <A>;
    #   while(<A>){
  
    foreach (@texte_tex) {
      chomp;

      my @item = ();
      #     print "$name2\n";;
      $_ =~ s/\\altaffiliation/\\affiliation/g if ($name2 eq "affiliation");
      #print "s1=$_ \n" ;
      #my $author;
      # traite crochet []

      my ($textecrochet,$texteapres) = extract_bracketed($_,"[");
      #print "1 = $textecrochet \n";

      my ($author,$suitetexte) = extract_bracketed($texteapres,"{");

      #print "s1=$_ \n" ;

      $author = bichop($author);
      # au1 \AND au2

      if ($author =~ /\\and/) {
	$and = 1;
      }

      #print "<br>1=$author";
      $_ =$author;
      my ($index_th) = /\\thanksref\{(\w+)\}$/; 
      #my $index_th = $1;
      $author = accent($author);
      my $string_thanks = $thanks_index{$index_th};

      $string_thanks =~ s/Present address://;
#      $string_thanks =~ s/on leave from//;
      $thanks{$author} = $string_thanks if (($index_th ne "") &&($thanks_index{$index_th} =~ /address/));
      #print "<br>2=$author --- $string_thanks --- $index_th";

      $textecrochet = bichop($textecrochet);
      $list_index_author{$author} = $textecrochet if ($textecrochet ne "");
      #print "<br>a= $author \n";
      $author =~ s/, and/ and/;
  
      push(@item,$author) if ($author ne "");
      #print "s2=$suitetexte \n" ;

      my ($vide,@next) = split(/\\$name2/,$suitetexte);


      foreach my $texte (@next) {
	#my $labo;
	#print "t= $texte \n";
	my ($textecrochet,$texteapres) = extract_bracketed($texte,"[");
	#print "2 = $textecrochet \n";

	my ($labo,$xyz) = extract_bracketed($texteapres,"{");
	#print "0 =$labo \n";
	$labo = bichop($labo);
	$labo =~ s/^ \s*//g; 
	$labo =~ s/\s*$//g;

	$textecrochet = bichop($textecrochet) if ($textecrochet ne "");
	#print "<br>$textecrochet = $labo \n";
	$list_index_labo{$textecrochet} = $labo ;

	$labo = $laliste{$labo} if ($laliste{$labo} ne "");
	$labo = accent($labo); 
	#print "2 = $labo \n";
	push(@item,$labo) if ($labo ne "");
      }
      push(@article_t,\@item);

    }				# A
    #  } #$file


    #return @article_t;
    my @article;
    if ($and == 0) {
      ####
      # traite \aut{A and B} \lab l -> A l , B l 
      # et aussi \au A \au B \lab l -> A l , B l
      # \au[ind_lab]{aut}  \lab[ind_lab]{lab} -> aut lab
      # \author[ind_lab1,ind_lab2]{name1} 

      #my @article;
      my @listeattente;
      foreach my $s (@article_t) {
	my ($auto,@labo) = @$s;

	my $labo1 =  $labo[0];


	if ($list_index_author{$auto} ne "") {
	  my @item;

	  my $index_labo = $list_index_author{$auto};
	  #print "<br>a=$auto";
	  push(@item,$auto);


	  # \author[lab1,lab2]{name1}

	  my @tab_index_lab = split(/,/,$index_labo);

	  foreach (@tab_index_lab) {
 
	    #push(@item,$list_index_labo{$index_labo});
	    #print "<br>$_ = $list_index_labo{$_}"; 
	    push(@item,$list_index_labo{$_});

	  }
	  push(@item,$thanks{$auto}) if ($thanks{$auto} ne "");
	  #push(@item,@labo);
	  push (@article,\@item);


	} elsif ($labo1 ne "") {
	  # autre

	  foreach my $auteurwait (@listeattente) { 

	    my @item;
	    push(@item,$auteurwait);
	    push(@item,@labo);
	    push (@article,\@item);
	  }

	  my @auteuritem=split(/,| and /,$auto);
	  foreach my $unauteur (@auteuritem) {

	    my @item; 
	    push(@item,$unauteur);
	    push(@item,@labo);
	    push (@article,\@item);
	  }

	  @listeattente = ();

	  #@listeauteur = ();
	  # last 


	} else {

	  push(@listeattente,$auto);
	}

      }				# foreach authorrwait

    } else			# $and = 1
      {
	#my @article;

	foreach my $s (@article_t) {

	  my ($aute,$labo) = @$s;

	  my @auteur = split(/\\and/,$aute);
	  my @labo = split(/\\and/,$labo);

	  my $nbre = @auteur;

	  my $i = 0;

	  foreach (@auteur) {
	    my @doc2;

	    push(@doc2,$_);
	    push(@doc2,$labo[$i]);

	    $i = $i +1;
	    push(@article,\@doc2), 
	  }			#for @auteur

	}			# for s 
 

      }				# and =1

    @article;
  }				#sub 


  
#########################################################################
# 
# pattern 2:
#
# aastex
#
# \author{ author1\altaffilmark{1}, author2\altaffilmark{2} }
# \altaffiltext{1}{lab1} 
# \altaffiltext{2}{lab2}
#
#########################################################################

sub grep_aut_altaff		
{
	my ($string_tex) = @_ ;
	my @article;
	# for list_index: transform {1} -> [1]
	$string_tex =~ s/\\altaffiltext{([^}]+)}/\\altaffiltext[$1]/g;
	my %listlab = list_index("altaffiltext",$string_tex);
	my @author_string = greplatexcom("author",["t"],$string_tex);
	my $authors = bichop($author_string[0]->{t});
	my @authors_array = split(/,/,$authors);
	foreach (@authors_array)	
	{	 
		/([^\\]+)\\altaffilmark{([^\\]+)}/;
		my @item;
		push(@item,$1);
		push(@item,$listlab{$2});
		push(@article,\@item);				
	}
	return @article;
}

#########################################################################
#
# pattern 3:
#
# \author{ author \\ lab}
#
#########################################################################

sub grepaut
{
    my ($name1,$string_tex) = @_ ;

    my @article;
    #print "in grepaut\n";
    my ($debut_string,@texte_tex) = split(/\\$name1/,$string_tex);

    foreach (@texte_tex) {
	chomp;

	my @item = ();
      
	my ($textecrochet,$textafter) = extract_bracketed($_,"[");
	#print "1 = $textecrochet \n";
	#print "2= $texteapres\n";
	my ($authorLab,$suitetexte) = extract_bracketed($textafter,"{");

	#print "s1=$_ \n" ;

	$authorLab = bichop($authorLab);
	# au1 \AND au2
	#print "a=$authorLab\n";

	my ($author,@lab)=split(/\\\\/,$authorLab);
	#print "a=$author\n";

	my @tab_author = split(/,| and /,$author);
	#print $tab_author[0];

	my $lab_string;
	foreach (@lab) {
	    s/\\and/./g;
	    s/,$/, /g;
	    $lab_string .= $_ . ","; 
	}
	$lab_string =~ s/^\s*//g;

	#print "l=$lab_string\n";
	foreach (@tab_author) {
	    my @item;
	    push(@item,$_);
	    push(@item,$lab_string);
	    push(@article,\@item);
	}

	return @article;

  
    }
}

#########################################################################
#
# pattern 4:
#
# \author{ author1 \lab{address}}
#
#########################################################################

sub grepautadd
  {
    my ($name1,$name2,$string_tex) = @_ ;
  
    my @rf=();    

    my ($debut_string,@texte_tex) = split(/\\$name1/,$string_tex);

    foreach (@texte_tex) {
      chomp;

      my $aut_lab;

      my %ref;

      ($aut_lab,$_) = extract_bracketed($_,"{");

      $aut_lab = bichop($aut_lab);
      $aut_lab =~ s/^\s//g; 
      $aut_lab =~ s/\s$//g;


      my (@suite) = split(/\\$name2/,$aut_lab);

      my @r;

      my $begin = 1;

      my $rnom; 
      foreach my $texte (@suite) {
	my $courant; 
	if ($begin == 0) {
	  # [lab_index] -> lab_name
	  my $laref;
	  my $leadr;

	  ($laref,$courant) = extract_bracketed($texte,"[");
	  ($leadr,$courant) = extract_bracketed($texte,"{");

	  $laref = bichop($laref);
	  $leadr =  bichop($leadr);

	  $ref{$laref} = $leadr if ($laref ne "");

	  # push address
	  if ($texte =~ /mark\[(.*)\]/) {
	    my $relf = $1;
	    my $leadr = $ref{$relf};
	    $leadr = accent($leadr);
	    push(@r,$leadr);

	  } else {
	    $leadr =~ s/\\.*{.*}//g;
	    $leadr = accent($leadr);
	    push(@r,$leadr);
	  }
 
	  if ($rnom ne "") {
	    my @tab = @r;
	    push(@rf,\@tab); 
	  }

	}			# begin == 0

	@r = ();
	$courant = $texte if ($begin == 1);
	$courant =~ s/\n/ /g;
	$courant =~ s/\\.*{.*}//g;
	$courant =~ s/^mark\[.*\]//g;
	$rnom = $courant if (!($texte =~ /mark\[(.*)\]/));
	my $chaine = accent($courant); 

	# push author

	push(@r,$chaine) if ( (! ($texte =~ /mark\[(.*)\]$/)) && (($begin == 1 )|| ($courant =~ /,|and/) )) ;
	$begin = 0;
      }

    }				# A

    #} # file

    return @rf;
  }				#fonc


#####################################################
#
# pattern 5:
#
# for aip articles
#
# \aut{nom}{address={adr1},altaddress={adr2}}
#
#####################################################


sub grepautadd_eq
{
    my ($name1,$name2,$string_tex) = @_ ;
    #print $string_tex;
    my @article=();
  
    my ($debut_string,@texte_tex) = split(/\\$name1/,$string_tex);

    foreach (@texte_tex) {
	chomp;
	#print ;
	my $aut;
	my $lab; 

	my @item;

	($aut,$lab) = extract_bracketed($_,"{");

	$aut = bichop($aut);
	$lab = bichop($lab);  
	$aut =~ s/^\s//g; 
	$aut =~ s/\s$//g;

	push(@item,$aut);

	my ($begin,@suite) = split(/${name2}=/,$lab);
        
    #    my @r;
    #    my $begin = 1;

#    my $rnom; 
 
    foreach my $texte (@suite) {
	#print "t=$texte \n";
	my ($leadr,$courant) = extract_bracketed($texte,"{");
	$leadr = bichop($leadr);
	#print "adr=$leadr \n";
	push(@item,$leadr);
    }
    push(@article,\@item);
}
return(@article);
}


######################################################### 
#
# pattern 6: 
#
# \author{name1$^1$, name2 
# \\ 
#  $^1§  labo\\
# }  
#
#########################################################


sub grepaut_math
  {
    my ($name1,$string_tex) = @_ ;

    my @article=();

    my @grep_author_lab = greplatexcom("$name1",[["arg"],"t"],$string_tex);
    my $author_lab =  bichop($grep_author_lab[0]->{t});

    my ($authors,@labs) = split(/\\\\/,$author_lab);

    my $lab_string;

    foreach (@labs) {
      $lab_string .= $_;
    }

    my @tab_authors = split(/\$/,$authors);

    my ($empty,@tab_address) = split(/\$/,$lab_string);

    my %labo;

    my $i = 0;
    my $indice;

    foreach (@tab_address) {
      if (!($i % 2)) {
	#print "<br>i=$_\n";
	/\^{?([\w\\]+)}?/;
	#print "i1= $1\n";
	#s/^\^//;
	$indice = $1;
      } else {
	s/Present address://; $labo{$indice} = $_; $indice = "";
      }
#      print "<br>la=$_\n";
      $i = $i +1;
    }

    my @list_author;
    my %name;
    my $author;
    $i = 0;

    foreach (@tab_authors) {

      if ($i % 2) { 
	/\^{?([\w,()\\]+)}?/;
#	print "<br>$i l=$_\na=$1\n";

	$name{$author} = $1; 
	push(@list_author,$author);
	$author = "";
      } else {
	#s/^\s*and //;
	#s/,$//;
#	print "<br>$i b=$_\n";
	$author = $_;
	$author =~ s/,\s*\\newauthor//g;
#	print "<br>$i au=$author\n";
      }
      $i =$i + 1;
#    print "<br>$_";

    }

    foreach (@list_author) {
      my @item;
      #print "$_<br>";
      push(@item,$_);
      #print "<br>$_ $name{$_}";
      my @tab_indice = split(/,/,$name{$_});
      foreach (@tab_indice) {
	push(@item,$labo{$_});
      }
      push(@article,\@item);
    }
    return @article;

  }


########################################################
#
# pattern 7:
#
# \aut {name1,$^1$ name2,$^2$  name3,$^{1,2}$}
# \lab {$^1$lab1 $^2$lab2}
# 
# \aut{name1 $^1$}
# \aut[name2 $^2$}
# \lab{$^1$ lab1}
# \lab{$^2$ lab2} 
#
########################################################


sub grepautadd_math 
  {
    my ($name1,$name2,$string_tex) = @_ ;

    my @article=();

    my $authors;
    my $address;

    my @aut = greplatexcom("$name1",["t"],$string_tex);
    foreach (@aut) {
      $authors .= bichop($_->{t}). ", ";
    }

    #(bichop($aut[0]->{t})
    my @addr=  greplatexcom("$name2",[["arg"],"t"],$string_tex);
    foreach (@addr) {
      $address .= bichop($_->{t}). ", ";
    }
  
    my @tab_authors = split(/\$/,$authors); 
    #print"<br>";
    my $i = 0;
    my %name;
    my %labo;
    my @list_author;

    my ($empty,@tab_address) = split(/\$/,$address);

    my $indice;
    my $author;

    foreach (@tab_address) {
      if (!($i % 2)) {
	#print "i=$_\n";
	/\^{?([\w,()]+)}?/;
	#print "i1= $1\n";
	#s/^\^//;
	$indice = $1;
      } else {
	$labo{$indice} = $_; $indice = "";
      }
      #print "la=$_\n";
      $i = $i +1;
    }

    $i = 0;

    foreach (@tab_authors) {
      if ($i % 2) { 
	/\^{?([\w,()]+)}?/;
	#/\^{?\(?([\w,]+)\)?}?/;
	#print "l=$_\na=$1\n";
	$name{$author} = $1; 
	push(@list_author,$author);
	$author = "";
      } else {
	s/^\s*and //;
	s/,$//;
	#print "b=$_\n";
	$author = $_;

      }
      $i =$i + 1;

    }

    foreach (@list_author) {
      my @item;
      #print "$_<br>";
      push(@item,$_);

      my @tab_indice = split(/,/,$name{$_});
      foreach (@tab_indice) {
	push(@item,$labo{$_});
      }
      push(@article,\@item);
    }
    return @article;
  }


#################################################################
#
# Functions for collaboration (physics)
#
# Collaborations now available: h1, aleph, l3, na59, babar, zeus
#
# Each function try to extract authors and lab with the special
# pattern used by a collaboration 
#
################################################################

################################################################
#
# Call the good function to extract authors and labs for
# articles with a collaboration name 
#
################################################################  

  
sub func_by_coll
{
    my ($string,$collaboration) = @_;
    my @article;
    @article = extract_article_h1($string) if ($collaboration eq "h1");
    @article = extract_article_aleph($string) if ($collaboration eq "aleph");
    @article = extract_article_l3($string) if ($collaboration eq "l3");
    @article = extract_article_na59($string) if ($collaboration eq "na59");
    @article = extract_article_babar($string) if ($collaboration eq "babar");
    @article = extract_article_zeus($string) if ($collaboration eq "zeus");
    return(@article);
}


###################################################################
#
# Collaboration 1: Na59
# 
# Extract authors and lab for article of Na59 collaboration 
#
#  external file with \author and \affiliation
#
###################################################################


sub extract_article_na59
{
    my ($string) = @_;
    my $chaine_file = $string ;
    return grepautaff("author","affiliation",$chaine_file);
}


##################################################################
# 
# Collaboration 2: H1
# 
# Extract authors and lab for article of H1 collaboration
#
# external file 
# I.~Name$^{24}$
# ...
# $ ^{24}$ lab name \\
#
###################################################################


sub extract_article_h1
{
    my ($string) = @_;
    my $chaine_file = $string ;
    #print $chaine_file;

    my $out_author = 0; 

    my @tab_au;
    my @tab_lab;
    my %name_lab;
    my $i;
    my $ligne_lab;
    my $chaine;
    my $author;
    my $index;

    #while (<>)

    my @tab_chaine = split(/\n/,$chaine_file);


    foreach (@tab_chaine) {
	# author 
	#print "l=$_\n";

	if ((/(^[^\s]+.*)\$\^{([\s\w,]+)}\$(,?)\s/) && ($out_author == 0)) {
	    #print "$_\n";
	    $out_author = 1 if ($3 eq "");
	    #print "out = $out_author $3 \n";
 
	    my $auteur = $1;
	    $auteur = accent($auteur);
	    #print "x=$auteur $1 $2\n";

	    my $index_lab = $2;
	    $index_lab =~ s/^\s*//;
	    $index_lab =~ s/\s*$//;

	    my @liste_t = split(/,/,$index_lab); 
	    my @liste;
	    my $chaine;

	    foreach (@liste_t) {
		push (@liste,$_) if (/\d+/);
	    }

	    #	print $_;
	    #print "a=$auteur";

	    #foreach my $in (@liste) 
	    #{
	    #print " i=$in";
	    #}
	    #print "\n"; 

	    #$tab_aut{$auteur} = \@liste;

	    $tab_au[$i] = $auteur;
	    $tab_lab[$i] = \@liste; 
	    $i = $i + 1;

	    #print "$i $tab_lab[$i][0] \n";
	}
	#print "n=" . @tab_au . "\n";

	# lab 
	if ( (/\$\s*\^{(\d+)}\$(.*?)(\$.*\$)?\s\\\\/) && ($out_author == 1) ) {  
	    #print "ligne1= $1 $2\n";
	    my $index= $1;
	    my $labo  = $2;
	    $index =~ s/^\s*//g;
	    $index =~ s/\s*$//g;
	    #print "ligne= $1 --- $2\n";
	    $labo = accent($labo);
	    $name_lab{$index} = $labo;
	    #print "li=$index $labo\n";
	    # more than 1 line
	} elsif ( (/\$\s*\^{(\d+)}\$(.*)\s*/) && ($out_author == 1) ) { 

	    $ligne_lab = 1;
	    $chaine = $2;
	    $index = 0;
	    $index = $1;
	    $index =~ s/^\s*//g;
	    $index =~ s/\s*$//g;

	    #print "12= $1 $2\n";
	} elsif ( (!/\\\\$/)  && ($ligne_lab == 1) ) {
	    #print "3s $_";
	    /(.*)/;
	    #print "3=$1\n"; 
	    $chaine .= " $1"; 

	} elsif ( (/(.*?)(\$.*\$)?\s*\\\\$/) && ($ligne_lab == 1) ) {

	    #print "4=$1\n";
	    $chaine .= " $1";
	    #print "$chaine\n";
	    $chaine = accent($chaine);
	    $name_lab{$index} = $chaine;
	    $ligne_lab = 0;
	    $chaine = "";
	}
    }

    my @total;

    my $nb_aut= @tab_au;

    #foreach my $author (keys %tab_aut)
    my $j;

    for ($j=0 ;$j < $nb_aut; $j++) {
	#print "au=$author\n";
	my @tableau;

	push(@tableau,$tab_au[$j]);

	#print "j $j = $tab_au[$j] \n";

	#print "t= $tab_au[$j] \n";

	my $adr = $tab_lab[$j];
	foreach my $lab (@$adr) {
	    #print "   l= $lab\n";
	    #print "   nl= $name_lab{$lab} \n";
	    push(@tableau,$name_lab{$lab});
 
	}
	push(@total,\@tableau) 
    }

    #print_item(@total);

    return(@total);

    #print "ok \n";
}


###############################################################
#
# collaboration 3: Aleph
# 
# Extract authors and lab for article of Aleph collaboration 
#
# \begin{sloopypar} 
# aut1,
# aut2,
# \command
# name1
# name2
# \end
#
##############################################################


sub grep_article_aleph
{
    my ($string) = @_;
    my $chaine_file = $string ;
    my %index_tab = list_index("footnotetext",$chaine_file);

    my @liste = theenvs("sloppypar",$chaine_file);

    #print "l=$liste \n";
    my @article;
    my %liste_index;
    foreach my $list (@liste) {
	my @tab_chaine = split(/\n/,$list);

	my $lab;
	my $in_author = 0;
	my $in_lab =  0;
	my $ok_lab= 0;
	my %foot_note;	
	my @author_wait;
	foreach (@tab_chaine) {

	    #if ((/^\s*\\\w+/) && (! /^\\mbox{/) && ($in_author == 1)){ print "1=$_\n"; 
	    #		$in_author = 0; $in_lab = 1; } 


	    if ( ((/^\s*\\nopagebreak/) || (/^\s*\\samepage/)) && ($in_author == 1) ) { #print "1=$_\n"; 
		$in_author = 0; $in_lab = 1;
	    } elsif ((/^\w+,?/) && ($in_lab == 0)) {
		$in_author = 1; 
		s/\s*\$\^{(\w+)}\$\s*$//; my $index = $1; s/,//;  push(@author_wait,$_) ; 
		my $newlab = $index_tab{$index} ; 
		#print "21=$_\n";  
		$foot_note{$_} = $newlab if ($newlab ne "");
		#print "$_ XXXXXXX i=$index --- $newlab\n";
	    } elsif ((/^\s*\\mbox{(.*)}/) && ($in_lab == 0)) {
		$in_author = 1; $_ = $1;
		s/\s*\$\^{(\w+)}\$\s*$//; s/,//; my $index = $1; push(@author_wait,$_) ; 
		my $newlab = $index_tab{$index} ; 
		#print "22=$_\n";  
		$foot_note{$_} = $newlab if ($newlab ne "");
	    } elsif ((/^\w+,?/) && ($in_lab == 1)) {
		s/;
	    }
	    $//;		#print "3=$_\n";  
	    $lab .= "$_ "; $ok_lab = 1;
	} elsif ((/^\s*\\\w+/) && ($in_lab == 1) && ($ok_lab == 1)) { #print "4=$_\n";
	    $in_author = 0; $in_lab = 0;  

	    foreach (@author_wait) { 
		my @item;

		push (@item,$_);

		$lab =~ s/\$\^{[\w,]+}\$\s*$//; 
		$lab =~ s/\\footnotemark\[\w*\]//;
		push (@item,$lab);
		$foot_note{$_} =~ s/^Now at //;
		$foot_note{$_} =~ s/^Also at //;
		$foot_note{$_} =~ s/Permanent address: //;
		push(@item,$foot_note{$_}) if (($foot_note{$_} ne "") && (! ($foot_note{$_} =~ /^(Research|Deceased|Supported)/)));
		push(@article,\@item);
	    }

	}

    }
}
return(@article);
}

##############################################################
#
# Collaboration 4: L3
# 
# Extract authors and lab for article of the L3 collaboration
#
# external file (\input)
#
# name1\r\tute\reflab\
# name2\r\tute{\reflab1,\reflab2}\
#
# \item[\reflab1] lab1
# \item[\reflab2] lab2
#
#################################################################
		

sub extract_article_l3
{
    my ($string) = @_;
    my $tex_string = $string;

    $tex_string =~ s/\\item/\}\\item/g;
# \1 -> $1
    $tex_string =~ s/(\\item\[.*\])/$1\{/g;

    #print $tex_string;

    my %index_tab = list_index("item",$tex_string);

    my @article;

    #my @liste = theenvs("sloppypar",$chaine_file);
    #\r\tute
 
    my %name;

    my @tab_line = split(/\n/,$tex_string);
    my @line_author =grep (/\\r\\tute|\\rlap.\\tute/, @tab_line);
    #my @author_index = 

    map (s/\\r\\tute|\\rlap.\\tute/ / , @line_author);

    foreach (@line_author) {
	my @item;
	my ($author,$index_labo) = split(/\s/); 
	# add space : J.C. smith -> J. C. Smith 
	#$author =~ s/([^\.]+)$/~$1/;
	$author =~ s/\./\. /g;
	push(@item,$author);
	#print "$index_labo ";

	my @tab_index_lab = split(/,/,$index_labo); 

	foreach (@tab_index_lab) {
	    s/^{//;
		s/}?\\$//;
	    #print "$_ ";
	    my $lab = $index_tab{$_};
	    $lab =~ s/\$\^?{\\\w+}\$\s*$//; 
	    push(@item,$lab);
	    #print "$author $index_tab{$_}\n";
	}
	#print "$author\n";
	push(@article,\@item);
    }
    return(@article);
    #exit;
}


####################################################################
#
# Collaboration 5: Babar
# 
# Extract authors and lab for article of the Babar collaboration
# 
# \begin{center}
# author1,
# author2
# \inst{lab}
# author3,\footnote{note}
# \end{center}
#
##################################################################### 
 

sub extract_article_babar
  {
    my ($string) = @_;
    my @article;
    my $authors_labs_string;
    my @array = theenvs("center",$string);
    my $center_string;
    foreach $center_string (@array) {
      $authors_labs_string = $center_string;
      last if ($center_string =~ /\\inst/s);
    }
 
    my @labo = greplatexcom("inst",["lab"],$authors_labs_string);
    my @footnote = greplatexcom("footnote",["note"],$authors_labs_string);
    my $i = 0;
    my $j = 0;
    my %otherlab;
    my @authors_array;
   
    my @line_array = split(/\n/,$authors_labs_string);

    foreach my $line (@line_array) {
      if ((!($line =~ /~/)) && (!($line =~ /\\inst/))) {
	next;
      } 
      if (($line =~ /\~/) && (! ($line =~ /\\inst/))) { 
	if ($line =~ /\\footnote\{/) { 
#	  print "<br>$line -- $j -- $footnote[$j]->{note}<br>";
	  my $footlab =  $footnote[$j]->{note}; 
	  bichop($footlab); 
	  $footlab =~ s/Also with //;
#	  print "<br> s=$footlab <br>";
	  $line =~ s/,\\footnote{.*//; 
				 $otherlab{$line} = $footlab;
				 $j = $j + 1;
				}

	    if ($line =~ /\\footnotemark\[(\d+)\]/) {
	      my $note = $1;  $line =~ s/,\\footnotemark\[.*//; 
	      $note = $note -1;
#	      print "<br>mark ". $line . " -- " . $note  . " -- ". $footnote[$note]->{note} . " <br>";
	      my $footlab = bichop($footnote[$j - 1]->{note});
	      $footlab =~ s/Also with //;
	      $otherlab{$line} = $footlab;
	    }

	  $line =~ s/,$//; 
	  push(@authors_array,$line);
	}  
	if ($line =~ /\\inst/) {
	  bichop($labo[$i]->{lab});
	  foreach (@authors_array) {
	    my @item;
	    push(@item,$_); 
	    push(@item,$labo[$i]->{lab}); 
	    push(@item,$otherlab{$_}) if (($otherlab{$_} ne "") && ($otherlab{$_} ne "Deceased"));
	    push(@article,\@item); 
	  }
	  @authors_array = ();
	  $i = $i + 1; 
	}
      }
      return @article;
    }

   
####################################################################
#
# Collaboration 6: Zeus
# 
# Extract authors and lab for article of the Zeus collaboration
# 
# author1,
# author2,
# author3\\    
# {\it lab1}~$^{a}$
# author3$^{  1}$,
# 
# \newpage
#
###################################################################### 

sub extract_article_zeus
{	
	my ($string) = @_;
	my @article;
    	my @line_array = split(/\n/,$string);
	my $begin; my $in_lab; 
	my @authors;
	my $string_lab;
	foreach (@line_array)
	{
	if ((/\\Large/) && (/zeus/i)) { $begin = 1; }
	elsif (($begin == 1) && (/\\newpage/)) { $begin = 0; last;}
	elsif (($begin == 1) && (/,\s*$/) && (!(/\{\\it /)) && ($in_lab != 1)) { 
		s/\$\^\{[^}]+\}\$//; 
			my $author = $_;	 
		if (/\\mbox/){	my @author_tempo = greplatexcom("mbox",["author"],$_); $author = bichop($author_tempo[0]->{author});} 
		push(@authors,$author); }
	elsif (($begin == 1) && (/\\\\\s*$/) && (!(/\{\\it /)) && ($in_lab != 1)) { s/\$\^\{[^}]+\}\$//g; 
			my $author = $_;
		if (/\\mbox/){	my @author_tempo = greplatexcom("mbox",["author"],$_); $author = bichop($author_tempo[0]->{author});} 	
			 push(@authors,$author);}
	elsif (($begin == 1) && (/\{\\it /)) {$string_lab .= $_; $in_lab = 1; }	
	elsif (($begin == 1) && ($in_lab == 1) && (!(/\\par/))) {$string_lab .= $_;}
	elsif (($begin == 1) && ($in_lab == 1) && (/\\par/)) { 
		$string_lab =~ s/^\s*//g;
		my ($thelab,$next) = extract_bracketed($string_lab,"{"); 
		$in_lab = 0; $string_lab =""; 
		$thelab = bichop($thelab); $thelab =~ s/\\it\s*//g; 
	
		foreach (@authors)
		{       my @item; 
			push(@item,$_);
			push(@item,$thelab);
			push(@article,\@item);
		}
		
		@authors = ();	
	   }			
	
	}		
	return @article;
}    

####################################################################
#
# Collaboration 7: Fermilab
# 
# Extract authors and lab for article with Fermilab report
# 
# \begin{center}
# author1,$^1$
# author2,$^$2
# author3 
# \end{center} 
# \begin{enumerate}
# \item lab1
# \item lab2
# \end{enumerate}
#
# arXiv: hep-ex/0304017
#
###################################################################### 

sub extract_report_fermilab
{
	my ($string) = @_;
	my @article;
	my @center = theenvs("center",$string);	
        my @enumerate = theenvs("enumerate",$string);	
	my $string_authors = $center[1];
        my $string_labs  = $enumerate[0];
	my @labs = split(/\\item/,$string_labs); 
	my ($empty,@authors) = split(/\n/,$string_authors);
	
	foreach (@authors)
	{
		my @item;
		s/\^\*,//g;
		/([\w~\.-]+),?\$\^{?([\d]+)}?\$/;
	 	push(@item,$1);
	 	push(@item,$labs[$2]);
	 	push(@article,\@item);
		#print "<br>$_ --- $1 --- $2";	
	}
	return @article;
}
    
1;


__END__

=pod 

=head1 AUTHOR 

Christian Rossi (E<lt>rossi@in2p3.frE<gt> and E<lt>rossi@loria.frE<gt>) 

=head1 SEE ALSO

L<perl>, L<latex>, L<Text::Balanced>.

=cut
