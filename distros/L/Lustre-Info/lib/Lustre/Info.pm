#
# Lutre::Info Mainclass
#
# (C) 2010 Adrian Ulrich - <adrian.ulrich@id.ethz.ch>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Lustre::Info;

use strict;
use warnings;
use Lustre::Info::OST;
use Lustre::Info::Export;
use Lustre::Info::MDT;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA       = qw(Exporter);
@EXPORT    = qw();
@EXPORT_OK = qw();
$VERSION   = '0.02';

use constant PROCFS_LUSTRE    => "/proc/fs/lustre";
use constant PROCFS_OBDFILTER => "/proc/fs/lustre/obdfilter";
use constant PROCFS_MDS       => "/proc/fs/lustre/mds";

##########################################################################
# Creates a new Spy Object
sub new {
	my($class,%args) = @_;
	my $self = {};
	bless($self,$class);
	return $self;
}

##########################################################################
# Return (uncached) list of all OBD Objects
sub get_ost_list {
	my($self) = @_;
	my @list = ();
	opendir(OBD, PROCFS_OBDFILTER) or return \@list;
	while(defined(my $dirent = readdir(OBD))) {
		next if $dirent =~ /^\./; # dotfile
		next if ! -d join("/",PROCFS_OBDFILTER, $dirent);
		push(@list, $dirent);
	}
	closedir(OBD);
	return \@list;
}

##########################################################################
# Returns (uncached) list of all exports known to all OSTs
sub get_export_list {
	my($self) = @_;
	my $list = {};
	my @osts = $self->get_ost_list;
	
	foreach my $this_ost (@{$self->get_ost_list}) {
		my $export_dir = PROCFS_OBDFILTER."/$this_ost/exports/";
		opendir(EXP, $export_dir) or next;
		while(defined(my $dirent = readdir(EXP))) {
			next if $dirent =~ /^\./; # dotfile;
			next if ! -d $export_dir.$dirent;
			$list->{$dirent}++;
		}
		closedir(EXP);
	}
	my @exports = keys(%$list);
	return \@exports;
}

##########################################################################
# Return (unchaced) list of all MTD Objects
sub get_mdt_list {
	my @list = ();
	opendir(OBD, PROCFS_MDS) or return \@list;
	while(defined(my $dirent = readdir(OBD))) {
		next if $dirent =~ /^\./; # dotfile
		next if ! -d join("/",PROCFS_MDS, $dirent);
		push(@list, $dirent);
	}
	closedir(OBD);
	return \@list;
}

##########################################################################
# Returns TRUE if current host is acting as an OST
sub is_ost {
	return ( -d PROCFS_LUSTRE."/ost" ? 1 : 0 );
}

##########################################################################
# Returns TRUE if current host is acting as an MDS
sub is_mds {
	return ( -d PROCFS_LUSTRE."/mds" ? 1 : 0 );
}

##########################################################################
# Returns TRUE if current host is acting as an MDT
sub is_mdt {
	return ( -d PROCFS_LUSTRE."/mdt" ? 1 : 0 );
}

##########################################################################
# Return object to __PACKAGE__::OST Class
sub get_ost {
	my($self,$ostname) = @_;
	return Lustre::Info::OST->new(super=>$self, ostname=>$ostname);
}

##########################################################################
# Returns object to __PACKAGE__::Export Class
sub get_export {
	my($self, $expname) = @_;
	return Lustre::Info::Export->new(super=>$self, export=>$expname);
}

##########################################################################
# Returns object to __PACKAGE__::MDT
sub get_mdt {
	my($self, $mdtname) = @_;
	return Lustre::Info::MDT->new(super=>$self, mdtname=>$mdtname);
}

##########################################################################
# Return current lustre version (undef if lustre is not loaded)
sub get_lustre_version {
	my $ver = undef;
	open(LF, PROCFS_LUSTRE."/version") or return $ver;
	while(<LF>) {
		if($_ =~ /^lustre: (\d.+)$/) { $ver = $1 }
	}
	close(LF);
	return $ver;
}




##########################################################################
# Try to parse a lustre statistics file created by lprocfs
sub _parse_stats_file {
	my($self,$fname) = @_;
	
	my $data = {};
	my $snap = 0;
	open(P, $fname) or return undef;
	while(<P>) {
		# req_waittime              21932809 samples [usec] 3 1047811 9446315012 4121280741355958 (<-- sqcount)
		if(my($name,$samples,$format,$min,$max,$count) = $_ =~ /^(\S+)\s+(\d+) samples \[(.+)\]\s+(\d+)\s+(\d+)\s+(\d+)[^\d]/) { # note: sqcount is not used
			$data->{$name} = { format=>$format, samples=>$samples, count=>$count };
		}
		elsif(my($rqname,$rqx,$rqformat) = $_ =~ /^(\S+)\s+(\d+) samples \[(.+)\]/) {
			$data->{$rqname}  = { format=>$rqformat, samples=>$rqx, count=>$rqx };
		}
		elsif($_ =~ /^snapshot_time\s+([0-9.]+) /) {
			$snap = $1;
		}
	}
	close(P);
	return({ timestamp=>$snap, data=>$data });
}

##########################################################################
# Try to parse the per-export 'brw' statistics file
sub _parse_brw_file {
	my($self,$fname) = @_;
	
	my $ctx = '';
	my $r   = {};
	open(P, $fname) or return undef;
	while(<P>) {
		if($_ =~ /^snapshot_time:\s+([0-9.]+) /) {
			$r->{timestamp} = $1;
		}
		elsif($_ =~ /([^:]+?)(\s+)ios .+ ios/) {
			$ctx = lc($1);
			$ctx =~ tr/a-z0-9/_/c;
		}
		elsif($_ =~ /^$/) {
			$ctx = '';
		}
		elsif($ctx && $_ =~ /^(.+):\s+(\d+)\s+\d+\s+\d+\s+\|\s*(\d+)\s+\d+/) {
			$r->{data}->{$ctx}->{$1} = { read=>$2, write=>$3 };
		}
	}
	close(P);
	return $r;
}


##########################################################################
# Quick'n'dirty 'generic' parser
sub _parse_generic_file {
	my($self,$fname) = @_;
	
	my $r = {};
	open(P, $fname) or return undef;
	while(<P>) {
		if(my($k,$v) = $_ =~ /^(\S+):\s+(.+)$/) {
			if($v =~ /^(\d+)\/(\d+)$/) {
				$v = [$1,$2];
			}
			$r->{$k} = $v;
		}
	}
	close(P);
	return $r;
}

##########################################################################
# Perform an addition on multiple deep hashrefs
# This could also be implemented by using recursion but perl is somewhat
# slow wehn it comes to call sub()'s, so eval should be faster for very
# 'deep' hashes.
sub sum_up_deep {
	my($self, $size, @reflist) = @_;
	
	my $to_eval_h = '';
	my $to_eval_m = '';
	my $to_eval_b = '';
	my $eval_code = undef;
	my $res       = {};
	foreach my $tnum (0..$size) {
		my $nnum = $tnum+1;
		my $xtab = ( "  " x $tnum );
		$to_eval_h .= "${xtab}foreach my \$l$nnum (keys(%{\$lroot$to_eval_m})) {\n";
		$to_eval_b = "$xtab}\n$to_eval_b";
		$to_eval_m .= "->{\$l$nnum}";
	}
	
	# Assemble perl-loop-code:
	$eval_code = "$to_eval_h\t\t\$res$to_eval_m += \$lroot$to_eval_m\n".$to_eval_b;
	
	#..and execute for each given hashref
	foreach my $lroot (@reflist) {
		eval $eval_code;
		return undef if $@; # error? -> most likely caused by an invalid $size setting!
	}
	return $res;
}


1;
__END__

=head1 NAME

Lustre::Info - Perl interface to Lustre procfs information

=head1 SYNOPSIS

  use strict;
  use Lustre::Info;
  
  my $l = Lustre::Info->new;
  print "Host is an OST? ".($l->is_ost ? 'yes - running lustre '.$l->get_lustre_version : 'no')."\n";
  
  if($l->is_ost) {
    print "List of OSTs on this OSS:\n";
    my @ost_list = @{$l->get_ost_list};
    print join("", map { "\t$_\n" } @ost_list);
    
    my $ost_ref = $l->get_ost($ost_list[0]);
    print "OST ".$ost_ref->get_name." is hosted on ".$ost_ref->get_blockdevice."\n";
  }

=head1 DESCRIPTION

"Lustre::Info" provides an object interface to obtain various information about lustre

=head1 CONSTRUCTOR

=over 4

=item new ()

Creates a new Lustre::Info object.

=back

=head1 METHODS

=over 4

=item get_ost_list

Returns an array-ref with all OSTs hosted by this OSS
(List will be empty on non-OST hosts)

=item get_export_list

Returns an array-ref with all known exports/nids/clients
on this OSS.

=item get_mdt_list

Returns an array-ref with all known MDTs hosted by this MDS
(Lustre < 2.0 installations will never have more than one MDT)

=item is_ost

Returns TRUE if this server acts as an OST

=item is_mds

Returns TRUE if this server acts as an MDS

=item is_mdt

Returns TRUE if this server is a MDT

=item get_lustre_version

Return currently running lustre (kernel module) version

=item get_ost(OST_NAME)

Returns a blessed reference to C<Lustre::Info::OST>

=item get_export(EXPORT_NAME)

Returns a blessed reference to C<Lustre::Info::Export>

=item get_mdt(MDT_NAME)

Returns a blessed reference to C<Lustre::Info::MDT>



=back

=head1 STATUS

Lustre::Info::* is in its early stages, the provided API should 
not be considered as 'stable'.

=head1 AUTHOR

Copyright (C) 2010, Adrian Ulrich E<lt>adrian.ulrich@id.ethz.chE<gt>

=head1 SEE ALSO

L<Lustre::Info::OST>,
L<Lustre::Info::Export>,
L<Lustre::Info::MDT>,
L<Lustre::LFS>,
L<http://www.lustre.org>

=cut
