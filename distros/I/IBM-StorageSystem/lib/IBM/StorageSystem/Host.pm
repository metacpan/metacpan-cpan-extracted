package IBM::StorageSystem::Host;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(WWPN id iogrp_count mask name node_logged_in_count port_count 
state status type);

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
        defined $args{'id'} or croak __PACKAGE__ 
		. ' constructor failed: mandatory id argument not supplied';

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Host - Class for operations with a IBM StorageSystem attached hosts

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Host is a utility class for operations with a IBM StorageSystem attached hosts.


        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      
					user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";


	# Print	a list of all configured hosts sorted by hostname, their WWPNs,
	# port state and login status.

	foreach $host ( map { $_->[0] } sort { $a->[1] cmp $b->[1] } map { [ $_, $_->name ] } $ibm->get_hosts ) { 
		my $c = 0;

		foreach $wwpn ( @{ $host->WWPN } ) { 
			print ( $c ? "\t" : ('-'x100)."\n".$host->name );
			print "\t\t\t$wwpn\t" . @{ $host->state }[$c] . "\t\t" .
				( @{$host->node_logged_in_count }[$c] ? '' : 'not ' ) . "logged in\n";
			$c++
		}   
	}

	# Prints something similar to:
	# ----------------------------------------------------------------------------------------------------
	# host-3			2101001B32A3D94C	active		logged in
	# 				2100001B3283D94C	active		logged in
	# ----------------------------------------------------------------------------------------------------
	# host-4			2100001B320786E7	active		logged in
	# 				2101001B322786E7	active		logged in
	# ----------------------------------------------------------------------------------------------------
	# storage-2			210100E08BB40A08	offline		not logged in
	# 				210000E08B940A08	offline		not logged in
	# ... etc.


=head1 METHODS

=head3 WWPN

Returns an array of the WWPNs configured for this host - the order of the WWPNs in the array preserves the order
in which the WWPNs were returned from the CLI.  For example, if two WWPNs would be returned from the CLI
command of lshost <host_id>, then the order in which the WWPNs will be preserved in the array so that the first
WWPN to be returned is the first array item and the second to be returned is the second array item.

See the L<NOTES> section for further detail.

=head3 id

Returns the numerical identifier of the host.

=head3 iogrp_count

Returns the IO group count for the host.

=head3 mask

Returns the LUN masking for the host.

=head3 name

Returns the name of the host - this is the name with which the host was configured with in the CLI or GUI.

=head3 node_logged_in_count

Returns an array of integers representing the node logged in count for the corresponding WWPN.  The array
order is preserved from the output of the CLI and the array index match the values returned from the B<WWPN> 
and B<state> methods.

=head3 port_count

Returns configured host port count.

=head3 state

Returns an array or host port states - the array order is preserved as returned by the CLI and the array
indexes match the values returned from the B<WWPN> and B<node_logged_in_count> methods.

=head3 status

Returns the host overal status, either one of online, offline or degraded.

=head3 type

Returns the host type.

=head1 NOTES

Note that the CLI output of an lshost <host_id> command in the StorageSystem CLI environment can return
multiple identical output lines for the values of 'state', 'node_logged_in_count' and 'WWPN' fields.
These output lines are positionally representational meaning that the first output lines refer to the
first port, the second set of lines refer to the second port, and so on.

Because this output is returned using positional output formatting only and not explicit field
numbering it is necessary to preserve the order implied by positional output formatting to retain the
relationship between port specific information.

To do so, the methods L<WWPN>, L<node_logged_in_count> and L<state> all return ordered arrays that
preserve the positional output from the CLI so that the indexes for all of the aforementioned methods
refer to a common port.  That is:

	# Given $i, then the port identified by WWPN
	@{ $host->wwpn[$i] }

	# Will have the port state
	@{ $host->state[$i] }

	# And the node_logged_in_count of
	@{ $host->node_logged_in_count[$i] }
        
=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-host at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Host>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Host

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Host>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Host>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Host>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Host/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

