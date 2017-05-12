# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::Weather;
use strict;
use warnings;

use base qw(Maplat::Worker::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::Weather;

use Carp;

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    $self->{lastRun} = "";

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we are pretty much self contained
    return;
}

sub register {
    my $self = shift;
    $self->register_worker("work");
    return;
}


sub work {
    my ($self) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    
    my $workCount = 0;
    
    my $now = getCurrentHour();
    if($self->{lastRun} eq $now) {
        return $workCount;
    }
    $self->{lastRun} = $now;
    
    $reph->debuglog("Starting weather update");
    if(weather_update($dbh, $memh)) {
        $reph->debuglog("Weather updated.");
        $workCount++;
    } else {
        $reph->debuglog("Weather update failed!");
    }
    
    return $workCount;
}


1;
__END__

=head1 NAME

Maplat::Worker::Weather - Update weather status information

=head1 SYNOPSIS

This module updates weather information by calling Maplat::Helpers::Weather.

=head1 DESCRIPTION

This is the worker part to update the weather information.
=head1 Configuration

        <module>
                <modname>weather</modname>
                <pm>Weather</pm>
                <options>
                        <db>maindb</db>
                        <memcache>memcache</memcache>
                        <reporting>reporting</reporting>
                </options>
        </module>

=head2 work

Internal function, does the weather update.

=head1 SEE ALSO

Maplat::Worker

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
