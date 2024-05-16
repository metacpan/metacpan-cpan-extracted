package Graphics::ColorNamesCMYK::ToutesLesCouleursCom;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-06'; # DATE
our $DIST = 'Graphics-ColorNamesCMYK-ToutesLesCouleursCom'; # DIST
our $VERSION = '0.001'; # VERSION

our $NAMES_CMYK_TABLE = {

  # Black
  'black' => 0x00000064, # 0,0,0,100
  'crow wing' => 0x00000064, # 0,0,0,100
  'walnut brou' => 0x002e5e4b, # 0,46,94,75
  'cassis' => 0x005d4b53, # 0,93,75,83
  'cassis' => 0x00614e4d, # 0,97,78,77
  'dorian' => 0x4d1a273b, # 77,26,39,59
  'ebony' => 0x00000064, # 0,0,0,100
  'animal black' => 0x00000064, # 0,0,0,100
  'black coal' => 0x00000064, # 0,0,0,100
  'aniline black' => 0x1229005b, # 18,41,0,91
  'carbon black' => 0x001a2f5d, # 0,26,47,93
  'black smoke' => 0x001a2f5d, # 0,26,47,93
  'jet black' => 0x00000064, # 0,0,0,100
  'black ink' => 0x00000064, # 0,0,0,100
  'ivory black' => 0x00000064, # 0,0,0,100
  'noiraud' => 0x00244652, # 0,36,70,82
  'licorice' => 0x00142152, # 0,20,33,82

  # Blue
  'blue' => 0x64640000, # 100,100,0,0
  'aquamarine' => 0x33000003, # 51,0,0,3
  'blue' => 0x64320000, # 100,50,0,0
  'blue' => 0x55250014, # 85,37,0,20
  'clear blue' => 0x340e0005, # 52,14,0,5
  'azurin' => 0x21340000, # 33,52,0,0
  'steel blue' => 0x4518001b, # 69,24,0,27
  'slate blue' => 0x1a15002d, # 26,21,0,45
  'cornflower blue' => 0x34220020, # 52,34,0,32
  'blue cornflower' => 0x34220020, # 52,34,0,32
  'blue jumped' => 0x6412001d, # 100,18,0,29
  'heavenly blue' => 0x54110007, # 84,17,0,7
  'cerulean' => 0x5e200009, # 94,32,0,9
  'cerulean blue' => 0x4721001c, # 71,33,0,28
  'blue wagon' => 0x1c120016, # 28,18,0,22
  'wheelwright blue' => 0x52130033, # 82,19,0,51
  'wheelwright blue' => 0x1c120016, # 28,18,0,22
  'blue sky' => 0x351d0000, # 53,29,0,0
  'cobalt blue' => 0x492f0033, # 73,47,0,51
  'berlin blue' => 0x3d1a0040, # 61,26,0,64
  'bleu de france' => 0x4f270009, # 79,39,0,9
  'midnight blue' => 0x6432003c, # 100,50,0,60
  'prussian blue' => 0x3d1a0040, # 61,26,0,64
  'denim blue' => 0x60380000, # 96,56,0,0
  'blue south sea' => 0x64000014, # 100,0,0,20
  'lozenge blue' => 0x0d050000, # 13,5,0,0
  'egyptian blue' => 0x5a450023, # 90,69,0,35
  'electric blue' => 0x53360000, # 83,54,0,0
  'blue woad' => 0x2c190028, # 44,25,0,40
  'blue horizon' => 0x170e0023, # 23,14,0,35
  'majorelle blue' => 0x3840000e, # 56,64,0,14
  'navy' => 0x60370046, # 96,55,0,70
  'maya blue' => 0x36170002, # 54,23,0,2
  'mineral blue' => 0x3d1a0040, # 61,26,0,64
  'midnight blue' => 0x565f003a, # 86,95,0,58
  'ultramarine' => 0x64640203, # 100,100,2,3
  'ultramarine' => 0x48640028, # 72,100,0,40
  'peacock' => 0x6011002c, # 96,17,0,44
  'persian blue' => 0x3c640000, # 60,100,0,0
  'oil blue' => 0x400b0044, # 64,11,0,68
  'royal blue' => 0x4f270009, # 79,39,0,9
  'sapphire blue' => 0x6349001d, # 99,73,0,29
  'teal' => 0x6400002c, # 100,0,0,44
  'smalt blue' => 0x64430028, # 100,67,0,40
  'tiffany blue' => 0x4a052600, # 74,5,38,0
  'turquin blue' => 0x3422002e, # 52,34,0,46
  'caeruleum' => 0x54110007, # 84,17,0,7
  'duck' => 0x610a0028, # 97,10,0,40
  'cerulean' => 0x340e0005, # 52,14,0,5
  'cyan' => 0x34000d00, # 52,0,13,0
  'cyan' => 0x53000002, # 83,0,0,2
  'fumes' => 0x1107000c, # 17,7,0,12
  'frosted' => 0x26000012, # 38,0,0,18
  'indigo' => 0x33590003, # 51,89,0,3
  'indigo' => 0x3964003a, # 57,100,0,58
  'indigo web' => 0x2a640031, # 42,100,0,49
  'klein 1' => 0x64570000, # 100,87,0,0
  'klein 2' => 0x4a520033, # 74,82,0,51
  'lapis lazuli' => 0x4c260027, # 76,38,0,39
  'lavender' => 0x242c0007, # 36,44,0,7
  'pastel' => 0x2c190028, # 44,25,0,40
  'pervenche' => 0x14140000, # 20,20,0,0
  'turquoise' => 0x55000801, # 85,0,8,1

  # Brown
  'brown' => 0x00225140, # 0,34,81,64
  'mahogany' => 0x00334f2f, # 0,51,79,47
  'chestnut' => 0x00264d23, # 0,38,77,35
  'amber' => 0x00136406, # 0,19,100,6
  'auburn' => 0x003d5c26, # 0,61,92,38
  'suntan' => 0x0016352d, # 0,22,53,45
  'beige' => 0x000e2516, # 0,14,37,22
  'light beige' => 0x00000a28, # 0,0,10,40
  'beigeasse' => 0x00051e1f, # 0,5,30,31
  'bistre' => 0x001e314c, # 0,30,49,76
  'bistre' => 0x00122a30, # 0,18,42,48
  'bitumen' => 0x00163145, # 0,22,49,69
  'blet' => 0x00225140, # 0,34,81,64
  'brick' => 0x00415030, # 0,65,80,48
  'bronze' => 0x0014493e, # 0,20,73,62
  'walnut brou' => 0x002e5e4b, # 0,46,94,75
  'office' => 0x0013363a, # 0,19,54,58
  'cocoa' => 0x0017283e, # 0,23,40,62
  'cachou' => 0x002b4a52, # 0,43,74,82
  'cafe' => 0x00226349, # 0,34,99,73
  'latte' => 0x00163d35, # 0,22,61,53
  'cannelle' => 0x001e3a33, # 0,30,58,51
  'caramel' => 0x003c6433, # 0,60,100,51
  'chestnut' => 0x000f1e32, # 0,15,30,50
  'light' => 0x0016352d, # 0,22,53,45
  'cauldron' => 0x00265930, # 0,38,89,48
  'chocolate' => 0x00243e41, # 0,36,62,65
  'pumpkin' => 0x002d500d, # 0,45,80,13
  'fauve' => 0x00365f20, # 0,54,95,32
  'sheet-dead' => 0x002f4828, # 0,47,72,40
  'grege' => 0x0007131b, # 0,7,19,27
  'moorish grey' => 0x000a243b, # 0,10,36,59
  'lavalliere' => 0x00264c2c, # 0,38,76,44
  'brown' => 0x00356441, # 0,53,100,65
  'mordore' => 0x0022512f, # 0,34,81,47
  'hazel' => 0x002a492a, # 0,42,73,42
  'burnt orange' => 0x003a6414, # 0,58,100,20
  'chip' => 0x00485845, # 0,72,88,69
  'red bismarck' => 0x004d5e23, # 0,77,94,35
  'red tomette' => 0x00394620, # 0,57,70,32
  'rust' => 0x002b5528, # 0,43,85,40
  'beef blood' => 0x005d6437, # 0,93,100,55
  'senois' => 0x00374a2d, # 0,55,74,45
  'sepia' => 0x00111d22, # 0,17,29,34
  'sepia' => 0x00152b20, # 0,21,43,32
  'tobacco' => 0x002f5126, # 0,47,81,38
  'sienna' => 0x00293f2c, # 0,41,63,44
  'umber' => 0x00071b3e, # 0,7,27,62
  'umber' => 0x0019492b, # 0,25,73,43
  'vanilla' => 0x0008200c, # 0,8,32,12

  # Gray
  'grey' => 0x0000003e, # 0,0,0,62
  'slate' => 0x100c003a, # 16,12,0,58
  'silver' => 0x00000013, # 0,0,0,19
  'clay' => 0x00000006, # 0,0,0,6
  'bi' => 0x00060f36, # 0,6,15,54
  'bistre' => 0x001e314c, # 0,30,49,76
  'bistre' => 0x00122a30, # 0,18,42,48
  'bitumen' => 0x00163145, # 0,22,49,69
  'celadon' => 0x15000923, # 21,0,9,35
  'chestnut' => 0x000f1e32, # 0,15,30,50
  'oxidized tin' => 0x0000001b, # 0,0,0,27
  'pure tin' => 0x00000007, # 0,0,0,7
  'fumes' => 0x1107000c, # 17,7,0,12
  'grege' => 0x0007131b, # 0,7,19,27
  'steel grey' => 0x0000001f, # 0,0,0,31
  'charcoal grey' => 0x48413d3d, # 72,65,61,61
  'payne grey' => 0x0f070035, # 15,7,0,53
  'gray iron' => 0x00000030, # 0,0,0,48
  'gray iron' => 0x00000032, # 0,0,0,50
  'pearl grey' => 0x00000013, # 0,0,0,19
  'pearl grey' => 0x04000250, # 4,0,2,80
  'gray' => 0x00000026, # 0,0,0,38
  'dove gray' => 0x0008081b, # 0,8,8,27
  'putty' => 0x0001131e, # 0,1,19,30
  'pinchard' => 0x00000014, # 0,0,0,20
  'lead' => 0x06010031, # 6,1,0,49
  'mountbatten pink' => 0x01180028, # 0,280,0,40
  'taupe' => 0x000a1d49, # 0,10,29,73
  'tourdille' => 0x00010818, # 0,1,8,24

  # Green
  'green' => 0x64006400, # 100,0,100,0
  'aquamarine' => 0x33000003, # 51,0,0,3
  'asparagus' => 0x17002b25, # 23,0,43,37
  'teal' => 0x6400002c, # 100,0,0,44
  'duck' => 0x610a0028, # 97,10,0,40
  'celadon' => 0x15000923, # 21,0,9,35
  'frosted' => 0x26000012, # 38,0,0,18
  'murky' => 0x23000c27, # 35,0,12,39
  'hooker' => 0x42005a45, # 66,0,90,69
  'jade' => 0x2a002609, # 42,0,38,9
  'khaki' => 0x000d472a, # 0,13,71,42
  'peppermint' => 0x58003a1c, # 88,0,58,28
  'water mint' => 0x42002b02, # 66,0,43,2
  'sinople' => 0x5600562a, # 86,0,86,42
  'turquoise' => 0x55000801, # 85,0,8,1
  'vert absinthe' => 0x2b00420d, # 43,0,66,13
  'green almond' => 0x22002d17, # 34,0,45,23
  'english green' => 0x3a002f4e, # 58,0,47,78
  'anise green' => 0x25005c00, # 37,0,92,0
  'green lawyer' => 0x22006231, # 34,0,98,49
  'green bottle' => 0x5c005c3a, # 92,0,92,58
  'green chartreuse' => 0x15005003, # 21,0,80,3
  'lime' => 0x64006400, # 100,0,100,0
  'chrome green' => 0x3a002f4e, # 58,0,47,78
  'verdigris' => 0x0a000a23, # 10,0,10,35
  'sap green' => 0x48005835, # 72,0,88,53
  'green water' => 0x1b001905, # 27,0,25,5
  'emerald green' => 0x64003b10, # 100,0,59,16
  'green empire' => 0x64004542, # 100,0,69,66
  'green spinach' => 0x29000045, # 41,0,0,69
  'green grass' => 0x3f004e26, # 63,0,78,38
  'green imperial' => 0x64004542, # 100,0,69,66
  'green khaki' => 0x0c003f2e, # 12,0,63,46
  'lichen green' => 0x1f002318, # 31,0,35,24
  'lime green' => 0x26004e01, # 38,0,78,1
  'malachite green' => 0x51002f25, # 81,0,47,37
  'larch green' => 0x32002338, # 50,0,35,56
  'military green' => 0x0d00223c, # 13,0,34,60
  'moss' => 0x23002b26, # 35,0,43,38
  'olive' => 0x15004b2d, # 21,0,75,45
  'green opaline' => 0x20000b0d, # 32,0,11,13
  'green parrot' => 0x4c004505, # 76,0,69,5
  'pine green' => 0x63000835, # 99,0,8,53
  'pistachio green' => 0x16003504, # 22,0,53,4
  'green leek' => 0x36002423, # 54,0,36,35
  'apple green' => 0x4a005215, # 74,0,82,21
  'green meadow' => 0x3b004810, # 59,0,72,16
  'green prasin' => 0x36002423, # 54,0,36,35
  'spring green' => 0x64003200, # 100,0,50,0
  'forest green' => 0x59003344, # 89,0,51,68
  'sage green' => 0x22001c26, # 34,0,28,38
  'green smaragdin' => 0x64003b10, # 100,0,59,16
  'green lime' => 0x15003d12, # 21,0,61,18
  'veronese green' => 0x15003b38, # 21,0,59,56
  'viride green' => 0x33001031, # 51,0,16,49

  # Orange
  'orange' => 0x002e5d07, # 0,46,93,7
  'apricot' => 0x002d4f0a, # 0,45,79,10
  'aurore' => 0x00143e00, # 0,20,62,0
  'bi' => 0x00061505, # 0,6,21,5
  'bisque' => 0x000b1700, # 0,11,23,0
  'carrot' => 0x00385505, # 0,56,85,5
  'pumpkin' => 0x002d500d, # 0,45,80,13
  'reef' => 0x00496409, # 0,73,100,9
  'copper' => 0x002a641e, # 0,42,100,30
  'gamboge' => 0x00235e06, # 0,35,94,6
  'mandarine' => 0x00244800, # 0,36,72,0
  'melon' => 0x00205a0d, # 0,32,90,13
  'orange' => 0x00226402, # 0,34,100,2
  'burnt orange' => 0x003a6414, # 0,58,100,20
  'roux' => 0x00365f20, # 0,54,95,32
  'safran' => 0x000c5b05, # 0,12,91,5
  'salmon' => 0x002b4203, # 0,43,66,3
  'tangerine' => 0x00495900, # 0,73,89,0
  'tanne' => 0x00316323, # 0,49,99,35
  'vanilla' => 0x0008200c, # 0,8,32,12
  'belly doe' => 0x000e1809, # 0,14,24,9

  # Pink
  'rose' => 0x00392601, # 0,57,38,1
  'bisque' => 0x000b1700, # 0,11,23,0
  'cherry' => 0x004e370d, # 0,78,55,13
  'chair' => 0x00172000, # 0,23,32,0
  'eggshell' => 0x00080b01, # 0,8,11,1
  'nymph thigh' => 0x00090600, # 0,9,6,0
  'raspberry' => 0x004e4016, # 0,78,64,22
  'fuchsia' => 0x004b2a01, # 0,75,42,1
  'heliotrope' => 0x0d370000, # 13,55,0,0
  'watermelon' => 0x00292500, # 0,41,37,0
  'magenta' => 0x00640000, # 0,100,0,0
  'dark magenta' => 0x00640032, # 0,100,0,50
  'magenta fuchsia' => 0x00642f0e, # 0,100,47,14
  'purple' => 0x002e0011, # 0,46,0,17
  'fishing' => 0x00191c01, # 0,25,28,1
  'brooms rose' => 0x002e1b17, # 0,46,27,23
  'candy pink' => 0x004a2502, # 0,74,37,2
  'pink' => 0x00191100, # 0,25,17,0
  'mountbatten pink' => 0x01180028, # 0,280,0,40
  'tea rose' => 0x002f3a00, # 0,47,58,0
  'hot pink' => 0x00643200, # 0,100,50,0
  'salmon' => 0x002b4203, # 0,43,66,3

  # Purple
  'purple' => 0x21640028, # 33,100,0,40
  'amethyst' => 0x13360023, # 19,54,0,35
  'aubergine' => 0x00641b4e, # 0,100,27,78
  'persian blue' => 0x3c640000, # 60,100,0,0
  'byzantine' => 0x00490d1a, # 0,73,13,26
  'byzantium' => 0x003f0c38, # 0,63,12,56
  'cherry' => 0x004e370d, # 0,78,55,13
  'colombin' => 0x00230c3a, # 0,35,12,58
  'fuchsia' => 0x004b2a01, # 0,75,42,1
  'glycine' => 0x091b000e, # 9,27,0,14
  'flax grey' => 0x0b0e0007, # 11,14,0,7
  'heliotrope' => 0x0d370000, # 13,55,0,0
  'indigo' => 0x33590003, # 51,89,0,3
  'indigo' => 0x3964003a, # 57,100,0,58
  'indigo web' => 0x2a640031, # 42,100,0,49
  'lavender' => 0x242c0007, # 36,44,0,7
  'wine lie' => 0x00533c21, # 0,83,60,33
  'lilas' => 0x0d330012, # 13,51,0,18
  'magenta' => 0x00640000, # 0,100,0,0
  'dark magenta' => 0x00640032, # 0,100,0,50
  'magenta fuchsia' => 0x00642f0e, # 0,100,47,14
  'purple' => 0x002e0011, # 0,46,0,17
  'orchid' => 0x0031020f, # 0,49,2,15
  'parma' => 0x0b1f0009, # 11,31,0,9
  'purple' => 0x005b3b26, # 0,91,59,38
  'prune' => 0x00542431, # 0,84,36,49
  'candy pink' => 0x004a2502, # 0,74,37,2
  'hot pink' => 0x00643200, # 0,100,50,0
  'red-violet' => 0x00592116, # 0,89,33,22
  'bishop violet' => 0x002e0c37, # 0,46,12,55
  'violine' => 0x00601225, # 0,96,18,37
  'zizolin' => 0x09620035, # 9,98,0,53

  # Red
  'red' => 0x00646400, # 0,100,100,0
  'amarante' => 0x00483b2b, # 0,72,59,43
  'bordeaux' => 0x005e4c39, # 0,94,76,57
  'brick' => 0x00415030, # 0,65,80,48
  'cherry' => 0x005e5e1b, # 0,94,94,27
  'reef' => 0x00496409, # 0,73,100,9
  'scarlet' => 0x00646407, # 0,100,100,7
  'strawberry' => 0x004b4b19, # 0,75,75,25
  'strawberry crushed' => 0x004e4e24, # 0,78,78,36
  'raspberry' => 0x004e4016, # 0,78,64,22
  'fuchsia' => 0x004b2a01, # 0,75,42,1
  'grenadine' => 0x004c4909, # 0,76,73,9
  'garnet' => 0x005a5239, # 0,90,82,57
  'watermelon' => 0x00292500, # 0,41,37,0
  'crimson' => 0x00383300, # 0,56,51,0
  'magenta' => 0x00640000, # 0,100,0,0
  'dark magenta' => 0x00640032, # 0,100,0,50
  'magenta fuchsia' => 0x00642f0e, # 0,100,47,14
  'purple' => 0x002e0011, # 0,46,0,17
  'nacarat' => 0x003f3f01, # 0,63,63,1
  'red ochre' => 0x001f3a0d, # 0,31,58,13
  'pass velvet' => 0x00483b2b, # 0,72,59,43
  'purple' => 0x005b3b26, # 0,91,59,38
  'prune' => 0x00542431, # 0,84,36,49
  'hot pink' => 0x00643200, # 0,100,50,0
  'alizarin red' => 0x00606416, # 0,96,100,22
  'english red' => 0x00565f03, # 0,86,95,3
  'red bismarck' => 0x004d5e23, # 0,77,94,35
  'red burgundy' => 0x0058583a, # 0,88,88,58
  'red nasturtium' => 0x003f4600, # 0,63,70,0
  'cardinal red' => 0x00535b1c, # 0,83,91,28
  'carmine red' => 0x00645429, # 0,100,84,41
  'red cinnabar' => 0x0059630e, # 0,89,99,14
  'red cinnabar' => 0x00485501, # 0,72,85,1
  'red poppy' => 0x00606416, # 0,96,100,22
  'crimson' => 0x00645429, # 0,100,84,41
  'crimson' => 0x005b490e, # 0,91,73,14
  'red adrianople' => 0x005a6322, # 0,90,99,34
  'red aniline' => 0x00646408, # 0,100,100,8
  'red gong' => 0x00515132, # 0,81,81,50
  'march rouge' => 0x00565f03, # 0,86,95,3
  'red crayfish' => 0x0053631a, # 0,83,99,26
  'red fire' => 0x00596400, # 0,89,100,0
  'red fire' => 0x00476400, # 0,71,100,0
  'red madder' => 0x005d5d07, # 0,93,93,7
  'red currant' => 0x005f5613, # 0,95,86,19
  'red culvert' => 0x00606416, # 0,96,100,22
  'ruby red' => 0x005c3a0c, # 0,92,58,12
  'red blood' => 0x005f5f30, # 0,95,95,48
  'red tomato' => 0x00525a0d, # 0,82,90,13
  'red tomette' => 0x00394620, # 0,57,70,32
  'turkish red' => 0x005a6322, # 0,90,99,34
  'red vermilion' => 0x0059630e, # 0,89,99,14
  'red vermilion' => 0x00485501, # 0,72,85,1
  'red-violet' => 0x00592116, # 0,89,33,22
  'rust' => 0x002b5528, # 0,43,85,40
  'beef blood' => 0x005d6437, # 0,93,100,55
  'senois' => 0x00374a2d, # 0,55,74,45
  'terracotta' => 0x003e3714, # 0,62,55,20
  'vermeil' => 0x0060570d, # 0,96,87,13
  'zizolin' => 0x09620035, # 9,98,0,53

  # White
  'white' => 0x00000000, # 0,0,0,0
  'alabaster' => 0x00000000, # 0,0,0,0
  'clay' => 0x00000006, # 0,0,0,6
  'azur mist' => 0x06000000, # 6,0,0,0
  'light beige' => 0x00000a28, # 0,0,10,40
  '-white' => 0x00000b00, # 0,0,11,0
  'white lead white' => 0x00000000, # 0,0,0,0
  'white cream' => 0x00051b01, # 0,5,27,1
  'white silver' => 0x00000000, # 0,0,0,0
  'white milk' => 0x00000101, # 0,0,1,1
  'flax white' => 0x00040802, # 0,4,8,2
  'white platinum' => 0x00041502, # 0,4,21,2
  'lead white' => 0x00000000, # 0,0,0,0
  'white saturn' => 0x00000000, # 0,0,0,0
  'white troyes' => 0x00000600, # 0,0,6,0
  'zinc white' => 0x03000000, # 3,0,0,0
  'white of spain' => 0x00000600, # 0,0,6,0
  'white ivory' => 0x00001164, # 0,0,17,100
  'ecru white' => 0x00000c00, # 0,0,12,0
  'lunar white' => 0x04000000, # 4,0,0,0
  'snow white' => 0x00000000, # 0,0,0,0
  'white opal' => 0x05000000, # 5,0,0,0
  'white-blue' => 0x00000000, # 0,0,0,0
  'eggshell' => 0x00080b01, # 0,8,11,1
  'nymph thigh' => 0x00090600, # 0,9,6,0

  # Yellow
  'yellow' => 0x00006400, # 0,0,100,0
  'amber' => 0x00136406, # 0,19,100,6
  'aurore' => 0x00143e00, # 0,20,62,0
  'butter' => 0x00053706, # 0,5,55,6
  'fees butter' => 0x00042d00, # 0,4,45,0
  'wheat' => 0x00084f09, # 0,8,79,9
  'blonde' => 0x0011310b, # 0,17,49,11
  'golden button' => 0x000d5d01, # 0,13,93,1
  'bulle' => 0x000b2907, # 0,11,41,7
  'goose caca' => 0x00005e14, # 0,0,94,20
  'chamois' => 0x00082912, # 0,8,41,18
  'champagne' => 0x00041b02, # 0,4,27,2
  'chrome' => 0x07005f00, # 7,0,95,0
  'chrome' => 0x00006200, # 0,0,98,0
  'lemon' => 0x03004c00, # 3,0,76,0
  'fauve' => 0x00365f20, # 0,54,95,32
  'flave' => 0x0000220a, # 0,0,34,10
  'sulfur flower' => 0x00003a00, # 0,0,58,0
  'gamboge' => 0x00235e06, # 0,35,94,6
  'yellow aureolin' => 0x000c4806, # 0,12,72,6
  'yellow banana' => 0x000d6112, # 0,13,97,18
  'chickadee' => 0x04005f06, # 4,0,95,6
  'yellow chartreuse' => 0x0d006400, # 13,0,100,0
  'cobalt yellow' => 0x00066400, # 0,6,100,0
  'naples yellow' => 0x00061a00, # 0,6,26,0
  'golden yellow' => 0x000a6106, # 0,10,97,6
  'imperial yellow' => 0x000b4f00, # 0,11,79,0
  'yellow mimosa' => 0x00023900, # 0,2,57,0
  'yellow mustard' => 0x04006413, # 4,0,100,19
  'yellow nankin' => 0x00093903, # 0,9,57,3
  'yellow olive' => 0x00006432, # 0,0,100,50
  'yellow straw' => 0x000b4800, # 0,11,72,0
  'yellow chick' => 0x00083e03, # 0,8,62,3
  'corn' => 0x000d3600, # 0,13,54,0
  'march' => 0x000c4107, # 0,12,65,7
  'putty' => 0x0001131e, # 0,1,19,30
  'honey' => 0x00125f0f, # 0,18,95,15
  'yellow ocher' => 0x0016520d, # 0,22,82,13
  'red ochre' => 0x001f3a0d, # 0,31,58,13
  'or' => 0x00125e00, # 0,18,94,0
  'orpiment' => 0x00115901, # 0,17,89,1
  'camel hair' => 0x0022511d, # 0,34,81,29
  'cow tail 1' => 0x00082b18, # 0,8,43,24
  'cow tail 2' => 0x000a1f22, # 0,10,31,34
  'sand' => 0x0008190c, # 0,8,25,12
  'safran' => 0x000c5b05, # 0,12,91,5
  'sulfur' => 0x00003a00, # 0,0,58,0
  'topaz' => 0x00063602, # 0,6,54,2
  'vanilla' => 0x0008200c, # 0,8,32,12
  'venetian' => 0x001b4009, # 0,27,64,9
};


1;
# ABSTRACT: CMYK colors from http://toutes-les-couleurs.com/ (red)

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::ColorNamesCMYK::ToutesLesCouleursCom - CMYK colors from http://toutes-les-couleurs.com/ (red)

=head1 VERSION

This document describes version 0.001 of Graphics::ColorNamesCMYK::ToutesLesCouleursCom (from Perl distribution Graphics-ColorNamesCMYK-ToutesLesCouleursCom), released on 2024-05-06.

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Graphics-ColorNamesCMYK-ToutesLesCouleursCom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Graphics-ColorNamesCMYK-ToutesLesCouleursCom>.

=head1 SEE ALSO

Other C<Graphics::ColorNamesCMYK::ToutesLesCoulersCom::*> modules.

Other C<Graphics::ColorNamesCMYK::*> modules.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Graphics-ColorNamesCMYK-ToutesLesCouleursCom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
