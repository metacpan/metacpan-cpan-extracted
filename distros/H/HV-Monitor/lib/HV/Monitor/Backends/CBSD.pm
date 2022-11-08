package HV::Monitor::Backends::CBSD;

use 5.006;
use strict;
use warnings;

=head1 NAME

HV::Monitor::Backends::CBSD - CBSD support for HV::Monitor

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

=head1 SYNOPSIS

    use HV::MOnitor::Backend::CBSD;
    
    my $backend=HV::MOnitor::Backend::CBSD->new;
    
    my $usable=$backend->usable;
    if ( $usable ){
        $return_hash_ref=$backend->run;
    }

=head1 METHODS

=head2 new

Initiates the backend object.

    my $backend=HV::MOnitor::Backend::CBSD->new;

=cut

sub new {
	my $self = { version => 1, };
	bless $self;

	return $self;
}

=head2 run

    $return_hash_ref=$backend->run;

=cut

sub run {
	my $self = $_[0];

	my $bls_raw
		= `/bin/sh -c "cbsd bls header=0 node= display=jname,jid,vm_ram,vm_curmem,vm_cpus,pcpu,vm_os_type,ip4_addr,status,vnc alljails=0 2> /dev/null" | sed -e 's/\x1b\[[0-9;]*m//g'`;
	if ( $? != 0 ) {
		return {
			data        => { hv => 'cbsd' },
			version     => $self->{version},
			error       => 2,
			errorString =>
				'"cbsd bls header=0 node= display=jname,jid,vm_ram,vm_curmem,vm_cpus,pcpu,vm_os_type,ip4_addr,status,vnc alljails=0" exited non-zero',
		};
	}

	# get the zfs stats
	my @zfs_stats = split( /\n/, `sysctl kstat.zfs` );

	# break down the ZFS and find likely disks
	my @zfs_list     = split( /\n/, `zfs list -p` );
	my $zfs_list_int = 1;
	my $zfs          = {};
	my @zfs_keys;
	foreach my $line (@zfs_list) {
		chomp($line);
		my ( $zfs_name, $zfs_used, $zfs_avail, $zfs_refer, $zfs_mount ) = split( /[\ \t]+/, $line, 5 );

		# make sure it is not mounted and that it ends in raw or vhd
		if (   $zfs_mount =~ /^\-$/
			&& $zfs_name =~ /[A-Za-z\-\_1-9]+\/[A-Za-z\-\_1-9]+\/[A-Za-z\-\_1-9]+\.[VvRr][HhAa][DdWw]$/ )
		{
			$zfs->{$zfs_name} = $zfs_used;
			push( @zfs_keys, $zfs_name );
		}
		$zfs_list_int++;
	}

	my $disk_list_raw = `cbsd bhyve-dsk-list header=0 display=jname,dsk_path,dsk_size | sed -e 's/\x1b\[[0-9;]*m//g'`;

	#remove color codes
	$bls_raw       =~ s/\^.{1,7}?m//g;
	$disk_list_raw =~ s/\^.{1,7}?m//g;

	my @disk_list = split( /\n/, $disk_list_raw );

	my @VMs;

	my $ifs_raw = `ifconfig | grep '^[A-Za-z]' | cut -d: -f 1`;
	my @ifs     = split( /\n/, $ifs_raw );

	my $return_hash = {
		VMs    => {},
		hv     => 'CBSD',
		totals => {
			'usertime'    => 0,
			'pmem'        => 0,
			'oublk'       => 0,
			'minflt'      => 0,
			'pcpu'        => 0,
			'mem_alloc'   => 0,
			'nvcsw'       => 0,
			'snaps'       => 0,
			'rss'         => 0,
			'snaps_size'  => 0,
			'cpus'        => 0,
			'cow'         => 0,
			'nivcsw'      => 0,
			'systime'     => 0,
			'vsz'         => 0,
			'etimes'      => 0,
			'majflt'      => 0,
			'inblk'       => 0,
			'nswap'       => 0,
			'on'          => 0,
			'off'         => 0,
			'off_hard'    => 0,
			'off_soft'    => 0,
			'unknown'     => 0,
			'paused'      => 0,
			'crashed'     => 0,
			'blocked'     => 0,
			'nostate'     => 0,
			'pmsuspended' => 0,
			'freqs'       => 0,
			'ftime'       => 0,
			'ipkts'       => 0,
			'ierrs'       => 0,
			'ibytes'      => 0,
			'idrop'       => 0,
			'opkts'       => 0,
			'oerrs'       => 0,
			'obytes'      => 0,
			'coll'        => 0,
			'odrop'       => 0,
		}
	};

	# values that should be totaled
	my @total = (
		'usertime', 'pmem',       'oublk',       'minflt',     'pcpu',   'mem_alloc',
		'nvcsw',    'snaps',      'rss',         'snaps_size', 'cpus',   'cow',
		'nivcsw',   'systime',    'vsz',         'etimes',     'majflt', 'inblk',
		'nswap',    'disk_alloc', 'disk_in_use', 'rbytes',     'rtime',  'rreqs',
		'wbytes',   'wreqs',      'ftime',       'freqs',      'wtime',  'disk_on_disk',
		'snaps',    'freqs',      'ftime',       'ipkts',      'ierrs',  'ibytes',
		'idrop',    'opkts',      'oerrs',       'obytes',     'coll',   'odrop'
	);

	my @bls_split = split( /\n/, $bls_raw );
	foreach my $line (@bls_split) {
		chomp($line);
		my ( $vm, $pid, $mem_alloc, $mem_use, $cpus, $pcpu, $vm_os_type, $ip, $status, $vnc )
			= split( /[\ \t]+/, $line );

		# The ones below are linux only, so just zeroing here.
		# syscw syscw rchar wchar rbytes wbytes cwbytes
		my $vm_info = {
			mem_alloc    => $mem_alloc,
			cpus         => $cpus,
			pcpu         => $pcpu,
			os_type      => $vm_os_type,
			ip           => $ip,
			console_type => 'vnc',
			console      => $vnc,
			snaps_size   => 0,
			snaps        => 0,
			ifs          => {},
			rbytes       => 0,
			wbytes       => 0,
			etimes       => 0,
			pmem         => 0,
			cow          => 0,
			majflt       => 0,
			minflt       => 0,
			nice         => 0,
			nivcsw       => 0,
			nswap        => 0,
			nvcsw        => 0,
			inblk        => 0,
			oublk        => 0,
			pri          => 0,
			rss          => 0,
			systime      => 0,
			usertime     => 0,
			vsz          => 0,
			disk_alloc   => 0,
			disk_in_use  => 0,
			disk_on_disk => 0,
			disks        => {},
			rtime        => 0,
			rreqs        => 0,
			wreqs        => 0,
			wtime        => 0,
			freqs        => 0,
			ipkts        => 0,
			ierrs        => 0,
			ibytes       => 0,
			idrop        => 0,
			opkts        => 0,
			oerrs        => 0,
			obytes       => 0,
			coll         => 0,
			odrop        => 0,
		};

		# convert for megabytes to kilobytes
		if ( defined( $vm_info->{mem_alloc} ) && $vm_info->{mem_alloc} =~ /^[0-9]+$/ ) {
			$vm_info->{mem_alloc} = $vm_info->{mem_alloc} * 1024 * 1024;
		}
		if ( $status =~ /^On/ ) {
			$vm_info->{status_int} = 1;
			$return_hash->{totals}{on}++;
			my $additional
				= `ps S -o pid,etimes,%mem,cow,majflt,minflt,nice,nivcsw,nswap,nvcsw,inblk,oublk,pri,rss,systime,usertime,vsz | grep '^ *'$pid'[\ \t]'`;

			chomp($additional);
			$additional =~ s/^[\ \t]*//;
			(
				$pid,               $vm_info->{etimes}, $vm_info->{pmem},    $vm_info->{cow},
				$vm_info->{majflt}, $vm_info->{minflt}, $vm_info->{nice},    $vm_info->{nivcsw},
				$vm_info->{nswap},  $vm_info->{nvcsw},  $vm_info->{inblk},   $vm_info->{oublk},
				$vm_info->{pri},    $vm_info->{rss},    $vm_info->{systime}, $vm_info->{usertime},
				$vm_info->{vsz}
			) = split( /[\ \t]+/, $additional );

			$vm_info->{rss} = $vm_info->{rss} * 1024;
			$vm_info->{vsz} = $vm_info->{rss} * 1024;

			# zero anything undefined
			my @keys = keys( %{$vm_info} );
			foreach my $info_key (@keys) {
				if ( !defined( $vm_info->{$info_key} ) ) {
					$vm_info->{$info_key} = 0;
				}
			}

			my ( $minutes, $seconds ) = split( /\:/, $vm_info->{systime} );
			$vm_info->{systime} = ( $minutes * 60 ) + $seconds;

			( $minutes, $seconds ) = split( /\:/, $vm_info->{usertime} );
			$vm_info->{usertime} = ( $minutes * 60 ) + $seconds;

			#
			# NIC info
			#

			my @bnics_raw = split( /\n/,
				`cbsd bhyve-nic-list display=nic_parent,nic_hwaddr jname=$vm | sed -e 's/\x1b\[[0-9;]*m//g'` );
			my $bnics_int = 1;
			while ( defined( $bnics_raw[$bnics_int] ) ) {
				my $nic = $bnics_int - 1;

				chomp( $bnics_raw[$bnics_int] );
				my @line_split = split( /[\ \t]+/, $bnics_raw[$bnics_int] );

				my $nic_info = {
					mac    => $line_split[1],
					parent => $line_split[0],
					if     => '',
					ipkts  => 0,
					ierrs  => 0,
					ibytes => 0,
					idrop  => 0,
					opkts  => 0,
					oerrs  => 0,
					obytes => 0,
					coll   => 0,
					odrop  => 0,
				};

				$vm_info->{ifs}{ 'nic' . $nic } = $nic_info;

				$bnics_int++;
			}

			# go through each
			my @add_stats = ( 'ipkts', 'ierrs', 'idrop', 'ibytes', 'opkts', 'obytes', 'oerrs', 'coll', 'odrop' );
			foreach my $interface (@ifs) {
				my $if_raw = `ifconfig $interface | grep -E 'description: ' | cut -d: -f 2- | head -n 1`;
				chomp($if_raw);
				$if_raw =~ s/^[\'\"\ ]+//;
				$if_raw =~ s/[\'\"]$//;
				if ( $if_raw =~ /^$vm-nic[0-9]+/ ) {
					my $nic = $if_raw;
					$nic =~ s/^$vm\-//;

					$vm_info->{ifs}{$nic}{if} = $interface;

					my @netstats     = split( /\n/, `netstat -ibdWn -I $interface` );
					my $netstats_int = 1;
					while ( defined( $netstats[$netstats_int] ) ) {
						my $line = $netstats[$netstats_int];
						chomp($line);

						my $if_stats = {};

						(
							$if_stats->{int},   $if_stats->{mtu},   $if_stats->{network}, $if_stats->{address},
							$if_stats->{ipkts}, $if_stats->{ierrs}, $if_stats->{idrop},   $if_stats->{ibytes},
							$if_stats->{opkts}, $if_stats->{oerrs}, $if_stats->{obytes},  $if_stats->{coll},
							$if_stats->{odrop}
						) = split( /[\ \t]+/, $line );

						foreach my $current_stat (@add_stats) {
							if ( $if_stats->{$current_stat} =~ /^[0-9]+$/ ) {
								$vm_info->{ifs}{$nic}{$current_stat} += $if_stats->{$current_stat};
								$vm_info->{$current_stat} += $if_stats->{$current_stat};
							}
						}

						$netstats_int++;
					}
				}
			}

		}
		elsif ( $status =~ /^[Oo][Ff][Ff]/ ) {
			$vm_info->{status_int} = 8;
			$return_hash->{totals}{off}++;
		}
		else {
			# CBSD also has some mode called maintenance and slave,
			# but it is very unclear what those are
			$vm_info->{status_int} = 9;
			$return_hash->{totals}{unknown}++;
		}

		#
		# process the snapshots
		#
		my $snaplist_raw = `cbsd jsnapshot mode=list jname=$vm | sed -e 's/\x1b\[[0-9;]*m//g'`;
		my @snaplist     = split( /\n/, $snaplist_raw );

		# line 0 is always the header
		my $snaplist_int = 1;
		while ( defined( $snaplist[$snaplist_int] ) ) {
			chomp( $snaplist[$snaplist_int] );
			my ( $jname, $snapname, $snap_creation, $refer ) = split( /[\ \t]+/, $snaplist[$snaplist_int] );
			if ( $refer =~ /[Kk]$/ ) {
				$refer =~ s/[Kk]$//;
				$refer = $refer * 1000;
			}
			elsif ( $refer =~ /[Mm]$/ ) {
				$refer =~ s/[Mm]$//;
				$refer = $refer * 1000000;
			}
			elsif ( $refer =~ /[Gg]$/ ) {
				$refer =~ s/[Gg]$//;
				$refer = $refer * 1000000000;
			}
			elsif ( $refer =~ /[Tt]$/ ) {
				$refer =~ s/[Tt]$//;
				$refer = $refer * 1000000000000;
			}
			$vm_info->{snaps_size} = $vm_info->{snaps_size} + $refer;
			$snaplist_int++;
		}
		$vm_info->{snaps} = $#snaplist;

		#
		# go through the disk list and for matching ones
		#
		foreach my $line (@disk_list) {
			my $disk_info = {
				in_use  => 0,
				on_disk => 0,
				alloc   => 0,
				rbytes  => 0,
				rtime   => 0,
				rreqs   => 0,
				wbytes  => 0,
				wtime   => 0,
				wreqs   => 0,
				freqs   => 0,
				ftime   => 0,
			};
			if ( $line =~ /^$vm[\t\ ]/ ) {
				my ( $vm2, $disk_name, $size ) = split( /[\t\ ]+/, $line );
				$size =~ s/\/.*$//;
				if ( $size =~ /[Kk]$/ ) {
					$size =~ s/[Kk]$//;
					$size = $size * 1024;
				}
				elsif ( $size =~ /[Mm]$/ ) {
					$size =~ s/[Mm]$//;
					$size = $size * 1024 * 1024;
				}
				elsif ( $size =~ /[Gg]$/ ) {
					$size =~ s/[Gg]$//;
					$size = $size * 1024 * 1024 * 1024;
				}
				elsif ( $size =~ /[Tt]$/ ) {
					$size =~ s/[Tt]$//;
					$size = $size * 1024 * 1024 * 1024 * 1024;
				}
				$disk_info->{alloc} = $size;

				my $zfs_key_matched = 0;
				foreach my $zfs_key (@zfs_keys) {
					if ( $zfs_key =~ /\/$vm\/$disk_name$/ ) {
						my ($disk_used)
							= grep( /\/$vm\/$disk_name[\t\ ]+used[\t\ ]+/, split( /\n/, `zfs get -p all $zfs_key` ) );
						$disk_used =~ s/[\ \t]+\-[\ \t]*$//;
						$disk_used =~ s/.*[\ \t]+used[\ \t]+//;
						$disk_info->{on_disk} = $disk_used;
						$disk_info->{in_use}  = $disk_used;

						my $kstat_int     = 0;
						my $kstat_matched = 0;
						while ( defined( $zfs_stats[$kstat_int] ) && ( !$kstat_matched ) ) {
							if ( $zfs_stats[$kstat_int] =~ /^kstat\.zfs\..*dataset.objset\-.*\: $zfs_key/ ) {
								$kstat_matched = 1;
								my $zfs_stat_base = $zfs_stats[$kstat_int];
								$zfs_stat_base =~ s/\.dataset\_name\:.*$//;
								( $disk_info->{rreqs} )  = grep( /^$zfs_stat_base\.reads/,    @zfs_stats );
								( $disk_info->{wreqs} )  = grep( /^$zfs_stat_base\.writes/,   @zfs_stats );
								( $disk_info->{wbytes} ) = grep( /^$zfs_stat_base\.nwritten/, @zfs_stats );
								( $disk_info->{rbytes} ) = grep( /^$zfs_stat_base\.nread/,    @zfs_stats );
								$disk_info->{rreqs}  =~ s/^.*\:[\ \t]//;
								$disk_info->{wreqs}  =~ s/^.*\:[\ \t]//;
								$disk_info->{rbytes} =~ s/^.*\:[\ \t]//;
								$disk_info->{wbytes} =~ s/^.*\:[\ \t]//;

								$vm_info->{rreqs}  += $disk_info->{rreqs};
								$vm_info->{rbytes} += $disk_info->{rbytes};
								$vm_info->{wreqs}  += $disk_info->{rreqs};
								$vm_info->{wbytes} += $disk_info->{rbytes};
							}

							$kstat_int++;
						}

						$zfs_key_matched = 1;
					}
				}
				if ( !$zfs_key_matched ) {
					$disk_info->{on_disk} = $size;
					$disk_info->{in_use}  = $size;
				}

				$vm_info->{disk_alloc}   += $disk_info->{alloc};
				$vm_info->{disk_on_disk} += $disk_info->{on_disk};
				$vm_info->{disk_in_use}  += $disk_info->{in_use};

				$vm_info->{disks}{$disk_name} = $disk_info;
			}
		}

		#
		# put the totals together
		#
		foreach my $to_total (@total) {
			if ( defined( $vm_info->{$to_total} ) ) {
				if ( defined( $return_hash->{totals}{$to_total} ) ) {
					$return_hash->{totals}{$to_total} = $return_hash->{totals}{$to_total} + $vm_info->{$to_total};
				}
				else {
					$return_hash->{totals}{$to_total} = $vm_info->{$to_total};
				}
			}
		}

		$return_hash->{VMs}{$vm} = $vm_info;
		push( @VMs, $vm );
	}

	return {
		version     => $self->{version},
		error       => 0,
		errorString => '',
		data        => $return_hash,
	};
}

=head2 usable

Dies if not usable.

    eval{ $backend->usable; };
    if ( $@ ){
        print 'Not usable because... '.$@."\n";
    }

=cut

sub usable {
	my $self = $_[0];

	# Make sure we are on a OS on which ZFS is usable on.
	if ( $^O !~ 'freebsd' ) {
		die '$^O is "' . $^O . '" and not "freebsd"';
	}

	# make sure we can locate cbsd
	# Written like this as which on some Linux distros such as CentOS 7 is broken.
	my $cmd_bin = `/bin/sh -c 'which cbsd 2> /dev/null'`;
	if ( $? != 0 ) {
		die 'The command "cbsd" is not in the path... ' . $ENV{PATH};
	}

	return 1;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hv-monitor at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=HV-Monitor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HV::Monitor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=HV-Monitor>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/HV-Monitor>

=item * Search CPAN

L<https://metacpan.org/release/HV-Monitor>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;
