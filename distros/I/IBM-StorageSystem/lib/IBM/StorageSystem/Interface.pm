package IBM::StorageSystem::Interface;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.02';
our @ATTR = qw(Node:Interface Node Interface MAC Master/Subordinate Bonding_mode 
Transmit_hash_policy Up/Down Speed IP-Addresses MTU);

foreach my $attr ( @ATTR ) { 
        {   
		my $mattr = lc $attr;
		$mattr =~ s/\//_or_/g;
		$mattr =~ s/-/_/g;

		foreach my $s ( qw(ip mac mtu) ) {
			my $u = uc $s;
			$mattr =~ s/(^|_)($s)/$1$u/g
		}

                no strict 'refs';
                *{ __PACKAGE__ .'::'. $mattr } = sub {
                        my( $self, $val ) = @_;
			$val =~ s/\#/no/ if $val;
                        $self->{$mattr} = $val if $val;
                        return $self->{$mattr}
                }
        }
}

sub new {
        my( $class, $ibm, %args ) = @_; 
        my $self = bless {}, $class;

        defined $args{'Node:Interface'} 
		or croak __PACKAGE__ . ' Constructor failed: mandatory Node:Interface argument not supplied';

	foreach my $attr ( keys %args ) {
		my $mattr = lc $attr;
		$mattr =~ s/\//_or_/g;
		$mattr =~ s/-/_/g;

		foreach my $s ( qw(ip mac mtu) ) {
			my $u = uc $s;
			$mattr =~ s/(^|_)($s)/$1$u/g
		}

		$self->{$mattr} = $args{$attr} 
	}

	return $self;
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Interface - Class for operations with a IBM StorageSystem network interfaces

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Interface - Class for operations with a IBM StorageSystem network interfaces

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      
					user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Get interface ethX0 on management node mgmt001st001 as an IBM::StorageSystem::Interface object
	my $interface = $ibm->interface('mgmt001st001:ethX0');

	# Print the interface status
	print $interface->up_or_down;

	# Print the interface status
	print $interface->speed;

	# Alternately;
	print $ibm->interface('mgmt001st001:ethX0')->speed;

	# Print a list of all interfaces, the node on which they reside,
	# their status, speed and role
	
	foreach my $interface ( $ibm->get_interfaces ) {
		print "Node: " . $interface->node . "\n";
		print "Interface: " . $interface->interface . "\n";
		print "\tStatus: " . $interface->up_or_down . "\n";
		print "\tSpeed: " . $interface->speed . "\n";
		print "\tRole: " . $interface->subordinate_or_master . "\n----------\n";
	}
	

=head1 METHODS

=head3 bonding_mode

Returns the interface bonding mode - B<Note> that this attribute will likely be
null for subordinate interfaces.

=head3 IP_addresses

Returns the IP address(es) associated with the interface - B<note> that this may be
a single address, a comma-separated list of multiple addresses or null.

=head3 interface

Returns the interface system name (e.g. ethX1).

=head3 MAC

Returns the MAC (Media Access Controll) address of the interface.  <BNote> that the
MAC address is returned in a URL percent encoded string - i.e. the colon character is
encoded as the string "%3A".

=head3 MTU

Returns the MTU (Maximum Transmissable Unit) for the interface in MD.

=head3 master_or_subordinate

Returns the role of the interface - either MASTER or SUBORDINATE.

=head3 node

returns the node on which the interface resides.

=head3 speed

Returns the interfaces media speed in MB/s. 

=head3 transmit_hash_policy

Returns the interface transmit hash policy - B<Note> that this attribute will likely be
null for subordinate interfaces.

=head3 up_or_down

Returns the up or down state of the interface - either UP or DOWN.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-interface at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Interface>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Interface

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Interface>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Interface>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Interface>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Interface/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

