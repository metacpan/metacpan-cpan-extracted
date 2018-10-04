package Graphics::ColorNames::Werner;

# ABSTRACT: RGB codes for Werner's Nomenclature of Colours


use v5.6;

use strict;
use warnings;

# RECOMMEND PREREQ: Graphics::ColorNames

our $VERSION = 'v1.0.2';

sub NamesRgbTable() {
    use integer;
    return {
        applegreen              => 0xadba98,
        arterialbloodred        => 0x711518,
        ashgrey                 => 0xcbc8b7,
        asparagusgreen          => 0xc2c190,
        auriculapurple          => 0x533552,
        aurorared               => 0xcd6d57,
        azureblue               => 0x5c6b8f,
        berlinblue              => 0x7994b5,
        blackishbrown           => 0x453b32,
        blackishgreen           => 0x5d6161,
        blackishgrey            => 0x5b5c61,
        bluishblack             => 0x413f44,
        bluishgreen             => 0xa4b6a7,
        bluishgrey              => 0x9c9d9a,
        bluishlilacpurple       => 0xd0d5d3,
        bluishpurple            => 0x8590ae,
        broccolibrown           => 0x9b856b,
        brownishorange          => 0x92462f,
        brownishpurplered       => 0x8d746f,
        brownishred             => 0x6e3b31,
        bufforange              => 0xebbc71,
        campanulapurple         => 0x6c6d94,
        carminered              => 0xce536b,
        celadinegreen           => 0xb8bfaf,
        chestnutbrown           => 0x7a4b3a,
        chinablue               => 0x383867,
        chocolatered            => 0x4d3635,
        clovebrown              => 0x766051,
        cochinealred            => 0x7a4848,
        creamyellow             => 0xf3daa7,
        crimsonred              => 0xb7757c,
        deeporangecolouredbrown => 0x864735,
        deepreddishbrown        => 0x553d3a,
        deepreddishorange       => 0xbb603c,
        duckgreen               => 0x33431e,
        dutchorange             => 0xdfa837,
        emeraldgreen            => 0x93b778,
        flaxflowerblue          => 0x6f88af,
        fleshred                => 0xe9c49d,
        frenchgrey              => 0xbebeb3,
        gallstoneyellow         => 0xa36629,
        gambogeyellow           => 0xe6d058,
        grassgreen              => 0x7d8c55,
        greenishblack           => 0x454445,
        greenishblue            => 0x719ba2,
        greenishgrey            => 0x8a8d84,
        greenishwhite           => 0xf2ebcd,
        greyishblack            => 0x555152,
        greyishblue             => 0x8aa1a6,
        greyishwhite            => 0xe2ddc6,
        hairbrown               => 0x8b7859,
        honeyyellow             => 0xa77d35,
        hyacinthred             => 0xa75536,
        imperialpurple          => 0x584c77,
        indigoblue              => 0x4f638d,
        inkblack                => 0x252024,
        kingsyellow             => 0xead665,
        lakered                 => 0xb74a70,
        lavenderpurple          => 0x77747f,
        leekgreen               => 0x979c84,
        lemonyellow             => 0xdbc364,
        liverbrown              => 0x513e32,
        mountaingreen           => 0xb2b599,
        ochreyellow             => 0xefcc83,
        oilgreen                => 0xab924b,
        olivegreen              => 0x67765b,
        orangecolouredwhite     => 0xf3e9ca,
        orpimentorange          => 0xd17c3f,
        paleblackishpurple      => 0x4a475c,
        pansypurple             => 0x39334a,
        peachblossomred         => 0xeecfbf,
        pearlgrey               => 0xb7b5ac,
        pistachiogreen          => 0x8e9849,
        pitchorbrownishblack    => 0x423937,
        plumpurple              => 0x463759,
        primroseyellow          => 0xebdd99,
        prussianblue            => 0x1c1949,
        purplishred             => 0x612741,
        purplishwhite           => 0xece6d0,
        reddishblack            => 0x433635,
        reddishorange           => 0xbe7249,
        reddishwhite            => 0xf2e7cf,
        redlilacpurple          => 0xbfbac0,
        rosered                 => 0xeedac3,
        saffronyellow           => 0xd09b2c,
        sapgreen                => 0x7c8635,
        scarletred              => 0xb63e36,
        scotchblue              => 0x281f3f,
        siennayellow            => 0xf1d28c,
        siskingreen             => 0xc8c76f,
        skimmedmilkwhite        => 0xe6e1c9,
        smokegrey               => 0xbfbbb0,
        snowwhite               => 0xf1e9cd,
        strawyellow             => 0xf0d696,
        sulphuryellow           => 0xccc050,
        tilered                 => 0xc76b4a,
        ultramarineblue         => 0x657abb,
        umberbrown              => 0x613936,
        veinousbloodred         => 0x3f3033,
        velvetblack             => 0x241f20,
        verdigrisgreen          => 0x61ac86,
        verditterblue           => 0x6fb5a8,
        vermilionred            => 0xb5493a,
        violetpurple            => 0x3a2f52,
        waxyellow               => 0xab9649,
        wineyellow              => 0xd7c485,
        woodbrown               => 0xc39e6d,
        yellowishbrown          => 0x946943,
        yellowishgrey           => 0xbab191,
        yellowishwhite          => 0xf2eacc,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNames::Werner - RGB codes for Werner's Nomenclature of Colours

=head1 VERSION

version v1.0.2

=head1 SYNOPSIS

  require Graphics::ColorNames::Werner;

  $NameTable = Graphics::ColorNames::Werner->NamesRgbTable();
  $RgbBlack  = $NameTable->{asparagusgreen};

=head1 DESCRIPTION

This module defines color names and their associated RGB values
from the online version of
L<Werner's Nomenclature of Colors|https://www.c82.net/werner/>.
It is intended as a plugin for L<Graphics::ColorNames>.

Note that the color names have been normalized to lower case,
without and punctuation. However, they will use the original
spelling, e.g. "colour" instead of "color".

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Graphics-ColorNames-Werner>
and may be cloned from L<git://github.com/robrwo/Graphics-ColorNames-Werner.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Graphics-ColorNames-Werner/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Slaven Rezić

Slaven Rezić <slaven@rezic.de>

=head1 COPYRIGHT AND LICENSE


Robert Rothenberg has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
