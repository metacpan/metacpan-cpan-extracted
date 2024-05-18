package HashData::Color::CMYK::JohnDecemberCom;

use strict;
use Role::Tiny::With;
with 'HashDataRole::Source::LinesInDATA';
#with 'Role::TinyCommons::Collection::FindItem::Iterator';         # add find_item() (has_item already added above)
#with 'Role::TinyCommons::Collection::PickItems::RandomSeekLines'; # add pick_items() that uses binary search

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'HashData-Color-CMYK-JohnDecemberCom'; # DIST
our $VERSION = '0.001'; # VERSION

# STATS

1;
# ABSTRACT: CMYK color names (from johndecember.com)

=pod

=encoding UTF-8

=head1 NAME

HashData::Color::CMYK::JohnDecemberCom - CMYK color names (from johndecember.com)

=head1 VERSION

This document describes version 0.001 of HashData::Color::CMYK::JohnDecemberCom (from Perl distribution HashData-Color-CMYK-JohnDecemberCom), released on 2024-05-06.

=head1 DESCRIPTION

CMKY value are in this format: I<C>,I<M>,I<Y>,I<K>. Where each C/M/Y/K value is
an integer from 0 to 100.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/HashData-Color-CMYK-JohnDecemberCom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-HashData-Color-CMYK-JohnDecemberCom>.

=head1 SEE ALSO

Source: L<https://johndecember.com/html/spec/colorcmyk.html>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=HashData-Color-CMYK-JohnDecemberCom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
alaska sky:81,55,0,45
aliceblue (svg):6,3,0,0
aluminum:7,5,0,29
amethyst:0,32,16,38
anjou pear:0,6,96,27
antiquewhite1:0,6,14,0
antiquewhite4:0,6,14,45
antiquewhite (svg):0,6,14,2
apricot:0,36,57,2
aquamarine4:50,0,17,45
aquamarine:49,0,33,14
aquamarine (svg):50,0,17,0
aquarium:72,0,12,33
ash:0,2,9,22
avacado:16,0,55,24
azure3:6,0,0,20
barney:0,77,34,17
bartlett pear:0,17,78,20
battleship:1,0,7,18
beach sand:0,10,26,7
beige (svg):0,0,10,4
bisque3:0,11,23,20
blackberry:0,0,3,77
black (safe 16 svg hex3):0,0,0,100
bloodorange (hex3):0,92,100,20
bloodred (safe hex3):0,100,100,60
blueberry fresh:49,35,0,32
blue corn chips:0,11,2,65
bluegrass:32,0,11,56
blue ice:11,0,2,4
blue jeans:39,24,0,58
blue line:77,27,0,13
blue ridge mtns:65,37,0,19
bone (safe hex3):0,0,20,0
bordeaux:0,84,71,40
breadfruit:15,0,75,39
brightgold:0,0,88,15
bright red (safe hex3):0,100,80,0
bronzeii:0,25,63,35
brown2:0,75,75,7
brown4:0,75,75,45
brownmadder:0,81,81,14
brownochre:0,51,77,47
brown (svg):0,75,75,35
brushed aluminum:8,0,4,23
bubble gum:0,43,27,0
burlywood (svg):0,17,39,13
buttermilk:0,5,29,0
cadetblue3:40,4,0,20
cadetblue:40,0,0,38
cadmiumorange:0,62,99,0
cadmiumredlight:0,99,95,0
cafe americano:0,26,54,79
camo2:16,0,18,21
canvas:0,13,48,38
carnation:0,40,20,13
cashew:0,22,48,13
cat eye:17,0,63,10
cat eye:45,24,0,13
chartreuse3:50,0,100,20
cherry:0,60,57,8
chili:0,66,69,17
chocolate1:0,50,86,0
chocolate3:0,50,86,20
chromeoxidegreen:20,0,84,50
cichlid:100,76,0,0
cinnabargreen:46,0,77,30
circuit board:43,0,60,60
clover:61,0,47,37
cobaltgreen:58,0,56,43
cobalt (safe hex3):60,60,0,0
cobaltvioletdeep:8,79,0,38
coconut:0,1,19,0
coconut shell:0,37,65,26
coffee:0,51,98,33
concord grape:33,99,0,40
cooler:45,0,10,71
coral1:0,55,66,0
cornsilk2:0,3,14,7
cornsilk3:0,2,14,20
cornsilk4:0,2,14,45
cornsilk (svg):0,3,14,0
cotton candy:0,28,12,3
cranberry:0,73,41,29
cream city brick:0,2,20,11
crimson (svg):0,91,73,14
cucumber:53,0,32,64
curacao:51,52,0,27
cyan2 (hex3):100,0,0,7
darkgoldenrod1:0,27,94,0
darkgoldenrod (svg):0,27,94,28
darkgray (svg):0,0,0,34
darkgreencopper:37,0,7,54
darkgrey (svg):0,0,0,34
darkkhaki (svg):0,3,43,26
darkmagenta (svg):0,100,0,45
darkolivegreen:0,0,41,69
darkolivegreen3:21,0,56,20
darkorange1:0,50,100,0
darkorange4:0,50,100,45
darkorange (svg):0,45,100,0
darkorchid1:25,76,0,0
darkorchid:25,76,0,20
darkseagreen2:24,0,24,7
darkseagreen4:24,0,24,45
darkslateblue (svg):48,56,0,45
darkslategray1:41,0,0,0
darkslategray4:41,0,0,45
darktan:0,30,48,41
darkviolet (svg):30,100,0,17
dark wheat:0,14,44,9
darkwood:0,29,50,48
deeppink3:0,92,42,20
deepskyblue3:100,25,0,20
deepskyblue (svg):100,25,0,0
delft:69,55,0,58
denim:61,33,0,33
desert sand:0,9,16,0
diamond blue:94,18,0,9
dimgray (svg):0,0,0,59
dimgrey (svg):0,0,0,59
dodgerblue3:88,43,0,20
dodgerblue4:88,44,0,45
dog tongue:0,33,13,4
eggplant:4,24,0,47
englishred:0,71,88,17
eton blue:25,0,19,22
fenway monster:39,2,0,52
firebrick4:0,81,81,45
fire truck green:5,0,98,16
flatpink (safe hex3):0,20,20,0
floralwhite (svg):0,2,6,0
fog:0,0,10,20
fraser fir:28,0,25,58
fresh green:57,0,28,15
fuchsia2 (hex3):0,100,33,0
gainsboro (svg):0,0,0,14
ganegreen (hex3):0,0,57,53
garden hose:87,0,26,44
gold4:0,16,100,45
gold5:0,38,75,20
goldenrod:0,0,49,14
goldenrod2:0,24,86,7
goldochre:0,40,81,22
gold (svg):0,16,100,0
grapefruit:0,5,42,5
grass:59,0,73,26
gray:0,0,0,25
gray10:0,0,0,90
gray1:0,0,0,99
gray11:0,0,0,89
gray12:0,0,0,88
gray13:0,0,0,87
gray14:0,0,0,86
gray15:0,0,0,85
gray16:0,0,0,84
gray (16 svg):0,0,0,50
gray17:0,0,0,83
gray18:0,0,0,82
gray19:0,0,0,81
gray2:0,0,0,98
gray20 (safe hex3):0,0,0,80
gray21:0,0,0,79
gray22:0,0,0,78
gray23:0,0,0,77
gray24:0,0,0,76
gray25:0,0,0,75
gray26:0,0,0,74
gray27:0,0,0,73
gray28:0,0,0,72
gray29:0,0,0,71
gray30:0,0,0,70
gray3:0,0,0,97
gray31:0,0,0,69
gray32:0,0,0,68
gray33 (hex3):0,0,0,67
gray34:0,0,0,66
gray35:0,0,0,65
gray36:0,0,0,64
gray37:0,0,0,63
gray38:0,0,0,62
gray39:0,0,0,61
gray4:0,0,0,96
gray40 (safe hex3):0,0,0,60
gray42:0,0,0,58
gray43:0,0,0,57
gray44:0,0,0,56
gray45:0,0,0,55
gray46:0,0,0,54
gray47:0,0,0,53
gray48:0,0,0,52
gray49:0,0,0,51
gray50:0,0,0,50
gray5:0,0,0,95
gray51:0,0,0,49
gray52:0,0,0,48
gray53:0,0,0,47
gray54:0,0,0,46
gray55:0,0,0,45
gray56:0,0,0,44
gray57:0,0,0,43
gray58:0,0,0,42
gray59:0,0,0,41
gray6:0,0,0,94
gray60 (safe hex3):0,0,0,40
gray61:0,0,0,39
gray62:0,0,0,38
gray63:0,0,0,37
gray64:0,0,0,36
gray65:0,0,0,35
gray66:0,0,0,34
gray67:0,0,0,33
gray68:0,0,0,32
gray69:0,0,0,31
gray70:0,0,0,30
gray7:0,0,0,93
gray71:0,0,0,29
gray72:0,0,0,28
gray73:0,0,0,27
gray74:0,0,0,26
gray75:0,0,0,25
gray76:0,0,0,24
gray77:0,0,0,23
gray78:0,0,0,22
gray79:0,0,0,21
gray8:0,0,0,92
gray80 (safe hex3):0,0,0,20
gray81:0,0,0,19
gray82:0,0,0,18
gray83:0,0,0,17
gray84:0,0,0,16
gray85:0,0,0,15
gray86:0,0,0,14
gray87:0,0,0,13
gray88:0,0,0,12
gray89:0,0,0,11
gray90:0,0,0,10
gray9:0,0,0,91
gray91:0,0,0,9
gray92:0,0,0,8
gray93:0,0,0,7
gray94:0,0,0,6
gray95:0,0,0,5
gray97:0,0,0,3
gray98:0,0,0,2
gray99:0,0,0,1
green (16 svg):100,0,100,50
green3:100,0,100,20
green algae:42,0,43,33
green apple:35,0,67,41
green ash:28,0,6,44
green card:17,0,5,2
green gables:47,0,8,54
green grape:0,1,90,19
green lantern:56,0,60,45
green led:63,0,96,1
green mist:21,0,39,7
green pepper:54,0,98,51
green stamp:34,0,28,52
greenyellow:33,0,49,14
greenyellow (svg):32,0,82,0
grey (16 svg):0,0,0,50
guacamole:23,0,38,16
gummi yellow:0,13,95,2
heather blue:12,6,0,18
honeydew2:6,0,6,7
hotpink (svg):0,59,29,0
iceberg lettuce:10,0,50,11
indianred1:0,58,58,0
indiglo:98,9,0,0
indigo dye:91,43,0,45
indigo (svg):42,100,0,49
ivory2:0,0,6,7
ivory3:0,0,6,20
ivory4:0,0,6,45
ivory (svg):0,0,6,0
jonathan apple:0,63,76,30
kermit:14,0,90,26
khaki:0,0,40,38
khaki1:0,4,44,0
khaki2:0,3,44,7
khaki3:0,3,44,20
khaki4:0,4,44,45
khaki (svg):0,4,42,6
kiwi:18,0,34,40
kumquat:0,38,96,14
lake huron:37,16,0,42
lake michigan:59,14,0,24
lake superior:41,22,0,47
la maison bleue:62,31,0,0
lavenderblush2:0,6,4,7
lavenderblush3:0,6,4,20
lavenderblush4:0,6,4,45
lavenderblush (svg):0,6,4,0
lavender field:2,37,0,53
lavender (safe hex3):0,25,0,20
lemonchiffon2:0,2,20,7
lemonchiffon3:0,2,20,20
lemonchiffon4:0,1,19,45
lemonchiffon (svg):0,2,20,0
lightblue (svg):25,6,0,10
light copper:0,18,38,7
light cyan3:12,0,0,20
lightcyan (svg):12,0,0,0
light goldenrod2:0,8,45,7
light goldenrod3:0,7,45,20
lightgoldenrodyellow (svg):0,0,16,2
lightgray (svg):0,0,0,17
light green (svg):39,0,39,7
lightgrey (svg):0,0,0,17
light pink1:0,32,27,0
light pink3:0,32,27,20
light salmon2:0,37,52,7
light skyblue1:31,11,0,0
light skyblue4:31,12,0,45
light slateblue:48,56,0,0
light steelblue1:21,12,0,0
light steelblue3:21,12,0,20
light wood:0,17,29,9
light yellow2:0,0,12,7
light yellow3:0,0,12,20
light yellow4:0,0,12,45
lightyellow (svg):0,0,12,0
limepulp:11,0,39,7
lindsay eyes:34,6,0,40
linen (svg):0,4,8,2
liz eyes:57,21,0,55
magenta2 (hex3):0,100,0,7
mailbox:71,40,0,35
manatee gray:0,6,7,31
mandarianorange:0,47,78,11
maroon3:0,80,30,20
maroon4:0,80,29,45
maroon5:0,70,99,59
marsorange:0,54,87,41
masters jacket:64,0,13,75
medium aquamarine2:75,0,25,20
medium aquamarine3:76,0,25,20
medium blue:75,75,0,20
mediumblue (svg):100,100,0,20
medium goldenrod:0,0,26,8
mediumorchid (svg):12,60,0,17
medium purple1:33,49,0,0
medium purple3:33,49,0,20
medium seagreen:41,0,41,56
mediumseagreen (svg):66,0,37,30
medium slateblue2:50,100,0,0
mediumvioletred (svg):0,89,33,22
medium wood:0,23,40,35
midnightblue:41,41,0,69
mint blue:14,0,2,0
mintcream (svg):4,0,2,0
mint ice cream:13,0,16,11
mistyrose3:0,11,12,20
naplesyellowdeep:0,34,93,0
natural turquoise:65,0,6,24
navajowhite2:0,13,32,7
navy (16 svg):100,100,0,50
neonavocado (safe hex3):100,0,60,0
neonblue:70,70,0,0
neonpink:0,57,22,0
newtan:0,15,33,8
od green:15,0,27,68
offwhitegreen (safe hex3):20,0,20,0
oldlace (svg):0,3,9,1
old money:55,0,37,56
olive (16 svg):0,0,100,50
olive3b:37,0,54,63
olivedrab (svg):25,0,75,44
orange4:0,35,100,45
orangered:0,86,100,0
orangered2:0,73,100,7
orange (svg):0,35,100,0
orchid4:0,49,1,45
orchid (svg):0,49,2,15
pabst blue:72,60,0,44
pacific blue:51,19,0,58
packer gold:0,28,92,1
palegoldenrod (svg):0,3,29,7
palegreen3:40,0,40,20
paleturquoise1 (hex3):27,0,0,0
paleturquoise4:27,0,0,45
palevioletred2:0,49,33,7
palevioletred4:0,49,33,45
papaya:0,0,51,0
park ranger:6,0,9,70
parrot:76,45,0,14
parrotgreen (safe hex3):80,0,80,0
pastel blue:22,2,0,4
peach:0,6,14,0
peachpuff (svg):0,15,27,0
pear:8,0,78,11
permanent redviolet:0,83,68,14
peru (svg):0,35,69,20
picasso blue:99,53,0,1
pickle:0,2,72,52
pinegreen (safe hex3):100,0,100,80
pink2:0,29,23,7
pink candy:0,26,7,14
pink glass:0,10,2,17
pistachio shell:0,12,27,8
plum2:0,27,0,7
plum pudding:0,69,40,47
police strobe:96,29,0,0
pool table:74,0,58,27
popcornyellow (hex3):0,0,33,0
powderblue (svg):23,3,0,10
presidential blue:43,49,0,67
purple3:39,81,0,20
purple ink:0,31,3,39
purple rose:22,63,0,53
ralphyellow (safe hex3):0,0,100,20
red3:0,100,100,20
red roof:0,53,61,22
robin's egg:18,4,0,7
romaine lettuce:29,0,58,67
rosemadder:0,76,75,11
rosybrown2:0,24,24,7
rosybrown4:0,24,24,45
royalblue2:72,54,0,7
ruby red:0,81,73,22
safety cone:0,67,80,0
salmon1:0,45,59,0
salmon4:0,45,59,45
sandybrown (svg):0,33,61,4
scotland pound:36,0,27,56
seagreen3:67,0,38,20
seagreen (svg):67,0,37,45
seashell2:0,4,7,7
seashell3:0,4,7,20
seashell4:0,4,6,45
seashell (svg):0,4,7,0
semisweet chocolate1:0,38,64,58
sgibrightgray:0,2,14,23
sgilight gray (hex3):0,0,0,33
sgiolivedrab:0,0,61,44
sienna2:0,49,72,7
sienna4:0,49,73,45
sign orange:0,47,100,13
silver (16 svg):0,0,0,25
skyblue1:47,19,0,0
skyblue4:47,19,0,45
slateblue:100,50,0,0
slateblue3:49,57,0,20
slategray3:22,11,0,20
slategrey (svg):22,11,0,44
snow2:0,2,2,7
snow3:0,2,2,20
snow4:0,1,1,45
snow (svg):0,2,2,0
springgreen4:100,0,50,45
springgreen (safe hex3):100,0,80,0
springgreen (svg):100,0,50,0
stained glass:82,78,0,0
stainless steel:0,0,2,12
steelblue3:61,28,0,20
strawberry:0,80,81,25
summersky:75,21,0,13
sweet potato vine:19,0,71,21
tangerine:0,55,91,0
tank:0,3,35,62
tan (svg):0,14,33,18
teal (16 svg):100,0,0,50
terreverte:40,0,84,63
thistle1:0,12,0,0
thistle3:0,12,0,20
titanium:0,4,7,29
tomato4:0,61,73,45
tomato (svg):0,61,72,0
turquoise2:100,4,0,7
turquoise:26,0,0,8
turquoiseblue:100,0,30,22
vandykebrown:0,60,95,63
venetianred:0,88,85,17
verylight grey:0,0,0,20
violet:0,41,0,69
violet flower:25,63,0,0
violetred:0,75,25,20
violetred3:0,76,41,20
warmgrey:0,0,18,50
wasabi (safe hex3):60,0,60,0
wavecrest:25,0,2,20
wheat:0,0,12,15
wheat1:0,9,27,0
wheat3:0,9,27,20
white (safe 16 svg hex3):0,0,0,0
whitesmoke (svg):0,0,0,4
yellow2 (hex3):0,0,100,7
yellow3:0,0,100,20
yellow4:0,0,100,45
yellow candy:0,1,41,7
yellowgreen (svg):25,0,76,20
yellowochre:0,43,90,11
yellow perch:0,4,49,12
yellow (safe 16 svg hex3):0,0,100,0
yinmn blue:68,44,0,44
