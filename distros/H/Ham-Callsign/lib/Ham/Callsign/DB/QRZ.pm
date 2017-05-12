# Copyright (C) 2008 Wes Hardaker
# License: Same as perl.  See the LICENSE file for details.
package Ham::Callsign::DB::QRZ;

use Ham::Callsign::DB;
use Ham::Callsign;
use Ham::Scraper;

our @ISA = qw(Ham::Callsign::DB);

use strict;

sub init {
    my ($self) = @_;
    # none needed
}

sub do_load_data {
    my ($self, $place) = @_;
    # none needed.
}

sub do_lookup {
    my ($self, $callsign) = @_;

    my %qrz = Ham::Scraper::QRZ($callsign);
    my %results = (%qrz, FromDB => 'QRZ');

    return if (!$results{'Name'});

    $results{'thecallsign'} = uc($callsign);
    $results{'entity_name'} = $qrz{'Name'};

    $results{'first_name'} =  $qrz{'Name'};
    $results{'first_name'} =~ s/ .*//;

    $results{'last_name'} =  $qrz{'Name'};
    $results{'last_name'} =~ s/.* //;

    $results{'city'} =  $qrz{'CityStateZip'};
    $results{'city'} =~ s/,* .*//;

    $results{'zip'} =  $qrz{'CityStateZip'};
    $results{'zip'} =~ s/.*(\d+)$/$1/;

    $results{'state'} =  $qrz{'CityStateZip'};
    $results{'state'} =~ s/.* ([A-Z][A-Z]) .*/$1/;

    $results{'qth'} = $qrz{'CityStateZip'} . ", " . $qrz{'Grid'};

    foreach my $xfer (qw(CityStateZip TimeZone GMTOffset Grid)) {
	$results{$xfer} = $qrz{$xfer};
    }

    return [new Ham::Callsign(%results)];
}

sub do_create_tables {
    my ($self) = @_;

    # not needed
}

1;

=pod

=head1 NAME

=cut


