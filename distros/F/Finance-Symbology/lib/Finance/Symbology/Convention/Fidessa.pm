package Finance::Symbology::Convention::Fidessa;

use strict;
use warnings;

our $VERSION = 0.3;

my $template = {
    'Preferred' => {
        pattern => qr/^([A-Z]+)(-)$/,
        template => '-',
    },
    'Preferred Class' => {
        pattern => qr/^([A-Z]+)(-([A-Z]))$/,
        template => '-=CLASS=',
        class => 3
    },
    'Class' => {
        pattern => qr/^([A-Z]+)(\.([A-Z]))$/,
        template => '.=CLASS=',
        class => 3
    },
    'Preferred when distributed' => {
        pattern => qr/^([A-Z]+)(-WD)$/,
        template => '-WD',
    },
    'When distributed' => {
        pattern => qr/^([A-Z]+)(!W$)/,
        template => '!W',
    },
    'Warrants' => {
        pattern => qr/^([A-Z]+)(\+)$/,
        template => '+',
    },
    'Warrants Class' => {
        pattern => qr/^([A-Z]+)(\+([A-Z]))$/,
        template => '+=CLASS=',
        class => 3
    },
    'Called' => {
        pattern => qr/^([A-Z]+)(!L)$/,
        template => '!',
    },
    'Class Called' => {
        pattern => qr/^([A-Z]+)(\.([A-Z])L)$/,
        template => '.=CLASS=L',
        class => 3
    },
    'Preferred Called' => {
        pattern => qr/^([A-Z]+)(-CL)$/,
        template => '-CL',
    },
    'Preferred Class Called' => {
        pattern => qr/^([A-Z]+)(-([A-Z])\.CL)$/,
        template => '-=CLASS=.CL',
        class => 3
    },
    'Preferred Class When Issued' => {
        pattern => qr/^([A-Z]+)(-([A-Z])\*)$/,
        template => '-=CLASS=*',
        class => 3
    },
    'Emerging Company Marketplace' => {
        pattern => qr/^([A-Z]+)(!EC)$/,
        template => '!EC',
    },
    'Partial Paid' => {
        pattern => qr/^([A-Z]+)(!PP)$/,
        template => '!PP',
    },
    'Convertible' => {
        pattern => qr/^([A-Z]+)(!V)$/,
        template => '!V',
    },
    'Convertible Called' => {
        pattern => qr/^([A-Z]+)(!VL)$/,
        template => '!VL',
    },
    'Class Convertible' => {
        pattern => qr/^([A-Z]+)(\.([A-Z])V)$/,
        template => '.=CLASS=V',
        class => 3
    },
    'Preferred Class Convertible' => {
        pattern => qr/^([A-Z]+)(-([A-Z])V)$/,
        template => '-=CLASS=V',
        class => 3
    },
    'Preferred Class When Distributed' => {
        pattern => qr/^([A-Z]+)(-([A-Z])WD)$/,
        template => '-=CLASS=WD',
        class => 3
    },
    'Rights' => {
        pattern => qr/^([A-Z]+)(!R)$/,
        template => '!R',
    },
    'Units' => {
        pattern => qr/^([A-Z]+)(\.U)$/,
        template => '.U',
    },
    'When Issued' => {
        pattern => qr/^([A-Z]+)(\*)$/,
        template => '*',
    },
    'Rights When Issued' => {
        pattern => qr/^([A-Z]+)(!R\*)$/,
        template => '!R*',
    },
    'Preferred When Issued' => {
        pattern => qr/^([A-Z]+)(-\*)$/,
        template => '-*',
    },
    'Class When Issued' => {
        pattern => qr/^([A-Z]+)(\.([A-Z])\*)$/,
        template => '.=CLASS=*',
        class => 3
    },
    'Warrant When Issued' => {
        pattern => qr/^([A-Z]+)(\+\*)$/,
        template => '+*',
    },
    'TEST Symbol' => {
        pattern => qr/^([A-Z]+)(\.CT)$/,
        template => '/TEST' },
    #Fidessa only symbols
    'Special' => {
        pattern => qr/^([A-Z]+)(\.SP)$/
    },
    'Stamped' => {
        pattern => qr/^([A-Z]+)(\.SD)$/
    },
    'With Warrants' => {
        pattern => qr/^([A-Z]+)(:W)$/
    },
    'Without Warrants' => {
        pattern => qr/^([A-Z]+)(:XW)$/
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
