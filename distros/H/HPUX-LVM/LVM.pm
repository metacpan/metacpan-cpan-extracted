package HPUX::LVM;

use 5.006;
use strict;
#use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HPUX::LVM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '1.06';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

### Start


use vars '$AUTOLOAD';
use Carp ;
use Storable;

sub new
  {
    my $debug=0;
    my $debug1=0;
    my $debug2=0;
    my $debug5=0;

    my ($class, @subargs) = @_ ;

    my %arglist	 =	(
	target_type 	=> "local"	,
	persistance 	=> "new"	,
	datafile 	=> "/tmp/lvminfo.dat",
	access_prog 	=> "ssh"	,
	access_system 	=> "localhost"	,
	access_user	=> "root"	,
	remote_command1 => '/usr/sbin/vgdisplay -v',
	remote_command2 => '/usr/sbin/lvdisplay -v',
	@subargs,
			);

	if ($debug)	{
	 print "target_type  : $arglist{target_type}\n";
	 print "persistance  : $arglist{persistance}\n";
	 print "datafile     : $arglist{datafile}\n";
	 print "access_prog  : $arglist{access_prog}\n";
	 print "access_system: $arglist{access_system}\n";
	 print "access_user  : $arglist{access_user}\n";
	 print "remote_command1: $arglist{remote_command1}\n";
	 print "remote_command2: $arglist{remote_command2}\n";
			}

    my $source_access  =$arglist{target_type};
    my $new_or_saved   =$arglist{persistance};
    my $datafile       =$arglist{datafile};
    my $remote_access  =$arglist{access_prog};
    my $remote_system  =$arglist{access_system};
    my $remote_user    =$arglist{access_user};
    my $remote_command1 =$arglist{remote_command1};
    my $remote_command2 =$arglist{remote_command2};

    my $templine;      		#line by line of vgdisplay output
    my @tempdataline;  		#space split templine when gathering vg 
				#and lv attributes
    my @tempdataline1; 		#slash sub split of tempdataline value so lvname
		       		#can be lvol1 and not /dev/vg02/lvol1
    my $alternate_link="no"; 	#yes or no to indicate an alternate 
				#link was found
    my @vgdisplay;      	#results of vgdisplay command
    my @lvdisplay;       	#results of lvdisplay command
    my $lvname_confirm;  	#holds lvname extracted from output 
				#(templvname) and compares to current 
				#lvnamefrom vgdisplay (yet another sanity check)
    my @templvname;     	#split line on match of LV Name in 
				#lvdisplay output

    my @currentline_savetemp; 	#space split current_line (templine)
    my @lastline_savetemp;    	#had to save previous lines data for alt-links
    my $lastline_save;          #Space split lastline_savetemp
    my $pvname_previous;      	#extracted from lastline_savetemp
    my $alternate_pvname;
    my $alternate_line;
    my %alternate_link_list;  	#May be getting rid of this one
    my $current_VG;     	#volume group that its currently working 
				#on in the loop

    my @tempvgname;     	#space split templine that vgname was found on
    my $vgname;         	#extracted from tempvgname
    my $vgname_save;    	#saved copy of above

    my $volgrpdatacnt;  	#number of attributes for a volume group 
				#(sanity check)
    my $lvdatacnt;        	#number of attributes that each logical 
				#volume has (sanity check) in vgdisplay 
				#command 5?
    my $lvdataline;        	# each line in lvdisplay command
    my %vg_info; 		#MAIN hash that it returns!
    my $vginfo_ref = \%vg_info;

    my $lvcnt;		#number of logical volumes in vg's
    my $lvname;		#name of current logical volume in command
    my $started_lvdatacollect;  #0 or 1 depending on if it has 
				#started to parse the lvdisplay attributes yet
    my $lvdatacnt2;	#number of attributes gathered for 
			#logical volume in lvdisplay command 15?
 			#should be the same number for all.  this is just
			#a sanity check for the paranoid parser people
    my $parse_logical_vols; #set to yes when it gets to the
			    #logical volume output of the vgdisplay command
			    # so it can skip some if checks
    my $lvpvcnt;	#number of physical volumes in logical 
			#volume per lvdisplay output.  later 
			#compared to vgdisplays PV count.
    my @final_pvnamedatatemp;   # array that contains LE on PV and 
				#PE on PV per the lvdisplay command 
				#later to be turned into hash value
    my $pvtempname;  	#just a definition for debugging purposes.  
			#Its the pv name from lvdisplay distribution 
			#of physical volumes part
    my $pvcnt;	        #number of physical volumes in volume 
			#group from ---physical volumes--- part.
    my $pvdatacnt;     	#number of attributs associated to the 
			#phyical volumes part of vgdisplay output (sanity check)
    my $pvname;         #physical volume name from physical volumes 
			#section of vgdisplay output

# Check for persistance request

	if ($arglist{persistance} eq "old")	{
                print "retrieving a copy from prosperity...\n" if $debug;
                $vginfo_ref = Storable::retrieve $datafile
                        or die "unable to retrieve hash data in /tmp\n";
                        return bless($vginfo_ref,$class);
						}

    @vgdisplay=`$remote_access $remote_system -l $remote_user -n $remote_command1` 
	or die "Unable to execute $remote_command1: $@\n";

# For debuggin on win95    
# @vgdisplay=`type vgdisplay.vgtest` or die "unable to exec command vgdisplay: $@\n";





    LINEB: foreach $templine (@vgdisplay)	{
	if ( $templine eq "" || $templine =~ /^\s+$/ )	{
		next LINEB;
							}
#
# Added this code to support Alternate link indentification.
# This required that I save the previous lines data
# Not yet merged into new format yet.
#

# First check to see if the alternate link flag has been tripped

	if ($alternate_link eq "yes" )	{
		@currentline_savetemp 	= split /\s+/,$alternate_line; 
		@lastline_savetemp 	= split /\s+/,$lastline_save;
		$pvname_previous  = $lastline_savetemp[3];
#print "pvname_previous is $pvname_previous\n";
		$alternate_pvname = $currentline_savetemp[3]; 
#
# I give up.  Create an alternate link hash with the key as the main link
#and the alternate as the value and refrence it later
#
		print "Adding Alternate link/s to object\n" if $debug5;
		push @{ $alternate_link_list{$pvname_previous} },$alternate_pvname;
		$vg_info{$vgname}->{Physical_Vols}->{$pvname_previous}->{Alternate_Links}=\@{ $alternate_link_list{$pvname_previous} };
#print "alternate_pvname is $alternate_pvname\n";
		$alternate_link="no";
#next LINEB; 
					}
# End of Alternate link code that I have yet to use in new format

	if ($templine =~ /^VG Name/)	{
#get the vgname
		@tempvgname = split /\s+/, $templine;
		$vgname = $tempvgname[2];
		$vgname_save = $vgname;
#		print "Initializing $vgname...\n";
		$volgrpdatacnt=0;
		$current_VG = $vgname;
		next LINEB;
					}
	next LINEB unless defined($current_VG);
# Now get all the volumegroup data		
 	if ($templine =~ /^VG Write Access/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{VG_Write_Access}=$tempdataline[3];
	$volgrpdatacnt++;
	next LINEB;
						}
 	if ($templine =~ /^VG Status/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{VG_Status}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^Max LV/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Max_LV}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^Cur LV/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Cur_LV}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^Open LV/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Open_LV}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^Max PV/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Max_PV}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^Cur PV/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Cur_PV}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine  =~ /^Act PV/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Act_PV}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^Max PE per PV/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Max_PE_per_PV}=$tempdataline[4]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^VGDA/)		{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{VGDA}=$tempdataline[1]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^PE Size \(Mbytes\)/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{PE_Size_Mbytes}=$tempdataline[3]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^Total PE/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Total_PE}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^Alloc PE/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Alloc_PE}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^Free PE/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Free_PE}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
 	if ($templine =~ /^Total PVG/)	{
	@tempdataline=split /\s+/, $templine;
	$vg_info{$vgname}->{Total_PVG}=$tempdataline[2]; 	
	$volgrpdatacnt++;
	next LINEB;
					}
	if ( $volgrpdatacnt == 15 )	{
print "Got all volume group data for $current_VG, $volgrpdatacnt of 15\n" if $debug;
			$volgrpdatacnt=0;
					}
#
# Now get and store logical volume data for current VG
#
	if ($templine =~ /^   --- Logical volumes ---/)	{
#print "Start of Logical Volume data\n";
		$lvcnt = 0;
		$parse_logical_vols="yes";
		next LINEB;	
									}
	if ($templine =~ /^   LV Name/)	{
		@tempdataline=split /\s+/, $templine;
		 print "Logical volume parse: $tempdataline[3]\n" if $debug;
		@tempdataline1 = split /\//, $tempdataline[3];
		 print "Just Logical Volume : $tempdataline1[3]\n" if $debug1;
		$lvname = $tempdataline1[3];
		 print "Starting logical volume $lvname\n" if $debug1;
		$lvdatacnt=0;
		next LINEB;
					} 
	 print "$templine" if $debug1;

	if ($templine =~ /^   LV Status/)	{
	 @tempdataline=split /\s+/, $templine;
	 $vg_info{$vgname}->{lvols}->{$lvname}->{LV_Status}
		=$tempdataline[3];
	 $lvdatacnt++;
		next LINEB;
							}
	if ($templine =~ /^   LV Size \(Mbytes\)/)	{
		@tempdataline=split /\s+/, $templine;
	 $vg_info{$vgname}->{lvols}->{$lvname}->{LV_Size}
		=$tempdataline[4];
		$lvdatacnt++;
		next LINEB;
								}
	if ($templine =~ /^   Current LE/)	{
		@tempdataline=split /\s+/, $templine;
	 $vg_info{$vgname}->{lvols}->{$lvname}->{Current_LE}
		=$tempdataline[3];
		$lvdatacnt++;
		next LINEB;
	 						}	
	if ($templine =~ /^   Allocated PE/)	{
		@tempdataline=split /\s+/, $templine;
	 $vg_info{$vgname}->{lvols}->{$lvname}->{Allocated_PE}
		=$tempdataline[3];
		$lvdatacnt++;
		next LINEB;
							}	
	if ($templine =~ /^   Used PV/)	{
		@tempdataline=split /\s+/, $templine;
	 $vg_info{$vgname}->{lvols}->{$lvname}->{Used_PV}
		=$tempdataline[3]; 	
		$lvdatacnt++;
#
# We should have all the logical volume data now
# if not them something went horriby wrong and the next 
# statement will catch it and exit
#
		if ($lvdatacnt != 5)	{ 
			print "Did not get all the logical volume data from vgdisplay\n";	
			print "Only got $lvdatacnt of 5\n";
			print "Problems...\n";
			exit;
					    }
		else 			{
print "Got all $lvdatacnt of 5 logical volume data for $lvname\n\n" if $debug;
print "vgname: $vgname\n" if $debug;
print "lvname: $lvname\n" if $debug;

		@lvdisplay = 
	`$remote_access $remote_system -l $remote_user -n $remote_command2 $vgname/$lvname` 
		or die "remote command $remote_command2 failed: $@\n";

#for win95 debugging purposes
#    @lvdisplay = `type $lvname.vgtest`;

			LVDATALINE: foreach $lvdataline (@lvdisplay)	{
#attempt at keepalive timeout prevention below
#attempt at stoping browser timeout	print "<B></B>";

			if ($lvdataline =~ /^   --- Logical extents ---/) {
#
# Were done summ it up
#
	print "Done getting physical volume data.\n" if $debug;
	print "Now comparing lvdisplay physical volumes to vgdisplays used PV for each lv.  Yet another sanity check\n" if $debug;
		if ($lvpvcnt == $vg_info{$vgname}->{lvols}->{$lvname}->{Used_PV} )	{
		    @final_pvnamedatatemp=();
															}

					else								{
													}
					$lvpvcnt=0;
					last LVDATALINE;
																			}
				if ($lvdataline =~ /^--- Logical volumes ---/) {
				    $started_lvdatacollect=1;
				    next LVDATALINE;
												}

	if ($lvdataline =~ /^LV Name/)	{
#get the lvname just like getting the vgname part above
		@templvname = split /\s+/, $lvdataline;
		$lvname_confirm = $templvname[2];
		 print "Starting to process $lvname which should be the same as $lvname_confirm!...\n" if $debug;
		$lvdatacnt2=0;
		next LVDATALINE;
							}
	if ($lvdataline =~ /^VG Name/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{VG_Name}=$templvname[2];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^LV Permission/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{LV_Permission}=$templvname[2];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^LV Status/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{LV_Status}=$templvname[2];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^Mirror copies/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{Mirror_copies}=$templvname[2];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^Consistency Recovery/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{Consistency_Recovery}=$templvname[2];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^Schedule/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{Schedule}=$templvname[1];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^LV Size \(Mbytes\)/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{LV_Size_Mbytes}=$templvname[3];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^Current LE/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{Current_LE}=$templvname[2];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^Allocated PE/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{Allocated_PE}=$templvname[2];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^Stripes/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{Stripes}=$templvname[1];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^Stripe Size \(Kbytes\)/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{Stripe_Size_Kbytes}=$templvname[3];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^Bad block/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{Bad_block}=$templvname[2];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^Allocation/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{Allocation}=$templvname[1];
	$lvdatacnt2++;
	next LVDATALINE;
							}
	if ($lvdataline =~ /^IO Timeout \(Seconds\)/)	{
	@templvname=split /\s+/, $lvdataline;
	$vg_info{$vgname}->{lvols}->{$lvname}->{lvdata}->{IO_Timeout_Seconds}=$templvname[3];
	$lvdatacnt2++;
	next LVDATALINE;
							}
# End of extracting logical volume attributes
#now count em up and compare to a static number that its supposed to be
		if ($lvdatacnt2 != 14)	{
			print "Did not get all the logical volume data in lvdisplay command\n";	
			print "Only got $lvdatacnt2 of 14\n";
			print "Problems...\n";
			exit;
						}
		else 			{
print "Got all $lvdatacnt2 of 14 logical volume data for $lvname\n\n" if $debug;
					}
	
				if ($lvdataline =~ /^   ---  Distribution of logical volume ---/)	{
				 print "Start of Physical Volume data for $lvname\n" if $debug;
					$lvpvcnt = 0;
					next LVDATALINE;	
													}
					
				if ($lvdataline =~ /^   \/dev/)	{
					@tempdataline=split /\s+/, $lvdataline;
#
# Ouch, my head hurts now...  Now I add a third hash with an annonymouns array as the value that
# contains the pv info
#
					$pvtempname=$tempdataline[1];
					 print "PVname should be : $pvtempname\n" if $debug;
					 print "tempdataline2 is   : $tempdataline[2]\n" if $debug;
					 print "tempdataline3 is   : $tempdataline[3]\n" if $debug;
					#add it here directly!
					$vg_info{$vgname}->{lvols}->{$lvname}->{Ordered_PV}->{$lvpvcnt}=$tempdataline[1];
					$vg_info{$vgname}->{lvols}->{$lvname}->{PV_Data}->{$tempdataline[1]}->{le_on_pv}=$tempdataline[2];
					$vg_info{$vgname}->{lvols}->{$lvname}->{PV_Data}->{$tempdataline[1]}->{pe_on_pv}=$tempdataline[3];
#$logical_volume_hash_data{$vgname}{$lvname}{LVPVDATA}=$lvdataline[2];
					$lvpvcnt++;
					next LVDATALINE;
								}
#NEXT LINE ENDS lvdisplay foreach 
								}

		next LINEB;
#next line ends else statement way up there
					}
					} #end of "Used PV last volume group extract if statement
#
# Here we start the physical volume data gathering thats in the vgdisplay output just for yucks...
#
	if ($templine =~ /^   --- Physical volumes ---/)	{
#		print "Start of Physical Volume data for volume group $current_VG\n";
		$pvcnt = 0;
		next LINEB;	
										}
	if ($templine =~ /^   PV Name/ && $templine !~ /Alternate Link/ )	{
		$lastline_save = $templine;
		@tempdataline=split /\s+/, $templine;
		$pvname = $tempdataline[3];
#print "Starting Physical volume $pvname in group $current_VG\n";
#push @{ $physical_volume_hash_data{$vgname}{$pvname}}, $tempdataline[3];
		$pvdatacnt=0;
		next LINEB;
					}
#
#Added this one to support PV links
#
	if ($templine =~ /^   PV Name/ && $templine =~ /Alternate Link/ )	{
#set the flag for processing at the beginning of the next LINEB foreach
		print "Caught an alternate link\n" if $debug5;
		$alternate_line=$templine;
		$alternate_link="yes";
		next LINEB;
										}

	if ($templine =~ /^   PV Status/)	{
# Made it past alternate links, set default value if its not there.
	unless ( exists( $vg_info{$vgname}->{Physical_Vols}->{$pvname}->{Alternate_Links}) )	{				
		print "No Alternate links found! setting default\n" if $debug5;
		$vg_info{$vgname}->{Physical_Vols}->{$pvname}->{Alternate_Links}=[ "None" ];
			}
		@tempdataline=split /\s+/, $templine;
		$vg_info{$vgname}->{Physical_Vols}->{$pvname}->{PV_Status}=$tempdataline[3];
		$pvdatacnt++;
		next LINEB;
							}	
	if ($templine =~ /^   Total PE/)	{
		@tempdataline=split /\s+/, $templine;
		$vg_info{$vgname}->{Physical_Vols}->{$pvname}->{Total_PE}=$tempdataline[3];
		$pvdatacnt++;
		next LINEB;
							}	
	if ($templine =~ /^   Free PE/)	{
		@tempdataline=split /\s+/, $templine;
		$vg_info{$vgname}->{Physical_Vols}->{$pvname}->{Free_PE}=$tempdataline[3];
		$pvdatacnt++;
#
# We should have all the physical volume data now
#
	if ($pvdatacnt != 3)		{
		print "Did not get all the physical volume data\n";	
		print "Only got $pvdatacnt of 3\n";
		print "Problems...\n";
		exit;
					}
	else 				{
#		print "Got all $pvdatacnt of 3 physical volume data for $lvname\n";
					}
		next LINEB;
					}

#Should not see the next line print out!!! All lines should be accounted for
#print "Unaccounted for line:\n";
#print "$templine";
} #end of vgdisplay extraction routine foreach

        if ( $arglist{persistance} eq "new" )   {
                print "saving a copy for prosperity...\n" if $debug;
                Storable::nstore \%vg_info, $datafile
                        or die "unable to store hash data in /tmp\n";
                                        }




return bless($vginfo_ref, $class);
      }


sub AUTOLOAD {
#
# Some ugly hacketry to be able to autoload sub hashes.
# There must be a better way.
#
	my $debug = 0;

    my ($class, @subargs) = @_ ;
	
	return if $AUTOLOAD =~ /::DESTROY$/;

    my %arglist	 =	(
	volume_group 		=> undef,
	vg_sub_cat		=> undef,
	vg_sub_cat_lv 		=> undef,
	vg_sub_cat_lv_data	=> undef,
	vg_sub_cat_pv 		=> undef,
	vg_sub_cat_pv_data	=> undef,
	vg_sub_cat_pv_data_pv	=> undef,
	@subargs,
			);

	print "Passed: @_<--\n" if $debug;
	print "Yoyoyoyo got called here\n" if $debug;
	my $self 	= $class;
	my $VOLGRP 	= $arglist{volume_group} || "0"; #required to get anything useful
	print "VOLGRP is $VOLGRP\n" if $debug;
	my $THIRDARG	= $arglist{vg_sub_cat} || "0";   # should be one of Volgrp attrs if not defined else:
						  # "Physical_Vols"
						  # "lvols"
	print "THIRDARG is $THIRDARG\n" if $debug;	

	my $FOURTHARG	= $arglist{vg_sub_cat_lv} || $arglist{vg_sub_cat_pv} || "0";	# can be each of the following:
					# actual phyical vol "/dev/dsk/..."
					# actual logical volume "lvol#"	
	print "FOURTHARG is $FOURTHARG\n" if $debug;

	my $FIFTHARG	= $arglist{vg_sub_cat_lv_data} || $arglist{vg_sub_cat_pv_data} || "0";	# Can be any of the following:
					# physical volume attribute if not defined
					# logical volume attribute if not defined
					# OR link on to:
					# "PV_Data"
					# "lvdata"
	print "FIFTHARG is $FIFTHARG\n" if $debug;

	my $SIXTHARG	= $arglist{vg_sub_cat_pv_data_pv} || "0";	# can be "lvdata" attribute if not defined else 
					# actual phyical volume "/dev/dsk..."
	print "SIXTHARG is $SIXTHARG\n" if $debug;
		
	print "VOLGRP: $VOLGRP\n" if $debug;
	print "AUTOLOAD: $AUTOLOAD\n" if $debug;
	$AUTOLOAD =~ /.*::get_(\w+)/ or croak "No Such method: $AUTOLOAD\n";
	print "AUTOLOAD is now: $AUTOLOAD\n" if $debug;
	croak "$self not an object" unless ref($self);
#	return if $AUTOLOAD =~ /::DESTROY$/;
	# start checking arguments here from 6th down to 3rd
	print "\$1 is set to: $1\n" if $debug;


	if ($SIXTHARG) 	{
	  print "Found sixtharg.\n" if $debug;
	  unless (exists $self->{$VOLGRP}->{$THIRDARG}->{$FOURTHARG}->{$FIFTHARG}->{$SIXTHARG}->{$1})		{
		croak "Cannot access $1 field in $self->{$VOLGRP}->{$THIRDARG}->{$FOURTHARG}->{$FIFTHARG}->{$SIXTHARG}\n";
				}
	   return $self->{$VOLGRP}->{$THIRDARG}->{$FOURTHARG}->{$FIFTHARG}->{$SIXTHARG}->{$1};
			}

	if ($FIFTHARG) 	{
	  print "Found fiftharg.\n" if $debug;
	  unless (exists $self->{$VOLGRP}->{$THIRDARG}->{$FOURTHARG}->{$FIFTHARG}->{$1})		{
		croak "Cannot access $1 field in $self->{$VOLGRP}->{$THIRDARG}->{$FOURTHARG}->{$FIFTHARG}\n";
			}
	   return $self->{$VOLGRP}->{$THIRDARG}->{$FOURTHARG}->{$FIFTHARG}->{$1};
			}


	if ($FOURTHARG) {
	  print "Found fourtharg.\n" if $debug;
	  unless (exists $self->{$VOLGRP}->{$THIRDARG}->{$FOURTHARG}->{$1})		{
		croak "Cannot access $1 field in $self->{$VOLGRP}->{$THIRDARG}->{$FOURTHARG}\n";
	}
	  return $self->{$VOLGRP}->{$THIRDARG}->{$FOURTHARG}->{$1};
			}

	if ($THIRDARG) {
	  print "Found thirdarg.\n" if $debug;
	  unless (exists $self->{$VOLGRP}->{$THIRDARG}->{$1})		{
		croak "Cannot access $1 field in $self->{$VOLGRP}->{$THIRDARG}";
									}
	   return $self->{$VOLGRP}->{$THIRDARG}->{$FOURTHARG}->{$1};
			}

# Just check the main volgrp attr
	  print "No extra args. continur to check default level\n" if $debug;

	unless (exists $self->{$VOLGRP}->{$1})	{
		croak "Cannot access $1 field in $self->{$VOLGRP}\n";
						}
	print "self says its: $self->{$1}\n" if $debug;
	if (@_) { return $self->{$VOLGRP}->{$1} = shift }
	else	{ return $self->{$VOLGRP}->{$1} 	}


	      }

sub traverse	{
        my $self = shift;
        my $debug=0;
   	my $debug2=0;
        print "I am self: $self\n" if $debug;
        my $mainkey;
        my $subkey;
	my $subsubkey;
	my $subsubsubkey;
	my $subsubsubsubkey;
	my $subsubsubsubsubkey;
        my $dev_file;

        foreach $mainkey ( sort keys %{ $self } )    {
         print "Main Key: $mainkey\n";
         print "Values:\n";
          foreach $subkey ( sort keys %{ $self->{$mainkey} } )   {
           print "	SubKey: $subkey,		Value: $self->{$mainkey}->{$subkey}\n";
	   print "ref:",ref( $self->{$mainkey}->{$subkey} ),"\n" if $debug2;
	   if (ref($self->{$mainkey}->{$subkey}) eq "HASH") 	{
	    print "Got here identified sub hash!\n" if $debug2;
	    foreach $subsubkey ( sort keys %{ $self->{$mainkey}->{$subkey} } )	{
	     print "		SubSubKey: $subsubkey		Value: $self->{$mainkey}->{$subkey}->{$subsubkey}\n";
	     if (ref($self->{$mainkey}->{$subkey}->{$subsubkey}) eq "HASH") 	{
	      print "Got here identified sub sub hash!\n" if $debug2;
	      foreach $subsubsubkey ( sort keys %{ $self->{$mainkey}->{$subkey}->{$subsubkey} } )    {
	       print "			SubSubSubKey: $subsubsubkey		Value: $self->{$mainkey}->{$subkey}->{$subsubkey}->{$subsubsubkey}\n";
	       if (ref($self->{$mainkey}->{$subkey}->{$subsubkey}->{$subsubsubkey}) eq "HASH") 	{
	        print "Got here identified sub sub sub hash!\n" if $debug2;
	        foreach $subsubsubsubkey ( sort keys %{ $self->{$mainkey}->{$subkey}->{$subsubkey}->{$subsubsubkey} } )	{
	         print "				SubSubSubSubKey: $subsubsubsubkey		Value: $self->{$mainkey}->{$subkey}->{$subsubkey}->{$subsubsubkey}->{$subsubsubsubkey}\n";
	         if (ref($self->{$mainkey}->{$subkey}->{$subsubkey}->{$subsubsubkey}->{$subsubsubsubkey}) eq "HASH") 	{
	          print "Got here identified sub sub sub sub hash!\n" if $debug2;
	           foreach $subsubsubsubsubkey ( sort keys %{ $self->{$mainkey}->{$subkey}->{$subsubkey}->{$subsubsubkey}->{$subsubsubsubkey} } )	{
                    print "				SubSubSubSubSubKey: $subsubsubsubsubkey		Value: $self->{$mainkey}->{$subkey}->{$subsubkey}->{$subsubsubkey}->{$subsubsubsubkey}->{$subsubsubsubsubkey}\n";

		     
	}
															}
															}
												}
											        }
										}
										} 
								}
							    }
						}
		}


sub get_all_lvols_on_disk	{
				}

sub get_disk_lvol_data		{
# disk device /dev/dsk/c4t3d0 passed or equivilent
# returns pointer to hash of hashes
# hash key: /dev/dsk/c#t#d# is a pointer to another hash
#	key:lvol is a pointer to yet another hash
#	   key: le_on_pv value: "###"
#	   key: pe_on_pv value: "###"
#		 
        my ($self, @subargs) = @_;

        my %arglist      =      (
                device_name      => ""   ,
                @subargs,
                                );
	my $dev_file = $arglist{device_name};
        my $debug =0;
   	my $debug2=0;
        print "I am self: $self\n" if $debug;
        my $mainkey;
	my $vg_phys_vols;
	my $vg_vol;
	my %lv_vols;
	my $lv_vols=\%lv_vols;
	my $lv_in_vg;
	my $pv_in_lv;
	my $pv_in_vg;
	my $logical_vol; #used in traversal at bottom for debugging
        foreach $mainkey ( sort keys %{ $self } )    	{
         print "Main Key: $mainkey\n" if $debug;
	  foreach $vg_phys_vols ( sort keys %{ $self->{$mainkey}->{Physical_Vols} } )	{
	    print "Checking: $vg_phys_vols against $dev_file\n" if $debug;
#First look for it on the vgdisplay output part.
	    if ( $vg_phys_vols eq $dev_file )	{
#if found there, then save it and continue to dig for per lv info
	      print "Got one $vg_phys_vols equals $dev_file\n" if $debug;
	      print "Checking further now that I've made a match\n" if $debug;
	      print "Found device $dev_file in $mainkey!\n" if $debug2;
             $vg_vol=$mainkey;
	      print "Volume Group is $vg_vol now\n" if $debug;
	      foreach $lv_in_vg ( sort keys %{ $self->{$mainkey}->{lvols} } )	{
		print "Checking lvol $lv_in_vg for phys_dev\n"if $debug;
		  foreach $pv_in_lv ( sort keys %{ $self->{$mainkey}->{lvols}->{$lv_in_vg}->{PV_Data} } ) {
		    print "Checking $pv_in_vg to match $dev_file\n" if $debug;
		      if ( $pv_in_lv eq $dev_file )	{
			print "Matched lvol specific physical vol $lv_in_vg: $vg_phys_vols equals $dev_file\n" if $debug;
			$lv_vols->{$lv_in_vg}=	{
				vg_on_pv => $vg_vol,	
				le_on_pv => $self->{$mainkey}->{lvols}->{$lv_in_vg}->{PV_Data}->{$dev_file}->{le_on_pv},
				pe_on_pv => $self->{$mainkey}->{lvols}->{$lv_in_vg}->{PV_Data}->{$dev_file}->{pe_on_pv}, 
						};
							}
			
											      }
								 }








						}
										}

							}
		 print "$dev_file:\n" if $debug2;
		foreach $logical_vol ( sort keys %{ $lv_vols } )	{
		 print "	logical_vol: $logical_vol\n" if $debug2;
		 print "		le_on_pv: $lv_vols{$logical_vol}->{le_on_pv}\n" if $debug2;
		 print "		pe_on_pv: $lv_vols{$logical_vol}->{pe_on_pv}\n" if $debug2;
									}
		return \%lv_vols;

				}

sub get_all_volumegroups	{
# Returns an array of all the Volume groups (primary keys)
# No args needed
        my ($self, @subargs) = @_;

        my %arglist      =      (
                @subargs,
                                );
        my $debug =0;
   	my $debug2=0;
        my $mainkey;
	my @volumegroups;
       foreach $mainkey (sort keys %{ $self } )    	{
		push @volumegroups, $mainkey;
									}
	return \@volumegroups;
				}
sub get_all_pvlinks	{
#
#
#
# Returns a hash of array/s with pimary links as keys and second 
#  and thrid etc links as an ordered array.
# ie. /dev/dsk/c1t2d0 :Key
#        /dev/dsk/c2t2d0 1st alternate :$array[0]
#        /dev/dsk/c3t2d0 2nd alternate :$array[1]
#        /dev/dsk/c4t2d0 3rd alternate :$array[2]
# No args needed
        my ($self, @subargs) = @_;

        my %arglist      =      (
                @subargs,
                                );
        my $debug =0;
   	my $debug2=0;
   	my $debug5=0;
        my $mainkey;
	my $vg;
	my $pvinvg;
	my @volumegroups;
	my @lvol_attra;
	my %returnhash="";
       foreach $mainkey (sort keys %{ $self } )    	{
		print "Volume Groups in self: $mainkey\n" if $debug5;
		push @volumegroups, $mainkey;
							}
	foreach $vg	( @volumegroups )	{
	  print "VG: $vg\n" if $debug5;
  PVLOOP:   foreach $pvinvg (sort keys %{ $self->{$vg}->{Physical_Vols} } )    	{
#
# Check each physical volume, check for pvlinks and add them as appropriate
#
		print "PVinVG: $pvinvg\n" if $debug5;
	      if ( $self->{$vg}->{Physical_Vols}->{$pvinvg}->{Alternate_Links}->[0] eq "None" ) 	{
		print "It was NOT defined, continuing\n" if $debug5;
		@lvol_attra = "";
		next PVLOOP;
	}
	      else	{
	     	print "It was defined, continuing\n" if $debug5;
		@lvol_attra = @{ $self->{$vg}->{Physical_Vols}->{$pvinvg}->{Alternate_Links} };
		print "lvol_attra: @lvol_attra\n<BR>" if $debug5;
		$returnhash{$pvinvg} = [ @lvol_attra ];
			}
	
									 	}
						}
	return \%returnhash;
				}
sub get_vg_physicalvols		{
#return an array
#pass vg

        my ($self, @subargs) = @_;

        my %arglist      =      (
                volume_group     => ""   ,
                @subargs,
                                );
	my $vol_group = $arglist{volume_group};
        my $debug =0;
   	my $debug2=0;
        my $mainkey;
	my @physicalvols;
       foreach $mainkey (sort keys %{ $self->{$vol_group}->{Physical_Vols} } )    	{
		push @physicalvols, $mainkey;
									}
	return \@physicalvols;

				}
sub get_vg_physicalvol_attr	{
#return an scalar
#pass vg,phyvol,attr

        my ($self, @subargs) = @_;
	my $debug=0;
   	my $debug2=0;
	print "I am: $self\n" if $debug;
	print "Args: @subargs\n" if $debug;

        my %arglist      =      (
                volume_group     => ""   ,
                device_name      => ""   ,
                attribute        => ""   ,
                @subargs,
                                );
	my $vol_group = $arglist{volume_group};
	my $dev_file  = $arglist{device_name};
	print "Vol_group is : $vol_group\n" if $debug;
	my $attr      = $arglist{attribute};
        my $mainkey;
	my $physical_attr;
	print "Vol_group is : $vol_group\n" if $debug;
	$physical_attr = $self->{$vol_group}->{Physical_Vols}->{$dev_file}->{$attr};
	return $physical_attr;

				}
sub get_vg_lvols		{
#return an array
#pass vg

        my ($self, @subargs) = @_;

        my %arglist      =      (
                volume_group     => ""   ,
                @subargs,
                                );
	my $vol_group = $arglist{volume_group};
        my $debug =0;
   	my $debug2=0;
        my $mainkey;
	my @logicalvols;
        foreach $mainkey ( sort keys %{ $self->{$vol_group}->{lvols} } ) {
		push @logicalvols, $mainkey;
									  }
	return \@logicalvols;

				}
sub get_vg_lvol_attr_vgdisplay	{
#return an scalar
#pass vg,lvol,attr

        my ($self, @subargs) = @_;

        my %arglist      =      (
                volume_group     => ""   ,
                logical_vol      => ""   ,
                attribute        => ""   ,
                @subargs,
                                );
	my $vol_group   = $arglist{volume_group};
	my $logical_vol = $arglist{logical_vol};
	my $attr        = $arglist{attribute};
        my $debug =0;
   	my $debug2=0;
	print "vol_group: $vol_group\n" if $debug;
	print "logical_vol: $logical_vol\n" if $debug;
	print "attribute: $attr\n" if $debug;
	my $lvol_attr;
        my $mainkey;
	$lvol_attr = $self->{$vol_group}->{lvols}->{$logical_vol}->{$attr};
	print "attribute is: $lvol_attr\n" if $debug;
	return $lvol_attr;
				}
sub get_vg_alternate_links	{
#return an array
#pass vg,pv

        my ($self, @subargs) = @_;

        my %arglist      =      (
                volume_group     => ""   ,
                device_name      => ""   ,
                attribute        => "Alternate_Links"   ,
                @subargs,
                                );
	my $vol_group   = $arglist{volume_group};
	my $device_name = $arglist{device_name};
	my $attr        = $arglist{attribute};
        my $debug =0;
   	my $debug2=0;
   	my $debug5=0;
	print "vol_group: $vol_group\n" if $debug5;
	print "attribute: $attr\n" if $debug5;
	print "device_name: $device_name\n" if $debug5;
	my @lvol_attr;
	if ( defined( $self->{$vol_group}->{Physical_Vols}->{$device_name}->{$attr} ) )	{
	print "It was defined, continuing\n" if $debug5;
	@lvol_attr = @{ $self->{$vol_group}->{Physical_Vols}->{$device_name}->{$attr} };
	}
	else	{
	print "It was NOT defined, continuing\n" if $debug5;
	@lvol_attr = ( "NotDefined" );
		}
	return \@lvol_attr;
				}

sub get_vg_lvol_attr_lvdisplay	{
#return an scalar
#pass vg,lvol,attr

        my ($self, @subargs) = @_;

        my %arglist      =      (
                volume_group     => ""   ,
                logical_vol     => ""   ,
                attribute        => ""   ,
                @subargs,
                                );
	my $vol_group   = $arglist{volume_group};
	my $logical_vol = $arglist{logical_vol};
	my $attr        = $arglist{attribute};
        my $debug =0;
   	my $debug2=0;
        my $mainkey;
	my $lvol_attr;
	$lvol_attr = $self->{$vol_group}->{lvols}->{$logical_vol}->{lvdata}->{$attr};
	return $lvol_attr;
				}

sub get_vg_lvol_stripeorder    {
#return an array
#pass vg,lvol,phyvol

        my ($self, @subargs) = @_;

        my %arglist      =      (
                volume_group     => ""   ,
                logical_vol      => ""   ,
                @subargs,
                                );
        my $vol_group   = $arglist{volume_group};
        my $logical_vol = $arglist{logical_vol};
        my $debug =0;
        my $debug2=0;
        my $mainkey;
        my @lvol_stripeorder;
        foreach $mainkey ( sort keys %{ $self->{$vol_group}->{lvols}->{$logical_vol}->{'Ordered_PV'} } ) {
                push @lvol_stripeorder, $self->{$vol_group}->{lvols}->{$logical_vol}->{'Ordered_PV'}->{ $mainkey };
                                                                          }
        return \@lvol_stripeorder;
                                }

sub get_vg_lvol_physicalvols	{
#return an array
#pass vg,lvol,phyvol

        my ($self, @subargs) = @_;

        my %arglist      =      (
                volume_group     => ""   ,
                logical_vol      => ""   ,
                device_name      => ""   ,
                @subargs,
                                );
	my $vol_group   = $arglist{volume_group};
	my $logical_vol = $arglist{logical_vol};
	my $device_name = $arglist{device_name};
        my $debug =0;
   	my $debug2=0;
        my $mainkey;
	my @lvol_physvols;
        foreach $mainkey ( sort keys %{ $self->{$vol_group}->{lvols}->{$logical_vol}->{'PV_Data'} } ) {
		push @lvol_physvols, $mainkey;
									  }
	return \@lvol_physvols;
				}
sub get_vg_lvol_physicalvol_attr{
#return an scalar
#pass vg,lvol,phyvol,attr

        my ($self, @subargs) = @_;

        my %arglist      =      (
                volume_group     => ""   ,
                logical_vol      => ""   ,
                device_name      => ""   ,
                attribute        => ""   ,
                @subargs,
                                );
	my $vol_group   = $arglist{volume_group};
	my $logical_vol = $arglist{logical_vol};
	my $device_name = $arglist{device_name};
	my $attr        = $arglist{attribute};
        my $debug =0;
   	my $debug2=0;
        my $mainkey;
	my $lvol_physvol_attr;
	$lvol_physvol_attr = $self->{$vol_group}->{lvols}->{$logical_vol}->{PV_Data}->{$device_name}->{$attr};
	return $lvol_physvol_attr;
				}

### End
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

HPUX::LVM - Perl function to handle HPUX LVM structure

=head1 SYNOPSIS

  my $lvminfo_data = new HPUX::LVMInfo(
                                target_type     =>"local",
                                persistance     =>"new",
                                access_prog     =>"ssh",
                                access_system   =>"localhost",
                                access_user     =>"root"
                                );

	$arref2 = $lvminfo_data->get_all_volumegroups();

	foreach $vg (@$arref2)  {
	        print "Volume Group: $vg\n";
	        push @save_vgs, $vg;
	        $vg_save = $vg;
       		                 }
	$arref2a = $lvminfo_data->get_vg_physicalvols(
       	                 volume_group    => $vg_save
                                        );

	print "Physical vols in vg: $vg_save\n";
	foreach $pvinvg (@$arref2a)	{
	        print "$pvinvg\n";
	        push @save_pvs, $pvinvg;
	        $pvinvg_save = $pvinvg;
       		                         }

=head1 DESCRIPTION

This module takes the output from the LVM Commands vgdisplay and
lvdisplay and pvdisplay and puts them in a hash of hashes in the
following manner as an example:

   '/dev/vg08' => HASH(0x404214c8)
      'Act_PV' => 4
      'Alloc_PE' => 4092
      'Cur_LV' => 2
      'Cur_PV' => 4
      'Free_PE' => 0
      'Max_LV' => 255
      'Max_PE_per_PV' => 1023
      'Max_PV' => 16
      'Open_LV' => 2
      'PE_Size_Mbytes' => 4
      'Physical_Vols' => HASH(0x40421510)
         '/dev/dsk/c3t12d0' => HASH(0x404215a0)
            'Free_PE' => 0
            'PV_Status' => 'available'
            'Total_PE' => 1023
         '/dev/dsk/c3t13d0' => HASH(0x40421528)
            'Free_PE' => 0
            'PV_Status' => 'available'
            'Total_PE' => 1023
         '/dev/dsk/c3t14d0' => HASH(0x40421564)
            'Free_PE' => 0
            'PV_Status' => 'available'
            'Total_PE' => 1023
         '/dev/dsk/c3t15d0' => HASH(0x404215dc)
            'Free_PE' => 0
            'PV_Status' => 'available'
            'Total_PE' => 1023
      'Total_PE' => 4092
      'Total_PVG' => 0
      'VGDA' => 8
      'VG_Status' => 'available'
      'VG_Write_Access' => 'read/write'
      'lvols' => HASH(0x4042166c)
         'lvol1' => HASH(0x40421684)
            'Allocated_PE' => 2046
            'Current_LE' => 2046
            'LV_Size' => 8184
            'LV_Status' => 'available/syncd'
            'PV_Data' => HASH(0x4042178c)
               '/dev/dsk/c3t14d0' => HASH(0x404217a4)
                  'le_on_pv' => 1023
                  'pe_on_pv' => 1023
               '/dev/dsk/c3t15d0' => HASH(0x404217d4)
                  'le_on_pv' => 1023
                  'pe_on_pv' => 1023
            'Used_PV' => 2
            'lvdata' => HASH(0x404216b4)
               'Allocated_PE' => 2046
               'Allocation' => 'strict'
               'Bad_block' => 'on'
               'Consistency_Recovery' => 'MWC'
               'Current_LE' => 2046
               'IO_Timeout_Seconds' => 'default'
               'LV_Permission' => 'read/write'
               'LV_Size_Mbytes' => 8184
               'LV_Status' => 'available/syncd'
               'Mirror_copies' => 0
               'Schedule' => 'parallel'
               'Stripe_Size_Kbytes' => 0
               'Stripes' => 0
               'VG_Name' => '/dev/vg08'
         'lvol2' => HASH(0x40422834)
            'Allocated_PE' => 2046
            'Current_LE' => 2046
            'LV_Size' => 8184
            'LV_Status' => 'available/syncd'
            'PV_Data' => HASH(0x4042293c)
               '/dev/dsk/c3t12d0' => HASH(0x40422984)
                  'le_on_pv' => 1023
                  'pe_on_pv' => 1023
               '/dev/dsk/c3t13d0' => HASH(0x40422954)
                  'le_on_pv' => 1023
                  'pe_on_pv' => 1023
            'Used_PV' => 2
            'lvdata' => HASH(0x40422864)
               'Allocated_PE' => 2046
               'Allocation' => 'strict'
               'Bad_block' => 'on'
               'Consistency_Recovery' => 'MWC'
               'Current_LE' => 2046
               'IO_Timeout_Seconds' => 'default'
               'LV_Permission' => 'read/write'
               'LV_Size_Mbytes' => 8184
               'LV_Status' => 'available/syncd'
               'Mirror_copies' => 0
               'Schedule' => 'parallel'
               'Stripe_Size_Kbytes' => 0
               'Stripes' => 0
               'VG_Name' => '/dev/vg08'

each attribute is the same as output in the command but with underscores
instead of spaces so "Allocated PE" is "Allocated_PE".  I also had to add
attributes "Physical_Vols","lvols","lvdata" and "PV_Data". (for logical volume data)

"Physical_Vols" is a hash refrence to all the Physical Volumes in the VG

"Alternate_Links" is an array refrence under each physical vol that contains
all the links to that device (if any).  First array element is "None" if there
are no links. (Not listed above but its under "Physical_Vols"

"lvols" is a hash refrence to all the volume groups in the VG

"lv_data" is a hash refrence to lvdisplays output of the logical volume.

"PV_Data" is a hash refrence to all the physical volumes that make up the
volume group and how much space they use on each.

The data can then be access through the provided methods (Subroutines).

=head1 FUNCTION

=head2 new()

The main object constructor that returns the hash refrence.
The keys of the hash are all the volume groups on your system.  
It accepts the following paramters:

        target_type     values: local(default) or remote
        persistance     values: new(default) or old
        datafile        values: Path and name of datafile to store object
	                        if persistance is selected.  Default is 
				"/tmp/vginfo.dat"
        access_prog     values: ssh(default) or remsh
        access_system   values: localhost(default) or remote system name
        access_user     values: root(default) or remote username

The list of keys and attributes is illustrated in full in the example above.

=head2 traverse()

  example method that just traverses the object and prints it out.

=head2 get_all_lvols_on_disk(
		device_name	=> "/dev/dsk/c#t#d#"
				)

 returns refrence to hash of hashes
 hash key: /dev/dsk/c#t#d# is a refrence to another hash
       key:lvol is a refrence to yet another hash
          key: le_on_pv value: "###"
          key: pe_on_pv value: "###"

 not sure if I still need this method around but it works so I'll
 keep it in.

=head2 get_vg_physicalvols(
		volume_group	=> "/dev/vg##"
				)

  returns an array refrence to an array that contains all the physical
  volumes that make up the volume group

=head2 get_vg_physicalvol_attr(
		volume_group	=> "/dev/vg##",
		device_name	=> "/dev/dsk/c#t#d#",
		attribute	=> "PV_Status"
				)

  returns the scalar value of the attribute requested.

=head2 get_vg_lvols(
		volume_group	=> "/dev/vg##"
			)

  returns an array refrence to an array that contains all the logical
  volumes that make up the volume group

=head2 get_vg_lvol_attr_vgdisplay(
		volume_group	=> "/dev/vg##",
		logical_vol	=> "lvol#",
		attribute	=> "LV_Size"
				)

  returns the scalar value of the attribute requested.  these are
  the attributes gathered about the logical volume from the
  vgdisplay command

=head2 get_vg_lvol_attr_lvdisplay(
		volume_group	=> "/dev/vg##",
		logical_vol	=> "lvol#",
		attribute	=> "Stripes"
				)

  returns the scalar value of the attribute requested. These are
  the attributes gathered about the logical volume from the
  lvdisplay command.  There are several more than in the vgdisplay
  command.

=head2 get_vg_lvol_physicalvols(
		volume_group	=> "/dev/vg##",
		logical_vol	=> "/dev/lvol#"
				)

  returns an array refrence to an array that contains all the physical
  volumes that make up the logical volume.

=head2 get_vg_lvol_physicalvol_attr(
		volume_group	=> "/dev/vg##",
		logical_vol	=> "/dev/lvol#",
		device_name	=> "/dev/dsk/c#t#d#",
		attribute	=> "le_on_pv"
					)
=head2 get_vg_alternate_links(
		volume_group	=> "/dev/vg##",
		device_name	=> "/dev/dsk/c#t#d#",
					)

  returns the scalar value of the attribute requested.

=head1 CAVEATS

I beleive that you have to be root to run this.

=head1 AUTHOR

Christopher White, <chrwhite@seanet.com>

Copyright (C) 2001 Christopher White.  All rights reserved.  this program is fre
e software;  you can redistribute it and/or modify it under the same terms as pe
rl itself.

=head1 SEE ALSO

L<vgdisplay>(1M)
L<lvdisplay>(1M)
L<pvdisplay>(1M)

=cut
