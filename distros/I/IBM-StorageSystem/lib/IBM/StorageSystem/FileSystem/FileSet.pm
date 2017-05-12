package IBM::StorageSystem::FileSystem::FileSet;

use strict;
use warnings;

use Scalar::Util qw(weaken);
use Carp qw(croak);

our @ATTR = qw(	Alloc_inodes		Comment	Creation_time	Data ID		device_name 
		Inode_space_owner	Inodes	Is_independent	Max_inodes	Name 
		Parent_id		Path	Root_inode	Status		Timestamp);

our $OBJ = { 
                snapshot => {
                        cmd     => 'lssnapshot -Y',
                        id      => 'Snapshot_ID',
                        class   => 'IBM::StorageSystem::Snapshot',
                        type    => 'snapshot',
                        sl      => 1
                }   
};

foreach my $attr ( map lc, @ATTR ) { 
        {   
	no strict 'refs';
	*{ __PACKAGE__ .'::'. $attr } = 
		sub {
			my( $self, $val ) = @_; 
			$self->{$attr} = $val if $val;
			return $self->{$attr}
		}
        }
}

foreach my $obj ( keys %{ $OBJ } ) { 
	{   
	no strict 'refs';
	my $m = 'get_'.$obj.'s';

	*{ __PACKAGE__ ."::$obj" } = 
		sub {
			my( $self, $id ) = @_; 
			defined $id or return;

			return ( $self->{$obj}->{$id}	? $self->{$obj}->{$id} 
							: $self->$m( $id ) ) 
		};  

	*{ __PACKAGE__ .'::get_'. $obj } = 
		sub { 
			return $_[0]->$m( $_[1] ) 
		};

	*{ __PACKAGE__ . "::$m" } = 
		sub {
			my ( $self, $id ) = @_; 
			my %args = ( cmd	=> "$OBJ->{$obj}->{cmd} $self->{device_name} -j $self->{name} ",
				     class	=> $OBJ->{$obj}->{class}, 
				     type	=> $OBJ->{$obj}->{type}, 
				     id		=> $OBJ->{$obj}->{id} 
				);
			my @res = $self->{__ibm}->__get_sl_objects( %args );
    
			return ( defined $id	? $self->{ $OBJ->{$obj}->{type} }->{$id} 
						: @res )
		}
	}   
}

sub new {
        my( $class, $ibm, %args ) = @_; 
        my $self = bless {}, $class;
        defined $args{ID} or croak 'Constructor failed: mandatory argument ID not supplied';
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

IBM::StorageSystem::FileSystem::FileSet - Utility class for operations with a IBM storage system filesystem filesets

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::FileSystem::FileSet - Utility class for operations with a IBM storage system filesystem filesets

        use IBM::StorageSystem;

        my $ibm = IBM::StorageSystem->new(      
					user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                        ) or die "Couldn't create object! $!\n";

=head3 alloc_inodes

Returns the number of allocated inodes for the fileset.

B<Note> that the number of allocated inodes is returned in a human-readable format with a variable units -
e.g. the value may be returned as 10K or 10M, where K and M refer to the unit.

=head3 comment

Returns the user-specified fileset comment.

=head3 creation_time

Returns the fileset creation time.

=head3 data

Returns the amount of data in use for the fileset in a human-readable format (kB, MB, GB, TB or PB where
1 kB is equal to 1000 bytes).

=head3 device_name

Returns the name of the file system to which the fileset belongs.

=head3 id

Returns the fileset numerical identifier.

=head3 inode_space_owner

Returns the numerical identifier of the fileset owner.

=head3 inodes

Returns the number of inodes in use.

=head3 is_independent

Specifies if the fileset is independent.

=head3 max_inodes

Returns the maximum number of allocatable inodes.

=head3 name

Returns the fileset name.

=head3 parent_id

Returns the parent fileset identifier.

=head3 path

Returns the fileset path if the fileset B<status> is linked and blank otherwise.

=head3 root_inode

Returns the number of the root inode.

=head3 get_snapshots

Returns an array of L<IBM::StorageSystem::Snapshots> for the fileset.

See L<IBM::StorageSystem::Snapshots> for more information.

=head3 status

Returns the fileset status; either linked or unlinked.

=head3 timestamp

Returns a timestamp of the last time at which the fileset information was updated in the CTDB.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-storagesystem-filesystem-fileset at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-FileSystem-FileSet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::FileSystem::FileSet


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-FileSystem-FileSet>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-FileSystem-FileSet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-FileSystem-FileSet>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-FileSystem-FileSet/>

=back


=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

