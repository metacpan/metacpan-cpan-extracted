package Linux::DVB::DVBT::Advert::Mem ;

=head1 NAME

Linux::DVB::DVBT::Advert::Mem

=head1 SYNOPSIS

	use Linux::DVB::DVBT::Advert::Mem ;
  
  	$Linux::DVB::DVBT::Advert::Mem::MEM_PROFILE = 1 ;
  	
  	# set baseline memory usage start value - all reports are relative to this
  	set_used() ;
  	
  	# display memory used from baseline (and also relative to last call)
  	print_used() ;
  	
	# show size of variables
	var_size("message string", $var1, @var2) ;
	
=head1 DESCRIPTION

For debug/developer use.

This module contains memory profiling tools that I used while developing the advert removal modules

=cut

use strict ;

our $VERSION = '1.00' ;
our $MEM_PROFILE ;
our $DEBUG ;

our $HAS_MEM ;
our %mHash ;
our $first_mem ;
our $prev_mem ;


#============================================================================================

=head2 Mem

=over 4


=back

=cut

BEGIN {
	$MEM_PROFILE = 0 ;
	$DEBUG = 0 ;
	
	
	*set_used = \&set_used_null ;
	*get_used = \&get_used_null ;
	*print_used = \&print_used_null ;
	*varsize = \&varsize_null ;

	my %PROCLIST = (
		'print_used_win32'	=> ["Win32::SystemInfo"],
		'print_used_proc'	=> ["Proc::ProcessTable"],
	) ;

print STDERR "Mem.pm\n" if $DEBUG ;			
	
	foreach my $func (keys %PROCLIST)
	{
print STDERR " + check $func... \n" if $DEBUG ;			
		
		my $ok =1 ;
		foreach my $mod (@{$PROCLIST{$func}})
		{
print STDERR " + import $mod... " if $DEBUG ;			
			if (eval "require $mod") 
			{
				$mod->import() ;
print STDERR "ok\n" if $DEBUG ;			
			}
			else
			{
				$ok = 0 ;
print STDERR "fail\n" if $DEBUG ;			
			}
		}
		
		if ($ok)
		{
			$HAS_MEM = 1 ;
			eval {
			*print_used = \&$func ;
			} ;
			last ;
print STDERR "MEM: got $func\n" if $DEBUG ;			
		}
	}
	
	my $mod = "Devel::Size" ;
print STDERR " + import $mod... " if $DEBUG ;			
	if (eval "require $mod") 
	{
		$mod->import() ;
		*varsize = \&varsize_devel ;
print STDERR "ok\n" if $DEBUG ;			
print STDERR "MEM: got $mod\n" if $DEBUG ;			
	}
	else
	{
print STDERR "fail\n" if $DEBUG ;			
	}
}

# --------------------------------------------------------------------------------------------
sub get_used_null
{
}

# --------------------------------------------------------------------------------------------
sub get_used_win32
{
	return 0 unless $MEM_PROFILE ;
	
	my $avail ;
    if (Win32::SystemInfo::MemoryStatus(%mHash, "MB"))
    {
    	$avail = $mHash{'AvailPhys'} * 1.0 ;
    }
    
    return $avail ;
}

# --------------------------------------------------------------------------------------------
sub get_used_proc
{
	return 0 unless $MEM_PROFILE ;

	my $t = new Proc::ProcessTable;
	my $total = 0 ;
	foreach my $got ( @{$t->table} ) 
	{
		my $pid = $got->pid ;
		next if not $pid eq $$;
		
		if ($got->can("size"))
		{
			$total += $got->size;
		}
		else
		{
			my @lines = `cat /proc/$pid/statm 2>/dev/null` ;
			my ($size_pages, 
			$resident_pages, 
			$share_pages, 
			$trs_pages, 
			$lrs_pages, 
			$drs_pages, 
			$dt_pages) = split /\s+/, $lines[0] ;

			if ($resident_pages)
			{
				# 4k pages to bytes
				my $resident = $resident_pages << 12 ;
	
	#print " + pmap $pid : $resident\n" ;
	
				$total += $resident ;
			}
		}
	}
	if ($total)
	{
		$total = int($total / (1024*1024)) ;
	}
	
	return $total ;
}


# --------------------------------------------------------------------------------------------
sub set_used_null
{
}

# --------------------------------------------------------------------------------------------
sub set_used_win32
{
	return 0 unless $MEM_PROFILE ;
	
	my $avail = get_used_win32();
    if ($avail)
    {
    	$prev_mem = $avail ;
    	$first_mem ||= $avail ;
    }
    
    return $avail ;
}

# --------------------------------------------------------------------------------------------
sub set_used_proc
{
	return 0 unless $MEM_PROFILE ;

	my $total = get_used_proc() ;
	if ($total)
	{
		$total = int($total / (1024*1024)) ;
		
    	$prev_mem = $total ;
    	$first_mem ||= $total ;
	}
	
	return $total ;
}

# --------------------------------------------------------------------------------------------
sub print_used_null
{
}

# --------------------------------------------------------------------------------------------
sub print_used_win32
{
	my ($msg) = @_ ;
	
	return unless $MEM_PROFILE ;
	
	$msg ||= "" ;
	
	my $avail = get_used_win32() ;
    if ($avail)
    {
		if ($first_mem)
		{
			my $used = $first_mem - $avail ;
			my $diff = $prev_mem - $avail ;
			$msg .= ": " if $msg ; 
			print "${msg}Memory used $used MB (since last call $diff MB)\n" ;
		}
    	
    	$prev_mem = $avail ;
    	$first_mem ||= $avail ;
    }
}

# --------------------------------------------------------------------------------------------
sub print_used_proc
{
	my ($msg) = @_ ;
	
	return unless $MEM_PROFILE ;

	$msg ||= "" ;
	
	my $total = get_used_proc() ;
	if ($total)
	{
		if ($first_mem < $total)
		{
			my $used = $total - $first_mem ;
			my $diff = $total - $prev_mem ;
			$msg .= ": " if $msg ; 
			print "${msg}Memory used $used MB (since last call $diff MB)\n" ;
		}

    	$prev_mem = $total ;
    	$first_mem ||= $total ;
	}
	
}



#---------------------------------------------------------------------------------
sub varsize_null
{
}

#---------------------------------------------------------------------------------
sub varsize_devel
{
	my ($msg, @vars) = @_ ;

	return unless $MEM_PROFILE ;

	print "\n-------------------------------------------------------------------------\n" ;
	my @collect ;
	
	foreach (@vars)
	{
		push @collect, $_ ;
	}
	my $size = int(Devel::Size::total_size(\@collect) / (1024 * 1024)) ;
	print "$msg : Variables size = $size MB\n" ; 
		
	print "\n-------------------------------------------------------------------------\n" ;
}


# ============================================================================================
# END OF PACKAGE

1;

