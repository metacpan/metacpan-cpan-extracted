# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::Weather;
use strict;
use warnings;

use 5.012;

use Maplat::Helpers::DBSerialize;
use Weather::Google;
use WWW::Mechanize;
use Data::Dumper;
# Translations and caching

use base qw(Exporter);
our @EXPORT = qw(weather_update weather_get weather_reload); ## no critic (Modules::ProhibitAutomaticExportation)
our $VERSION = 0.995;

use Carp;

sub weather_reload {
    my ($dbh, $memh) = @_;
    
    my %weatherdata;
    
    my %icons;
    my $isth = $dbh->prepare("SELECT * FROM weather_icons")
            or croak($dbh->errstr);
    $isth->execute or croak($dbh->errstr);
    while((my $icon = $isth->fetchrow_hashref)) {
        my $tmp = dbthaw($icon->{icon_data});
        $icons{$icon->{icon_name}} = $$tmp;
    }
    $weatherdata{icons} = \%icons;
    
    my @forecast;
    my $fsth = $dbh->prepare("SELECT * FROM weather_forecast")
            or croak($dbh->errstr);
    $fsth->execute or croak($dbh->errstr);
    my %map = (
               current  => 0,
               today    => 1,
               tomorrow => 2,
               day_after_tomorrow   => 3,
              );
    while((my $fc = $fsth->fetchrow_hashref)) {
        $forecast[$map{$fc->{weather_day}}] = $fc;
    }
    
    $weatherdata{forecast} = \@forecast;
    
    $memh->set("WeatherCache", \%weatherdata);
    
    return \%weatherdata;
}

sub weather_geticon {
    my ($url) = @_;
    
    my $mech = WWW::Mechanize->new();
    my $result = $mech->get("http://www.google.com$url");
    if($result->is_success) {
        return $result->content;
    }
    return;
}

# Convert Fahrenheit to celsius
sub FtoC {
    my ($f) = @_;
    
    my $c = (5/9)*($f-32);
    $c = int($c);
    
    return $c;
}

sub weather_update {
    my ($dbh, $memh) = @_;
    
    my $gsth = $dbh->prepare("SELECT icon_name FROM weather_icons")
            or croak($dbh->errstr);
    my @icons;
    $gsth->execute() or croak($dbh->errstr);
    while((my $icon = $gsth->fetchrow_array)) {
        push @icons, $icon;
    }
    $gsth->finish;
    
    my $gw = Weather::Google->new(
        'Gleisdorf, Austria',
        {language => 'en', encoding => 'latin1'},
    );
    
    my $current = $gw->current_conditions;
    my $forecast = $gw->forecast_conditions;
    
    
    # *** Check/get all the icons ***
    my $icsth = $dbh->prepare("INSERT INTO weather_icons (icon_name, icon_data) VALUES (?,?)")
            or croak($dbh->errstr);
    
    my @sources = ($current->{icon});
    for(my $i = 0; $i < 3; $i++) {
        push @sources, $forecast->[$i]->{icon};
    }
    
    foreach my $icon (@sources) {
        my $shortname = $icon;
        next if(!defined($shortname) || $shortname eq "");
        $shortname =~s/^.*\///g;
        $shortname =~s/\.gif$//g;
        if(!($shortname ~~ @icons)) {
            my $data = weather_geticon($icon);
            if(!defined($data)) {
                #print stderr "Icon $shortname has no data!\n";
            } else {
                #print "Icon $shortname not in " . Dumper(@icons) . "\n";
                if($icsth->execute($shortname, dbfreeze($data))) {
                    $dbh->commit;
                    push @icons, $shortname;
                } else {
                    $dbh->rollback;
                    #return 0;
                }
            }
        }
    }
    
    # *** Clean up old data ***
    my $delsth = $dbh->prepare("DELETE FROM weather_forecast")
            or croak($dbh->errstr);
    if(!$delsth->execute) {
        $dbh->rollback;
        return 0;
    }
    
    # *** Insert new weather report ***
    my $insth = $dbh->prepare("INSERT INTO weather_forecast
                              (weather_day, day_name, temp_low, temp_high, icon_name)
                              VALUES (?,?,?,?,?)")
            or croak($dbh->errstr);
    # ...fake "now" as a forecast
    $forecast->[3]->{condition} = $current->{condition};
    $forecast->[3]->{icon} = $current->{icon};
    $forecast->[3]->{day_of_week} = "Now";
    $forecast->[3]->{high} = $current->{temp_f};
    $forecast->[3]->{low} = $current->{temp_f};
    
    my @map = qw[today tomorrow day_after_tomorrow current];
    for(my $i = 0; $i < 4; $i++) {
        my $shortname = $forecast->[$i]->{icon};
        $shortname =~s/^.*\///g;
        $shortname =~s/\.gif$//g;
        
        print "Inserting " . $map[$i] . "\n";
        if(!$insth->execute($map[$i],
                            $forecast->[$i]->{day_of_week},
                            FtoC($forecast->[$i]->{low}),
                            FtoC($forecast->[$i]->{high}),
                            $shortname
                            )) {
            $dbh->rollback;
            return 0;
        }
    }
    $dbh->commit;
    
    weather_reload($dbh, $memh);
    
    return 1;
}

sub weather_get {
    my ($dbh, $memh) = @_;

    my $weather = $memh->get("WeatherCache");
    
    if(!$weather || ref($weather) ne 'HASH') {
        return weather_reload($dbh, $memh);
    }
    
    return $weather;
}

1;
__END__

=head1 NAME

Maplat::Helpers::Weather - helper for "weather" app

=head1 SYNOPSIS

  use Maplat::Helpers::Weather;
  
=head1 DESCRIPTION

This module gets the current weather information from google and does the memcache/db handling

=head2 weather_get

Internal function

=head2 weather_geticon

Internal function

=head2 weather_reload

Internal function

=head2 weather_update

Internal function

=head2 FtoC

Convert Fahrenheit to Celsius

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
