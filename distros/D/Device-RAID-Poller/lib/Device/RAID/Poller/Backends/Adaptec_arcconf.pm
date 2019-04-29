package Device::RAID::Poller::Backends::Adaptec_arcconf;

use 5.006;
use strict;
use warnings;

=head1 NAME

Device::RAID::Poller::Backends::Adaptec_arcconf - Handles polling using the Adaptec arcconf utility.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Device::RAID::Poller::Backends::Adaptec_arcconf;
    
    my $backend = Device::RAID::Poller::Backends::Adaptec_arcconf->new;
    
    my $usable=$backend->usable;
    my %return_hash;
    if ( $usable ){
        %return_hash=$backend->run;
        my %status=$backend->run;
        use Data::Dumper;
        print Dumper( \%status );
    }

=head1 METHODS

=head2 new

Initiates the backend object.

    my $backend = Device::RAID::Poller::Backends::Adaptec_arcconf->new;

=cut

sub new {
	my $self = {
				usable=>0,
				adapters=>0,
				};
    bless $self;

    return $self;
}

=head2 run

Runs the poller backend and report the results.

If nothing is nothing is loaded, load will be called.

    my %status=$backend->run;
    use Data::Dumper;
    print Dumper( \%status );

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

	# get a list of devices
	my $adapter=1;
	while( $adapter <= $self->{adapters} ){
		my $raw=`arcconf GETCONFIG $adapter AD`;
		my @raw_split=split(/\n/, $raw);

		# Figures out the BBU status
		my $bbustatus='unknown';
		my @backup_lines=grep(/Overall\ Backup\ Unit\ Status/, @raw_split);
		if (
			defined($backup_lines[0]) &&
			(
			 ( $backup_lines[0] =~ /\:[\t ]*Ready/ ) ||
			 ( $backup_lines[0] =~ /Normal/ )
			 )
			){
			# If this matches, it should be good.
			# Can't match just /Ready/ as it will also match "Not Ready".
			my $bbustatus='good';
		}elsif(
			   defined($backup_lines[0]) &&
			   (
				( $backup_lines[0] =~ /Invalid/ ) ||
				( $backup_lines[0] =~ /Not\ Present/ )
				)
			   ){
			my $bbustatus='na';
		}elsif( defined($backup_lines[0]) ){
			# If we are here, we did not match it as being good or not present
			my $bbustatus='bad';
		}

		# Grab the LD config.
		$raw=`arcconf GETCONFIG $adapter LD`;
		@raw_split=split(/\n/, $raw);
		my $LDN=undef;
		my $dev=undef;
		foreach my $line (@raw_split){
			if ( $line =~ /Logical Device number/ ){
				$line=~s/[\t ]*Logical Device number[\t ]*//;
				$LDN=$line;
				$dev='arcconf '.$adapter.'-'.$LDN;
				$return_hash{devices}{$dev}={
											 'backend'=>'FBSD_graid',
											 'name'=>$dev,
											 'good'=>[],
											 'bad'=>[],
											 'spare'=>[],
											 'type'=>'unknown',
											 'BBUstatus'=>'na',
											 'status'=>'unknown',
											 };
			}

			# If we have a LDN, then we are in a LD information section of the output
			if ( $line =~ /Status\ of\ Logical\ Device/ ){
				$line=~s/[\t ]*Status\ of\ Logical\ Device\:[\t ]*//;
				if (
					( $line =~ /Optimal/ ) ||
					(
					 ( $line =~ /Reconfiguring/ ) &&
					 ( $line !~ /Degraded/ ) &&
					 ( $line !~ /Suboptimal/ )
					 )
					 ){
					# Optimal appears to be the only fully good one.
					# Reconfiguring not paired with either Suboptimal or Degraded is good
					$return_hash{$dev}{type}='good';
				}elsif( $line =~ /Rebuilding/ ){
					# Should match either of the two below.
					# Suboptimal, Rebuilding
					# Degraded, Rebuilding
					$return_hash{$dev}{type}='rebuilding';
				}else{
					# Anything else is bad.
					$return_hash{$dev}{type}='bad';
				}
			}elsif( $line =~ /RAID level/ ){
				$line=~s/[\t ]*RAID\ level\:[\t ]*//;
				$return_hash{$dev}{type}=$line;
			}elsif( $line =~ /[\t ]*Segment [0123456789]/ ){
				$line =~ s/[\t ]*Segment [0123456789]*\:[\t ]*//;
				if ( $line =~ /Present/ ){
					$line=~s/Present[\t ]*//;
					push( @{ $return_hash{devices}{$dev}{good} }, $line );
				}elsif( $line =~ /Missing/ ){
					# The disk is is just missing.
					push( @{ $return_hash{devices}{$dev}{bad} }, $line );
				}else{
					$line=~s/[A-Za-z\t ]*//;
					push( @{ $return_hash{devices}{$dev}{bad} }, $line );
				}
			}
		}

		$adapter++;
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

	if (
		( $^O !~ 'linux' ) ||
		( $^O !~ 'freebsd' )
		){
		$self->{usable}=0;
		return 0;
	}

	# make sure we can locate mdadm
	my $mdadm_bin=`which arcconf`;
	if ( $? != 0 ){
		$self->{usable}=0;
        return 0;
	}

	# make sure we have atleast one device
	my $raw=`arcconf LIST`;
	if ( $? != 0 ){
		$self->{usable}=0;
        return 0;
	}
	my @raw_split=split(/\n/, $raw);
	my @found_lines=grep(/Controllers\ found/, @raw_split);
	if (defined( $found_lines[0] )){
		# grab the first and should be online line, which should be formatted like below...
		# Controllers found: 1
		my $found=$found_lines[0];
		chomp($found);
		$found=~s/.*\:[\t ]*//;
		if (
			( $found =~ /[0123456789]+/ ) &&
			( $found > 0 )
			){
			$self->{adapters}=$found;
		}else{
			# either contains extra characters or zero
			$self->{usable}=0;
			return 0;
		}
	}else{
		# Command errored in some way or output changed.
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
