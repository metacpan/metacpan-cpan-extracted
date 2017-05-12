package IBM::StorageSystem::Pool;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(Filesystem:Name Filesystem Name Size Usage Available_fragments Available_blocks Disk_list);

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

our $STATS = { 
                throughput => {
                        cmd     => '-g pool_throughput',
                        class   => 'IBM::StorageSystem::Statistic::Pool::Throughput'
                        },  
};

foreach my $stat ( keys %{ $STATS } ) { 
        {   
        no strict 'refs';
        *{ __PACKAGE__ .'::'. $stat } = 
        sub {
                my( $self, $t ) = @_; 
                $t ||= 'minute';
                my $stats = $self->{__ibm}->__lsperfdata( cmd   => "$STATS->{$stat}->{cmd} -t $t -p $self->{'filesystem:name'}",
                                                          class => $STATS->{$stat}->{class} 
                                                        );  
                return $stats
        }   
        }   
}

sub new {
        my( $class, $ibm, %args ) = @_; 
        my $self = bless {}, $class;
        defined lc $args{'filesystem:pool'} or croak __PACKAGE__ . ' constructor failed: mandatory filesystem:pool argument not supplied';
	$self->{ name } = $args{Name};

	foreach my $attr ( keys %args ) { $self->{lc $attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Pool - Class for operations with a IBM StorageSystem pool objects

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Pool is a class for operations with a IBM StorageSystem pool objects.

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      
					user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Print a 
	
=head1 METHODS

=head3 name

Returns the name of the pool.

=head3 filesystem

Returns the name of the file system for the pool - note that it there is a many to many relationship for
pools and filesystems.

=head3 size

Returns the size of the pool in bytes.

=head3 usage

Returns the percentage of used space in the file system pool.

=head3 available_fragments

Returns the available space in blocks that are partly used by data.

=head3 available_blocks

Returns the available space in full blocks.

=head3 disk_list

Returns a semi-colon separated list of the NSDs which are members of the file system pool.

=head3 throughput( $time_period )

Returns a L<IBM::StorageSystem::Statistic::Pool::Throughput> object containing pool throughput
statistical and performance data for the specified period.

Valid values for the timeperiod parameter are one of minute, hour, day, week, month, quarter 
and year - if the timeperiod parameter is not specified it will default to minute.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-pool at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Pool>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Pool

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Pool>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Pool>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Pool>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Pool/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

