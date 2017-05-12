#!/usr/bin/perl 
# 
# Example cgi script that use LaTeX::Authors.pl
#
# Upload a tex file or a tar file (for example an arXiv tar file) 
# and show the authors and laboratories. 
#
# First the script upload the file, copy it to /tmp/author/$$, uncompress
# if needed, find the authors and lab and print it with html tags.
#      
# By Christian Rossi (rossi@in2p3.fr and rossi@loria.fr)
# CCSD/CNRS (http://www.ccsd.cnrs.fr/)
#
# version 0.1 - 2003/04/10 
#
   

use LaTeX::Authors;
use CGI qw(:standard);
use strict;

# tmp working directory 

my $ROOT_TEMP_DIR = "/tmp/author";

my $query = new CGI;

#  
# no param so print upload form  
#  

if (!param()) {	
  
    print $query->header,
          $query->start_html('Extract authors from LaTeX file'),
	  $query->h1('Extract authors and labs from a LaTeX file'),
	  $query->hr,
          $query->start_multipart_form, 
          $query->filefield(-name=>'uploaded_file',
			    -default=>'starting value',
			    -size=>50,
			    -maxlength=>80);			
    print p;
    print "";	  
    print $query->checkbox(-name=>'by_labs',
			   -value=>'1',
			   -label=>' By laboratories');                 
    print p;
    print $query->submit(-name=>'button_name', 
			 -value=>'Load file');
    print "&nbsp;  &nbsp;";
    print $query->reset, 
          $query->end_form,     
          $query->hr,	   
          $query->end_html;			      			      

} else {

#
# if param do the work						
#

    print $query->header,
          $query->start_html('Authors list in LaTeX file'),
	  $query->h1('Authors and laboratories in LaTeX file');

    my $fh = $query->param('uploaded_file');
    my $by_labs = $query->param('by_labs'); 

    my $filename = $fh;
    my $pid = $$;
    
    # test dir 
    if (!(-d $ROOT_TEMP_DIR)) {
	if (!(mkdir($ROOT_TEMP_DIR))) {
	    print("Error: Can't create directory $ROOT_TEMP_DIR"); exit(250);
	}
	if (!(-w $ROOT_TEMP_DIR)) {
	    print("Error: Unwritable directory $ROOT_TEMP_DIR");exit(249);
	}
    }
  
    my $TEMP_DIR = $ROOT_TEMP_DIR . "/" . $pid;

    if (!(-d $TEMP_DIR)) {
	if (!(mkdir($TEMP_DIR))) {
	    print("Error: Can't create directory $TEMP_DIR"); exit(248);
	}

	if (!(-w $TEMP_DIR)) {
	    print("Error: Unwritable directory $TEMP_DIR");exit(247);
	}
    }

    if (!(chdir($TEMP_DIR))) {
	print("Error: Can't cd to directory $TEMP_DIR"); 
	exit(246);
    }

    $filename =~ s/.*\\//;	# Remove everything before a "\" (MSDOS or Win)
    $filename =~ s/.*\://;	# Remove everything before a ":" (MSDOS or Win)
    $filename =~ s/.*\///;	# Remove everything before a "/" (UNIX)
    $filename =~ s/ /_/g;	# Change spaces into underscores
    $filename =~ tr/A-Z/a-z/;
 
    # upload 
    open(OUTFILE,">$TEMP_DIR/$filename");

    my $buffer;

    while (my $bytesread = read($fh,$buffer,1024)) {
	print OUTFILE $buffer;
    }

    close(OUTFILE); 

    # uncompress tar, zip...
    un_archive($TEMP_DIR);
    	 
    my $tex_file = find_tex_file($TEMP_DIR);
	
    print "File name = $tex_file<br>\n";
  
    # load tex file to a string
    my $tex_string = load_file_string($tex_file);		

    # return authors and labs
    # where @doc = (\@item1, \@item2,...) 
    # and @item1 = (author1, lab1, lab2) 			         	
    my @doc = router($tex_string);

    my $html_string;

    # html list
    if ($by_labs) {
	$html_string = string_bylabs_html(@doc);  
    } else {		
	$html_string = string_byauthors_html(@doc);
    }
   
    # print authors and labs list
    print $html_string;

    print p,hr,p;

    # print tex file     
    print "<pre>";
    print $tex_string; 
    print "</pre>";

    print $query->end_html;

}			      
			      
			      
			      
