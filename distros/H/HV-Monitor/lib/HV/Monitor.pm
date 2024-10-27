package HV::Monitor;

use 5.006;
use strict;
use warnings;
use Module::List qw(list_modules);

=head1 NAME

HV::Monitor - A generalized module for gathering stats for a hypervisor.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use HV::Monitor;

=head1 METHODS

=head2 new

Inits the object.

One option is taken and that is a hash ref.

    # init with the cbsd backend
    my $hm->new({backend=>'CBSD'});

The keys are list as below.

    - backend :: The name of the backend to use.
        Default :: CBSD

=cut

sub new {
	my $module = shift;
	my $config = shift;

	if ( !defined( $config->{backend} ) ) {
		$config->{backend} = 'CBSD';
	}

	my $self = {
		version => 1,
		backend => $config->{backend},
	};
	bless $self;

	return $self;
}

=head2 load

This loads the specified backend.

    eval{ $hm->load; };
    if ( $@ ){
        print "Failed to load the backend... ".$@;
    }

=cut

sub load {
	my $self = $_[0];

	my $loaded = 0;

	my $backend_test;
	my $usable;
	my $test_string = '
use HV::Monitor::Backends::' . $self->{backend} . ';
$backend_test=HV::Monitor::Backends::' . $self->{backend} . '->new;
$usable=$backend_test->usable;
';
	eval($test_string);
	if ($usable) {
		$self->{backend_mod} = $backend_test;
		$loaded = 1;
	}
	else {
		die( 'Failed to load backend... ' . $@ );
	}

	return $loaded;
}

=head2 run

Runs the poller backend and report the results.

If nothing is nothing is loaded, load will be called.

    my $status=$hm->run;

=cut

sub run {
	my $self = $_[0];

	if ( !defined( $self->{backend_mod} ) ) {
		return {
			version     => $self->{version},
			data        => {},
			error       => 1,
			errorString => 'No module loaded',
		};
	}

	my $to_return;
	eval { $to_return = $self->{backend_mod}->run };
	if ($@) {
		return {
			version     => $self->{version},
			data        => {},
			error       => 1,
			errorString => 'Failed to run backend... ' . $@,
		};
	}

	return $to_return;
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

1;    # End of HV::Monitor
