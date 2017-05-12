package IBM::StorageSystem::Service;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(active configured name);

foreach my $attr ( map lc, @ATTR ) { 
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
        defined $args{'Name'} or croak __PACKAGE__ . ' constructor failed: mandatory Name argument not supplied';
	$self->{ name } = $args{Name};

	if ( defined $args{'Is_active'}     )	{ $self->{ active }	= $args{'Is_active'}	 }
	if ( defined $args{'Is_configured'} )	{ $self->{ configured }	= $args{'Is_configured'} }
	if ( defined $args{'Enabled'}	    )	{ $self->{ enabled }	= $args{'Enabled'}	 }
	if ( defined $args{'Configured'}    )	{ $self->{ configured }	= $args{'Configured'}	 }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Service - Class for operations with a IBM StorageSystem service entities

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Service - Class for operations with a IBM StorageSystem service entities

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Print the enabled status of the NFS service
	print $ibm->service(NFS)->enabled;

	# Print the configured and enabled status of all services
	printf( "%-20s%-20s%-20s\n", 'Service', 'Configured', 'Active' );
	map { printf( "%-20s%-20s%-20s\n", $_->name, $_->configured, $_->active ) } $ibm->get_services;

	
=head1 METHODS

=head3 name

Returns the name of the service.

=head3 active

Returns the active status of the service.

=head3 configured

Returns the configured status of the service.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-service at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Service>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Service

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Service>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Service>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Service>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Service/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

