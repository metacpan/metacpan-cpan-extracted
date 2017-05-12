package IBM::StorageSystem::Mount;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(File_system Mount_status Last_update Nodes);

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
        defined $args{'File_system'} or croak __PACKAGE__ 
		. ' constructor failed: mandatory File_system argument not supplied';
	
        foreach my $attr ( @ATTR ) { $self->{lc $attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Mount - Class for operations with IBM StorageSystem mounts

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Mount - Class for operations with IBM StorageSystem mount

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Print mount status of file system fs1
	print "Mount status: " . $ibm->mount(fs1) . "\n";

	# Print only those file system that aren't mounted
	map { print $_->file_system . " is not mounted.\n" } 
	grep { $_->mount_status ne 'mounted' }
	$ibm->get_mounts;


=head1 METHODS

=head3 file_system

Returns the name of the file system.

=head3 mount_status

Returns the mount status of the file system.

=head3 nodes

Returns a comma-separated list of the nodes on which the file system is mounted.

=head3 last_update

Returns a timestamp of the last time the CTDB mount status was updated.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-mount at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Mount>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Mount


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Mount>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Mount>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Mount>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Mount/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

