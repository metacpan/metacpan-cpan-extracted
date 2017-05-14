#!/opt/perl5/bin/perl
#
# Copyright (C) 2001 Christopher White.  All rights reserved. This
#   program is free software;  you can redistribute it and/or modify it
#   under the same terms as perl itself.
#

$|=1;

$mystyle=<<END;
<!--
.smallContent { font-family: Verdana, Arial, Helvetica; font-size: .7em; color: black;}
.smallContenthead { font-family: Verdana, Arial, Helvetica; font-size: .7em; color: white;}
-->
END


use CGI ':standard';

$query = new CGI;

sub clear_it {
        print "Content-type: text/html\n\n";
        print "<body>\n";
        print "\n";
             }

@hphosts=("youhostnamehere", "hostname");

sub query_main {
        print header;
        print start_html(-title=>'HP Disk Mapper',-BGCOLOR=>'white', -style=>{-code=>$mystyle} ),
        h1('HP Disk Mapper'),
        start_form( -class=>'smallContent' ),br,
	"This cgi will display physical volume data per volume group." ,br,
	"Useful for looking for extra space for expansion.",br,
	"<TABLE WIDTH=600> <TR>  <TD WIDTH=150 VALIGN=TOP>",
"<TR><TD>Select Host</TD><TD>",textfield(-name=>'cgi_hpsystem_single'),"</TD></TR>",
"<TR><TD>Optionally highlight filesystem</TD><TD>",textfield('cgi_hpfilesystemhl'),"</TD></TR>",
"<TR><TD>Postscript output?</TD><TD>",	radio_group(-name=>'cgi_postout',
                                -values=>['yes', 'no'],
                                -default=>'no'),"</TD></TR>",
"<TR><TD>Optional PS filename</TD><TD>",textfield('cgi_psfile_name'),"</TD></TR>",
"<TR><TD>Optional LVM data filename</TD><TD>",textfield('cgi_datafile_name'),"</TD></TR>",
"<TR><TD>remsh or ssh</TD><TD>",radio_group(-name=>'cgi_rtype',
                                -values=>['remsh', 'ssh'],
                                -default=>'ssh'),"</TD></TR>",
"<TR><TD>Use data from last run?</TD><TD>",radio_group(-name=>'cgi_persist',
                                -values=>['yes', 'no'],
                                -default=>'no'),"</TD></TR>",
	"</TD> <TD VALIGN=TOP>",
	"</TD></TR></TABLE>",br,
        br,submit(-name=>"Submit Change"),br,
        reset(-name=>"Reset Form"),br,
        end_form;
		}
if (param())    {
	$final_hpname_test=$query->param('cgi_hpsystem_single');
	$final_persist=$query->param('cgi_persist');
	if  ( $final_persist eq "yes" )	{
		$final_persist="old";
					}
	else				{
		$final_persist="new";
					}
	$final_post=$query->param('cgi_postout');
	if ($final_post eq "yes" )	{
		$final_post=1;
					}
	else				{
		$final_post=0;
					}
	$final_post_name=$query->param('cgi_psfile_name');
	$final_data_name=$query->param('cgi_datafile_name');
	$final_type=$query->param('cgi_type');	
	$final_fshighlight=$query->param('cgi_hpfilesystemhl');	
	$final_rtype=$query->param('cgi_rtype');	
if ( length($final_hpname_test) > 1 ) 		{
	$final_hpname=$final_hpname_test;
	$myurl = 'http://maximus.wireless.attws.com/cgi-bin/hp_disk_info.cgi?p_hpsystem='.$final_hpname.'&p_type='.$final_type.'&p_filesystemhl='.$final_fshighlight.'&p_rtype='.$final_rtype.'&p_post='.$final_post.'&p_loc_data='.$final_data_name.'&p_post_data='.$final_post_name.'&p_persist='.$final_persist;

	print redirect(-uri=>"$myurl");
						}
else						{
 	$final_hpname=$query->param('cgi_hpsystems');
						}

	$myurl = 'http://maximus.wireless.attws.com/cgi-bin/hp_disk_info.cgi?p_hpsystem='.$final_hpname.'&p_type='.$final_type.'&p_filesystemhl='.$final_fshighlight.'&p_rtype='.$final_rtype.'&p_post='.$final_post.'&p_loc_data='.$final_data_name.'&p_post_data='.$final_post_name.'&p_persist='.$final_persist;
	print redirect(-uri=>"$myurl");

                }
else    {
query_main;
        }
 print hr;
 print "</HTML>\n";
