#!/usr/bin/perl -w
#
# Example Utility using Lustre::Info
#
# (C) 2010 Adrian Ulrich - <adrian.ulrich@id.ethz.ch>
#
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
use strict;
use Lustre::Info;
use Getopt::Long;
use Data::Dumper;

use constant ANSI_ESC    => "\x1b[";
use constant ANSI_RSET   => '0m';

$| = 1;

my $opts = {};
my $l    = Lustre::Info->new;

GetOptions($opts, "summary|s", "ost-stats", "filter=s", "monitor=s", "help", "version", "as-list", "delay=i");

# fixup default delay value
$opts->{delay} = 3 if !exists($opts->{delay}) or $opts->{delay} < 1;


if($opts->{help}) {
	usage();
}
elsif($opts->{version}) {
	version();
}
elsif($opts->{summary}) {
	show_summary();
}
elsif(exists($opts->{'ost-stats'})) {
	loop_ost_stats();
}
elsif($opts->{monitor}) {
	$opts->{filter} = "." if !exists($opts->{filter});
	
	if($l->is_ost) {
		loop_client_stats($opts->{filter},'ost','traffic')      if $opts->{monitor} eq 'ost';
		loop_client_stats($opts->{filter},'ost','pattern')      if $opts->{monitor} eq 'ost-pattern';
		loop_client_stats($opts->{filter},'export','traffic')   if $opts->{monitor} eq 'nid';
		loop_client_stats($opts->{filter},'export','pattern')   if $opts->{monitor} eq 'nid-pattern';
		loop_brw_stats($opts->{filter}, 'disk_i_o_size')        if $opts->{monitor} eq 'io-size';
		loop_brw_stats($opts->{filter}, 'disk_fragmented_i_os') if $opts->{monitor} eq 'io-frag';
		loop_brw_stats($opts->{filter}, 'i_o_time__1_1000s_')   if $opts->{monitor} eq 'io-time';
		loop_brw_stats($opts->{filter}, 'disk_i_os_in_flight')  if $opts->{monitor} eq 'in-flight';
	}
	die "$0: unknown value for --monitor: `$opts->{monitor}'\n";
}
else {
	usage();
}



#######################################################################
# Display usage information / help
sub usage {
	die join("\n",
	"Usage: $0 OPTION",
	"",
	"Valid OPTIONs are:",
	"--help                    Display this information and exit",
	"--version                 Display version information",
	"--summary                 Display some information about this host",
	"--ost-stats               Display per-OST statistics",
	"--monitor=ACTION          Display various statistics, valid values for `ACTION' are:",
	"                           --- IF RUNNING ON AN OST: ---",
	"                            ost         : show ost->client stats (filter affects ost)",
	"                            ost-pattern : show `metadata' rpcs of clients per ost",
	"                            nid         : show client->ost stats (filter affects nid)",
	"                            nid-pattern : same as ost-pattern, but filter affects nid",
	"                            io-size     : track io-size per client",
	"                            io-frag     : track io-fragmentation per client",
	"                            io-time     : track service time per client",
	"                            in-flight   : track in-flight queue per client",
	"--filter=REGEXP           Filter --monitor output (use `.' to show everything)",
	"--delay=SECONDS           Refresh interval (defaults to 3 sec.)",
	"--as-list                 Do not clear the screen",
	"",
	"",
	"Report bugs to <adrian.ulrich\@id.ethz.ch>.",
	"");
}

#######################################################################
# Display version and exit
sub version {
	die join("\n",
	"lustre-info $Lustre::Info::VERSION, running with Perl ".sprintf("%vd", $^V)." ($^X) on `$^O'",
	"Report bugs to <adrian.ulrich\@id.ethz.ch>.",
	"");
}

#######################################################################
# Return 'clear-screen' ascii sequence
sub _cls {
	return "# ".localtime()."\n" if $opts->{'as-list'};
	return ANSI_ESC.'H'.ANSI_ESC.'2J';
}



#######################################################################
# Display a short summary about this host
sub show_summary {
	my @summary_objs = ();
	
	print "Lustre module version    : ".($l->get_lustre_version)."\n";
	print "Host is acting as OST    : ".($l->is_ost ? 'yes' : 'no')."\n";
	print "Host is acting as MDS    : ".($l->is_mds ? 'yes' : 'no')."\n";
	print "Host is acting as MDT    : ".($l->is_mdt ? 'yes' : 'no')."\n";
	
	if($l->is_ost) {
		print "\nOST list:\n";
		@summary_objs = map( { $l->get_ost($_) } @{$l->get_ost_list} );
	}
	elsif($l->is_mdt) {
		print "\nMDT list:\n";
		@summary_objs = map( { $l->get_mdt($_) } @{$l->get_mdt_list} );
	}
	
	foreach my $so (@summary_objs) {
		my $size   = sprintf("%.2f",$so->get_kbytes_total/1024/1024);
		my $free   = sprintf("%.2f",$so->get_kbytes_free/1024/1024);
		
		my $f_free = $so->get_files_free;
		my $f_total= $so->get_files_total;
		my $f_used = $f_total - $f_free;
		my $f_pct  = ( $f_total ? sprintf("%.2f",( $f_free / $f_total * 100)) : 0 );
		
		my $rcinfo = $so->get_recovery_info;
		my $blkdev = $so->get_blockdevice;
		
		print join("\n",( "\t".$so->get_name,
		        "\t\tblock_device  : $blkdev"   , "\t\tlast_recovery : ".gmtime($rcinfo->{recovery_start})." (UTC)",
		        "\t\ttotal_size    : $size GB", "\t\tfree_space    : $free GB",
		        "\t\tfiles         : $f_used in use (~ $f_pct\% free)",
		        "",
		  ));
	}
	
}

#######################################################################
# Display per-OST statistics
sub loop_ost_stats {
	
	die "This host is not an OST\n" unless $l->is_ost;
	
	my $orx = {}; # reference with all ost data
	foreach my $this_ost (@{$l->get_ost_list}) {
		my $obj              = $l->get_ost($this_ost) or next;
		my $blkdev           = $obj->get_blockdevice;
		   $orx->{$this_ost} = { name=>$this_ost, blkdev=>$blkdev, obj=>$obj };
	}
	
	# loop forever:
	for(;;) {
		print _cls();
		foreach my $this_ost (sort(keys(%$orx))) {
			my $oref = $orx->{$this_ost};
			$oref->{obj}->collect_ost_stats;
			
			my $stats = $oref->{obj}->get_ost_stats or next; # no data (yet);
			my $slice = $stats->{_slice}            or next; # ???
			my $wps   = $stats->{write_bytes}/$slice/1024/1024;
			my $rps   = $stats->{read_bytes}/$slice/1024/1024;
			printf("%16s (\@ %8s) :  write=%8.3f MB/s, read=%8.3f MB/s", $this_ost, $oref->{blkdev}, $wps, $rps);
			
			# Add some 'metadata' info
			foreach my $type (qw(create destroy setattr preprw)) {
				printf(", %s=%5.1f R/s",$type,$stats->{$type}/$slice);
			}
			print "\n";
		}
		sleep($opts->{delay});
	}
}

#######################################################################
# Display per-client statistics for OSTs matching regexp
sub loop_client_stats {
	my($regexp, $provider, $xmode) = @_;
	
	my($gx, $gx_list)                    = ("get_${provider}", "get_${provider}_list");
	my @ost_ref                          = map { $l->$gx($_) } grep(/$regexp/, @{$l->$gx_list});
	my($kludge, $what, $div_by, $fields) = ( $xmode eq 'traffic' ? ('_bytes', 'MB/s', 1024*1024, ['read','write']) : ('', 'op/s', 1, ['setattr','preprw','create', 'destroy']) );
	
	for(;;) {
		my $memhog = {};
		foreach my $ost_obj (sort @ost_ref) {
			$ost_obj->collect_client_stats; # Trigger new data collection
			_update_memhog( Memhog=>$memhog, Data=>$ost_obj->get_client_stats, Name=>$ost_obj->get_name, PostfixKludge=>$kludge,
			                Fields=>$fields, Reverse=>($provider eq 'export' ? 1 : 0));
		}
		
		my $lvl2_seen = delete($memhog->{_LVL2_SEEN_});
		my @ost_seen  = sort(keys(%$lvl2_seen));
		_dump_matrix(Data=>$memhog, Items=>\@ost_seen, What=>$what, Divide=>$div_by, Fields=>$fields, ShowAll=>($provider =~ /^ost/ ? 0 : 1) );
		sleep($opts->{delay});
	}
	# NOT REACHED
}


#######################################################################
#
sub loop_brw_stats {
	my($regexp, $kind) = @_;
	
	my @exp_ref = map { $l->get_export($_) } grep(/$regexp/, @{$l->get_export_list});
	
	for(;;) {
		my $memhog   = {};
		my $seen_lbl = {};
		foreach my $exp_obj (@exp_ref) {
			$exp_obj->collect_brw_stats;
			my $r     = $exp_obj->get_brw_stats or next; # -> first run
			my $data  = $r->{data}->{$kind};
			my $slice = $r->{_slice} or next;
			foreach my $label (keys(%$data)) {
				my $wps = $data->{$label}->{'write'}/$slice;
				my $rps = $data->{$label}->{'read'}/$slice;
				$memhog->{$exp_obj->get_name}->{$label} = { write=>$wps, read=>$rps };
				$seen_lbl->{$label}=1;
			}
		}
		
		my @xitems = sort(keys(%$seen_lbl));
		_dump_matrix(Data=>$memhog, Items=>\@xitems, What=>"OPs/s of `$kind'", ShowAll=>1, Divide=>1);
		sleep($opts->{delay});
	}
}


#######################################################################
# Extract data from memhog and create per-second stats
sub _update_memhog {
	my(%args) = @_;
	my $memhog  = $args{Memhog};
	my $dataset = $args{Data};
	my $name    = $args{Name};
	my $pfk     = ($args{PostfixKludge} || ''); # for ugli postfix'es :-(
	my $fields  = $args{Fields} || ['read', 'write'];
	
	my $reverse = ($args{Reverse} ? 1 : 0 );
	foreach my $key (keys(%$dataset)) {
		my $slice      = $dataset->{$key}->{_slice} or next;
		my($lx1, $lx2) = ( $reverse ? ($name,$key) : ($key,$name) );
		foreach my $mh_key (@$fields) {
			$memhog->{$lx1}->{$lx2}->{$mh_key} = $dataset->{$key}->{$mh_key.$pfk}/$slice;
		}
		$memhog->{_LVL2_SEEN_}->{$lx2} = 1;
	}
}


sub _dump_matrix {
	my(%args) = @_;
	
	my $memhog   = $args{Data};                    # Current dataset
	my $items    = $args{Items};                   # Items to display in header
	my $what     = $args{What};                    # Type of data (MB/s)
	my $divide   = $args{Divide};                  # Divide values by ....
	my $hide     = ($args{ShowAll} ? 0 : 1 );      # Hide/Show clients with total_wps+total_rps < 1
	my $fields   = $args{Fields} || ['read', 'write'];
	my $n_items  = int(@$items);
	my $n_fields = int(@$fields);
	my $seen_c   = 0;
	my $shown_c  = 0;
	
	print _cls().ANSI_ESC."7m"; # Switch into 'invert' mode
	if($n_items > 0) {
		printf("%-19s|", "> client nid");
		print join("|", map({sprintf("%-${n_fields}0s", " $_")} @$items))."| ";
		print "+++ TOTALS +++ " if $n_items > 1;
		print "($what)";
	}
	else {
		print "collecting data, please wait...";
	}
	print ANSI_ESC.ANSI_RSET."\n"; # switch back into normal mode
	
	foreach my $nid (sort(keys(%$memhog))) {
		my $total = {};
		my $tsum  = 0;
		my $str   = sprintf("%-19s|",$nid); # Add client ID to list
		$seen_c++;
		
		foreach my $this_item (@$items) {
			my $qref = ( $memhog->{$nid}->{$this_item} || { map( { ($_,0) } @$fields ) } ); # <-- note the ultra smart use of map ;-)
			my @data = ();
			foreach my $this_field (@$fields) {
				push(@data, sprintf("%s=%6.1f", substr($this_field,0,1), $qref->{$this_field}/$divide));
				$total->{$this_field} += $qref->{$this_field};
				$tsum                 += $qref->{$this_field};
			}
			$str .= sprintf("%-${n_fields}0s|", " ".join(", ",@data)); # each field has 10 chars
		}
		next if $tsum/$divide < 1 && $hide;
		print "$str";
		if($n_items > 1) {
			# add totals:
			print " ".join(", ",map( { sprintf("%s=%6.1f", $_,$total->{$_}/$divide) } @$fields) );
		}
		print "\n";
		$shown_c++;
	}
	
	printf("# %d client(s) hidden\n", $seen_c-$shown_c) if $hide;
	
}
__END__
	# Change into 'invert' mode
	print _cls().ANSI_ESC."7m";
	
	if($n_items >= 1) {
		printf("%-20s| %s","> client_nid", join("|", map { sprintf("%-${f_width}s"," $_") } @$items));
		print "| +++ TOTAL +++ ($what)" if $n_items > 1;
	}
	else {
		print "collecting data, please wait...";
	}
	
	# Restore terminal defaults
	print ANSI_ESC.ANSI_RSET."\n";
	
	my $shown = 0; # Number lines that we show
	my $count = 0; # Number of lines that we know
	foreach my $eid (sort(keys(%$memhog))) {
		my($str,$tt,$total) = ('',0,{});
		$count++;
		foreach my $this_item (@$items) {
			my $qref = ( $memhog->{$eid}->{$this_item} || { map( { ($_,0) } @$fields ) } ); # <-- note the ultra smart use of map ;-)
			my @data = ();
			foreach my $this_field (@$fields) {
				push(@data, sprintf("%s=%6.1f", substr($this_field,0,1), $qref->{$this_field}/$divide));
				$total->{$this_field} += $qref->{$this_field};
				$tt += $qref->{$this_field};
			}
			$str .= sprintf("%-${f_width}s|", join(", ",@data));;
		}
		next if $tt/$divide < 1 && $hide; # almost no traffic -> hide if requested
		$shown++;
		printf("%-20s| %s ",$eid, $str);
		print join(", ",map( { sprintf("%s=%6.1f", $_,$total->{$_}/$divide) } @$fields) );
		print "\n";
	}
	
	printf("# %d client(s) hidden\n", $count-$shown) if $hide;
	
}



