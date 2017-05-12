# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::WebApps;
use strict;
use warnings;

use 5.012;
use base qw(Maplat::Web::BaseModule);

use Maplat::Helpers::Weather;
use Maplat::Helpers::DBSerialize;

our $VERSION = 0.995;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    return $self;
}

sub reload {
    my ($self) = shift;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    weather_reload($dbh, $memh);

    return;
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{settings}->{webpath}, "get_settings");
    $self->register_webpath($self->{weatherfile}->{webpath}, "get_file");
    $self->register_prerender("prerender");
    return;
}

sub get_settings {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    my $seth = $self->{server}->{modules}->{$self->{usersettings}};

    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{settings}->{pagetitle},
        webpath         =>  $self->{settings}->{webpath},
    ); 

    my %settings = (
        WebAppShowWeather   => 1,
        WebAppShowSnow      => 1,
    );
    
    foreach my $key (keys %settings) {
        my ($ok, $val) = $seth->get($webdata{userData}->{user}, $key);
        if(!$ok) {
            $val = $settings{$key};
            $seth->set($webdata{userData}->{user}, $key, \$val);
        } else {
            $val = dbderef($val);
            $settings{$key} = $val;
        }
    }
    
    # Just set the keys... the values are set in the prerender stage anyway
    my $mode = $cgi->param('mode') || 'view';
    if($mode eq "update") {
        foreach my $key (keys %settings) {
            my $val = $cgi->param($key);
            if(defined($val)) {
                $seth->set($webdata{userData}->{user}, $key, \$val);
                $settings{$key} = $val;
            }
        }
    }
    
    my $template = $self->{server}->{modules}->{templates}->get("webapps_settings", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_file {
    my ($self, $cgi) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    my $weather = weather_get($dbh, $memh);
    
    my $webpath = $cgi->path_info();
    $webpath =~ s/.*\///go;
    if(!defined($weather->{icons}->{$webpath})) {
        return (status  =>  404);
    }
    
    return (status  =>  200,
            type    => "image/gif",
            data    => $weather->{icons}->{$webpath},
            expires         => $self->{weatherfile}->{expires},
            cache_control   =>  $self->{weatherfile}->{cache_control}
            );
}


sub prerender {
    my ($self, $webdata) = @_;

    return unless(defined($webdata->{userData}->{user}));

    my $seth = $self->{server}->{modules}->{$self->{usersettings}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    my %settings = (
        WebAppShowWeather   => 1,
        WebAppShowSnow      => 1,
    );
    
    foreach my $key (keys %settings) {
        my ($ok, $val) = $seth->get($webdata->{userData}->{user}, $key);
        if(!$ok) {
            $val = $settings{$key};
            $seth->set($webdata->{userData}->{user}, $key, \$val);
        } else {
            $val = dbderef($val);
            if(!defined($val)) {
                print STDERR "Bla\n";
            } else {
                $settings{$key} = $val;
            }
        }
    }
    
    foreach my $key (keys %settings) {
        $webdata->{$key} = $settings{$key};
    }
    
    if($settings{WebAppShowWeather}) {
        my $weather = weather_get($dbh, $memh);
        $webdata->{WebAppWeatherStatus} = $weather->{forecast};
        $webdata->{WebAppWeatherFile} = $self->{weatherfile}->{webpath};
    }
    
    return;
}

1;
__END__

=head1 NAME

Maplat::Web::WebApps - add small tools and toys to the webinterface

=head1 SYNOPSIS

Add small tools and toys to the web interface

=head1 Configuration

THIS MODULE IS HIGHLY EXPERIMENTAL. DO NOT USE AT THE MOMENT!

=head2 get_file

Renders the icons

=head2 get_settings

General settings mask for WebApps

=head2 prerender

Add various webdata values to support rendering the WebApps

=head1 SEE ALSO

Maplat::Web

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
