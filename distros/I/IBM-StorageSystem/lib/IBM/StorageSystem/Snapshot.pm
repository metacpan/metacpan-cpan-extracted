package IBM::StorageSystem::Snapshot;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(Device_name Fileset_name Snapshot_ID Rule_Name Status Creation Used_metadata Used_data ID Timestamp);

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
        defined $args{'Snapshot_ID'} or croak __PACKAGE__ 
		. ' constructor failed: mandatory Snapshot_ID parameter missing';

        foreach my $attr ( @ATTR ) { $self->{lc $attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Snapshot - Class for operations with a IBM StorageSystem snapshot objects

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Snapshot is a class for operations with a IBM StorageSystem snapshot objects.

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      
					user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Print a list of all snapshots tabularly ordered by file system and fileset,
	# including the age of each snapshot in days.

	use Date::Calc qw(Today Delta_Days);

	my ( $y, $m, $d ) = Today;

	foreach my $filesystem ( $ibm->get_filesystems ) { 
		print "Filesystem: ". $filesystem->device_name ."\n";
	    
		foreach my $fileset ( $filesystem->get_filesets ) { 
			print "\tFileset : ". $fileset->name ."\n";
	    
			foreach my $snapshot ( $fileset->get_snapshots ) { 
				my $dd = Delta_Days( ( split /-/, ( split / /, $snapshot->creation )[0], 3 ), $y, $m, $d );
				print "\t\tSnapshot ID: ". $snapshot->id ." is $dd days old\n"
			}   
		}   
	}

	# Prints something like:
	# Filesystem: fs1
	#	Fileset : root
	#	Fileset : share-dlf
	#		Snapshot ID: 2790 is 0 days old
	#		Snapshot ID: 2742 is 0 days old
	#		Snapshot ID: 2693 is 1 days old
	#		Snapshot ID: 2645 is 1 days old
	#		Snapshot ID: 2597 is 1 days old
	#		Snapshot ID: 2550 is 1 days old
	#		Snapshot ID: 2456 is 2 days old
	#		Snapshot ID: 2409 is 2 days old
	#		Snapshot ID: 2362 is 2 days old
	#		Snapshot ID: 2314 is 3 days old
	# ... etc.

=head1 METHODS

=head3 device_name

Returns the name of the filesystem on which the snapshot resides (use in combination with the fileset method).

=head3 fileset_name

Returns the name of the fileset to which the snapshot applies - this will be null for filesystem level
snapshots.

=head3 snapshot_id

Returns the snapshot unique ID.

=head3 rule_name

Returns the name of the rule which generated the snapshot.

=head3 status

Returns the status of the snapshot - either valid or invalid.

=head3 creation

Returns the creation time of the snapshot in the format 'YYYY-MM-DD HH:MM:SS'.

=head3 used_metadata

Returns the snapshot metadata storage usage in KB.

=head3 used_data

Returns the snapshot data storage usage in KB.

=head3 id

Returns the snapshot integer ID - note that this may not be unique on the target system.

=head3 timestamp

Returns a timestamp in the format 'YYYY-MM-DD HH:MM:SS' at which the snapshot CTDB data was last verified.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-snapshot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Snapshot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Snapshot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Snapshot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Snapshot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Snapshot>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Snapshot/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
