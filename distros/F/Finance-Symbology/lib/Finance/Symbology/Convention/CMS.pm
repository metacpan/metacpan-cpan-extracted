package Finance::Symbology::Convention::CMS;

use strict;
use warnings;

our $VERSION = 0.2;

my $template = {
    'Preferred' => {
        pattern => qr/^([A-Z]+)\s(PR)$/,
        template => ' PR'
    },
    'Preferred Class' => {
        pattern => qr/^([A-Z]+)\s(PR)([A-Z])$/,
        template => ' PR=CLASS=',
        class => 3
    },
    'Class' => {
        pattern => qr/^([A-Z]+)\s([A-Z])$/ ,
        template => ' =CLASS=',
        class => 2
    },
    'Preferred when distributed' => {
        pattern => qr/^([A-Z]+)\s(PRWD)$/,
        template => ' PRWD'
    },
    'When distributed' => {
        pattern => qr/^([A-Z]+)\s(WD)$/,
        template => ' WD'
    },
    'Warrants' => {
        pattern => qr/^([A-Z]+)\s(WS)$/,
        template => ' WS'
    },
    'Warrants Class' => {
        pattern => qr/^([A-Z]+)\s(WS)([A-Z])$/,
        template => ' WS=CLASS=',
        class => 3
    },
    'Called' => {
        pattern => qr/^([A-Z]+)\s(CL)$/,
        template => ' CL'
    },
    'Class Called' => {
        pattern => qr/^([A-Z]+)\s([A-Z])(CL)$/,
        template => ' =CLASSCL',
        class => 2
    },
    'Preferred Called' => {
        pattern => qr/^([A-Z]+)\s(PRCL)$/,
        template => ' PRCL'
    },
    'Preferred Class Called' => {
        pattern => qr/^([A-Z]+)\s(PR([A-Z])CL)$/,
        template => ' PR=CLASS=CL',
        class => 3
    },
    'Preferred Class When Issued' => {
        pattern => qr/^([A-Z]+)\s(PR([A-Z])WI)$/,
        template => ' PR=CLASS=WI'
    },
    'Emerging Company Marketplace' => {
        pattern => qr/^([A-Z]+)\s(EC)$/,
        template => ' EC'
    },
    'Partial Paid' => {
        pattern => qr/^([A-Z]+)\s(PP)$/,
        template => ' PP'
    },
    'Convertible' => {
        pattern => qr/^([A-Z]+)\s(CV)$/,
        template => ' CV'
    },
    'Convertible Called' => {
        pattern => qr/^([A-Z]+)\s(CVCL)$/,
        template => ' CVCL'
    },
    'Class Convertible' => {
        pattern => qr/^([A-Z]+)\s([A-Z])(CV)$/,
        template => ' =CLASS=CV',
        class => 2
    },
    'Preferred Class Convertible' => {
        pattern => qr/^([A-Z]+)\s(PR([A-Z])CV)$/,
        template => ' PR=CLASS=CV',
        class => 3
    },
    'Preferred Class When Distributed' => {
        pattern => qr/^([A-Z]+)\s(PR([A-Z])WD)$/,
        template => ' PR=CLASS=WD',
        class => 3
    },
    'Rights' => {
        pattern => qr/^([A-Z]+)\s(RT)$/,
        template => ' RT'
    },
    'Units' => {
        pattern => qr/^([A-Z]+)\s(U)$/,
        template => ' U'
    },
    'When Issued' => {
        pattern => qr/^([A-Z]+)\s(WI)$/,
        template => ' WI'
    },
    'Rights When Issued' => {
        pattern => qr/^([A-Z]+)\s(RTWI)$/,
        template => ' RTWI'
    },
    'Preferred When Issued' => {
        pattern => qr/^([A-Z]+)\s(PRWI)$/,
        template => ' PRWI'
    },
    'Class When Issued' => {
        pattern => qr/^([A-Z]+)\s([A-Z])(WI)$/,
        template => ' =CLASS=WI',
        class => 2
    },
    'Warrant When Issued' => {
        pattern => qr/^([A-Z]+)\s(WSWI)$/,
        template => ' WSWI'
    },
    'TEST Symbol' => {
        pattern => qr/^([A-Z]+)\s(TEST)$/,
        template => ' TEST'
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
