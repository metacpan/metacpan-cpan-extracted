package IBM::StorageSystem::Task;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(Name Description Status Last_run Runs_on Type Scheduled Second 
Minute Hour DayOfMonth Month DayOfWeek Parameter);

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
        defined $args{'Name'} or croak __PACKAGE__ 
		. ' constructor failed: mandatory Name argument not supplied';

        foreach my $attr ( @ATTR ) { $self->{lc $attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Task - Class for operations with IBM StorageSystem tasks

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Task - Class for operations with IBM StorageSystem tasks

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Print the status of the SNAPSHOTS task
	my $snapshots = $ibm->task(SNAPSHOTS);
	print "Status: " . $snapshots->status . "\n";

	# Alternately
	print "Status: " . $ibm->task(SNAPSHOTS)->status . "\n";

	# Print the array status of all arrays in our system
	map { print "Array ", $_->mdisk_id, " status ", $_->status, "\n" } $ibm->get_arrays;
	
=head1 METHODS

=head3 name

Returns the task name.

=head3 description 

Returns the task description.

=head3 status

Returns the task last run status.

=head3 last_run

Returns the time at which the task was last run.

=head3 runs_on 

Returns the node on which the task runs.

=head3 type

Returns the task type, either B<CRON> or B<GUI>.

=head3 scheduled

Returns teh scheduled status of the task.

=head3 second

Returns the second at which the second at which the task is run - used in conjunction with 
the B<minute>, B<hour>, B<dayofmonth>, B<dayofweek> and B<month> methods.

=head3 minute

Returns the minute at which the second at which the task is run - used in conjunction with 
the B<second>, B<hour>, B<dayofmonth>, B<dayofweek> and B<month> methods.

=head3 hour

Returns the hour at which the second at which the task is run - used in conjunction with 
the B<second>, B<minute>, B<dayofmonth>, B<dayofweek> and B<month> methods.

=head3 dayofmonth

Returns the day of the month at which the second at which the task is run - used in conjunction with 
the B<second>, B<minute>, B<hour>, B<dayofweek> and B<month> methods.

=head3 dayofweek

Returns the day of the week at which the second at which the task is run - used in conjunction with 
the B<second>, B<minute>, B<hour>, B<dayofmonth> and B<month> methods.

=head3 month

Returns the second at which the second at which the task is run - used in conjunction with 
the B<second>, B<minute>, B<hour>, B<dayofmonth> and B<dayofweek> methods.

=head3 parameter

Returns and parameters for the task.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-task at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Task>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Task

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Task>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Task>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Task>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Task/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

