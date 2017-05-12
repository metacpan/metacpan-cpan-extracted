package Finance::Symbology::Convention::NASDAQ::Integrated;

use strict;
use warnings;

our $VERSION = 0.2;

my $template = {
    'Preferred' => {
        template => '-',
        pattern => qr/^([A-Z]+)(-)$/ 
    },
    'Preferred Class' => {
        template => '-=CLASS=',
        pattern => qr/^([A-Z]+)(-([A-Z]))$/,
        class => 3
    },
    'Class' => {
        template => '.=CLASS=',
        pattern => qr/^([A-Z]+)(\.([A-Z]))$/,
        class => 3 
    },
    'Preferred when distributed' => {
        template => '-$',
        pattern => qr/^([A-Z]+)(-\$)$/ 
    },
    'When distributed' => {
        template => '$',
        pattern => qr/^([A-Z]+)(\$)$/ 
    },
    'Warrants' => {
        template => '+',
        pattern => qr/^([A-Z]+)(\+)$/ 
    },
    'Warrants Class' => {
        template => '+=CLASS=',
        pattern => qr/^([A-Z]+)(\+([A-Z]))$/ ,
        class => 3
    },
    'Called' => {
        template => '*',
        pattern => qr/^([A-Z]+)(\*)$/ 
    },
    'Class Called' => {
        template => '.=CLASS=*',
        pattern => qr/^([A-Z]+)(\.([A-Z])\*)$/,
        class => 3 
    },
    'Preferred Called' => {
        template => '-*',
        pattern => qr/^([A-Z]+)(-\*)$/ 
    },
    'Preferred Class Called' => {
        template => '-=CLASS=*',
        pattern => qr/^([A-Z]+)(-([A-Z])\*)$/,
        class => 3
    },
    'Preferred Class When Issued' => {
        template => '-=CLASS=#',
        pattern => qr/^([A-Z]+)(-([A-Z])#)$/,
        class => 3
    },
    'Emerging Company Marketplace' => {
        template => '!',
        pattern => qr/^([A-Z]+)(!)$/ 
    },
    'Partial Paid' => {
        template => '@',
        pattern => qr/^([A-Z]+)(\@)$/ 
    },
    'Convertible' => {
        template => '%',
        pattern => qr/^([A-Z]+)(\%)$/ 
    },
    'Convertible Called' => {
        template => '%*',
        pattern => qr/^([A-Z]+)(\%\*)$/ 
    },
    'Class Convertible' => {
        template => '.=CLASS=%',
        pattern => qr/^([A-Z]+)(\.([A-Z])\%)$/,
        class => 3
    },
    'Preferred Class Convertible' => {
        template => '-=CLASS=%',
        pattern => qr/^([A-Z]+)(-([A-Z])\%)$/ ,
        class => 3
    },
    'Preferred Class When Distributed' => {
        template => '-=CLASS=$',
        pattern => qr/^([A-Z]+)(-([A-Z])\$)$/ ,
        class => 3
    },
    'Rights' => {
        template => '^',
        pattern => qr/^([A-Z]+)(\^)$/ 
    },
    'Units' => {
        template => '=',
        pattern => qr/^([A-Z]+)(=)$/ 
    },
    'When Issued' => {
        template => '#',
        pattern => qr/^([A-Z]+)(#)$/ 
    },
    'Rights When Issued' => {
        template => '^#',
        pattern => qr/^[A-Z]+\^#$/ 
    },
    'Preferred When Issued' => {
        template => '-#',
        pattern => qr/^([A-Z]+)(-#)$/ 
    },
    'Class When Issued' => {
        template => '.=CLASS=#',
        pattern => qr/^([A-Z]+)(\.([A-Z])#)$/ ,
        class => 3
    },
    'Warrant When Issued' => {
        template => '+#',
        pattern => qr/^[A-Z]+\+#$/ 
    },
    'TEST Symbol' => {
        template => '~', 
        pattern => qr/^([A-Z]+)(~)$/
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
