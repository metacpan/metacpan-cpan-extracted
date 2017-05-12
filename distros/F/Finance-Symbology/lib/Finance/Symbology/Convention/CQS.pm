package Finance::Symbology::Convention::CQS;

use strict;
use warnings;

our $VERSION = 0.2;

my $template = {
    'Preferred' => {
        pattern => qr/^([A-Z]+)(p)$/,
        template => 'p'
    } ,
    'Preferred Class' => {
        pattern => qr/^([A-Z]+)(p)([A-Z])$/,
        template => 'p=CLASS=',
        class => 3
    } ,
    'Class' => {
        pattern => qr/^([A-Z]+)\/([A-Z])$/ ,
        template => '/=CLASS=',
        class => 2
    } ,
    'Preferred when distributed' => {
        pattern => qr/^([A-Z]+)(p\/WD)$/,
        template => 'p/WD'
    } ,
    'When distributed' => {
        pattern => qr/^([A-Z]+)\/(WD)$/,
        template => '/WD'
    } ,
    'Warrants' => {
        pattern => qr/^([A-Z]+)\/(WS)$/,
        template => '/WS'
    } ,
    'Warrants Class' => {
        pattern => qr/^([A-Z]+)\/(WS\/([A-Z]))$/,
        template => '/WS/=CLASS=',
        class => 3
    } ,
    'Called' => {
        pattern => qr/^([A-Z]+)\/(CL)$/,
        template => '/CL'
    } ,
    'Class Called' => {
        pattern => qr/^([A-Z]+)\/([A-Z])\/(CL)$/,
        template => '/=CLASS/CL',
        class => 2
    } ,
    'Preferred Called' => {
        pattern => qr/^([A-Z]+)(p\/CL)$/,
        template => 'p/CL'
    } ,
    'Preferred Class Called' => {
        pattern => qr/^([A-Z]+)(p([A-Z])\/CL)$/,
        template => 'p=CLASS=/CL',
        class => 3
    } ,
    'Preferred Class When Issued' => {
        pattern => qr/^([A-Z]+)(p([A-Z])w)$/,
        template => 'p=CLASS=w',
        class => 3
    } ,
    'Emerging Company Marketplace' => {
        pattern => qr/^([A-Z]+)\/(EC)$/,
        template => '/EC'
    } ,
    'Partial Paid' => {
        pattern => qr/^([A-Z]+)\/(PP)$/,
        template => '/PP'
    } ,
    'Convertible' => {
        pattern => qr/^([A-Z]+)\/(CV)$/,
        template => '/CV'
    } ,
    'Convertible Called' => {
        pattern => qr/^([A-Z]+)\/(CV\/CL)$/,
        template => '/CV/CL'
    } ,
    'Class Convertible' => {
        pattern => qr/^([A-Z]+)\/([A-Z])\/(CV)$/,
        template => '/=CLASS=/CV',
        class => 2
    } ,
    'Preferred Class Convertible' => {
        pattern => qr/^([A-Z]+)(p([A-Z])\/CV)$/,
        template => 'p=CLASS=/CV',
        class => 3
    } ,
    'Preferred Class When Distributed' => {
        pattern => qr/^([A-Z]+)(p([A-Z])\/WD)$/,
        template => 'p=CLASS=/WD',
        class => 3
    } ,
    'Rights' => {
        pattern => qr/^([A-Z]+)(r)$/,
        template => 'r'
    } ,
    'Units' => {
        pattern => qr/^([A-Z]+)\/(U)$/,
        template => '/U'
    } ,
    'When Issued' => {
        pattern => qr/^([A-Z]+)(w)$/,
        template => 'w'
    } ,
    'Rights When Issued' => {
        pattern => qr/^([A-Z]+)(rw)$/,
        template => 'rw'
    } ,
    'Preferred When Issued' => {
        pattern => qr/^([A-Z]+)(pw)$/,
        template => 'pw'
    } ,
    'Class When Issued' => {
        pattern => qr/^([A-Z]+)\/([A-Z])(w)$/,
        template => '/=CLASS=w',
        class => 2
    } ,
    'Warrant When Issued' => {
        pattern => qr/^([A-Z]+)\/(WSw)$/,
        template => '/WSw'
    } ,
    'TEST Symbol' => {
        pattern => qr/^([A-Z]+)\/(TEST)$/,
        template => '/TEST' 
    }
};

sub check {
    my ($self, $symbol) = @_;

    for my $type (keys %{$template}){
        if (my @matches = $symbol =~ m/$template->{$type}{pattern}/){
            my @class = splice(@matches,$template->{$type}{class}-1,1)
                if defined $template->{$type}{class};

            my $returnObj;
            $returnObj->{type}   = $type;
            $returnObj->{symbol} = shift @matches;
            $returnObj->{class}  = shift @class if defined $class[0];
            $returnObj->{suffix} = shift @matches if defined $matches[0]; 

            return $returnObj;
        }
    }
    return undef;
}

sub convert {
    my ($self, $obj) = @_;

    my $outline = $template->{$obj->{type}}{template};

    return -1 unless defined $outline;

    $outline =~ s/=CLASS=/$obj->{class}/
        if defined $obj->{class};

    return $obj->{symbol}.$outline;
}


1;
