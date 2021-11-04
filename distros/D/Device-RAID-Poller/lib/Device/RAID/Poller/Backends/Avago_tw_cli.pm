package Device::RAID::Poller::Backends::Avago_tw_cli;

use 5.006;
use strict;
use warnings;

=head1 NAME

Device::RAID::Poller::Backends::Avago_tw_cli - Handles polling using the Avago tw_cli utility.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Device::RAID::Poller::Backends::Avago_tw_cli;
    
    my $backend = Device::RAID::Poller::Backends::Avago_tw_cli->new;
    
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

    my $backend = Device::RAID::Poller::Backends::Avago_tw_cli->new;

=cut

sub new {
	my $self = {
		usable   => 0,
		adapters => 0,
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
	my $self = $_[0];

	my %return_hash = (
		'status'  => 0,
		'devices' => {},
	);

	# if not usable, no point in continuing
	if ( !$self->{usable} ) {
		return %return_hash;
	}

	# need to parse this to get the available ontrollers
	#
	## tw_cli show
	#Ctl   Model        (V)Ports  Drives   Units   NotOpt  RRate   VRate  BBU
	#------------------------------------------------------------------------
	#c2    9690SA-8I    6         6        2       0       1       1      Charging
	my $raw = `tw_cli show`;
	if ( $? != 0 ) {
		return %return_hash;
	}
	my @raw_split = split( /\n/, $raw );

	# controller stuff starts on line tree, array are zero indexed
	my $line_int = 2;

	# holds a list of the found controllers
	my %controllers;
	while ( defined( $raw_split[$line_int] ) ) {
		my ( $controller, $model, $vports, $drives, $units, $notopt, $rrate, $vrate, $bbu )
			= split( /[\t\ ]+/, $raw_split[$line_int], 9 );

		# make sure we have the info we care about
		if (   defined($controller)
			&& defined($bbu) )
		{
			# normalize the found BBU data
			if ( $bbu =~ /Charging/ ) {
				$bbu = 'charging';
			}
			elsif ( $bbu =~ /^-/ ) {
				$bbu = 'notPresent';
			}
			elsif ( $bbu =~ /[Oo][Kk]/ ) {
				$bbu = 'good';
			}
			elsif ( $bbu =~ /Testing/ ) {
				$bbu = 'testing';
			}elsif (
					($bbu=~/Fault/) ||
					($bbu=~/WeakBat/) ||
					($bbu=~/Error/)
					) {
				$bbu='failed';
			}
			else {
				$bbu = 'unknown';
			}

			$controllers{$controller} = $bbu;
		}

		$line_int++;
	}

	# parse thise to figure out drive status
	#
	## tw_cli /c2 show
	#Unit  UnitType  Status         %RCmpl  %V/I/M  Stripe  Size(GB)  Cache  AVrfy
	#------------------------------------------------------------------------------
	#u0    RAID-1    OK             -       -       -       298.013   Ri     ON
	#u1    RAID-5    OK             -       -       64K     2793.94   Ri     ON
	#
	#VPort Status         Unit Size      Type  Phy Encl-Slot    Model
	#------------------------------------------------------------------------------
	#p0    OK             u0   298.09 GB SATA  0   -            ST3320613AS
	#p1    OK             u0   298.09 GB SATA  1   -            ST3320613AS
	#p2    OK             u1   931.51 GB SATA  2   -            Hitachi HDS721010CL
	#p3    OK             u1   931.51 GB SATA  3   -            Hitachi HDS721010CL
	#p4    OK             u1   931.51 GB SATA  4   -            Hitachi HDS721010CL
	#p5    OK             u1   931.51 GB SATA  5   -            Hitachi HDS721010CL
	foreach my $controller ( @{ keys(%controllers) } ) {
		$raw = `tw_cli /$controller show`;
		my $process = 1;
		if ( $? != 0 ) {
			$process = 0;
		}
		@raw_split = split( /\n/, $raw );

		my @arrays;

		# raid stuff starts on line three
		$line_int = 2;
		while ( defined( $raw_split[$line_int] ) ) {
			my @line_split = split( /[\t\ ]+/, $raw_split[$line_int] );

			if ( defined( $line_split[0] )
				&& ( $line_split[0] =~ /^u[0123456789]+/ ) )
			{

				# normalize array status
				my $status=$line_split[1];
				if ($status =~ /OK/) {
					$status='good';
				}elsif ( $status=~/^INIT/ ) {
					$status='initializing';
				}elsif (
						( $status =~ /^REBUILDING/ ) ||
						( $status =~ /^RECOVERY/ ) ||
						( $status =~ /^MIGRATING/ )
						){
					$status='rebuilding';
				}elsif (
						( $status=~/DEGRADED/ ) ||
						( $status=~/INOPERABLE/ )
						) {
					$status='failed';
				}else {
					$status='unknown';
				}

				# add a found array
				$return_hash{devices}{'Avago_tw_cli '.$line_split[0]}={
																	   BBUstatus=>$controllers{$controller},
																	   good=>[],
																	   bad=>[],
																	   spare=>[],
																	   $status=>$status,
																	   backend=>'Avago_tw_cli',
																	   type=>$line_split[1],
																	   };

			}

			# handle it if we find a drive line
			if ( defined( $line_split[0] )
				 && ( $line_split[0] =~ /^p[0123456789]+/ ) &&
				 defined( $line_split[1] ) &&
				 defined( $line_split[2] ) &&
				 ( $line_split[2] =~ /^u[0123456789]+/ )
				)
			{
				if ($line_split[1] =~ /OK/) {
					push(@{ $return_hash{devices}{'Avago_tw_cli '.$line_split[2]}{good} }, $line_split[0]);
				}else {
					push(@{ $return_hash{devices}{'Avago_tw_cli '.$line_split[2]}{bad} }, $line_split[0]);
				}
			}

			$line_int++;
		}

	}

	$return_hash{status} = 1;
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
	my $self = $_[0];

	if (   ( $^O !~ 'linux' )
		&& ( $^O !~ 'freebsd' ) )
	{
		$self->{usable} = 0;
		return 0;
	}

	# make sure we can locate arcconf
	my $arcconf_bin = `/bin/sh -c 'which tw_cli 2> /dev/null'`;
	if ( $? != 0 ) {
		$self->{usable} = 0;
		return 0;
	}

	# make sure we have atleast one device
	#
	## tw_cli show
	#Ctl   Model        (V)Ports  Drives   Units   NotOpt  RRate   VRate  BBU
	#------------------------------------------------------------------------
	#c2    9690SA-8I    6         6        2       0       1       1      Charging
	my $raw = `tw_cli show`;
	if ( $? != 0 ) {
		$self->{usable} = 0;
		return 0;
	}
	my @raw_split = split( /\n/, $raw );

	# if we don't exit zero it means something went wrong and should not
	# bother trying to do more with it
	if ( $? != 0 ) {
		$self->{usable} = 0;
		return 0;
	}

	if ( defined( $raw_split[2] ) ) {
		my @third_line = split( /[\t\ ]/, $raw_split[2], 9 );

		# we don't have a BBU status
		if ( !defined( $third_line[8] ) ) {
			$self->{usable} = 0;
			return 0;
		}

		# the first column does not match /^c[0123456789]+$/, e.g. "c2",
		# so something is wrong or their are no controllers
		if ( $third_line[8] !~ /^c[0123456789]+$/ ) {
			$self->{usable} = 0;
			return 0;
		}
	}
	else {
		# no third line showing any devices
		$self->{usable} = 0;
		return 0;
	}

	# if we get here, it is most likely good
	$self->{usable} = 1;
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

1;    # End of Device::RAID::Poller
