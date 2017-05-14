#!/usr/bin/perl
#
# Copyright (C) 2001 Christopher White.  All rights reserved. This
#   program is free software;  you can redistribute it and/or modify it
#   under the same terms as perl itself.
#

use HPUX::LVM;
use HPUX::Ioscan;
use HPUX::FS;
use CGI qw/:standard :html3/;

$debug=0;
$debug5=0;
$debug6=0;
$debug8=0;
$debug9=0;
$tablecnt=0;
$maxentries=0;
$tableentries=0;
$tableentries_save=0;

$query=new CGI;

$sub_system = $query->param('p_hpsystem');
$sub_type   = $query->param('p_type');
$sub_fshighlight = $query->param('p_filesystemhl');
$sub_rtype = $query->param('p_rtype');
$sub_post  = $query->param('p_post') || "0";
$sub_loc_data  = $query->param('p_loc_data')   || '/tmp/lvminfo.dat';
$sub_post_data  = $query->param('p_post_data') || '/tmp/postout.ps';
$sub_show_empty  = $query->param('p_show_empty') || 'no';
$sub_persist  = $query->param('p_persist') || 'new';

# Cgi setup stuff

#setup some custom html variables
		$html_border		=0;
		$html_cellheadercolor	="003366";
		$html_cellcolor		="CCCCCC";
		$html_font		="Helvetica";
		$html_headerfontcolor	="FFFFFF";
		$html_fontsize		="1";
		$html_cellfontcolor	="000000";


$|=1;

$myjavascript=<<END;
<!--
         width1 = 150 + 50
         config='directories=no,status=no,menubar=no,width='+width1+',height=150'
         config += 'toolbar=no,location=no,scrollbars=no,resizable=no'

         pop = window.open ("","pop",config)

         pop.document.write('<');
         pop.document.write('/SCRIPT><BODY BGCOLOR=blue TEXT=gold>');
         pop.document.write('<CENTER><B><H2>HP LVM Disk Info</H2></B></CENTER>');
         pop.document.write('<CENTER><FONT COLOR=white><B><H3>Please Wait... While This Page Loads</H3></B></CENTER>');
         pop.document.write('<CENTER><B><H6>This Window Will Close Itself...</H6></B></CENTER>');
         pop.document.write('</BODY>'); 
//-->
END



$mystyle=<<END;
<!--
.smallContent { font-family: Verdana, Arial, Helvetica; font-size: .8em; color: black;}
.smallContenthead { font-family: Verdana, Arial, Helvetica; font-size: .8em; color: white;}
-->
END

#check for postscript output option
# if sub_post=1 then do it.

if ( $sub_post ) {
	open (POSTOUT, ">$sub_post_data") or die "Unable to open postfile\n";
	&postscript_setup;
		 }

# start the html and put up a please wait javascript
print header();
print start_html(-title=>"Disk Layout of $sub_system",-style=>{-code=>$mystyle}, -script=>$myjavascript);

# Create data structures

my $lvminfo_data = new HPUX::LVM(
                                target_type     =>"local",
                                persistance     =>"$sub_persist",
                                datafile        =>"$sub_loc_data",
                                access_prog     =>"$sub_rtype",
                                access_system   =>"$sub_system",
                                access_user     =>"root"
                                );
print "<\BR><\BR>";

my $ioscan_data = new HPUX::Ioscan(
				target_type	=>"local",
				persistance	=>"$sub_persist",
				access_prog	=>"$sub_rtype",
				access_system	=>"$sub_system",
				access_user	=>"root",
				access_speed	=>"slow"
				);
print "<\BR><\BR>";
my $fsinfo_data = new HPUX::FS(
				target_type	=>"local",
				persistance	=>"$sub_persist",
				access_prog	=>"$sub_rtype",
				access_system	=>"$sub_system",
				access_user	=>"root"
				);
print "<\BR><\BR>";

#sample data structure traverse methods
#$junkme1	= $lvminfo_data->traverse();
#$junkme2	= $ioscan_data->traverse();
#$junkme3	= $fsinfo_data->traverse();

#Get a hash of all the pvlinks (if any)


my $hashref = $lvminfo_data->get_all_pvlinks;
print "Alternate Link Hash Ref is: $hashref\n" if $debug8;

my %linkhash = %$hashref;

#End of alternate link hash generation

print "Get Controllers!\n" if $debug;

$arref = $ioscan_data->get_disk_controllers();

# start main table thats gonna hold tables in its cells
# using raw HTML to create main table.

	$buffouttable_final='<TABLE BORDER=1>';

CONTRLOOP: foreach $contr ( @$arref )      {
	$maxentries=0;
        print "Controller: $contr\n" if $debug;
	$instance = $ioscan_data->get_instance_number(
				hwpath => $contr
						);
	$instance_desc = $ioscan_data->get_description(
				hwpath => $contr
						);
	print "Instance: $instance\n" if $debug;
	print "Get Disks in controller $contr\n" if $debug;

	$arref2 = $ioscan_data->get_all_disks_on_controller	(
				controller	=>"$contr"
								);
	if ( scalar(@$arref2) eq 0 and $sub_show_empty eq "no")	{
		print "No Devices on controller!\n" if $debug;
		next CONTRLOOP;
					}

	if ($sub_post)	{
$post_tablecnt=0;
print POSTOUT "\($contr Inst: $instance\) DoRowTitle\n";
			}

	$buffouttable_final=$buffouttable_final.'<TR><TH>'.$contr.'<BR> Inst: '.$instance.'<BR> Desc:'.$instance_desc.'</TH>';
	
	@rows=();
	@rows_good=();
	@headers=( "LVOL", "MNTPT", "EXT" );
#	push @rows_good, th({ -bgcolor=>$html_cellheadercolor, class=>'smallcontenthead' }, \@headers);
# adding some kind of device file sort order here:
	foreach $dsk ( @{ $arref2 } )	{
	$buffouttable_final=$buffouttable_final.'<TD VALIGN=top>';
	push @rows_good, th({ -bgcolor=>$html_cellheadercolor, class=>'smallcontenthead' }, \@headers);
         	print "disk: $dsk\n" if $debug;
		$getlvoldata = $lvminfo_data->get_disk_lvol_data(

				device_name	=> "$dsk"
								);
		@check_keys = keys %$getlvoldata;
		print "Check_keys is: @check_keys\n" if $debug5;
		print "scalar check_keys is:".scalar(@check_keys)."\n" if $debug5;
		 %disklvoldata = %$getlvoldata;
#alternative AUTOLOAD call (Kinda confusing, use the provided get methods)
#		 $total_pe_on_pv = $lvminfo_data->get_Total_PE( 
#				volume_group => $lv_vg,
#				vg_sub_cat   => Physical_Vols,
#				vg_sub_cat_pv=> $dsk, 
#							      ) || "\&nbsp";
		  @checklvols = (sort keys %disklvoldata);
		  print "Number of lvols: ",scalar(@checklvols),"\n" if $debug;
		  if ( scalar(@checklvols) < 1 )	{
			$total_pe_on_pv = "\&nbsp";
							}
		  foreach $lvol ( sort keys %disklvoldata )	{
			$tableentries++;
			$lv_vg = $disklvoldata{$lvol}->{vg_on_pv};
			$total_pe_on_pv = $lvminfo_data->get_vg_physicalvol_attr(
					volume_group 	=> "$lv_vg",
			 		device_name	=> "$dsk",
			 		attribute	=> "Total_PE" 
								);
			$stripes_on_lv = $lvminfo_data->get_vg_lvol_attr_lvdisplay(
					volume_group	=> "$lv_vg",
					logical_vol	=> "$lvol",
					attribute	=> "Stripes"
								);
			print "Total PE On PV=$total_pe_on_pv\n" if $debug;
			print "Volume Group: $lv_vg\n" if $debug;
			$lvolshow = $lv_vg.'/'.$lvol;
			print "Logical Vol: $lvol\n" if $debug;
			push @rows, $lvolshow;
			$mntpt = $fsinfo_data->get_filesystem_attr(
				filesystem	=> "$lvolshow",
				attribute	=> 'directory'
								);
			if ( $stripes_on_lv gt 0 )	{
#If stripes then do something useful
			$ordered_stripes_arr_ref = $lvminfo_data->get_vg_lvol_stripeorder(
					volume_group	=> "$lv_vg",
					logical_vol	=> "$lvol"
								);
			@ordered_stripes = @$ordered_stripes_arr_ref;
			$stripe_index=0;
			for ($i = 0; $i< @ordered_stripes ; $i++ ) 	{
				print "Ordered_stripes: $ordered_stripes[$i]\n<BR>" if $debug9;
				print "dsk: $dsk\n<BR>" if $debug9;
				if ( $ordered_stripes[$i] eq $dsk )	{
					$stripe_index=$i+1;
								}	
									}

				$mntpt=$mntpt.'(Stripe '.$stripe_index.' of '.scalar(@ordered_stripes);
							}
			if ( $mntpt eq "$sub_fshighlight" && $sub_fshighlight ne "" )	{
				$mntpt = '<FONT COLOR=RED>'.$mntpt.'</FONT>';
								}
			push @rows, $mntpt;
			print "  le_on_pv: $disklvoldata{$lvol}->{le_on_pv}\n" if $debug;
			push @rows, $disklvoldata{$lvol}->{pe_on_pv};
			print "  pe_on_pv: $disklvoldata{$lvol}->{pe_on_pv}\n" if $debug;
			$used_by_lv = $disklvoldata{$lvol}->{pe_on_pv};
			$used_pe = $used_pe + $disklvoldata{$lvol}->{pe_on_pv};
			push @rows_good, td({-bgcolor=>$html_cellcolor, -class=>'smallcontent'}, \@rows);
	if ($sub_post)	{
	$tablecnt++;
	$psbuff=$psbuff."\($rows[0]\) \($rows[1]\) \($rows[2]\) DoShadeRow\n";
	$psbufflen=$psbufflen."\($rows[0]\) check_length \($rows[1]\) check_length \($rows[2]\) check_length\n";
			}
	@rows=();
								}
#Count the number of rows in each disk and keep track of it so we can translate the postscript
# later the max number for that collumn.

	$tableentries_save = $tableentries;
if ($maxentries < $tableentries)	{
	print "TAbleEntries is: $tableentries<BR>\n" if $debug;
	$maxentries = $tableentries;
	print "Maxentries is now!: $maxentries<BR>\n" if $debug;
					}
	$tableentries=0;
	
	@total_line = ( "Total", "\&nbsp","$total_pe_on_pv" );
	$free_pe_on_pv = $total_pe_on_pv - $used_pe;
	$used_pe="";
	@free_line  = ( "Free" , "\&nbsp","$free_pe_on_pv"  );	
	push @rows_good,td({ -bgcolor=>$html_cellheadercolor, -class=>'smallcontenthead'}, \@total_line);
	push @rows_good,td({ -bgcolor=>$html_cellheadercolor, -class=>'smallcontenthead'}, \@free_line);

	if ($sub_post and $tableentries_save)	{
#	$psbuff=$psbuff."\($total_pe_on_pv\) \($free_pe_on_pv\ ) DoTotalandFree ".($tableentries_save+4)." check_ywrap\n";
	$psbuff=$psbuff."\($total_pe_on_pv\) \($free_pe_on_pv\ ) DoTotalandFree \n";
	$psbuff=$psbuff."/maxlength 0 def\n";
	$psbuff=$psbuff."/negmaxlength 0 def\n";
	$psbuff=$psbuff."\n";
	$psbuff=$psbuff."tablewidth totalrowwidthcalc\n";
	$psbuff=$psbuff."0 tablewidth htablepad add pretranslate \n";
	print "tableEntries_save is: $tableentries_save<BR>\n" if $debug;
	$psbuff=$psbuff."cellh \-".($tableentries_save+2)." mul 0 pretranslate\n";
	$psbuff=$psbuff."check_xwrap\n";
#temp add
	$psbuff=$psbuff.($tableentries_save+4)." check_ywrap\n";
#		$psbuff=$psbuff."0 negtotaltranslate translate\n";
#		$psbuff=$psbuff."/totaltranslate 0 def","\n";
#		$psbuff=$psbuff."/negtotaltranslate 0 def","\n";
#		$psbuff=$psbuff."/maxlength 0 def","\n";
#		$psbuff=$psbuff."/negmaxlength 0 def","\n";
	$post_tablecnt++;
			}
# Add alternate links to disk
	$disk_n_alt = $lvminfo_data->get_vg_alternate_links(
                volume_group    =>  $lv_vg,
                device_name     =>  $dsk
                                );
	print "disk_n_alt is:$disk_n_alt\n" if $debug5;
	print "disk_n_alt value is:@$disk_n_alt\n" if $debug5;
	@disk_n_alt_conv = @$disk_n_alt;
	$ps_disk_n_alt_good=$dsk;
	if ($disk_n_alt_conv[0] ne "None" and $disk_n_alt_conv[0] ne "NotDefined" )	{
	print "Alternate links found!\n" if $debug5;
	$ps_disk_n_alt_good=$dsk."LINK DATA";
	$disk_n_alt_good = $dsk.'<BR><FONT COLOR=GREEN>'.join('(link)<BR>', @disk_n_alt_conv).'(link)</FONT>';
									}
	else								{
	print "No alternate links found!\n" if $debug5;
	$disk_n_alt_good=$dsk;
									}
	 
		if (scalar(@check_keys) == 0 )	{
		$psbuff = "\(\) \( $ps_disk_n_alt_good \) MakeHeaderalt\n".$psbuff;
			print "No LVM found on this\n" if $debug5;
			print "Adding 1 to maxentries<BR>\n" if $debug;
			print "Makeing tableenties_save 1<BR>\n" if $debug;
			$maxentries++;
			$tableentries_save=1;
#
# If no LVM Found change the headings to device info type headings
#
			shift @rows_good;
			@headers=( "Class", "Driver", "Description" );
			$myhwpath = $ioscan_data->get_device_hwpath(
				device_name	=> $dsk
							);
			print "Myhwpath = $myhwpath\n" if $debug6;
			$myclass  = $ioscan_data->get_class(
				hwpath => $myhwpath
							);
			$mydriver = $ioscan_data->get_driver(
				hwpath => $myhwpath
							);
			$mydesc   = $ioscan_data->get_description(
				hwpath => $myhwpath
							);
			unshift @rows_good, th({ -bgcolor=>$html_cellheadercolor, class=>'smallcontenthead' }, \@headers);
			pop @rows_good;
			pop @rows_good;
			push @rows_good, td({-bgcolor=>$html_cellcolor, -class=>'smallcontent'}, [ $myclass, $mydriver, $mydesc ]);
			$disk_n_alt_good = $disk_n_alt_good.'<FONT COLOR=RED><BR>NOT IN LVM</FONT>';
#Add Disk Alternate Link Check Here
foreach $keyme ( sort keys %linkhash )     {
        print "Key: $keyme\n" if $debug8;
	$cntr=0;
        foreach $valueme ( @{ $linkhash{$keyme} } )        	{
		$cntr++;
		if (length($valueme) < 1)	{
			print "Value less than 1\n<BR>" if $debug8;
			print "Value is:",length($valueme),"<BR>\n" if $debug8;
					}
		
                print "Value: $valueme<BR>\n" if $debug8;
                print "disk_n_alt_good: $disk_n_alt_good<BR>\n" if $debug8;
		if ( $disk_n_alt_good =~ /$valueme<FONT/ )	{
			$disk_n_alt_good = $disk_n_alt_good."\<BR\>Link No. $cntr of $keyme";
							}
                                                        	}
                                        }
			$psbuff=$psbuff."\($myclass\) \($mydriver\) \($mydesc\) DoShadeRow\n";
			$psbufflen=$psbufflen."\($myclass\) check_length \($mydriver\) check_length \($mydesc\) check_length\n";
		$psbuff=$psbuff."/maxcellwidth maxlength def\n";
		$psbuff=$psbuff."/negmaxcellwidth maxcellwidth -1 mul def\n";
		$psbuff=$psbuff."/tablewidth maxcellwidth 3 mul def\n";
		$psbuff=$psbuff."/negtablewidth maxcellwidth  -3 mul def\n";
#	$psbuff=$psbuff."\(NA\) \(NA\ ) DoTotalandFree ".($tableentries_save+4)." check_ywrap\n";
	$psbuff=$psbuff."\(NA\) \(NA\ ) DoTotalandFree \n";
	$psbuff=$psbuff."/maxlength 0 def\n";
	$psbuff=$psbuff."/negmaxlength 0 def\n";
	$psbuff=$psbuff."tablewidth totalrowwidthcalc\n";
	$psbuff=$psbuff."0 tablewidth htablepad add pretranslate\n";
	print "Just added ending stuff to non lvm table<BR>\n" if $debug;
	$psbuff=$psbuff."cellh \-".($tableentries_save+2)." mul 0 pretranslate\n";
#temp add
	$psbuff=$psbuff.($tableentries_save+4)." check_ywrap\n";
	$psbuff=$psbuff."\n";
	$psbuff=$psbuff."\n";
	$psbuff=$psbuff."\n";
	print POSTOUT $psbufflen;
	print POSTOUT $psbuff;
	$psbufflen="";
						}
	else	{
	if ($sub_post)	{
#Dont need to check title length
#		$psbufflen =  $psbufflen."\($disk_n_alt_good \) check_length\n";
		print POSTOUT $psbufflen;
		print POSTOUT "/maxcellwidth maxlength def","\n";
		print POSTOUT "/negmaxcellwidth maxcellwidth -1 mul def","\n";
		print POSTOUT "/tablewidth maxcellwidth 3 mul def","\n";
		print POSTOUT "/negtablewidth maxcellwidth  -3 mul def","\n";
		print POSTOUT "","\n";
		$psbufflen="";
			}
		$psbuff = "\(\) \( $disk_n_alt_good \) MakeHeader\n".$psbuff;
		print POSTOUT $psbuff;
		}
#set it back
	@headers=( "LVOL", "MNTPT", "EXT" );
$buffouttable_single =  table({-border=>$html_border,-width=>'25%', -class=>'smallcontent'},
                        caption({-bgcolor=>$html_cellcolor, -class=>'smallcontent' },$disk_n_alt_good),
                        Tr(\@rows_good)
                        );		
			@rows=();
			@rows_good=();
			$psbuff="";
$buffouttable_final = $buffouttable_final.$buffouttable_single.'<TD>';
               		               	}

$buffouttable_final = $buffouttable_final.'</TR>';
if ($sub_post)	{
#		rewind to start of row
		$post_backup = $post_tablecnt*200;
		print POSTOUT "%Move to next row plus 4 row lengths\n";
	        print POSTOUT "cellh 4 mul 0 pretranslate\n";
		print POSTOUT "cellh 4 mul 0 pretranslate\n";
		print POSTOUT "0 negtotaltranslate pretranslate\n";
		print POSTOUT "/totaltranslate 0 def","\n";
		print POSTOUT "/negtotaltranslate 0 def","\n";
		print POSTOUT "/maxlength 0 def","\n";
		print POSTOUT "/negmaxlength 0 def","\n";
		}
		print "MaxEntries: $maxentries<BR>\n" if $debug;
                                }
print $buffouttable_final,'</TABLE>';
print end_html();

if ( $sub_post )	{
	print POSTOUT "showpage\n";
	close POSTFILE;
			}

sub postscript_setup	{

print POSTOUT "%","\n";
print POSTOUT "%------------defines--statics","\n";
print POSTOUT "%","\n";
print POSTOUT "%These values can be changed to whatever your prefrence","\n";
print POSTOUT "%","\n";
print POSTOUT "%height of font","\n";
print POSTOUT "/fonth 4 def","\n";
print POSTOUT "%global left margin","\n";
print POSTOUT "0 20 translate","\n";
print POSTOUT "%space between font and top/bottom of cell","\n";
print POSTOUT "/fontpad 2 def","\n";
print POSTOUT "%defines start of total row translation","\n";
print POSTOUT "/totaltranslate 0 def","\n";
print POSTOUT "/negtotaltranslate 0 def","\n";
print POSTOUT "%amount of pading between tables","\n";
print POSTOUT "/htablepad 4 def","\n";
print POSTOUT "%amount of points for whole sheet width lanscape","\n";
print POSTOUT "/widthofsheet 792 def";
print POSTOUT "%amount of points for whole sheet length tall","\n";
print POSTOUT "/lengthofsheet 612 def","\n";
print POSTOUT "%amount of padding between rows","\n";
print POSTOUT "/vtablepad 4 def","\n";
print POSTOUT "%left margin","\n";
print POSTOUT "/leftmargin 10 def","\n";
print POSTOUT "/rightmargin 10 def","\n";
print POSTOUT "%left side buffer between cell start and value","\n";
print POSTOUT "/lbuffstr 2 def","\n";
print POSTOUT "/maxlength 0 def","\n";
print POSTOUT "%pre translate variables","\n";
print POSTOUT "/xmove 0 def","\n";
print POSTOUT "/ymove 0 def","\n";
print POSTOUT "/totalxmove 0 def","\n";
print POSTOUT "/totalymove 0 def","\n";
print POSTOUT "%","\n";
print POSTOUT "%------------procedures","\n";
print POSTOUT "%","\n";
print POSTOUT "%Check add string lengths so we can base them all on the longest","\n";
print POSTOUT "/check_length {","\n";
print POSTOUT "  stringwidth exch /newlen exch def newlen maxlength gt  {%if","\n";
print POSTOUT "  /maxlength newlen def","\n";
print POSTOUT "  /negmaxlength newlen -1 mul def","\n";
print POSTOUT "             } if","\n";
print POSTOUT "                } def","\n";

print POSTOUT "/check_xwrap {","\n";
print POSTOUT " totalxmove 500 gt {%if","\n";
print POSTOUT "        /xmove 0 def","\n";
print POSTOUT "        /ymove 0 def","\n";
print POSTOUT "        /totalxmove 0 def","\n";
print POSTOUT "        /totalymove 0 def","\n";
print POSTOUT "        /totaltranslate 0 def","\n";
print POSTOUT "        /negtotaltranslate 0 def","\n";
#added 20 translate so each page starts futher down
print POSTOUT "        showpage 20 0 translate","\n";
print POSTOUT "                } if","\n";
print POSTOUT "        }def","\n";

print POSTOUT "%pre pretranslate to keep track of x","\n";
print POSTOUT "/pretranslate   {","\n";
print POSTOUT "        /ymove exch def","\n";
print POSTOUT "        /xmove exch def","\n";
print POSTOUT "        /totalymove totalymove ymove add def","\n";
print POSTOUT "        /totalxmove totalxmove xmove add def","\n";
print POSTOUT "        xmove ymove translate","\n";
print POSTOUT "                } def","\n";
print POSTOUT "%keep track of total table width (including the padding between them) as","\n";
print POSTOUT "% add them all up as we go so we know how much to translate back to the","\n";
print POSTOUT "% start.","\n";
print POSTOUT "/totalrowwidthcalc   {%def","\n";
print POSTOUT "  htablepad add totaltranslate add /totaltranslate exch def ","\n";
print POSTOUT "  /negtotaltranslate totaltranslate -1 mul def ","\n";
print POSTOUT "                   } def","\n";
print POSTOUT "\n";
print POSTOUT "%Check to see how far over we can go before wrapping","\n";
print POSTOUT "/check_ywrap {","\n";
print POSTOUT " /curr_xtrans exch def","\n";
print POSTOUT " /curr_xtrans curr_xtrans cellh mul cellh add def","\n";
print POSTOUT "  widthofsheet 200 sub totaltranslate lt  {%if","\n";
print POSTOUT "         0 negtotaltranslate pretranslate","\n";
print POSTOUT "         curr_xtrans 0 pretranslate","\n";
print POSTOUT "         /totaltranslate 0 def","\n";
print POSTOUT "         /negtotaltranslate 0 def","\n";
# add a spacer
print POSTOUT "(CONTINUED ROW) check_length","\n";
#print POSTOUT "() (CONTINUED ROW) MakeHeader","cellh 0 pretranslate\n";
print POSTOUT "cellh 0 pretranslate\n";
#print POSTOUT "(CONTINUED ROW) (CONTINUED ROW) (CONTRINUED ROW) DoShadeRow","cellh 0 pretranslate\n";
print POSTOUT "cellh 0 pretranslate\n";
print POSTOUT "/maxcellwidth maxlength def         ","\n";
print POSTOUT "/negmaxcellwidth maxcellwidth -1 mul def         ","\n";
print POSTOUT "/tablewidth maxcellwidth 3 mul def         ","\n";
print POSTOUT "/negtablewidth maxcellwidth -3 mul def         ","\n";
#print POSTOUT "(NA) (NA) DoTotalandFree         ","cellh 0 pretranslate cellh 0 pretranslate\n";
print POSTOUT "cellh 0 pretranslate cellh 0 pretranslate\n";
print POSTOUT "/maxlength 0 def         ","\n";
print POSTOUT "/negmaxlength 0 def         ","\n";
print POSTOUT "tablewidth totalrowwidthcalc         ","\n";
print POSTOUT "0 tablewidth htablepad add pretranslate         ","\n";
print POSTOUT "cellh -3 mul 0 pretranslate         ","\n";
print POSTOUT "check_xwrap","\n";
#end of spacer
print POSTOUT "             } if","\n";
print POSTOUT "                } def","\n";
print POSTOUT "%","\n";
print POSTOUT "%------------defines--formula-based","\n";
print POSTOUT "%","\n";
print POSTOUT "","\n";
print POSTOUT "% Define the Font","\n";
print POSTOUT "/HelveticaBold findfont fonth scalefont setfont","\n";
print POSTOUT "%width of cell (will vary depening on maximum string width","\n";
print POSTOUT "/cellw maxlength def %not used yet","\n";
print POSTOUT "%cell height total","\n";
print POSTOUT "/cellh fontpad 2 mul fonth add def","\n";
print POSTOUT "/negcellh cellh -1 mul def","\n";
print POSTOUT "%starting point (bottom left corner point xy pos) of string in cell","\n";
print POSTOUT "/cellstrstart cellh fontpad sub def","\n";
print POSTOUT "/negcellstrstart cellstrstart -1 mul def","\n";
print POSTOUT "/headstringstart cellstrstart def","\n";
print POSTOUT "%","\n";
print POSTOUT "%------------drawing procs","\n";
print POSTOUT "%","\n";
print POSTOUT "/DoRowTitle 	{","\n";
print POSTOUT " 0 0 moveto show /HelveticaBold findfont fonth scalefont setfont","\n";
print POSTOUT " 		} bind def","\n";
print POSTOUT "","\n";
print POSTOUT "/DoTableTitle	{","\n";
print POSTOUT " /titleval exch def","\n";
#print POSTOUT " 0 cellh moveto 90 rotate titleval show -90 rotate","\n";
print POSTOUT "  cellh cellh moveto fonth fonth rmoveto fonth -1.5 mul 0 rmoveto 90 rotate titleval show -90 rotate","\n";
print POSTOUT "		} def","\n";
print POSTOUT "	","\n";
print POSTOUT "/DoCell	{","\n";
print POSTOUT " /value exch def","\n";
print POSTOUT "%skip over title","\n";
print POSTOUT "%cellh accomodates the title","\n";
print POSTOUT " rightmargin leftmargin moveto","\n";
print POSTOUT " 0 maxlength rlineto cellh 0 rlineto 0 negmaxlength rlineto negcellh 0 rlineto fill stroke","\n";
print POSTOUT " rightmargin cellstrstart add leftmargin moveto","\n";
print POSTOUT " 90 rotate 1 setgray value show -90 rotate 0 setgray","\n";
print POSTOUT " 0 maxlength pretranslate","\n";
print POSTOUT "	} def","\n";
print POSTOUT "","\n";
print POSTOUT "/MakeHeaderalt{ ","\n";
print POSTOUT " /devicefileprimary exch def","\n";
print POSTOUT " /devicefilealternate exch def ","\n";
print POSTOUT " devicefileprimary DoTableTitle","\n";
print POSTOUT " (Class) DoCell","\n";
print POSTOUT " (Driver) DoCell","\n";
print POSTOUT " (Description) DoCell","\n";
print POSTOUT " 0 negmaxlength pretranslate","\n";
print POSTOUT " 0 negmaxlength pretranslate","\n";
print POSTOUT " 0 negmaxlength pretranslate","\n";
print POSTOUT " %translate down 1 row to start regular rows","\n";
print POSTOUT " cellh 0 pretranslate","\n";
print POSTOUT " 	  } bind def","\n";
print POSTOUT "","\n";
print POSTOUT "/MakeHeader{ ","\n";
print POSTOUT " /devicefileprimary exch def","\n";
print POSTOUT " /devicefilealternate exch def ","\n";
print POSTOUT " devicefileprimary DoTableTitle","\n";
print POSTOUT " (LVOL) DoCell","\n";
print POSTOUT " (Mount Point) DoCell","\n";
print POSTOUT " (Extents) DoCell","\n";
print POSTOUT " 0 negmaxlength pretranslate","\n";
print POSTOUT " 0 negmaxlength pretranslate","\n";
print POSTOUT " 0 negmaxlength pretranslate","\n";
print POSTOUT " %translate down 1 row to start regular rows","\n";
print POSTOUT " cellh 0 pretranslate","\n";
print POSTOUT " 	  } bind def","\n";
print POSTOUT "","\n";
print POSTOUT "/DoTotalandFree {","\n";
print POSTOUT "	/freedisk exch def","\n";
print POSTOUT "	/totaldisk exch def","\n";
print POSTOUT "	(Total) DoCell","\n";
print POSTOUT "	() DoCell","\n";
print POSTOUT "	totaldisk DoCell","\n";
print POSTOUT " %translate down 1 row","\n";
print POSTOUT " cellh 0 pretranslate","\n";
print POSTOUT " 0 negmaxlength pretranslate","\n";
print POSTOUT " 0 negmaxlength pretranslate","\n";
print POSTOUT " 0 negmaxlength pretranslate","\n";
print POSTOUT "	(Free) DoCell","\n";
print POSTOUT "	() DoCell","\n";
print POSTOUT "	freedisk DoCell","\n";
print POSTOUT "	0 negmaxlength pretranslate","\n";
print POSTOUT "	0 negmaxlength pretranslate","\n";
print POSTOUT "	0 negmaxlength pretranslate","\n";
print POSTOUT "		} def","\n";
print POSTOUT "/DoRow	{","\n";
print POSTOUT "	/extents exch def","\n";
print POSTOUT "	/filesystem exch def","\n";
print POSTOUT "	/logicalvol exch def","\n";
print POSTOUT "%skip the title and header","\n";
print POSTOUT "	rightmargin leftmargin moveto","\n";
print POSTOUT "	cellstrstart 0 rmoveto 90 rotate logicalvol show -90 rotate","\n";
print POSTOUT "	negcellstrstart 0 rmoveto","\n";
print POSTOUT "	0 maxlength pretranslate","\n";
print POSTOUT "	rightmargin leftmargin moveto","\n";
print POSTOUT "	cellstrstart 0 rmoveto 90 rotate filesystem show -90 rotate","\n";
print POSTOUT "	negcellstrstart 0 rmoveto","\n";
print POSTOUT "	0 maxlength pretranslate","\n";
print POSTOUT "	rightmargin leftmargin moveto","\n";
print POSTOUT "	cellstrstart 0 rmoveto 90 rotate extents show -90 rotate","\n";
print POSTOUT "	negcellstrstart 0 rmoveto","\n";
print POSTOUT " %translate down 1 row","\n";
print POSTOUT "	0 negmaxlength pretranslate","\n";
print POSTOUT "	0 negmaxlength pretranslate","\n";
print POSTOUT " cellh 0 pretranslate","\n";
print POSTOUT "	} def","\n";
print POSTOUT "/DoShadeRow	{","\n";
print POSTOUT "	/extents exch def","\n";
print POSTOUT "	/filesystem exch def","\n";
print POSTOUT "	/logicalvol exch def","\n";
print POSTOUT "%skip the title and header","\n";
print POSTOUT "	rightmargin leftmargin moveto","\n";
print POSTOUT "	cellstrstart 0 rmoveto 0 maxlength 2 sub rlineto cellh -1 mul -4 sub 0 rlineto 0 maxlength -1 mul 2 add rlineto cellstrstart 0 rlineto .8 setgray fill stroke 0 setgray","\n";
print POSTOUT "	rightmargin leftmargin moveto","\n";
print POSTOUT "	cellstrstart 0 rmoveto 90 rotate logicalvol show -90 rotate","\n";
print POSTOUT "	negcellstrstart 0 rmoveto","\n";
print POSTOUT "	0 maxlength pretranslate","\n";
print POSTOUT "	rightmargin leftmargin moveto","\n";
print POSTOUT "	cellstrstart 0 rmoveto 0 maxlength 2 sub rlineto cellh -1 mul -4 sub 0 rlineto 0 maxlength -1 mul 2 add rlineto cellstrstart 0 rlineto .8 setgray fill stroke 0 setgray","\n";
print POSTOUT "	rightmargin leftmargin moveto","\n";
print POSTOUT "	cellstrstart 0 rmoveto 90 rotate filesystem show -90 rotate","\n";
print POSTOUT "	negcellstrstart 0 rmoveto","\n";
print POSTOUT "	0 maxlength pretranslate","\n";
print POSTOUT "	rightmargin leftmargin moveto","\n";
print POSTOUT "	cellstrstart 0 rmoveto 0 maxlength 2 sub rlineto cellh -1 mul -4 sub 0 rlineto 0 maxlength -1 mul 2 add rlineto cellstrstart 0 rlineto .8 setgray fill stroke 0 setgray","\n";
print POSTOUT "	rightmargin leftmargin moveto","\n";
print POSTOUT "	cellstrstart 0 rmoveto 90 rotate extents show -90 rotate","\n";
print POSTOUT "	negcellstrstart 0 rmoveto","\n";
print POSTOUT " %translate down 1 row","\n";
print POSTOUT "	0 negmaxlength pretranslate","\n";
print POSTOUT "	0 negmaxlength pretranslate","\n";
print POSTOUT " cellh 0 pretranslate","\n";
print POSTOUT "	} def","\n";
print POSTOUT "","\n";
print POSTOUT "","\n";
print POSTOUT "","\n";
			}
