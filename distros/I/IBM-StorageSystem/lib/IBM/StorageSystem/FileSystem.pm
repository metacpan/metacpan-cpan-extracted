package IBM::StorageSystem::FileSystem;

use strict;
use warnings;

use IBM::StorageSystem::FileSystem::FileSet;
use IBM::StorageSystem::Snapshot;
use Scalar::Util qw(weaken);
use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(ACLtype Atime Block_allocation_type Block_size Cluster Def_quota 
Device_name Dmapi Ind_block_size Inode_size Inodes Last_update Locking_type 
Log_placement Logf_size Max_Inodes Min_frag_size Mount_point Mtime Quota 
Remote_device Replication Snapdir State Type Version);

our $OBJ = {
		fileset => {
			cmd	=> 'lsfset -v -Y',
			id	=> 'ID',
			class	=> 'IBM::StorageSystem::FileSystem::FileSet',
			type	=> 'fset',
			sl	=> 1
		},
		snapshot => {
			cmd	=> 'lssnapshot -Y',
			id	=> 'Snapshot_ID',
			class	=> 'IBM::StorageSystem::Snapshot',
			type	=> 'snapshot',
			sl	=> 1
		}
};

foreach my $obj ( keys %{ $OBJ } ) { 
	{   
	no strict 'refs';

	my $m = 'get_'.$obj.'s';

	*{ __PACKAGE__ ."::$obj" } = 
		sub {
			my( $self, $id ) = @_; 
			defined $id or return;

			return ( $self->{$obj}->{$id} 	? $self->{$obj}->{$id} 
							: $self->$m( $id ) 
				) 
		};  

	*{ __PACKAGE__ .'::get_'. $obj } = 
		sub { 
			my ( $self, $id ) = @_;
			return $self->$m( $id ) 
		};

	*{ __PACKAGE__ . "::$m" } = 
		sub {
			my ( $self, $id ) = @_;
			my %args = ( cmd	=> "$OBJ->{$obj}->{cmd} ".$self->device_name, 
				     class	=> $OBJ->{$obj}->{class}, 
				     type	=> $OBJ->{$obj}->{type}, 
				     id		=> $OBJ->{$obj}->{id} 
				);
			my @res = map { $_->device_name( $self->{device_name} ); $_ 
				      } $self->{__ibm}->__get_sl_objects( %args );

			return ( defined $id	? $self->{ $OBJ->{$obj}->{type} }->{$id} 
						: @res 
				)
		}
	}   
}

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
        defined $args{'Device_name'} 
		or croak __PACKAGE__ . ' constructor failed: mandatory Device_name argument not supplied';
	weaken( $self->{__ibm} = $ibm );

        foreach my $attr ( @ATTR ) { 
		$self->{lc $attr} = $args{$attr} 
	}

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::V7000::FileSystem - Class for operations with a IBM V7000 file system entities

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::V7000::FileSystem - Class for operations with a IBM V7000 file system entities

        use IBM::V7000;
        
        my $ibm = IBM::V7000->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Print the block size of file system 'fs1'
	print $ibm->fs(fs1)->block_size;
	
	# Get the file system 'fs2' as a IBM::V7000::FileSystem object
	my $fs = $ibm->fs(fs2);

	# Print the mount point of this file system
	print "fs2 mount point: " . $fs2->mount_point . "\n";

	# Call a function if inode usage on file system 'fs2' exceeds 90% of maximum allocation.
	monitoring_alert( 'Inode allocation > 90% on '.$fs->device_name ) 
		if ( ( ( $fs->inodes / $fs->max_inodes ) * 100 ) > 90 );

	# Do the same for all file systems
	map { monitoring_alert( 'Inode allocation > 90% on '.$_->device_name )
		if ( ( ( $fs->inodes / $fs->max_inodes ) * 100 ) > 90 ) } $ibm->get_fss;

=head1 METHODS

=head3 acltype

Returns the file system ACL type in use.

=head3 atime

Returns the value of the file system atime flag status.

=head3 block_allocation_type

Returns the value of the file system block allocation type.

=head3 block_size

Returns the file system block size.

=head3 cluster

Returns the cluster ID of the cluster on which the filesystem is mounted.

=head3 def_quota

Returns the value of the file system defined quota flag.

=head3 device_name

Returns the file system device name.

=head3 dmapi

Returns the file system DMAPI enabled status.

=head3 ind_block_size

Returns the file system indirect block size.

=head3 inode_size

Returns the file system inode size.

=head3 inodes

Returns the current number of allocated inodes for the file system.

=head3 last_update

Returns the last time the file system CTDB information was updated.

=head3 locking_type

Returns the file system locking type.

=head3 log_placement

Returns the file system log placement scheme.

=head3 logf_size

Returns the file system log file size.

=head3 max_inodes

Returns the maximum number of allocatable inodes for the file system.

=head3 min_frag_size

Returns the file system minimum fragment size.

=head3 mount_point

Returns the file system mount point.

=head3 mtime

Returns the file system mtime flag status.

=head3 quota

Returns the file system quota type.

=head3 remote_device

Returns the file system remote device.

=head3 replication

Returns the file system replication status.

=head3 snapdir

Returns the file system snapdir flag status.

=head3 get_snapshots

Returns an array of L<IBM::StorageSystem::Snapshots> for the file system.

See L<IBM::StorageSystem::Snapshot> for further information.

=head3 state

Returns the file system operational state.

=head3 type

Returns the file system type.

=head3 version

Returns the file system version.

=head3 fileset( $id )

	# Get fileset ID 200 on file system 'fs1' and print the number of used inodes
	my $fs = $ibm->filesystem(fs1);
	my $fileset = $fs->fileset(200);
	print $fileset->inodes;

	# Alternately
	print $ibm->filesystem(fs1)->fileset(200)->inoeds;

Returns the fileset for this filesystem specified by the numerical identifier as a L<IBM::StorageSystem::FileSystem::FileSet> object.

B<Note> that this is a caching method and that a previously retrieved L<IBM::StorageSystem::FileSystem::FileSet> object will
be returned if one has been cached from previous invocations.

=head3 get_fileset( $id )

This is a funtionally equivalent non-caching implementation of the B<fileset> method.

=head3 get_filesets

	# Print all filesets for this filesystem, their current, maximum and allocated inodes

	foreach my $fileset ( $filesystem->get_filesets ) [
		print	"Name: " . $fileset->name . "\n" .
			"Used inodes: " . $fileset->inodes . "\n" .
			"Allocated inodes: " . $fileset->alloc_inodes . "\n" .
			"Maximum inodes: " . $fileset->max_inodes . "\n" .
			"---------------------------------------\n"
	}

Returns an array of L<IBM::StorageSystem::FileSystem::FileSet> objects representing all filesets
for the specified file system.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-filesystem at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-V7000-FileSystem>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::V7000::FileSystem

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-V7000-FileSystem>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-V7000-FileSystem>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-V7000-FileSystem>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-V7000-FileSystem/>

=back


=head1 SEE ALSO

L<IBM::StorageSystem>, L<IBM::StorageSystem::FileSystem::FileSet>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

