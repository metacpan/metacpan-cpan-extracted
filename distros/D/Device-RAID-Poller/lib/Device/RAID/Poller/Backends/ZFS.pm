package Device::RAID::Poller::Backends::ZFS;

use 5.006;
use strict;
use warnings;

=head1 NAME

Device::RAID::Poller::Backends::ZFS - ZFS zpool backend.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Device::RAID::Poller::Backends::ZFS;
    
    my $backend = Device::RAID::Poller::Backends::ZFS;
    
    my $usable=$backend->usable;
    my %return_hash;
    if ( $usable ){
        %return_hash=$backend->run;
    }

=head1 METHODS

=head2 new

Initiates the backend object.

    my $backend = Device::RAID::Poller::Backends::FBSD_gmirror;

=cut

sub new {
	my $self = {
				usable=>0,
				};
    bless $self;

    return $self;
}

=head2 run

Runs the poller backend and report the results.

If nothing is nothing is loaded, load will be called.

    my $usable=$backend->usable;
    

=cut

sub run {
	my $self=$_[0];

	my %return_hash=(
					 'status'=>0,
					 'devices'=>{},
					 );

	# if not usable, no point in continuing
	if ( ! $self->{usable} ){
		return %return_hash;
	}

	# zpool status notes for config section
	# good...
	# INUSE = spare in use
	# ONLINE = working as intented
	# bad...
	# DEGRADED = device failed or is replacing one
	# OFFLINE = administrative or being replaced
	# FAULTED = failed disk
	# UNAVAIL = missing disk
	# spares...
	# AVAIL = available spare

	# Fetch the raw gmirror status.
	my $raw=`/sbin/zpool list`;
	if ( $? != 0 ){
		return %return_hash;
	}

	# split it and shift the header line off
	my @raw_split=split(/\n/, $raw);
	shift @raw_split;

	my @devs;

	# find out what devs we have and build the return hash
	foreach my $line (@raw_split){
		my @line_split=split( /[\t ]+/, $line);
		my $dev=$line_split[0];
		push(@devs, $dev);
		$dev='ZFS '.$dev;

		$return_hash{devices}{$dev}={
									 'backend'=>'ZFS',
									 'name'=>$dev,
									 'good'=>[],
									 'bad'=>[],
									 'spare'=>[],
									 'type'=>'ZFS',
									 'BBUstatus'=>'na',
									 'status'=>'unknown',
									 };

		if ( $line_split[9] eq "ONLINE" ){
			$return_hash{devices}{$dev}{status}='good';
		}else{
			$return_hash{devices}{$dev}{status}='bad';
		}
	}

	# process each pool and for disk status info
	foreach my $pool (@devs){
		my $dev='ZFS '.$pool;

		$raw=`/sbin/zpool status $pool`;
		my @raw_split=split(/\n/, $raw);

		# only begin processing ocne we find the line after name in the config section
		my $config_found=0;
		my $name_found=0;
		foreach my $line (@raw_split){
			$line=~s/^[\t ]+//;

			# Check if we are at the config section or not at ever section change.
			if ( $line =~ /^config\:/ ){
				$config_found=1;
			}elsif( $line =~ /^[A-Za-z0-1]+:/ ){
				$config_found=0;
			}

			if ( $config_found){
				# If we are in the config, begin processing after the NAME line.
				my $process=0;
				if ( $line =~ /^NAME/ ){
					$name_found=1;
				}elsif( $name_found ){
					$process=1;
				}

				# We are inally in the are with the info we want.
				if ( $process ){
					my @line_split=split(/[\t ]+/, $line);
					# Ignore vdev lines
					# The mirror line must include - or it will accidentally match geom_mirror devices.
					if (
						( defined( $line_split[0] ) ) &&
						( defined( $line_split[1] ) ) &&
						( $line_split[0] ne $pool ) &&
						( $line_split[0] !~ /^mirror\-/ ) &&
						( $line_split[0] !~ /^spare/ ) &&
						( $line_split[0] !~ /^log/ ) &&
						( $line_split[0] !~ /^cache/ )
						){
						# We are at a drive line, figure out the drive status.
						if (
							( $line_split[1] eq 'ONLINE' ) ||
							( $line_split[1] eq 'INUSE' )
							){
							push(@{ $return_hash{devices}{$dev}{good} }, $line_split[0]);
						}elsif( $line_split[1] eq 'AVAIL' ){
							push(@{ $return_hash{devices}{$dev}{spare} }, $line_split[0]);
						}else{
							push(@{ $return_hash{devices}{$dev}{bar} }, $line_split[0]);
						}
					}
				}
			}
		}
	}

	$return_hash{status}=1;

	return %return_hash;
}

=head2 usable

Returns a perl boolean for if it is usable or not.

    my $usable=$backend->usable;
    if ( ! $usable ){
        print "This backend is not usable.\n";
    }

=cut

sub usable {
	my $self=$_[0];

	# Make sure we are on a OS on which ZFS is usable on.
	if (
		( $^O !~ 'freebsd' ) &&
		( $^O !~ 'solaris' ) &&
		( $^O !~ 'netbsd' ) &&
		( $^O !~ 'linux' )
		){
		$self->{usable}=0;
		return 0;
	}

	# If this is FreeBSD, make sure ZFS is laoded.
	# If we don't do this, the pool test will result in
	# it being loaded, which we don't want to do.
	if ( $^O !~ 'freebsd' ){
		# Test for this via this method as 'kldstat -q -n zfs' will error if it is compiled in
		system('/sbin/sysctl -q kstat.zfs.misc.arcstats.hits > /dev/null');
		if ( $? != 0 ){
			$self->{usable}=0;
			return 0;
		}
	}

	# make sure we can locate zpool
	# Written like this as which on some Linux distros such as CentOS 7 is broken.
	my $zpool_bin=`/bin/sh -c 'which zpool 2> /dev/null'`;
	if ( $? != 0 ){
		$self->{usable}=0;
        return 0;
	}
	chomp($zpool_bin);
	$self->{zpool_bin}=$zpool_bin;

	# No zpools on this device.
	my $pool_test=`$zpool_bin list`;
	if ( $pool_test !~ /^NAME/ ){
		$self->{usable}=0;
        return 0;
	}

	$self->{usable}=1;
	return 1;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-device-raid-poller at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-RAID-Poller>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::RAID::Poller


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-RAID-Poller>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-RAID-Poller>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Device-RAID-Poller>

=item * Search CPAN

L<https://metacpan.org/release/Device-RAID-Poller>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Device::RAID::Poller
