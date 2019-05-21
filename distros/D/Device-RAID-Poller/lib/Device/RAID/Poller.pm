package Device::RAID::Poller;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Module::List qw(list_modules);
use JSON;

=head1 NAME

Device::RAID::Poller - Basic RAID status poller, returning RAID disk devices, types, and status.

=head1 VERSION

Version 0.1.2

=cut

our $VERSION = '0.1.2';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Device::RAID::Poller;

    my $drp = Device::RAID::Poller->new();
    ...

=head1 METHODS

=head2 new

This initiates the object.


=cut

sub new {
	my $self = {
				perror=>undef,
				error=>undef,
				errorString=>"",
				errorExtra=>{
							 flags=>{
									 1=>'invalidModule',
									 2=>'notLoaded',
									 }
							 },
				modules=> {},
				loaded=> {},
				};
    bless $self;

    return $self;
}

=head2 modules_get

Gets the currently specified modules to run.

A return of undef means none are set and at run-time each module
will be loaded and tried.

    my @modules=$drp->modules_get;

=cut

sub modules_get {
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return keys %{ $self->{modules} };
}

=head2 modules_set

This sets modules to use if one does not wish to attempt to load
them all upon load.

=cut

sub modules_set {
	my $self=$_[0];
	my @modules;
	if ( defined( $_[1] ) ){
		@modules=@{ $_[1] }
	}

	if( ! $self->errorblank ){
		return undef;
	}

	my $valid_backends=$self->list_backends;

	if (!defined( $modules[0] )){
		$self->{modules}=\@modules;
	}

	foreach my $module ( @modules ){
		if ( ! exists( $valid_backends->{'Device::RAID::Poller::Backends::'.$module} ) ){
			$self->{error}=1;
			$self->{errorString}='"'.$module.'"';
			$self->warn;
			return undef;
		}
	}

	$self->{modules}=\@modules;

	return 1;
}

=head2 list_backends

This lists the available backends. This lists the full
backends name, meaning it will return 'Device::RAID::Poller::Backends::fbsdGmiiror';

    my $backends=$drp->list_backends;

The returned value is a hashref where each key is a name
of a backend module.

If you want this as a array, you can do the following.

    my @backends=keys %{ $drp->list_backends };

=cut

sub list_backends{
	my $backends=list_modules("Device::RAID::Poller::Backends::", { list_modules => 1});

	return $backends;
}

=head2 list_loaded

This returns the list of backends that loaded
successfully.

=cut

sub list_loaded {
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	return keys %{ $self->{loaded} };
}

=head2 load

This loads up the modules. Each one in the list is
checked and then if started successfully, it is saved
for reuse later.

    my $loaded=$drp->load;
    if ( $loaded ){
        print "One or more backends are now loaded.\n";
    }else{
        print "No usable backends found.\n";
    }

=cut

sub load {
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	my @backends=keys %{ $self->list_backends };

	my $loaded=0;

	foreach my $backend ( @backends ){
		my $backend_test;
		my $usable;
		my $test_string='
use '.$backend.';
$backend_test='.$backend.'->new;
$usable=$backend_test->usable;
';
		eval( $test_string );
		if ( $usable ){
			$self->{loaded}{$backend}=$backend_test;
			$loaded=1;
		}
	}

	return $loaded;
}

=head2 run

Runs the poller backend and report the results.

If nothing is nothing is loaded, load will be called.

    m6 %status=$drp->run;

=cut

sub run {
	my $self=$_[0];

	if( ! $self->errorblank ){
		return undef;
	}

	# Load should always be called before run.
	my @loaded=$self->list_loaded;
	if ( ! defined($loaded[0]) ){
		$self->{error}=2;
		$self->{errorString}='No backend modules loaded';
		$self->warn;
		return undef;
	}

	my %return_hash;

	# Run each backend and check the return.
	foreach my $backend ( @loaded ){
		my %found;
		eval{
			%found=$self->{loaded}{$backend}->run;
		};

		# If we got a good return, pull each device into the return hash.
		if (
			defined($found{status}) &&
			defined($found{devices}) &&
			$found{status}
			){
			my @devs=keys( %{ $found{devices} } );
			foreach my $dev ( @devs ){
				$return_hash{$dev}=$found{devices}{$dev};
			}
		}
	}

	return %return_hash;
}

=head1 STATUS HASH

The statu hash made of of hashes. Each subhash is the of the type
documented under the section RAID HASH.

The keys of this hash are the device name as regarded by the module
in question. These may not represent a valid name under /dev, but may
just be a name generated to differentiate it from other devices. Both
the ZFS and MegaCLI backends are examples of this. In ZFS cases the
zpool is just a mountpoint some place. As to MegaCLI it is a name generated
from info gathered from the card.

=head2 RAID HASH

=head3 status

This can be any of the following values.

    bad - missing disks
    good - all disks are present
    rebuilding - one or more drives is being rebuilt
    unknown - Unable to determine the current status.

=head2 name

The name of the device.

=head2 backend

The backend that put polled this device. This is the name of the module
under "Device::RAID::Poller::Backends::". So "Device::RAID::Poller::Backends::ZFS"
would be "ZFS".

=head3 good

This is a list of good disks in the array..

=head3 bad

This is a list of bad disks in the array.

=head3 spare

This is a list of spare disks in the array.

=head3 type

This is type of RAID in question. This is a string that describes the RAID array.

This may also be complex, such as for ZFS it is the output of 'zpool status' for the
pool in question.

=head3 BBUstatus

This can be any of the following values.

    notPresent - No BBU.
    na - Not applicable. Device does not support it.
    failed - BBU failed.
    good - BBU is good.
    charging - BBU is charging.
    unknown - BBU status is not known.

=head1 BACKENDS

A backend is a module that exists directly under "Device::RAID::Poller::Backends::".

Three methods must be present and as of currently are expected to run with no arguments.

    new
    usable
    run

The new method creates the object.

The usable method runs some basic checks to see if it is usable or not.

The run method returns a hash with the assorted info. See the section BACKEND RETURN HASH for
more information.

=head2 BACKEND RETURN HASH

This is composed of keys below.

    devices - A array of hashes as documented in the section RAID HASH.
    stutus - A 0/1 representing if it the the run method was successful.

=head1 ERROR HANDLING/CODES

=head2 1/invalidModule

A non-existent module to use was specified.

=head2 2/notLoaded

Either load has not been called or no usable modules were found.

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
