package IBM::StorageSystem::Replication;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(filesystem log_Id status description time);

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
        defined $args{'log_Id'} or croak __PACKAGE__ 
		. ' constructor failed: mandatory log_Id argument not supplied';

        foreach my $attr ( @ATTR ) { $self->{lc $attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Replication - Class for operations with IBM StorageSystem asynchronous replications

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Replication - Class for operations with IBM StorageSystem asynchronous replications

        use IBM::StorageSystem;
        use Date::Calc qw(date_to_Time Today_and_Now);

        my $ibm = IBM::StorageSystem->new(      
					user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Generate an alert for any replication errors in the last six hours

	foreach my $task ( $ibm->get_replications ) {

		if ( $repl->status eq 'ERROR' and ( Date_to_Time( Today_and_Now ) 
			- ( Date_to_Time( split /-| |\./, $repl->time ) ) ) > 21_600 ) {
			alert( "Replication failure for filesystem " . $repl->filesystem . 
				" - log ID: " . $repl->log_id . )
		}

	}
	
=head1 METHODS

=head3 filesystem

The name of the filesystem on which the replication is configured.

=head3 log_id 

Returns the event log entry identifer for the replication task.

=head3 status

Returns the replication task completion status.

=head3 description

Returns a description of the replication task outcome.

=head3 time

Returns the completion time of the replication task in the format 'YYYY-MM-DD HH:MM:SS'; 

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-replication at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Replication>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Replication

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Replication>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Replication>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Replication>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Replication/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

