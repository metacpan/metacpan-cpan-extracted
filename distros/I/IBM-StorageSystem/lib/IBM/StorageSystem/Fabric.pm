package IBM::StorageSystem::Fabric;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(local_wwpn:remote_wwpn remote_wwpn remote_nportid id node_name 
local_wwpn local_port local_nportid state name cluster_name type);

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
        defined $args{'local_wwpn:remote_wwpn'} or croak __PACKAGE__ 
		. ' constructor failed: mandatory local_wwpn:remote_wwpn argument not supplied';

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Fabric - Class for operations with a IBM StorageSystem fabric entity

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Fabric is a utility class for operations with a IBM StorageSystem fabric entity.

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Print a list of our fabrics (sorted by fabric ID) including the fabric ID, node ID, port ID,
	# local WWPN, remote WWPN and fabric status.

	printf( "%-5s%-8s%-8s%-20s%-20s%-10s\n", 'ID', 'Node', 'Port', 'Local WWPN', 'Remote WWPN', 'Status');
	print '-'x80,"\n";

	for my $fabric ( map { $_->[0] } sort { $a->[1] cmp $b->[1] } map { [$_, $_->id] } $ibm->get_fabrics ) {
		printf( "%-5s%-8s%-8s%-20s%-20s%-10s\n", $fabric->id, $fabric->node_name, $fabric->local_port,
			$fabric->local_wwpn, $fabric->remote_wwpn, $fabric->state )
	}

	# Prints something like:
	#
	# ID   Node    Port    Local WWPN          Remote WWPN         Status    
	# --------------------------------------------------------------------------------
	# 1    node1   1       5005076802159D73    21000024FF43DE7B    active    
	# 1    node1   2       5005076802259D73    21000024FF35B8FC    active    
	# 2    node2   1       5005076802159D74    21000024FF43DE7A    active    
	# 2    node2   2       5005076802259D74    21000024FF35B8FD    active 


=head1 METHODS

=head3 cluster_name

Returns the cluster name of the fabric (if present).

=head3 id

Returns the fabric ID.

=head3 local_nportid

Returns the local NPort ID.

=head3 local_port

Returns the local port ID.

=head3 local_wwpn

Returns the local port World Wide Port Number (WWPN).

=head3 name

Returns the fabric name (if present).

=head3 node_name

Returns the the fabric node name.

=head3 remote_nportid

Returns the fabric remote NPort ID.

=head3 remote_wwpn

Returns the fabric remote WWPN.

=head3 state

Returns the fabric operational state.

=head3 type

Returns the fabric type.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-fabric at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Fabric>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Fabric


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Fabric>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Fabric>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Fabric>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Fabric/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

