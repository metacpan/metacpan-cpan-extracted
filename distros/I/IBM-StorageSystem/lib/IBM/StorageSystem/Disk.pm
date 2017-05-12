package IBM::StorageSystem::Disk;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(Name File_system Failure_group Type Pool Status Availability Timestamp Block_properties);

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
        defined $args{Name} or croak 'Constructor failed: mandatory Name argument not supplied';

        foreach my $attr ( @ATTR ) { $self->{lc $attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Disk - Class for operations with IBM StorageSystem disks

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Disk is a utility class for operations with IBM StorageSystem disks.

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      
				         user            => 'admin',
                                         host            => 'my-v7000',
                                         key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Get disk ID system_vol_00 as an IBM::StorageSystem::Disk object.
	my $disk = $ibm->disk( 'system_vol_01' );

	# Print the file system to which the disk is assigned
	print $disk->file_system;

	# Prints "fs1"
	
	# Print the pool to which the disk is assigned
	print "Disk pool: ", $disk->pool, "\n";

	# Prints "Disk pool: system"
	
	# Print the availability and failure group for all disks in a nicely formatted list
	printf("%-20s%-20s%-20s%-20s\n", 'File System', 'Disk', 'Availability', 'Failure Group');
	printf("%-20s%-20s%-20s%-20s\n", '-'x18, '-'x18, '-'x18, '-'x18, '-'x18);

	map { printf( "%-20s%-20s%-20s%-20s\n", 
		$_->file_system,
		$_->name,
		$_->availability,
		$_->failure_group) 
	} $ibm->get_disks;

	# Prints:
	#
	# File System         Disk                Availability        Failure Group       
	# ------------------  ------------------  ------------------  ------------------  
	# fs1                 silver_vol_00       up                  1                   
	# fs1                 silver_vol_01       up                  1                   
	# fs1                 silver_vol_02       up                  1                   
	# fs1                 silver_vol_03       up                  1                   
	# fs1                 silver_vol_04       up                  1                   
	# fs1                 silver_vol_05       up                  1

=head1 METHODS

=head3 availability

Returns the disk availability status.

=head3 block_properties

Returns a comma-separated list of the disk block properties.

=head3 failure_group

Returns the disk failure group.

=head3 file_system

Returns the file system to which the disk is allocated.

=head3 name

Returns the name of the disk.

=head3 pool

Returns the pool of which the disk is a member.

=head3 status

Returns the disk status.

=head3 timestamp

Returns a timestamp of the last time at which the CTDB disk information was updated.

=head3 type

Returns the disk type.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-disk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Disk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Disk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Disk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Disk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Disk>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Disk/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
