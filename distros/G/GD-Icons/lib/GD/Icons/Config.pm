package GD::Icons::Config;

our $VERSION = '0.04';

# $Id: Config.pm,v 1.9 2007/08/28 14:16:32 canaran Exp $

use warnings;
use strict;

use Carp;
use Config::General;
use Tie::IxHash;

our $DEFAULT_OBJ = GD::Icons::Config->new;

###############
# CONSTRUCTOR #
###############

sub new {
    my ($class, $config_file) = @_;

    my $self = bless {}, $class;

    if ($config_file) {
        my $config = new Config::General($config_file);
        tie my %config, "Tie::IxHash";
        %config = $config->getall;
        $self->config(\%config);
    }
    else {
        tie my %config, "Tie::IxHash";
        %config = (
            shape => $self->_all_shapes,
            color => $self->_all_colors,
        );
        $self->config(\%config);
    }

    return $self;
}

# Function  : Get/set method
# Arguments : $value
# Returns   : $value
# Notes     : None provided.

sub config {
    my ($self, $value) = @_;
    $self->{config} = $value if @_ > 1;
    return $self->{config};
}

# Function  : Command line listing of default config info
# Arguments : None
# Returns   : 1
# Notes     : Usage: perl -MGD::Icons::Config -e GD::Icons::Config::list

sub list {
    my ($self) = @_;

    my $all_shapes = $DEFAULT_OBJ->_all_shapes;
    my $all_colors = $DEFAULT_OBJ->_all_colors;

    my $list = "*** GD::Icons::Config Version $VERSION - Default Configuration ***\n\n";

    $list .= "# SHAPES\n\n";
    foreach (sort keys %{$all_shapes}) {
        $list .= sprintf('%-20s%s', $_, $all_shapes->{$_}) . "\n";
    }   

    $list .= "\n# COLORS \n\n";
    foreach (sort keys %{$all_colors}) {
        $list .= sprintf('%-20s%s', $_, $all_colors->{$_}) . "\n";
    }   

    print $list;

    return 1;
}

#######################
# Data storage methos #
#######################

# Function  : Get (storge) method for default shapes
# Arguments : None
# Returns   : \%all
# Notes     : This is a private method.

sub _all_shapes {
    my ($self) = @_;

    tie my %all, "Tie::IxHash";

    %all = (
        'square' =>
          qq(sl[11] lt[1] lc[_Black] py[0,0 10,0 10,10 0,10 0,0]         fl[5,5]),
        'triangle' =>
          qq(sl[11] lt[1] lc[_Black] py[5,0 10,10 0,10 5,0]              fl[5,5]),
        'diamond' =>
          qq(sl[11] lt[1] lc[_Black] py[5,0 0,5 5,10 10,5 5,0]           fl[5,5]),
        'l-shape' =>
          qq(sl[11] lt[1] lc[_Black] py[0,0 5,0 5,5 10,5 10,10 0,10 0,0] fl[3,3]),
        'pi' =>
          qq(sl[11] lt[1] lc[_Black] py[0,0 10,0 10,4 8,4 8,10 6,10 6,4 4,4 4,10 2,10 2,4 0,4 0,0] fl[2,2]),
        'plus' =>
          qq(sl[11] lt[1] lc[_Black] py[3,0 7,0 7,3 10,3 10,7 7,7 7,10 3,10 3,7 0,7 0,3 3,3 3,0] fl[4,4]),
        'square-pieces' =>
          qq(sl[11] lt[1] lc[_Black] py[0,0 10,0 10,4 8,4 8,6 10,6 10,10 0,10 0,6 2,6 2,4 0,4 0,0] fl[5,5]),
        'sand-clock' =>
          qq(sl[11] lt[1] lc[_Black] py[0,0 10,0 5,5 10,10 0,10 5,5 0,0] fl[5,2] fl[5,8]),
        '_padded-square' =>
          qq(sl[11] lt[1] lc[:fill]  py[0,0 0,9 9,9 0,9 0,0]             fl[5,5]),
        '_large_square' =>
          qq(sl[22] lt[1] lc[_Black] py[0,0 21,0 21,21 0,21 0,0]         fl[5,5]),
        '_letter-m' =>
          qq(sl[11] lt[1] lc[_Black] py[0,1 3,1 5,3 7,1 10,1 10,9 7,9 7,4 5,6 3,4 3,9 0,9 0,1] fl[2,2]),
        '_number-flag' =>
          qq(sl[14] lt[1] lc[_Black] py[0,0 13,0 13,13 0,13 0,0] fl[5,5] nm[:auto]),
    );

    return \%all;
}

# Function  : Get (storge) method for default colors
# Arguments : None
# Returns   : \%all
# Notes     : This is a private method..

sub _all_colors {
    my ($self) = @_;

    tie my %all, "Tie::IxHash";

    %all = (
        Blue                 => '#0000FF',
        BlueViolet           => '#8A2BE2',
        Brown                => '#A52A2A',
        BurlyWood            => '#DEB887',
        CadetBlue            => '#5F9EA0',
        Chartreuse           => '#7FFF00',
        Chocolate            => '#D2691E',
        Coral                => '#FF7F50',
        CornflowerBlue       => '#6495ED',
        Cornsilk             => '#FFF8DC',
        Crimson              => '#DC143C',
        Cyan                 => '#00FFFF',
        DarkBlue             => '#00008B',
        DarkGreen            => '#006400',
        DarkKhaki            => '#BDB76B',
        DarkOliveGreen       => '#556B2F',
        Darkorange           => '#FF8C00',
        DarkSalmon           => '#E9967A',
        DarkSeaGreen         => '#8FBC8F',
        DarkSlateBlue        => '#483D8B',
        DarkTurquoise        => '#00CED1',
        DodgerBlue           => '#1E90FF',
        ForestGreen          => '#228B22',
        Gold                 => '#FFD700',
        Gray                 => '#808080',
        Green                => '#008000',
        GreenYellow          => '#ADFF2F',
        Indigo               => '#4B0082',
        Khaki                => '#F0E68C',
        Lavender             => '#E6E6FA',
        LavenderBlush        => '#FFF0F5',
        LemonChiffon         => '#FFFACD',
        LightBlue            => '#ADD8E6',
        LightCoral           => '#F08080',
        LightCyan            => '#E0FFFF',
        LightGoldenRodYellow => '#FAFAD2',
        LightGray            => '#D3D3D3',
        LightGrey            => '#D3D3D3',
        LightGreen           => '#90EE90',
        LightPink            => '#FFB6C1',
        LightSalmon          => '#FFA07A',
        LightSeaGreen        => '#20B2AA',
        LightSkyBlue         => '#87CEFA',
        LightSlateGray       => '#778899',
        LightSteelBlue       => '#B0C4DE',
        LightYellow          => '#FFFFE0',
        Maroon               => '#800000',
        MediumBlue           => '#0000CD',
        MidnightBlue         => '#191970',
        MistyRose            => '#FFE4E1',
        Moccasin             => '#FFE4B5',
        Navy                 => '#000080',
        Olive                => '#808000',
        OliveDrab            => '#6B8E23',
        Orange               => '#FFA500',
        OrangeRed            => '#FF4500',
        Orchid               => '#DA70D6',
        PowderBlue           => '#B0E0E6',
        Purple               => '#800080',
        Red                  => '#FF0000',
        RosyBrown            => '#BC8F8F',
        RoyalBlue            => '#4169E1',
        SaddleBrown          => '#8B4513',
        Salmon               => '#FA8072',
        SandyBrown           => '#F4A460',
        SeaGreen             => '#2E8B57',
        SeaShell             => '#FFF5EE',
        Sienna               => '#A0522D',
        Silver               => '#C0C0C0',
        SkyBlue              => '#87CEEB',
        SlateBlue            => '#6A5ACD',
        SlateGray            => '#708090',
        SpringGreen          => '#00FF7F',
        SteelBlue            => '#4682B4',
        Tan                  => '#D2B48C',
        Teal                 => '#008080',
        Thistle              => '#D8BFD8',
        Tomato               => '#FF6347',
        Turquoise            => '#40E0D0',
        Violet               => '#EE82EE',
        Wheat                => '#F5DEB3',
        Yellow               => '#FFFF00',
        YellowGreen          => '#9ACD32',
        _Black               => '#000000',
        _White               => '#FFFFFF',
    );

    return \%all;
}

1;

__END__

=head1 NAME

GD::Icons::Config - Config module for GD::Icons

=head1 SYNOPSIS

 my $obj = GD::Icons::Config->new;
 my $config_ref = $obj->config;

 OR

 my $obj = GD::Icons::Config->new('config_file.txt');
 my $config_ref = $obj->config;

=head1 DESCRIPTION

This module provides config information for GD::Icons::Config.

=head1 USAGE

This module is not intended to be used directly. Please refer
to GD::Icons documentation for details.

The default values can be obtained by:

 perl -MGD::Icons::Config -e GD::Icons::Config::list

=head1 AUTHOR

Payan Canaran <pcanaran@cpan.org>

=head1 BUGS

=head1 VERSION

Version 0.04

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) 2006-2007 Cold Spring Harbor Laboratory

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See DISCLAIMER.txt for
disclaimers of warranty.

=cut

