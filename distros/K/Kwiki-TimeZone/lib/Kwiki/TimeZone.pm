package Kwiki::TimeZone;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.11';

const class_id => 'time_zone';
const config_file => 'time_zone.yaml';

sub register {
    $self->hub->config->add_file($self->config_file);
    my $registry = shift;
    $registry->add(preference => $self->time_zone);
}

sub time_zone {
    my $p = $self->new_preference('time_zone');
    $p->query('Enter your time zone.');
    $p->type('pulldown');
    my $default = eval { $self->hub->config->time_zone_default };
    undef $@;
    $p->default($default || 'GMT');
    my $choices = [
        IDLW => "International Date Line West",
        NT   => "Nome",
        AHST => "Alaska-Hawaii Standard",
        CAT  => "Central Alaska",
        HST  => "Hawaii Standard",
        HDT  => "Hawaii Daylight",
        YST  => "Yukon Standard",
        YDT  => "Yukon Daylight",
        PST  => "Pacific Standard",
        PDT  => "Pacific Daylight",
        MST  => "Mountain Standard",
        MDT  => "Mountain Daylight",
        CST  => "Central Standard",
        CDT  => "Central Daylight",
        EST  => "Eastern Standard",
        EDT  => "Eastern Daylight",
        ST   => "Atlantic Standard",
        ADT  => "Atlantic Daylight",
        NST  => "Newfoundland Standard",
        NDT  => "Newfoundland Daylight",
        AT   => "Azores",
        WAT  => "West Africa",
        GMT  => "Greenwich Mean",
        UT   => "Universal (Coordinated)",
        WET  => "Western European",
        BST  => "British Summer",
        CET  => "Central European",
        MET  => "iddle European",
        MEWT => "Middle European Winter",
        SWT  => "Swedish Winter",
        FWT  => "French Winter",
        MEST => "Middle European Summer",
        SST  => "Swedish Summer",
        FST  => "French Summer",
        EET  => "Eastern Europe, USSR Zone 1",
        CEST => "Central European Summer",
        BT   => "Baghdad, USSR Zone 2",
        IT   => "Iran",
        ZP4  => "USSR Zone 3",
        ZP5  => "USSR Zone 4",
        IST  => "Indian Standard",
        ZP6  => "USSR Zone 5",
        WAST => "West Australian Standard",
        WADT => "West Australian Daylight",
        JT   => "Java (3pm in Cronusland!)",
        TWN  => "Taiwan",
        CCT  => "China Coast, USSR Zone 7",
        JST  => "Japan Standard, USSR Zone 8",
        CAST => "Central Australian Standard",
        CADT => "Central Australian Daylight",
        GST  => "Guam Standard, USSR Zone 9",
        EAST => "Eastern Australian Standard",
        EADT => "Eastern Australian Daylight",
        NZT  => "New Zealand",
        NZST => "New Zealand Standard",
        IDLE => "International Date Line East",
        NZDT => "New Zealand Daylight",
    ];
    $p->choices($choices);
    return $p;
}

my $time_offsets = {
    IDLW => -12,
    NT   => -11,
    AHST => -10,
    CAT  => -10,
    HST  => -10,
    HDT  => -9,
    YST  => -9,
    YDT  => -8,
    PST  => -8,
    PDT  => -7,
    MST  => -7,
    MDT  => -6,
    CST  => -6,
    CDT  => -5,
    EST  => -5,
    EDT  => -4,
    ST   => -4,
    ADT  => -3,
    NST  => -3.5,
    NDT  => -2.5,
    AT   => -2,
    WAT  => -1,
    GMT  => 0,
    UT   => 0,
    WET  => 0,
    BST  => 1,
    CET  => 1,
    MET  => 1,
    MEWT => 1,
    SWT  => 1,
    FWT  => 1,
    MEST => 2,
    SST  => 2,
    FST  => 2,
    EET  => 2,
    CEST => 2,
    BT   => 3,
    IT   => 3.5,
    ZP4  => 4,
    ZP5  => 5,
    IST  => 5.5,
    ZP6  => 6,
    WAST => 7,
    WADT => 8,
    JT   => 7.5,
    TWN  => 8,
    CCT  => 8,
    JST  => 9,
    CAST => 9.5,
    CADT => 10.5,
    GST  => 10,
    EAST => 10,
    EADT => 11,
    NZT  => 12,
    NZST => 12,
    IDLE => 12,
    NZDT => 13,
};

sub format {
    my $time = shift;
    my $time_zone = $self->preferences->time_zone->value || 'GMT';
    my $offset = $time_offsets->{$time_zone} || 0;
    scalar(gmtime($time + $offset * 3600)) . " $time_zone";
}

__DATA__

=head1 NAME 

Kwiki::TimeZone - Kwiki Time Zone Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__config/time_zone.yaml__
time_zone_default: GMT
