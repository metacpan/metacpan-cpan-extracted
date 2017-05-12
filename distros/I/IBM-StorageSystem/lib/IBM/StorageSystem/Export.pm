package IBM::StorageSystem::Export;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(Name:Path Name Path Protocol Active Timestamp Options);

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
        defined $args{'Name:Path'} or croak __PACKAGE__ 
		. ' constructor failed: mandatory Name:Path argument not supplied';

	foreach my $attr ( keys %args ) { $self->{lc $attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Export - Class for operations with a IBM StorageSystem logical export entity

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Export - Class for operations with a IBM StorageSystem logical export entity

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Print a listing of all configured exports containing the export name, the export path,
	# the export protocol and the export status.

	printf( "%-20s%-40s%-10s%-10s\n", 'Name', 'Path', 'Protocol', 'Active' );

	foreach my $export ( $ibm->get_exports ) { 
		print '-'x100,"\n";
		printf( "%-20s%-40s%-10s%-10s\n", $export->name, $export->path, $export->protocol, $export->active )
	}

	# Prints something like:
	#
	#Name                Path                                    Protocol  Active    
	# ----------------------------------------------------------------------------------------------------
	# homes_root          /ibm/fs1/homes                          NFS       true      
	# ----------------------------------------------------------------------------------------------------
	# shares_root         /ibm/fs1/shares                         NFS       true      
	# ----------------------------------------------------------------------------------------------------
	# test                /ibm/fs1/test                           CIFS      true      
	# ----------------------------------------------------------------------------------------------------
	# ... etc.


=head1 METHODS

=head3 name

Returns the export name.

=head3 path

Returns the export path relative to the local file system.

=head3 protocol

Returns the export protocol (e.g. NFS, CIFS, etc.).

=head3 active

Returns the export status.

=head3 timestamp

Returns a timestamp of the last time at which the export status and detail was internally checked and verified.

=head3 options

Returns the export options - for a CIFS export this includes the export root ACL and ownership, for an NFS export
this includes all NFS options.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-export at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Export>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Export


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Export>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Export>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Export>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Export/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

