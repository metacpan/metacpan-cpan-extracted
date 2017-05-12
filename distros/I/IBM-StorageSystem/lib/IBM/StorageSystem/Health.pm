package IBM::StorageSystem::Health;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(Host:Sensor Host Sensor Status Value);

foreach my $attr ( map lc, @ATTR ) { 
        {   
                no strict 'refs';
                *{ __PACKAGE__ .'::'. $attr } = sub {
                        my( $self, $val ) = @_;
			$val =~ s/\#/no/ if $val;
                        $self->{$attr} = $val if $val;
                        return $self->{$attr}
                }   
        }   
}

sub new {
        my( $class, $ibm, %args ) = @_; 
        my $self = bless {}, $class;
        defined $args{'Host:Sensor'} or croak __PACKAGE__ 
		. ' constructor failed: mandatory Host:Sensor argument not supplied';
	
        foreach my $attr ( @ATTR ) { $self->{lc $attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Health - Class for operations with a IBM StorageSystem logical health stati

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Health - Class for operations with a IBM StorageSystem logical health stati

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Simple one-liner to print the sensor status and value for any error conditions.
	map { print join ' -> ', ( $_->sensor, $_->value."\n" ) } 
		grep { $_->status =~ /ERROR/ } $ibm->get_healths;

	# e.g.
	# CLUSTER -> Alert found in component cluster
	# MDISK -> Alert found in component mdisk
	# NODE -> Alert found in component node

=head1 METHODS

=head3 host

Returns the host to which the health status applies - this may either be an individual storage,
mangement, interface or multi-role node, or may be a cluster level status.

=head3 sensor

Returns the system or component sensor to which the health status applies.

=head3 status

Returns the health sensor status (e.g. OK, ERROR, etc.).

=head3 value

Returns the health sensor status description.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-health at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Health>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Health


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Health>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Health>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Health>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Health/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

