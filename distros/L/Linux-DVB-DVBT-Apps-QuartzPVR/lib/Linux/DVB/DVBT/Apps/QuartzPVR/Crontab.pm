package Linux::DVB::DVBT::Apps::QuartzPVR::Crontab ;

=head1 NAME

Linux::DVB::DVBT::Apps::QuartzPVR::Crontab - crontab utils

=head1 SYNOPSIS

use Linux::DVB::DVBT::Apps::QuartzPVR::Crontab ;


=head1 DESCRIPTION


=head1 DIAGNOSTICS

Setting the debug flag to level 1 prints out (to STDOUT) some debug messages, setting it to level 2 prints out more verbose messages.

=head1 AUTHOR

Steve Price 

=head1 BUGS

None that I know of!

=head1 INTERFACE

=over 4

=cut

use strict ;
use Carp ;

our $VERSION = "1.012" ;

#============================================================================================
# USES
#============================================================================================
use Data::Dumper ;
use Config::Crontab;
use File::Basename ;
use File::Path qw/mkpath/ ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Path ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Time ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Prog ;
use Linux::DVB::DVBT::Apps::QuartzPVR::Series ;

#============================================================================================
# GLOBALS
#============================================================================================

our $debug = 0 ;

our $ct ;
our $opts_href ;
our %rec_files ;
our %iplay_files ;
our %recorded_files ;
our $today_mins ;


#============================================================================================
# OBJECT METHODS 
#============================================================================================

BEGIN {
	
	## Get crontab (allow for no crontab yet). Reads the crontab for this UID (via crontab -l)
	$ct = new Config::Crontab;
	$ct->strict(0) ;
	$ct->read;
	$ct->strict(1) ;
	
	$opts_href = {
		'app'			=> undef,
		
		'padding'		=> 2,
		'early'			=> 30,
		'recprog'		=> '',
		'iplayprog'		=> '',
		'video_dir'		=> '',
		'audio_dir'		=> '',
		'crontag'		=> 'dvb-record',
		'crontag_iplay'	=> 'iplay-record',
		'run_dir'		=> '',
		'run_ext'		=> '.lst',
		'video_ext'		=> '.ts',
		'audio_ext'		=> '.mp3',
		'max_timeslip'	=> 60,		# max timeslip time in minutes ; 0 = no timeslip
		'log_dir'		=> '',
	} ;
	
	%rec_files = () ;
	%iplay_files = () ;
	%recorded_files = () ;
	
	## Create an instance of today (midnight) to compare with
	my $today_dt = Linux::DVB::DVBT::Apps::QuartzPVR::Time::parse_date("today", "0:00") ;
	$today_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($today_dt) ;
	
}

#---------------------------------------------------------------------
# Set options 
sub set
{
	my (%options) = @_ ;

#print "Crontab::set()\n" ;
	foreach my $opt (keys %options)
	{
		$opts_href->{$opt} = $options{$opt} ;

#print " $opt = $options{$opt}\n" ;
	}
	
	$debug = $options{'debug'} if exists($options{'debug'}) ;
	
	## Post-process
	foreach my $d (qw/run_dir video_dir audio_dir/)
	{
		$opts_href->{$d} = Linux::DVB::DVBT::Apps::QuartzPVR::Path::expand_path($options{$d}) ;
	}
	foreach my $p (qw/log_dir recprog iplayprog/)
	{
		my ($file, $dir, $suffix) = fileparse($opts_href->{$p}, qr/\.[^.]*/);
		$dir = Linux::DVB::DVBT::Apps::QuartzPVR::Path::expand_path($dir) ;
		$opts_href->{$p} = "$dir$file$suffix" ;
	}
}



#---------------------------------------------------------------------
sub get_blocks
{
	my ($tag) = @_ ;
	my @record_blocks = map {$ct->block($_)} $ct->select(
								-type		=> 'comment',
								-data_re	=> '\@\[' . $tag . '\]' 
								) ;
	return @record_blocks ;
}

#---------------------------------------------------------------------
sub block_lines
{
	my $lines = "" ;
	
	## cron blocks
	my @record_blocks = get_blocks($opts_href->{'crontag'}) ;
	foreach my $block (@record_blocks)
	{
		$lines .= $block->dump ;
		$lines .= "\n" ;
	}
	
	@record_blocks = get_blocks($opts_href->{'crontag_iplay'}) ;
	foreach my $block (@record_blocks)
	{
		$lines .= $block->dump ;
		$lines .= "\n" ;
	}
	
	## Any record files
	if (keys %rec_files)
	{
		$lines .= "\n" ;
		$lines .= "== Record Files ==\n" ;
		$lines .= "\n" ;

		foreach my $file (sort keys %rec_files)	
		{
			$lines .= "+---[ $opts_href->{'run_dir'}/$file ]------------\n" ;
			$lines .= "|\n" ;
			foreach my $line (@{$rec_files{$file}})
			{
				$lines .= "| $line\n" ;
			}
			$lines .= "+-------------------------------------------------------------------------------------\n\n" ;
		}	
	} 
	
	## Any IPLAY record files
	if (keys %iplay_files)
	{
		$lines .= "\n" ;
		$lines .= "== IPLAY Record Files ==\n" ;
		$lines .= "\n" ;

		foreach my $file (sort keys %iplay_files)	
		{
			$lines .= "+---[ $opts_href->{'run_dir'}/$file ]------------\n" ;
			$lines .= "|\n" ;
			foreach my $line (@{$iplay_files{$file}})
			{
				$lines .= "| $line\n" ;
			}
			$lines .= "+-------------------------------------------------------------------------------------\n\n" ;
		}	
	} 
	
	return $lines ;
}

#---------------------------------------------------------------------
sub display_blocks
{
	my @record_blocks = get_blocks($opts_href->{'crontag'}) ;
	
	print "\n\nBlocks:\n" ;
	foreach my $block (@record_blocks)
	{
		print "\n------------\n", $block->dump ;
	}

	@record_blocks = get_blocks($opts_href->{'crontag_iplay'}) ;
	
	print "\n\nIPLAY Blocks:\n" ;
	foreach my $block (@record_blocks)
	{
		print "\n------------\n", $block->dump ;
	}
}


#---------------------------------------------------------------------
# Update crontab to match database 
sub update
{
	my ($recording_aref) = @_ ;

	## get existing blocks
	my @record_blocks = get_blocks($opts_href->{'crontag'}) ;

	## Remove existing blocks
	$ct->remove(@record_blocks) ;

	## Create new blocks
	create_blocks($recording_aref) ;

}

#---------------------------------------------------------------------
# Update crontab to match database 
sub update_iplay
{
	my ($recording_aref) = @_ ;

	## get existing blocks
	my @record_blocks = get_blocks($opts_href->{'crontag_iplay'}) ;

	## Remove existing blocks
	$ct->remove(@record_blocks) ;

	## Create new blocks
	create_iplay_blocks($recording_aref) ;

}

#---------------------------------------------------------------------
# Write crontab 
sub commit
{
#print "commit()\n" ;
#print " + ensure $opts_href->{run_dir} is available\n" ;

    ## ensure path is available
    if (! -d "$opts_href->{run_dir}")
    {
    	mkpath("$opts_href->{run_dir}") or die "Error: Unable to create run directory $opts_href->{run_dir} : $!" ;
    }
    
#print " + clear files\n" ;
      
    ## clear record file list directory
    foreach my $f (glob("$opts_href->{run_dir}/*$opts_href->{run_ext}"))
    {
    	if (-f $f)
    	{
    		unlink $f ;
    	}
    }

#print " + create files\n" ;
    
    ## Create new files
	if (keys %rec_files)
	{
		foreach my $file (sort keys %rec_files)	
		{
			my $path = "$opts_href->{run_dir}/$file" ;
#print " + + $path\n" ;

			open my $fh, ">$path" or die "Error: Unable to create run file $path : $!" ;
			foreach my $line (@{$rec_files{$file}})
			{
				print $fh "$line\n" ;
			}
			close $fh ;
		}	
	} 

    ## Create new files
	if (keys %iplay_files)
	{
		foreach my $file (sort keys %iplay_files)	
		{
			my $path = "$opts_href->{run_dir}/$file" ;
#print " + + $path\n" ;

			open my $fh, ">$path" or die "Error: Unable to create run file $path : $!" ;
			foreach my $line (@{$iplay_files{$file}})
			{
				print $fh "$line\n" ;
			}
			close $fh ;
		}	
	} 

	## Write crontab
	$ct->write()    
	  or do {
        warn "Error: " . $ct->error . "\n";
      };
      
}


#---------------------------------------------------------------------
# Return the HASH of recorded files
sub recorded_files
{
	return \%recorded_files ;	
}

#---------------------------------------------------------------------
# Given the database, create a new set of blocks
# Also adjusts the start_datetime & end_datetime of each prog based on padding
#
sub create_blocks
{
	my ($db_aref) = @_ ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('Crontab::create_blocks') ;

	my $MAX_TIMESLIP = $opts_href->{'max_timeslip'} ;
	my $MAX_TIMESLIP_SECS = $MAX_TIMESLIP * 60 ;
	my $PAD = $opts_href->{'padding'} ;
	my $PAD_SECS = $PAD * 60 ;

#print "MAX_TIMESLIP=$MAX_TIMESLIP : MAX_TIMESLIP_SECS=$MAX_TIMESLIP_SECS\n" ;
#print "PAD=$PAD : PAD_SECS=$PAD_SECS\n" ;


$opts_href->{'app'}->prt_data("create_blocks() db_aref", $db_aref) if $debug>=3 ;

	## Group entries by adapter
	my %db ;
	foreach my $entry_href (@$db_aref)
	{
		my $adap = $entry_href->{'adapter'} ;
		$db{$adap} ||= [] ;
		push @{$db{$adap}}, $entry_href ;
	}

#print "pad=$opts_href->{padding}\n" if $debug>=3 ;

	## do an adapter's worth at a time
	my @blocks ;
	foreach my $adap (keys %db)
	{
		my @sorted = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } @{$db{$adap}} ;
		my $last_entry = scalar(@sorted)-1 ;

#$opts_href->{'app'}->prt_data("Sorted progs:", \@sorted) if $debug>=2  ;


		## Assumptions:
		## * Programs start on 5minute boundaries
		## * Padding < 5 mins
		## * Timeslip (if set) >> padding
		##

		## First tazz through setting the padding at start
		#		
		#	------++----			-----++--------
		#	 i-1  || *i*		=>	 i-1 || *i*			[i]start <= [i-1]end+PAD : No start pad
		#	------++----			-----++--------
		#	
		#	
		#	------+      +----		-----+   +...+---
		#	 i-1  |      | *i*	=>   i-1 |   :   |*i*	[i]start > [i-1]end+PAD : start pad
		#	------+      +----		-----+   +...+---
		#	
		for(my $i=0; $i<=$last_entry; ++$i)
		{
			# get list of all progs
			my @progs = ($sorted[$i]) ;
			if ($sorted[$i]->{'type'} eq 'multiplex')
			{
				# do mux entries
				push @progs, @{$sorted[$i]->{'multiplex'}} ;
			}				

			# do start
			if ($i==0)
			{
				## 1st entry in the list 
				
				# Ok to pad the first
				foreach my $prog_href (@progs)
				{
					Linux::DVB::DVBT::Apps::QuartzPVR::Prog::pad($prog_href, 'start', $PAD) ;
				}
			}
			else
			{
				# Check to see we have enough time between end of previous prog & start of this one
				foreach my $prog_href (@progs)
				{
					if (Linux::DVB::DVBT::Apps::QuartzPVR::Prog::check_pad($sorted[$i-1], $prog_href, $PAD))
					{
						Linux::DVB::DVBT::Apps::QuartzPVR::Prog::pad($prog_href, 'start', $PAD) ;
					}
				}				
			}
		}

		## Now do the end time
		#
		#	------++----			-----++--------
		#	 *i*  || i+1		=>	 *i* || i+1			[i]end <= [i+1]start+PAD : No end pad
		#	------++----			-----++--------
		#	
		#	
		#	------+      +----		-----+...+   +---
		#	 *i*  |      | i+1	=>   *i* |   :   |i+1	[i]end > [i-1]start+PAD : end pad
		#	------+      +----		-----+...+   +---
		#	
		#	------+   +..+----		-----+...+ +...+---
		#	 *i*  |   :  | i+1	=>   *i* |   : :   |i+1	[i]end > [i-1]start+PAD : end pad
		#	------+   +..+----		-----+...+ +...+---
		#	
		for(my $i=0; $i<=$last_entry; ++$i)
		{
			# get list of all progs
			my @progs = ($sorted[$i]) ;
			if ($sorted[$i]->{'type'} eq 'multiplex')
			{
				# do mux entries
				push @progs, @{$sorted[$i]->{'multiplex'}} ;
			}				

			# do end
			if ($i==$last_entry)
			{
				# Ok to pad the last
				foreach my $prog_href (@progs)
				{
					Linux::DVB::DVBT::Apps::QuartzPVR::Prog::pad($prog_href, 'end', $PAD) ;
				}
			}
			else
			{
				# Check to see we have enough time between end of this prog & start of the next one
				foreach my $prog_href (@progs)
				{
					my $diff_secs = Linux::DVB::DVBT::Apps::QuartzPVR::Time::timediff_secs($prog_href, $sorted[$i+1]) ;
					if ($diff_secs >= $PAD_SECS)
					{
						Linux::DVB::DVBT::Apps::QuartzPVR::Prog::pad($prog_href, 'end', $PAD) ;
					}
					else
					{
						# Not enough time for padding. See if start is adjacent to end of prev - if so, finish the previous one
						# a few seconds early to allow the DVB tuner time to be reset
						Linux::DVB::DVBT::Apps::QuartzPVR::Prog::finish_early($prog_href, $opts_href->{'early'}) ;
					}
				}
			}
		}

		## Finally extend the end time if we can timeslip
		
		# Allow for padding at end of previous & at start of next
		 
		for(my $i=0; $i<=$last_entry; ++$i)
		{
			# get list of all progs
			my @progs = ($sorted[$i]) ;
			if ($sorted[$i]->{'type'} eq 'multiplex')
			{
				# do mux entries
				push @progs, @{$sorted[$i]->{'multiplex'}} ;
			}				

			# do timeslip
			if ($i==$last_entry)
			{
				# Ok to timeslip the last
				foreach my $prog_href (@progs)
				{
					Linux::DVB::DVBT::Apps::QuartzPVR::Prog::timeslip($prog_href, $MAX_TIMESLIP) ;
				}
			}
			else
			{
				# Check to see we have enough time between end of this prog (these progs) & start of the next one
				foreach my $prog_href (@progs)
				{
					# start by clearing
					Linux::DVB::DVBT::Apps::QuartzPVR::Prog::timeslip($prog_href, 0) ;
					
					# check space
					my $diff_secs = Linux::DVB::DVBT::Apps::QuartzPVR::Time::timediff_secs($prog_href, $sorted[$i+1]) ;
#print "\nTIMESLIP: comparing :\n" ;
#print "  this: " ; Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched_entry($prog_href) ;				
#print "  next: " ; Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched_entry($sorted[$i+1]) ;				
#print "    diff secs=$diff_secs\n" ; 				
					
					if ($MAX_TIMESLIP)
					{
						if ($diff_secs > $MAX_TIMESLIP_SECS)
						{
							## Can accomodate the max timeslip
							Linux::DVB::DVBT::Apps::QuartzPVR::Prog::timeslip($prog_href, $MAX_TIMESLIP) ;
						}
						elsif ($diff_secs > $PAD_SECS)
						{
							## Can accomodate a smaller timeslip - limit to what is available
							Linux::DVB::DVBT::Apps::QuartzPVR::Prog::timeslip($prog_href, $diff_secs / 60) ;
						}
					}
#print "  final: " ; Linux::DVB::DVBT::Apps::QuartzPVR::Prog::disp_sched_entry($prog_href) ;				

				}
			}
		}

		## Now create crontab
		foreach my $entry_href (@sorted)
		{
			## Create block(s) for this entry and add to crontab 
			if ($entry_href->{'type'} eq 'multiplex')
			{
				push @blocks, create_mux_block($entry_href->{'id'}, $entry_href) ;
			}
			else
			{
				push @blocks, create_block($entry_href->{'id'}, $entry_href) ;
			}
		}
	}
	
	## Clear record file list
	%rec_files = () ;
	
	## Sort blocks by start time
	@blocks = sort { $a->{'start_dt_mins'} <=> $b->{'start_dt_mins'} } @blocks ;
	foreach my $block_href (@blocks)
	{
		## Skip anything before now
		next unless ($block_href->{'start_dt_mins'} >= $today_mins) ;
		
		## Ok so create block
		my $block = new Config::Crontab::Block ;
		$block->last(new Config::Crontab::Comment($block_href->{'comment'})) ;
		$block->last(new Config::Crontab::Event(
				-active		=> 1,
				-datetime 	=> $block_href->{'datetime'},
				-command	=> $block_href->{'command'},
		)) ;
	
		## Add block to crontab
		$ct->last($block) ;
		
		## Track record files
		if (exists($block_href->{'rec_file'}))
		{
			my $file = $block_href->{'rec_file'} ;
			$rec_files{$file} = $block_href->{'rec_contents'} ;
		}
	}
}

#---------------------------------------------------------------------
# Given the database, create a new set of blocks
#
sub create_iplay_blocks
{
	my ($db_aref) = @_ ;

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgTrace::startfn('Crontab::create_iplay_blocks') ;

	my @sorted = sort { Linux::DVB::DVBT::Apps::QuartzPVR::Prog::start_cmp($a, $b) } @{$db_aref} ;

$opts_href->{'app'}->prt_data("create_iplay_blocks() db_aref", $db_aref) if $debug>=3 ;

	## Clear record file list
	%iplay_files = () ;
	
	## create crontab
	my @blocks ;
	my %blocks ;
	foreach my $entry_href (@sorted)
	{
		## Create block(s) for this entry and add to crontab 
		my $block_href = create_iplay_block($entry_href->{'id'}, $entry_href) ;
		
		# don't create duplicates
		if (!exists($blocks{$block_href->{'id'}}))
		{
			push @blocks, $block_href ;
		}
		$blocks{$block_href->{'id'}} = $block_href ;
	}

	## Sort blocks by start time
	@blocks = sort { $a->{'start_dt_mins'} <=> $b->{'start_dt_mins'} } @blocks ;
	foreach my $block_href (@blocks)
	{
		## Skip anything before now
		next unless ($block_href->{'start_dt_mins'} >= $today_mins) ;
		
		## Ok so create block
		my $block = new Config::Crontab::Block ;
		$block->last(new Config::Crontab::Comment($block_href->{'comment'})) ;
		$block->last(new Config::Crontab::Event(
				-active		=> 1,
				-datetime 	=> $block_href->{'datetime'},
				-command	=> $block_href->{'command'},
		)) ;
	
		## Add block to crontab
		$ct->last($block) ;
	}
}


#---------------------------------------------------------------------
# Given a single database entry, create a new block
sub create_block
{
	my ($id, $entry_href) = @_ ;

	#	id / rid
	#	pid
	#	title
	#	date
	#	start
	#	duration
	#	episode
	#	num_episodes
	#	repeat
	#	channel
	#	adapter
	#	chan_type
	#	record

	# channel type (tv/audio)
	my $type = $entry_href->{'chan_type'} ;

	## Create command
	my $cmd ;
	
	my $fname = Linux::DVB::DVBT::Apps::QuartzPVR::Series::get_filename($entry_href) ;

	$cmd = $opts_href->{'recprog'} ;

	# Adapter
	$cmd .= " -a $entry_href->{adapter}" ;

	## Timeslip?
	if ($entry_href->{'timeslip'})
	{
		$cmd .= " -event $entry_href->{event} -timeslip $entry_href->{'timeslip'}" ;
	}

	if ($type eq 'radio')
	{
		## Pass in some extra info for tagging
		$cmd .= " -title '$entry_href->{title}'" ;
		my $episode = Linux::DVB::DVBT::Apps::QuartzPVR::Path::episode_string($entry_href) ;
		$cmd .= " -episode '$episode'" if $episode ;
	}

	## PID		
	my $pid = $entry_href->{'pid'} ;
	$cmd .= " -id $pid" ;
	
	# Channel
	$cmd .= " '$entry_href->{channel}'" ;
	
	# Filename
	my $recfilename = $fname ;
	$cmd .= " '$recfilename'" ;
	
	# Duration
	$cmd .= " $entry_href->{duration_secs}" ;
	
	
	# video display format
	my $screen_size = $entry_href->{'video'} ;
	

	# Log
	##$cmd .= " >> $opts_href->{log} 2>&1" ;
	$cmd .= " >> $opts_href->{log_dir}/dvbt-record.log 2>&1" ;
		
	# Set time
	my $datetime = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_format($entry_href->{'start_datetime'}, "%M %H %d %m *") ;			 

	## Create block
	my $block_id = $entry_href->{'id'} || $entry_href->{'rid'} ;
	my $block_comment = "# \@[$opts_href->{'crontag'}] id:$block_id title:\"$entry_href->{title}\" date:$entry_href->{date} start:$entry_href->{start} end:$entry_href->{end} duration:$entry_href->{duration} (video $screen_size) [$type]" ;

	my $block_href = {
		'comment'		=> $block_comment,
		'datetime' 		=> $datetime,
		'command'		=> $cmd,
		
		'start_dt_mins'	=> $entry_href->{'start_dt_mins'},
	} ;
	
	## Track recorded files
	$recorded_files{"$pid-dvbt"} = {
		%$entry_href,
		'rectype'	=> 'dvbt',
		'type'		=> $type,
		'file'		=> $recfilename,
	} ;
	
	return $block_href ;
}

#---------------------------------------------------------------------
# Given a single database entry, create a new block
sub create_iplay_block
{
	my ($id, $entry_href) = @_ ;

	my ($fdir, $file) = Linux::DVB::DVBT::Apps::QuartzPVR::Series::get_filename($entry_href) ;

	## Track record files
	my ($iplay_cmd, $iplay_comment) ;

	# channel type
	my $type = $entry_href->{'chan_type'} ;
	$iplay_cmd .= " --type $type" ;

	# Directory
	my $dir = $fdir ;
	$iplay_cmd .= " --output '$dir'" ;
	
	# Get
	my $title = $entry_href->{'title'} ;
	$iplay_cmd .= " --get '$title'" ;

	## PID		
	my $pid = $entry_href->{'pid'} ;
	$iplay_cmd .= " -id $pid" ;
	
	# Sub-title (not the texty bits at the bottom of the screen!)
	my $subtitle = $entry_href->{'subtitle'} || "" ;
	$subtitle = "($subtitle)" if ($subtitle) ;
	
	my $block_id = $entry_href->{'id'} || $entry_href->{'rid'} ;

	$iplay_comment = "# id:$block_id title:\"$entry_href->{title}\" $subtitle date:$entry_href->{prog_date} start:$entry_href->{prog_start} duration:$entry_href->{duration} [$type]" ;

	my $iplay_ctrl_file = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_format($entry_href->{'start_datetime'}, "iplay-%Y-%m-%d".$opts_href->{'run_ext'}) ;
	$iplay_ctrl_file = Linux::DVB::DVBT::Apps::QuartzPVR::Path::cleanpath("$iplay_ctrl_file") ;
		
	$iplay_files{$iplay_ctrl_file} ||= [];
	push @{$iplay_files{$iplay_ctrl_file}}, $iplay_comment ;
	push @{$iplay_files{$iplay_ctrl_file}}, $iplay_cmd ;
	push @{$iplay_files{$iplay_ctrl_file}}, "" ;
	


	## Create command
	my $cmd ;
	$cmd = $opts_href->{'iplayprog'} ;
	$cmd .= " -file $opts_href->{'run_dir'}/$iplay_ctrl_file" ;
	
	# Log
	$cmd .= " >> $opts_href->{log_dir}/dvbt-iplay.log 2>&1" ;
		
	# Set time
	my $datetime = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_format($entry_href->{'start_datetime'}, "%M %H %d %m *") ;			 

	## Create block
	my $block_comment = "# \@[$opts_href->{'crontag_iplay'}]" ;

	my $block_href = {
		'comment'		=> $block_comment,
		'datetime' 		=> $datetime,
		'command'		=> $cmd,
		
		'start_dt_mins'	=> $entry_href->{'start_dt_mins'},
		
		# Used to ensure we only get one crontab job per day (but the control file is filled with all the info)
		'id'			=> "$datetime",
	} ;
	
	## Track recorded files
	my $recfilename = "$dir" ;
	$recorded_files{"$pid-iplay"} = {
		%$entry_href,
		'rectype'	=> 'iplay',
		'type'		=> $type,
		'file'		=> $recfilename,
		
		'adapter'	=> -1,
	} ;
	
	return $block_href ;
}


#---------------------------------------------------------------------
# Given a multiplex entry, create a new block
sub create_mux_block
{
	my ($id, $mux_href) = @_ ;

	# After padding, only the following fields have been affected by the padding:
	#
	# duration_secs
	# start_datetime
	# end_datetime

	my $dt = $mux_href->{'start_datetime'} ;
	my $start_dt_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($dt) ;

	## Create command
	my $cmd ;
	$cmd = $opts_href->{'recprog'} ;

	# Adapter
	$cmd .= " -a $mux_href->{adapter}" ;

	my $rec_file = sprintf "mux%03d$opts_href->{run_ext}", $mux_href->{'multid'} ;
	$rec_file = Linux::DVB::DVBT::Apps::QuartzPVR::Path::cleanpath("$rec_file") ;
	
	$cmd .= " -file $opts_href->{'run_dir'}/$rec_file" ;

	my @rec_contents = () ;
	push @rec_contents, "## Multiplex $mux_href->{multid} recording list" ;
	push @rec_contents, "## " ;
	push @rec_contents, "" ;
	my $idx=0 ;	
	foreach my $entry_href (@{$mux_href->{'multiplex'}})
	{
		my $entry = "" ;
		
		my $datetime = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_format($entry_href->{'start_datetime'}, "%M %H %d %m *") ;			 
		my $block_id = $entry_href->{'id'} || $entry_href->{'rid'} ;
		my $block_comment = "# event:$entry_href->{event} id:$block_id title:\"$entry_href->{title}\" date:$entry_href->{date} start:$entry_href->{start} end:$entry_href->{end} duration:$entry_href->{duration}" ;
		
		if ($idx)
		{
			$dt = $entry_href->{'start_datetime'} ;
			my $entry_start_dt_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($dt) ;
			my $offset = ($entry_start_dt_mins - $start_dt_mins) *60 ;
			$entry .= "+$offset\t" ;	
		}
		else
		{
			$entry .= "  \t" ;
		}

		## debug info
		my $end_dt = $entry_href->{'end_datetime'} ;
		$block_comment .= " (" . Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($dt) . " - " . Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($end_dt) . " Duration: " . Linux::DVB::DVBT::Apps::QuartzPVR::Time::secs2time($entry_href->{duration_secs}) . ")" ;

		my $fname = Linux::DVB::DVBT::Apps::QuartzPVR::Series::get_filename($entry_href) ;
		
		# channel type
		my $type = $entry_href->{'chan_type'} ;
	
		# Channel
		$entry .= " '$entry_href->{channel}'" ;
		
		# Filename
		my $recfilename = $fname ;
		$entry .= " '$recfilename'" ;
		
		# Duration
		$entry .= " $entry_href->{duration_secs}" ;
		
		## Timeslip?
		if ($entry_href->{'timeslip'})
		{
			$entry .= " \t-event $entry_href->{event} -timeslip $entry_href->{'timeslip'}" ;
		}

		if ($type eq 'radio')
		{
			## Pass in some extra info for tagging
			$entry .= " -title '$entry_href->{title}'" ;
			
			my $episode = Linux::DVB::DVBT::Apps::QuartzPVR::Path::episode_string($entry_href) ;
			$entry .= " -episode '$episode'" if $episode ;
		}

		## PID		
		my $pid = $entry_href->{'pid'} ;
		$entry .= " -id $pid" ;
	
		++$idx ;
		
		push @rec_contents, $block_comment ;
		push @rec_contents, $entry ;
		push @rec_contents, "" ;

		
		## Track recorded files
		$recorded_files{"$pid-dvbt"} = {
			%$entry_href,
			'rectype'	=> 'dvbt',
			'type'		=> $type,
			'file'		=> $recfilename,
		} ;
	
	}
	
	# Set time
	my $datetime = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_format($mux_href->{'start_datetime'}, "%M %H %d %m *") ;			 

	# Log
	##$cmd .= " >> $opts_href->{log} 2>&1" ;
	$cmd .= " >> $opts_href->{log_dir}/dvbt-record.log 2>&1" ;
		

	## Create block
	my $block_comment = "# \@[$opts_href->{'crontag'}] MULTIPLEX$mux_href->{multid} date:$mux_href->{date} start:$mux_href->{start} end:$mux_href->{end} duration:$mux_href->{duration}" ;

	my $block_href = {
		'comment'		=> $block_comment,
		'datetime' 		=> $datetime,
		'command'		=> $cmd,
		
		'start_dt_mins'	=> $start_dt_mins,
		
		'rec_file'		=> $rec_file,
		'rec_contents'	=> \@rec_contents,
	} ;
	
	return $block_href ;
}

#---------------------------------------------------------------------
sub check_cron
{
	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::startfn() ;

print "check_cron()\n" if $debug ;


	my @record_blocks = map {$ct->block($_)} $ct->select(
								-type		=> 'comment',
								-data_re	=> '\@\[' . $opts_href->{'crontag'} . '\]' 
								) ;
	# process
	my %cron = (
		'0'	=> {},
		'1'	=> {},
	);
	foreach my $block (@record_blocks)
	{
		for my $event ( $block->select( -type => 'event') ) 
		{
			#	# @[dvb-record] id:197 title:"The Big Bang Theory" date:2010/02/20 start:22:25:00 end:22:50:00 duration:00:25:00
			#	25 22 20 02 * dvbt-ffrecord -a 0 'E4' '/served/videos/PVR/The Big Bang Theory-20100220222500.mpeg' 1455 >> /var/log/users/sdprice1/dvbt-ffrec.log 2>&1
			#
			# cmd = "dvbt-ffrecord -a 0 'E4' '/served/videos/PVR/The Big Bang Theory-20100220222500.mpeg' 1455 >> /var/log/users/sdprice1/dvbt-ffrec.log 2>&1"
			# hour = 22
			# min = 25
			# month = 02
			# day = 20
			#
			my $cmd = $event->command() ;
			my $hour = $event->hour() ;
			my $min = $event->minute() ;
			my $day = $event->dom() ;
			my $month = $event->month() ;
			
			my $adap = "0" ;
			my $duration_secs = 0 ;
			my $chan ;
			my $prog ;
			my $found = 0 ;
print "cmd=\"$cmd\"\n" if $debug ;
			if ($cmd =~ /(?:dvbt\-ffrecord|dvbt\-ffrecord\.pl) \-a (\d+) \'([^\']+)\' \'([^\']+)\' (\d+)/)
			{
				($adap, $chan, $prog, $duration_secs) = ($1, $2, $3, $4) ;
				$adap = sprintf "%0d", $adap ;
				++$found ;
print " + got (adap=$adap, chan=$chan, prog=$prog, secs=$duration_secs)\n" if $debug ;
			}
			elsif ($cmd =~ /^dvbt\-ffrecord \'([^\']+)\' \'([^\']+)\' (\d+)/)
			{
				($chan, $prog, $duration_secs) = ($1, $2, $3) ;
				++$found ;
print " + got (chan=$chan, prog=$prog, secs=$duration_secs)\n" if $debug ;
			}
			next unless $found ;
						
			my $date = "2010/$month/$day" ;
			my $time = sprintf "%02d:%02d", $hour, $min ;
			my $dt = Linux::DVB::DVBT::Apps::QuartzPVR::Time::parse_date($date, $time) ;
			my $dt_mins = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2mins($dt) ;

			my $dt_end = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt_offset($dt, "+ $duration_secs seconds") ;
			my $end_time = Linux::DVB::DVBT::Apps::QuartzPVR::Time::dt2hms($dt_end) ;
			
print "date=$date time=$time dt=$dt dt-end=$dt_end end=$end_time mins=$dt_mins\n" if $debug ;
			
			my $start = 60 * $dt_mins ;
			my $end = $start + $duration_secs ;

print "start=$start end=$end\n" if $debug ;
			
			$cron{$adap}{$dt_mins} ||= [] ;
			push @{$cron{$adap}{$dt_mins}}, {
				'date'		=> $date,
				'time'		=> $time,
				'chan'		=> $chan,
				'prog'		=> $prog,
				'duration'	=> $duration_secs,
				'start'		=> $start,
				'end'		=> $end,
				'endtime'	=> $end_time,
			} ;	
    	}
	}
	
	# sort
	foreach my $adap (sort { $a <=> $b } keys %cron)
	{
		my $dvb = "DVB$adap" ;
		
		my $prev_end = 0 ;
		my $prev ;
		foreach my $dt_mins (sort { $a <=> $b } keys %{$cron{$adap}})
		{
			if (scalar(@{$cron{$adap}{$dt_mins}}) > 1)
			{
				print "ERROR: multiple programs scheduled at the same time on $dvb:\n" ;
				foreach my $entry (@{$cron{$adap}{$dt_mins}})
				{
					print "  $entry->{'date'} $entry->{'prog'} $entry->{'time'} - $entry->{'endtime'} : '$entry->{'title'}' $entry->{'chan'} ($entry->{'type'})\n" ;
				}
				print "\n" ;
			}
			else
			{
				my $entry = $cron{$adap}{$dt_mins}[0] ;
				my $error = "" ;
				if ($entry->{'start'} <= $prev_end)
				{
					$error = "program overlap" ;
				}
				elsif ($entry->{'start'} - $prev_end < $opts_href->{'early'})
				{
					$error = "programs are too close (less than $opts_href->{'early'} secs)" ;
				}
				
				if ($error)
				{
					print "ERROR: $error on $dvb:\n" ;
					print "  $entry->{'date'} $entry->{'prog'} $entry->{'time'} - $entry->{'endtime'}\n" ;
					print "  $entry->{'date'} $prev->{'prog'} $prev->{'time'} - $prev->{'endtime'}\n" ;
					print "\n" ;
				}
				$prev_end = $entry->{'end'} ;
				$prev = $entry ;
			}			
		}
	}

	Linux::DVB::DVBT::Apps::QuartzPVR::Base::DbgProf::endfn() ;
}



#============================================================================================
# DEBUG
#============================================================================================
#


# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

__END__


