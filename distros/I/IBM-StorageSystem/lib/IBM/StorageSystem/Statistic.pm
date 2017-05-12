package IBM::StorageSystem::Statistic;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(weaken);

our $VERSION = '0.01';
our @ATTR = qw(name epoch current peak peak_time peak_epoch);

foreach my $attr ( @ATTR ) { 
        {   
                no strict 'refs';
                *{ __PACKAGE__ .'::'. $attr } = sub {
                        my( $self, $val ) = @_;
                        $self->{$attr} = $val if $val;
                        return $self->{$attr}
                }   
        }   
}

sub new {
        my( $class, $ibm, %args ) = @_;
        my $self = bless {}, $class;
	weaken( $self->{__ibm} = $ibm );
	foreach my $attr ( keys %args ) { $self->{$attr} = $args{$attr} }
	$self->{ts} = time;
	return $self;
}

sub refresh {
	my $self = shift;

	foreach my $stat ( splice @{ [ split /\n/, $self->{__ibm}->__cmd( 'lssystemstats -gui -delim :' ) ] }, 1 ) {
		my ( $name, $epoch, $current, $peak, $peak_time, $peak_epoch ) = split /:/, $stat;
		next unless $name eq $self->name;
		$self->epoch( $epoch );
		$self->current( $current );
		$self->peak( $peak );
		$self->peak_time( $peak_time );
		$self->peak_epoch( $peak_epoch )
	}

	$self->{ts} = time;
	return $self
}

sub history {
	my $self = shift;
	my @res;
	
	foreach my $stat (splice @{ [split /\n/, $self->{__ibm}->__cmd( "lssystemstats -history $self->{name} -delim :")] }, 1) {
		my ( $time, $name, $value ) = split /:/, $stat;
		push @res, { time => $time, value => $value };
	}

	return reverse @res;
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Statistic - Class for operations with IBM StorageSystem system statistics

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Statistic - Class for operations with IBM StorageSystem system statistics

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";
	
	# Print the current system FC IOPS
	print $ibm->fc_io->current;

	# Print the peak system FC IOPS
	print $ibm->fc_io->peak;

	# Refresh the FC IOPS statistics and print the new current value
	$ibm->fc_io->refresh;
	print $ibm->fc_io->current;

	# Or, alternately
	print $ibm->fc_io->refresh->current;

	# Retrieve the historical statistics for CPU usage and print
	# them along with the recorded epoch time
	foreach my $v ( $ibm->fc_io->history ) { print "$v->{time} : $v->{value}\n" }

	# e.g.
	# 130110140921 : 100
	# 130110140916 : 100
	# 130110140911 : 92
	# 130110140906 : 90
	# 130110140901 : 100
	# 130110140856 : 100
	# 130110140851 : 92
	# ... etc.

=head1 METHODS

=head3 name 

Returns the statistic name - this is the same name as the method invocant.

=head3 epoch 

Returns the epoch value for the samle period in which the statistic was measured.

=head3 current 

Returns the current statistic value.  Please refer to the lssystemstat manual page
for detailed information on possible return values.

=head3 peak

Returns the peak statistic value for the current measurement time period.

=head3 peak_time

Returns the time at which the peak statistic value for the current measurement period
was recorded.

Please see the L<NOTES> section below regarding the time format used and conversion
methods.

=head3 peak_epoch

Returns the epoch time at which the peak statistic value for the current measurement 
period was recorded.

=head3 refresh

Refreshes the statistic values.

=head3 history

Returns an array of historical values for the statistics where each array member is an
anonymous hash with two keys; B<time> - the sample time at which measurement was recorded,
and B<value> - the value recorded.

Please see the L<NOTES> section below regarding the time format used and conversion
methods.

=head1 NOTES

The values returned by the B<peak_time> method, and the hash value of 'time' for each 
member in the array returned by the B<history> method are 'epoch' values returned by the
CLI, however these are not true epoch values in a Unix sense.

Because of this, it is not possible to pass these values to B<localtime> for conversion
without manipulation and obtain correct dates.  The easiest way in which to correct the 
epoch times is to subtract the difference between the values of B<peak_time> and B<peak_epoch>
from each historical epoch time. i.e.

	$t = $ibm->fc_io->peak_time - $ibm->fc_io->peak_epoch;

	# Using the example from the SYNOPSIS section above, output with Unix epoch timestamps
	foreach my $v ( $ibm->fc_io->history ) { 
		print ( $v->{time} - $t ) . ": $v->{value}\n" 

		# Or with human-readable times
		# print ~~ localtime ( $v->{time} - $t ) . ": $v->{value}\n" 
	}

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-quota at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Statistic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Statistic

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Statistic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Statistic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Statistic>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Statistic/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

