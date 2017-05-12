package Helios::MetajobBurstService;

use 5.008000;
use base qw( Helios::Service );
use strict;
use warnings;

our $VERSION = '2.83';

# CHANGE HISTORY:
# [LH] [2015-08-14]: Changed all CRLF endings to Unix-style LF endings.

=head1 NAME

Helios::MetajobBurstService - base class for metajob burst services in Helios

=head1 DESCRIPTION

Helios::MetajobBurstService is a subclass of Helios::Service specially tasked with bursting 
metajobs.  You can subclass this class to provide special metajob bursters for your application.  
This allows you more fine grained control over the volume of jobs entering the Helios job queue.

A MetajobBurstService class supports one config parameter, burst_interval, which is the 
number of seconds between metajob bursts.  This is to prevent the metajob bursting process from 
running so fast the Helios job queue is overwhelmed with burst jobs.

=cut

=head1 

=cut

sub burstJob {
	my $self = shift;
	my $config = $self->getConfig();
	my $jobnumber = $self->SUPER::burstJob(@_);
	if ( defined($config->{burst_interval}) ) {
		sleep $config->{burst_interval};
	}
	return $jobnumber;
}


1;
__END__


=head1 SEE ALSO

L<Helios::Service>

=head1 AUTHOR

Andrew Johnson, E<lt>ajohnson at ittoolbox dotcomE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by CEB Toolbox, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

