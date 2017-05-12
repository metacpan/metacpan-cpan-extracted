# 1 "y.tab.pl"
#pragma GCC set_debug_pwd "/Volumes/gbarr/Desktop/spl-1.2.1/Lingua-Shakespear"
# 1 "<built-in>"
# 1 "<command line>"
# 1 "y.tab.pl"
#$yysccsid = "@(#)yaccpar 1.8 (Berkeley) 01/20/91 (Perl 2.0 12/31/92)";
# 2 "Shakespeare.y"
package Lingua::Shakespeare;

$VERSION = "1.00";

use strict;
use Filter::Util::Call;

my ($yychar, $yyerrflag, $yynerrs, $yyn, @yyss, $yyssp, $yystate, @yyvs, $yyvsp);
my ($yylval, $yys, $yym, $yyval, %yystate, $yydebug, $yylineno, $output);

my ($num_errors, $num_warnings, @token, $current_act, $current_scene);

sub import {
  filter_add({});
  $yylineno = (caller)[2]+1;
  1;
}

sub unimport { filter_del() }

  my $preamble = <<'PREAMBLE';
require Lingua::Shakespeare::Play;
my ($comp1, $comp2);
my $play = Lingua::Shakespeare::Play->new;
$|=1;
PREAMBLE

sub varname {
  (my $name = lc shift) =~ tr/ /_/;
  '$' . $name;
}

sub set_line { "#line $yylineno\n" }
# 39 "y.tab.pl"
sub constARTICLE () { 257 }
sub constBE () { 258 }
sub constCHARACTER () { 259 }
sub constFIRST_PERSON () { 260 }
sub constFIRST_PERSON_POSSESSIVE () { 261 }
sub constFIRST_PERSON_REFLEXIVE () { 262 }
sub constNEGATIVE_ADJECTIVE () { 263 }
sub constNEGATIVE_COMPARATIVE () { 264 }
sub constNEGATIVE_NOUN () { 265 }
sub constNEUTRAL_ADJECTIVE () { 266 }
sub constNEUTRAL_NOUN () { 267 }
sub constNOTHING () { 268 }
sub constPOSITIVE_ADJECTIVE () { 269 }
sub constPOSITIVE_COMPARATIVE () { 270 }
sub constPOSITIVE_NOUN () { 271 }
sub constSECOND_PERSON () { 272 }
sub constSECOND_PERSON_POSSESSIVE () { 273 }
sub constSECOND_PERSON_REFLEXIVE () { 274 }
sub constTHIRD_PERSON_POSSESSIVE () { 275 }
sub constCOLON () { 276 }
sub constCOMMA () { 277 }
sub constEXCLAMATION_MARK () { 278 }
sub constLEFT_BRACKET () { 279 }
sub constPERIOD () { 280 }
sub constQUESTION_MARK () { 281 }
sub constRIGHT_BRACKET () { 282 }
sub constAND () { 283 }
sub constAS () { 284 }
sub constENTER () { 285 }
sub constEXEUNT () { 286 }
sub constEXIT () { 287 }
sub constHEART () { 288 }
sub constIF_NOT () { 289 }
sub constIF_SO () { 290 }
sub constLESS () { 291 }
sub constLET_US () { 292 }
sub constLISTEN_TO () { 293 }
sub constMIND () { 294 }
sub constMORE () { 295 }
sub constNOT () { 296 }
sub constOPEN () { 297 }
sub constPROCEED_TO () { 298 }
sub constRECALL () { 299 }
sub constREMEMBER () { 300 }
sub constRETURN_TO () { 301 }
sub constSPEAK () { 302 }
sub constTHAN () { 303 }
sub constTHE_CUBE_OF () { 304 }
sub constTHE_DIFFERENCE_BETWEEN () { 305 }
sub constTHE_FACTORIAL_OF () { 306 }
sub constTHE_PRODUCT_OF () { 307 }
sub constTHE_QUOTIENT_BETWEEN () { 308 }
sub constTHE_REMAINDER_OF_THE_QUOTIENT_BETWEEN () { 309 }
sub constTHE_SQUARE_OF () { 310 }
sub constTHE_SQUARE_ROOT_OF () { 311 }
sub constTHE_SUM_OF () { 312 }
sub constTWICE () { 313 }
sub constWE_MUST () { 314 }
sub constWE_SHALL () { 315 }
sub constACT_ROMAN () { 316 }
sub constSCENE_ROMAN () { 317 }
sub constROMAN_NUMBER () { 318 }
sub constNONMATCH () { 319 }
sub constYYERRCODE () { 256 }
my @yylhs = ( -1,
    0, 1, 1, 2, 2, 2, 3, 3, 3, 4,
    4, 4, 4, 4, 5, 5, 5, 6, 6, 7,
    7, 8, 8, 9, 9, 10, 10, 11, 11, 12,
   12, 12, 12, 12, 13, 13, 14, 14, 14, 14,
   14, 14, 14, 14, 14, 15, 15, 15, 16, 16,
   17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
   17, 17, 17, 18, 18, 18, 19, 19, 19, 20,
   20, 20, 21, 21, 22, 22, 22, 23, 23, 23,
   24, 24, 24, 25, 26, 26, 27, 27, 28, 28,
   28, 28, 28, 29, 29, 29, 30, 30, 30, 31,
   31, 32, 32, 32, 32, 33, 33, 33, 33, 34,
   35, 35, 35, 36, 36, 36, 37, 38, 38, 38,
   38, 39, 39, 39, 40, 40, 40, 41, 41, 42,
   42, 42, 42, 42, 42, 42, 42, 42, 42, 42,
   42, 43, 43, 44, 44, 45, 45, 45, 45, 45,
   45, 45, 45, 45, 45, 45, 45, 45, 45, 45,
   45, 45, 45, 45, 45, 45, 45, 45, 45, 45,
   45, 45, 45, 45, 45, 45, 45, 45, 45, 45,
   45, 45, 45, 45, 45, 45, 45, 45, 45, 45,
   45, 45, 45, 45, 45, 45, 45, 45, 45, 45,
   45, 45, 46, 47, 47, 48, 48, 48, 48, 48,
   49, 49, 49, 49, 49, 49, 50, 50, 50, 50,
   50, 50, 50, 50, 50,
);
my @yylen = ( 2,
    1, 2, 2, 4, 4, 4, 1, 1, 1, 1,
    1, 1, 1, 1, 4, 4, 4, 1, 2, 3,
    3, 1, 1, 1, 1, 2, 1, 1, 1, 2,
    2, 2, 2, 1, 1, 1, 4, 4, 4, 4,
    3, 4, 4, 4, 3, 3, 3, 3, 2, 2,
    3, 4, 4, 3, 3, 4, 4, 4, 4, 3,
    4, 4, 3, 3, 3, 3, 2, 2, 2, 1,
    1, 1, 1, 1, 3, 3, 3, 1, 2, 2,
    1, 2, 2, 1, 1, 1, 2, 2, 3, 2,
    3, 3, 3, 1, 2, 2, 1, 2, 2, 1,
    1, 1, 1, 1, 1, 5, 5, 5, 5, 1,
    3, 3, 3, 3, 3, 3, 2, 1, 1, 2,
    2, 4, 4, 4, 1, 3, 3, 1, 2, 4,
    3, 5, 4, 4, 4, 3, 3, 5, 5, 5,
    5, 1, 1, 1, 2, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 2, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 4,
    2, 4, 4, 4, 2,
);
my @yydefred = ( 0,
    0, 146, 147, 148, 149, 150, 151, 152, 153, 154,
  155, 156, 157, 158, 159, 160, 161, 162, 163, 164,
  165, 166, 167, 168, 169, 170, 171, 172, 173, 174,
  175, 176, 177, 178, 179, 180, 181, 182, 183, 184,
  185, 186, 187, 188, 189, 190, 191, 192, 193, 194,
  195, 196, 197, 198, 199, 200, 201, 202, 0, 0,
    0, 144, 0, 0, 0, 18, 0, 0, 0, 0,
  142, 143, 110, 203, 35, 36, 145, 0, 0, 0,
    0, 0, 0, 19, 0, 0, 0, 3, 0, 2,
    0, 0, 0, 23, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 118, 119, 0, 16, 17, 15,
    6, 5, 4, 0, 0, 0, 0, 0, 0, 0,
    0, 120, 121, 124, 123, 122, 0, 0, 0, 29,
   28, 70, 0, 0, 0, 0, 0, 71, 72, 0,
  211, 212, 0, 0, 0, 213, 214, 215, 128, 0,
  216, 125, 0, 0, 45, 0, 0, 0, 0, 0,
   41, 0, 0, 0, 73, 74, 68, 0, 0, 217,
  102, 0, 103, 34, 104, 0, 105, 0, 206, 10,
  207, 11, 12, 13, 208, 209, 14, 210, 0, 218,
  219, 0, 0, 0, 0, 0, 84, 0, 100, 0,
  101, 205, 81, 204, 97, 0, 0, 0, 88, 87,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 69, 67, 0, 0, 0, 129, 42, 0, 37,
    0, 38, 44, 40, 43, 39, 78, 94, 0, 0,
    0, 0, 0, 0, 85, 86, 24, 27, 25, 30,
   31, 32, 33, 0, 0, 225, 221, 0, 0, 0,
    0, 137, 0, 0, 0, 0, 82, 83, 99, 0,
   98, 136, 131, 0, 0, 0, 112, 113, 111, 115,
  116, 114, 0, 0, 0, 127, 126, 66, 64, 65,
   55, 60, 51, 63, 54, 21, 20, 0, 9, 8,
    7, 0, 96, 80, 79, 95, 26, 50, 49, 0,
    0, 0, 0, 0, 0, 0, 135, 0, 134, 0,
  133, 130, 0, 0, 57, 59, 62, 53, 56, 58,
   61, 52, 47, 48, 46, 107, 224, 223, 222, 220,
  108, 109, 106, 141, 140, 139, 138, 132,
);
my @yydgoto = ( 59,
   69, 70, 302, 189, 66, 67, 158, 95, 243, 244,
  140, 190, 74, 105, 245, 246, 141, 142, 143, 144,
  167, 106, 247, 202, 203, 248, 145, 60, 249, 204,
  205, 191, 146, 75, 147, 148, 88, 107, 89, 149,
  150, 151, 76, 96, 62, 63, 206, 192, 152, 193,
);
my @yysindex = ( 74,
 -210, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, -209,
  265, 0, -165, -157, -211, 0, -235, -224, -156, -156,
    0, 0, 0, 0, 0, 0, 0, -254, -215, 138,
  138, 138, -156, 0, 138, 138, -150, 0, -138, 0,
 -156, -157, -156, 0, 136, 328, 136, 136, 136, -169,
  138, 138, -102, -214, 0, 0, -138, 0, 0, 0,
    0, 0, 0, 136, -11, -197, -142, -81, 43, -113,
   50, 0, 0, 0, 0, 0, -42, 392, 715, 0,
    0, 0, -107, -10, 202, 412, -8, 0, 0, -201,
    0, 0, -237, -234, -225, 0, 0, 0, 0, -197,
    0, 0, -42, -197, 0, -30, -79, -25, -1, -229,
    0, 8, 25, 137, 0, 0, 0, -151, 599, 0,
    0, 599, 0, 0, 0, 599, 0, 599, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 470, 0,
    0, 490, -128, 30, -7, 215, 0, 599, 0, 424,
    0, 0, 0, 0, 0, -220, -117, -206, 0, 0,
  140, -78, 140, 15, -20, -226, -14, -14, 140, 140,
  140, 0, 0, 140, 16, 33, 0, 0, 38, 0,
   53, 0, 0, 0, 0, 0, 0, 0, -104, -99,
  -16, -160, -238, 702, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 199, -213, 0, 0, 702, 548, 140,
  702, 0, 645, 399, 568, 215, 0, 0, 0, 424,
    0, 0, 0, 140, 140, 403, 0, 0, 0, 0,
    0, 0, 140, 140, 414, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 257, 0, 0,
    0, -227, 0, 0, 0, 0, 0, 0, 0, 263,
  702, 702, 626, 263, 263, 263, 0, 140, 0, 140,
    0, 0, 140, 432, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
);
my @yyrindex = ( 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 292,
    0, 0, 0, 0, 0, 0, 0, 0, 9, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 10, 0, 0, 0, 0, 0, 0, 0,
   11, 12, 13, 0, 0, -5, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 7, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    0, 0, 3, 5, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
);
my @yygindex = ( 0,
  237, 0, 0, 0, 176, 484, -114, 654, 0, 411,
    0, -111, 671, 499, 158, 0, 0, 0, 0, 0,
  463, 501, 0, -181, 0, 367, 0, 0, 0, -184,
    0, 0, 0, 40, 0, 0, 540, 0, 0, -103,
  533, 0, -186, 4, -59, 0, 537, 0, 266, -136,
);
sub constYYTABLESIZE () { 1015 }
my @yytable = ( 214,
   77, 77, 76, 61, 75, 162, 117, 262, 90, 93,
   92, 91, 89, 269, 267, 271, 268, 308, 219, 273,
   64, 222, 80, 65, 277, 279, 280, 282, 334, 284,
  224, 85, 288, 289, 290, 272, 77, 291, 293, 295,
   92, 118, 312, 65, 81, 64, 227, 229, 65, 275,
  227, 86, 255, 231, 217, 257, 335, 71, 127, 72,
  128, 68, 225, 165, 309, 82, 166, 285, 226, 313,
  119, 120, 121, 317, 129, 218, 319, 322, 220, 221,
   68, 276, 260, 264, 268, 269, 112, 325, 326, 328,
   78, 130, 131, 65, 132, 133, 329, 330, 332, 134,
   68, 135, 136, 237, 137, 101, 68, 310, 71, 238,
   72, 73, 237, 153, 296, 128, 138, 139, 238, 80,
  103, 314, 316, 239, 318, 102, 320, 258, 324, 129,
  240, 344, 239, 345, 241, 237, 346, 348, 212, 240,
  104, 238, 159, 241, 242, 160, 130, 131, 207, 132,
  133, 298, 77, 116, 134, 239, 135, 136, 299, 137,
   87, 300, 240, 303, 301, 208, 241, 242, 161, 304,
  274, 138, 139, 117, 337, 338, 340, 278, 2, 3,
    4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
   14, 15, 16, 17, 18, 19, 20, 229, 21, 71,
  155, 72, 230, 231, 22, 23, 24, 25, 26, 27,
   28, 29, 30, 31, 32, 33, 34, 35, 36, 37,
   38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
   48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
   58, 127, 84, 128, 125, 209, 305, 215, 263, 169,
   22, 228, 306, 172, 84, 165, 232, 129, 166, 77,
  174, 76, 210, 75, 216, 176, 71, 178, 72, 73,
  281, 292, 22, 283, 22, 22, 239, 132, 133, 77,
  233, 76, 134, 75, 135, 136, 169, 137, 294, 234,
  172, 1, 71, 71, 72, 72, 160, 174, 156, 138,
  139, 157, 176, 83, 178, 163, 235, 71, 164, 72,
   71, 297, 72, 239, 91, 93, 77, 77, 76, 76,
   75, 75, 117, 117, 90, 93, 92, 91, 89, 1,
    2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
   12, 13, 14, 15, 16, 17, 18, 19, 20, 336,
   21, 261, 265, 341, 342, 343, 22, 23, 24, 25,
   26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
   36, 37, 38, 39, 40, 41, 42, 43, 44, 45,
   46, 47, 48, 49, 50, 51, 52, 53, 54, 55,
   56, 57, 58, 94, 2, 3, 4, 5, 6, 7,
    8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
   18, 19, 20, 71, 21, 72, 73, 71, 236, 72,
   22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
   32, 33, 34, 35, 36, 37, 38, 39, 40, 41,
   42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
   52, 53, 54, 55, 56, 57, 58, 211, 2, 3,
    4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
   14, 15, 16, 17, 18, 19, 20, 196, 21, 197,
  266, 311, 286, 287, 22, 23, 24, 25, 26, 27,
   28, 29, 30, 31, 32, 33, 34, 35, 36, 37,
   38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
   48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
   58, 2, 3, 4, 5, 6, 7, 8, 9, 10,
   11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
  333, 21, 71, 73, 72, 73, 79, 22, 23, 24,
   25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
   35, 36, 37, 38, 39, 40, 41, 42, 43, 44,
   45, 46, 47, 48, 49, 50, 51, 52, 53, 54,
   55, 56, 57, 58, 2, 3, 4, 5, 6, 7,
    8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
   18, 19, 20, 259, 21, 122, 223, 123, 307, 90,
   22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
   32, 33, 34, 35, 36, 37, 38, 39, 40, 41,
   42, 43, 44, 45, 46, 47, 48, 49, 50, 51,
   52, 53, 54, 55, 56, 57, 58, 168, 169, 154,
  170, 171, 172, 173, 321, 0, 0, 0, 327, 174,
    0, 0, 0, 175, 176, 177, 178, 213, 169, 331,
  170, 171, 172, 173, 0, 0, 71, 0, 72, 174,
   71, 0, 72, 175, 176, 177, 178, 347, 0, 270,
  199, 71, 200, 72, 201, 179, 180, 181, 182, 183,
  184, 185, 186, 187, 188, 250, 0, 0, 251, 71,
    0, 72, 252, 0, 253, 179, 180, 181, 182, 183,
  184, 185, 186, 187, 188, 254, 169, 0, 170, 171,
  172, 173, 0, 0, 97, 98, 0, 174, 99, 100,
    0, 175, 176, 177, 178, 256, 169, 0, 170, 171,
  172, 173, 0, 0, 114, 115, 0, 174, 0, 0,
    0, 175, 176, 177, 178, 108, 0, 109, 110, 111,
  113, 0, 0, 179, 180, 181, 182, 183, 184, 185,
  186, 187, 188, 0, 124, 126, 0, 0, 0, 0,
    0, 0, 0, 179, 180, 181, 182, 183, 184, 185,
  186, 187, 188, 315, 169, 0, 170, 171, 172, 173,
    0, 0, 0, 0, 0, 174, 0, 0, 0, 175,
  176, 177, 178, 323, 169, 0, 170, 171, 172, 173,
    0, 0, 0, 0, 0, 174, 0, 0, 0, 175,
  176, 177, 178, 0, 0, 0, 0, 0, 0, 0,
    0, 179, 180, 181, 182, 183, 184, 185, 186, 187,
  188, 196, 0, 197, 198, 199, 0, 200, 0, 201,
    0, 179, 180, 181, 182, 183, 184, 185, 186, 187,
  188, 339, 169, 0, 170, 171, 172, 173, 0, 0,
    0, 0, 0, 174, 0, 0, 0, 175, 176, 177,
  178, 169, 0, 170, 171, 172, 173, 0, 0, 0,
    0, 0, 174, 0, 0, 0, 175, 176, 177, 178,
    0, 0, 71, 0, 72, 0, 0, 0, 0, 179,
  180, 181, 182, 183, 184, 185, 186, 187, 188, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 179, 180,
  181, 182, 183, 184, 185, 186, 187, 188, 169, 0,
  170, 171, 172, 173, 0, 0, 0, 0, 0, 174,
  194, 0, 195, 175, 176, 177, 178, 196, 0, 197,
  198, 199, 0, 200, 0, 201, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 179, 180, 181, 182, 183,
  184, 185, 186, 187, 188,
);
my @yycheck = ( 136,
    0, 61, 0, 0, 0, 120, 0, 194, 0, 0,
    0, 0, 0, 198, 196, 200, 198, 256, 256, 206,
  256, 256, 277, 259, 211, 212, 213, 214, 256, 256,
  256, 256, 219, 220, 221, 256, 96, 224, 225, 226,
  256, 256, 256, 259, 256, 256, 150, 277, 259, 256,
  154, 276, 189, 283, 256, 192, 284, 278, 256, 280,
  258, 316, 288, 298, 303, 277, 301, 294, 294, 283,
  285, 286, 287, 260, 272, 277, 263, 264, 316, 317,
  316, 288, 194, 195, 266, 270, 256, 274, 275, 276,
  256, 289, 290, 259, 292, 293, 283, 284, 285, 297,
  316, 299, 300, 264, 302, 256, 316, 244, 278, 270,
  280, 281, 264, 256, 229, 258, 314, 315, 270, 277,
  259, 258, 259, 284, 261, 276, 263, 256, 265, 272,
  291, 318, 284, 320, 295, 264, 323, 324, 135, 291,
  279, 270, 256, 295, 296, 259, 289, 290, 256, 292,
  293, 256, 212, 256, 297, 284, 299, 300, 263, 302,
  317, 266, 291, 263, 269, 273, 295, 296, 282, 269,
  288, 314, 315, 276, 311, 312, 313, 256, 257, 258,
  259, 260, 261, 262, 263, 264, 265, 266, 267, 268,
  269, 270, 271, 272, 273, 274, 275, 277, 277, 278,
  282, 280, 282, 283, 283, 284, 285, 286, 287, 288,
  289, 290, 291, 292, 293, 294, 295, 296, 297, 298,
  299, 300, 301, 302, 303, 304, 305, 306, 307, 308,
  309, 310, 311, 312, 313, 314, 315, 316, 317, 318,
  319, 256, 67, 258, 256, 256, 263, 256, 256, 257,
  256, 282, 269, 261, 79, 298, 282, 272, 301, 259,
  268, 259, 273, 259, 273, 273, 278, 275, 280, 281,
  256, 256, 278, 294, 280, 281, 284, 292, 293, 279,
  282, 279, 297, 279, 299, 300, 257, 302, 256, 282,
  261, 0, 278, 278, 280, 280, 259, 268, 256, 314,
  315, 259, 273, 67, 275, 256, 282, 278, 259, 280,
  278, 259, 280, 284, 78, 79, 316, 317, 316, 317,
  316, 317, 316, 317, 316, 316, 316, 316, 316, 256,
  257, 258, 259, 260, 261, 262, 263, 264, 265, 266,
  267, 268, 269, 270, 271, 272, 273, 274, 275, 310,
  277, 194, 195, 314, 315, 316, 283, 284, 285, 286,
  287, 288, 289, 290, 291, 292, 293, 294, 295, 296,
  297, 298, 299, 300, 301, 302, 303, 304, 305, 306,
  307, 308, 309, 310, 311, 312, 313, 314, 315, 316,
  317, 318, 319, 256, 257, 258, 259, 260, 261, 262,
  263, 264, 265, 266, 267, 268, 269, 270, 271, 272,
  273, 274, 275, 278, 277, 280, 281, 278, 282, 280,
  283, 284, 285, 286, 287, 288, 289, 290, 291, 292,
  293, 294, 295, 296, 297, 298, 299, 300, 301, 302,
  303, 304, 305, 306, 307, 308, 309, 310, 311, 312,
  313, 314, 315, 316, 317, 318, 319, 256, 257, 258,
  259, 260, 261, 262, 263, 264, 265, 266, 267, 268,
  269, 270, 271, 272, 273, 274, 275, 263, 277, 265,
  266, 283, 217, 218, 283, 284, 285, 286, 287, 288,
  289, 290, 291, 292, 293, 294, 295, 296, 297, 298,
  299, 300, 301, 302, 303, 304, 305, 306, 307, 308,
  309, 310, 311, 312, 313, 314, 315, 316, 317, 318,
  319, 257, 258, 259, 260, 261, 262, 263, 264, 265,
  266, 267, 268, 269, 270, 271, 272, 273, 274, 275,
  284, 277, 278, 281, 280, 281, 63, 283, 284, 285,
  286, 287, 288, 289, 290, 291, 292, 293, 294, 295,
  296, 297, 298, 299, 300, 301, 302, 303, 304, 305,
  306, 307, 308, 309, 310, 311, 312, 313, 314, 315,
  316, 317, 318, 319, 257, 258, 259, 260, 261, 262,
  263, 264, 265, 266, 267, 268, 269, 270, 271, 272,
  273, 274, 275, 193, 277, 107, 144, 107, 242, 70,
  283, 284, 285, 286, 287, 288, 289, 290, 291, 292,
  293, 294, 295, 296, 297, 298, 299, 300, 301, 302,
  303, 304, 305, 306, 307, 308, 309, 310, 311, 312,
  313, 314, 315, 316, 317, 318, 319, 256, 257, 117,
  259, 260, 261, 262, 256, -1, -1, -1, 256, 268,
   -1, -1, -1, 272, 273, 274, 275, 256, 257, 256,
  259, 260, 261, 262, -1, -1, 278, -1, 280, 268,
  278, -1, 280, 272, 273, 274, 275, 256, -1, 266,
  267, 278, 269, 280, 271, 304, 305, 306, 307, 308,
  309, 310, 311, 312, 313, 169, -1, -1, 172, 278,
   -1, 280, 176, -1, 178, 304, 305, 306, 307, 308,
  309, 310, 311, 312, 313, 256, 257, -1, 259, 260,
  261, 262, -1, -1, 81, 82, -1, 268, 85, 86,
   -1, 272, 273, 274, 275, 256, 257, -1, 259, 260,
  261, 262, -1, -1, 101, 102, -1, 268, -1, -1,
   -1, 272, 273, 274, 275, 95, -1, 97, 98, 99,
  100, -1, -1, 304, 305, 306, 307, 308, 309, 310,
  311, 312, 313, -1, 114, 115, -1, -1, -1, -1,
   -1, -1, -1, 304, 305, 306, 307, 308, 309, 310,
  311, 312, 313, 256, 257, -1, 259, 260, 261, 262,
   -1, -1, -1, -1, -1, 268, -1, -1, -1, 272,
  273, 274, 275, 256, 257, -1, 259, 260, 261, 262,
   -1, -1, -1, -1, -1, 268, -1, -1, -1, 272,
  273, 274, 275, -1, -1, -1, -1, -1, -1, -1,
   -1, 304, 305, 306, 307, 308, 309, 310, 311, 312,
  313, 263, -1, 265, 266, 267, -1, 269, -1, 271,
   -1, 304, 305, 306, 307, 308, 309, 310, 311, 312,
  313, 256, 257, -1, 259, 260, 261, 262, -1, -1,
   -1, -1, -1, 268, -1, -1, -1, 272, 273, 274,
  275, 257, -1, 259, 260, 261, 262, -1, -1, -1,
   -1, -1, 268, -1, -1, -1, 272, 273, 274, 275,
   -1, -1, 278, -1, 280, -1, -1, -1, -1, 304,
  305, 306, 307, 308, 309, 310, 311, 312, 313, -1,
   -1, -1, -1, -1, -1, -1, -1, -1, 304, 305,
  306, 307, 308, 309, 310, 311, 312, 313, 257, -1,
  259, 260, 261, 262, -1, -1, -1, -1, -1, 268,
  256, -1, 258, 272, 273, 274, 275, 263, -1, 265,
  266, 267, -1, 269, -1, 271, -1, -1, -1, -1,
   -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
   -1, -1, -1, -1, -1, 304, 305, 306, 307, 308,
  309, 310, 311, 312, 313,
);
sub constYYFINAL () { 59 }



sub constYYMAXTOKEN () { 319 }

my @yyname = (
"end-of-file",'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','',
'','','','','','','','','','','','','','','','','','','','','','','',"ARTICLE","BE","CHARACTER",
"FIRST_PERSON","FIRST_PERSON_POSSESSIVE","FIRST_PERSON_REFLEXIVE",
"NEGATIVE_ADJECTIVE","NEGATIVE_COMPARATIVE","NEGATIVE_NOUN","NEUTRAL_ADJECTIVE",
"NEUTRAL_NOUN","NOTHING","POSITIVE_ADJECTIVE","POSITIVE_COMPARATIVE",
"POSITIVE_NOUN","SECOND_PERSON","SECOND_PERSON_POSSESSIVE",
"SECOND_PERSON_REFLEXIVE","THIRD_PERSON_POSSESSIVE","COLON","COMMA",
"EXCLAMATION_MARK","LEFT_BRACKET","PERIOD","QUESTION_MARK","RIGHT_BRACKET",
"AND","AS","ENTER","EXEUNT","EXIT","HEART","IF_NOT","IF_SO","LESS","LET_US",
"LISTEN_TO","MIND","MORE","NOT","OPEN","PROCEED_TO","RECALL","REMEMBER",
"RETURN_TO","SPEAK","THAN","THE_CUBE_OF","THE_DIFFERENCE_BETWEEN",
"THE_FACTORIAL_OF","THE_PRODUCT_OF","THE_QUOTIENT_BETWEEN",
"THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN","THE_SQUARE_OF","THE_SQUARE_ROOT_OF",
"THE_SUM_OF","TWICE","WE_MUST","WE_SHALL","ACT_ROMAN","SCENE_ROMAN",
"ROMAN_NUMBER","NONMATCH",
);
my @yyrule = (
"\$accept : StartSymbol",
"StartSymbol : Play",
"Act : ActHeader Scene",
"Act : Act Scene",
"ActHeader : ACT_ROMAN COLON Comment EndSymbol",
"ActHeader : ACT_ROMAN COLON Comment error",
"ActHeader : ACT_ROMAN error Comment EndSymbol",
"Adjective : POSITIVE_ADJECTIVE",
"Adjective : NEUTRAL_ADJECTIVE",
"Adjective : NEGATIVE_ADJECTIVE",
"BinaryOperator : THE_DIFFERENCE_BETWEEN",
"BinaryOperator : THE_PRODUCT_OF",
"BinaryOperator : THE_QUOTIENT_BETWEEN",
"BinaryOperator : THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN",
"BinaryOperator : THE_SUM_OF",
"CharacterDeclaration : CHARACTER COMMA Comment EndSymbol",
"CharacterDeclaration : error COMMA Comment EndSymbol",
"CharacterDeclaration : CHARACTER error Comment EndSymbol",
"CharacterDeclarationList : CharacterDeclaration",
"CharacterDeclarationList : CharacterDeclarationList CharacterDeclaration",
"CharacterList : CHARACTER AND CHARACTER",
"CharacterList : CHARACTER COMMA CharacterList",
"Comment : String",
"Comment : error",
"Comparative : NegativeComparative",
"Comparative : PositiveComparative",
"Comparison : NOT NonnegatedComparison",
"Comparison : NonnegatedComparison",
"Conditional : IF_SO",
"Conditional : IF_NOT",
"Constant : ARTICLE UnarticulatedConstant",
"Constant : FIRST_PERSON_POSSESSIVE UnarticulatedConstant",
"Constant : SECOND_PERSON_POSSESSIVE UnarticulatedConstant",
"Constant : THIRD_PERSON_POSSESSIVE UnarticulatedConstant",
"Constant : NOTHING",
"EndSymbol : QuestionSymbol",
"EndSymbol : StatementSymbol",
"EnterExit : LEFT_BRACKET ENTER CHARACTER RIGHT_BRACKET",
"EnterExit : LEFT_BRACKET ENTER CharacterList RIGHT_BRACKET",
"EnterExit : LEFT_BRACKET EXIT CHARACTER RIGHT_BRACKET",
"EnterExit : LEFT_BRACKET EXEUNT CharacterList RIGHT_BRACKET",
"EnterExit : LEFT_BRACKET EXEUNT RIGHT_BRACKET",
"EnterExit : LEFT_BRACKET ENTER error RIGHT_BRACKET",
"EnterExit : LEFT_BRACKET EXIT error RIGHT_BRACKET",
"EnterExit : LEFT_BRACKET EXEUNT error RIGHT_BRACKET",
"EnterExit : LEFT_BRACKET error RIGHT_BRACKET",
"Equality : AS Adjective AS",
"Equality : AS error AS",
"Equality : AS Adjective error",
"Inequality : Comparative THAN",
"Inequality : Comparative error",
"InOut : OpenYour HEART StatementSymbol",
"InOut : SPEAK SECOND_PERSON_POSSESSIVE MIND StatementSymbol",
"InOut : LISTEN_TO SECOND_PERSON_POSSESSIVE HEART StatementSymbol",
"InOut : OpenYour MIND StatementSymbol",
"InOut : OpenYour error StatementSymbol",
"InOut : SPEAK error MIND StatementSymbol",
"InOut : LISTEN_TO error HEART StatementSymbol",
"InOut : SPEAK SECOND_PERSON_POSSESSIVE error StatementSymbol",
"InOut : LISTEN_TO SECOND_PERSON_POSSESSIVE error StatementSymbol",
"InOut : OpenYour HEART error",
"InOut : SPEAK SECOND_PERSON_POSSESSIVE MIND error",
"InOut : LISTEN_TO SECOND_PERSON_POSSESSIVE HEART error",
"InOut : OpenYour MIND error",
"Jump : JumpPhrase ACT_ROMAN StatementSymbol",
"Jump : JumpPhrase SCENE_ROMAN StatementSymbol",
"Jump : JumpPhrase error StatementSymbol",
"JumpPhrase : JumpPhraseBeginning JumpPhraseEnd",
"JumpPhrase : error JumpPhraseEnd",
"JumpPhrase : JumpPhraseBeginning error",
"JumpPhraseBeginning : LET_US",
"JumpPhraseBeginning : WE_MUST",
"JumpPhraseBeginning : WE_SHALL",
"JumpPhraseEnd : PROCEED_TO",
"JumpPhraseEnd : RETURN_TO",
"Line : CHARACTER COLON SentenceList",
"Line : CHARACTER COLON error",
"Line : CHARACTER error SentenceList",
"NegativeComparative : NEGATIVE_COMPARATIVE",
"NegativeComparative : MORE NEGATIVE_ADJECTIVE",
"NegativeComparative : LESS POSITIVE_ADJECTIVE",
"NegativeConstant : NegativeNoun",
"NegativeConstant : NEGATIVE_ADJECTIVE NegativeConstant",
"NegativeConstant : NEUTRAL_ADJECTIVE NegativeConstant",
"NegativeNoun : NEGATIVE_NOUN",
"NonnegatedComparison : Equality",
"NonnegatedComparison : Inequality",
"OpenYour : OPEN SECOND_PERSON_POSSESSIVE",
"OpenYour : OPEN error",
"Play : Title CharacterDeclarationList Act",
"Play : Play Act",
"Play : Title CharacterDeclarationList error",
"Play : Title error Act",
"Play : error CharacterDeclarationList Act",
"PositiveComparative : POSITIVE_COMPARATIVE",
"PositiveComparative : MORE POSITIVE_ADJECTIVE",
"PositiveComparative : LESS NEGATIVE_ADJECTIVE",
"PositiveConstant : PositiveNoun",
"PositiveConstant : POSITIVE_ADJECTIVE PositiveConstant",
"PositiveConstant : NEUTRAL_ADJECTIVE PositiveConstant",
"PositiveNoun : NEUTRAL_NOUN",
"PositiveNoun : POSITIVE_NOUN",
"Pronoun : FIRST_PERSON",
"Pronoun : FIRST_PERSON_REFLEXIVE",
"Pronoun : SECOND_PERSON",
"Pronoun : SECOND_PERSON_REFLEXIVE",
"Question : BE Value Comparison Value QuestionSymbol",
"Question : BE error Comparison Value QuestionSymbol",
"Question : BE Value error Value QuestionSymbol",
"Question : BE Value Comparison error QuestionSymbol",
"QuestionSymbol : QUESTION_MARK",
"Recall : RECALL String StatementSymbol",
"Recall : RECALL error StatementSymbol",
"Recall : RECALL String error",
"Remember : REMEMBER Value StatementSymbol",
"Remember : REMEMBER error StatementSymbol",
"Remember : REMEMBER Value error",
"Scene : SceneHeader SceneContents",
"SceneContents : EnterExit",
"SceneContents : Line",
"SceneContents : SceneContents EnterExit",
"SceneContents : SceneContents Line",
"SceneHeader : SCENE_ROMAN COLON Comment EndSymbol",
"SceneHeader : SCENE_ROMAN COLON Comment error",
"SceneHeader : SCENE_ROMAN error Comment EndSymbol",
"Sentence : UnconditionalSentence",
"Sentence : Conditional COMMA UnconditionalSentence",
"Sentence : Conditional error UnconditionalSentence",
"SentenceList : Sentence",
"SentenceList : SentenceList Sentence",
"Statement : SECOND_PERSON BE Constant StatementSymbol",
"Statement : SECOND_PERSON UnarticulatedConstant StatementSymbol",
"Statement : SECOND_PERSON BE Equality Value StatementSymbol",
"Statement : SECOND_PERSON BE Constant error",
"Statement : SECOND_PERSON BE error StatementSymbol",
"Statement : SECOND_PERSON error Constant StatementSymbol",
"Statement : SECOND_PERSON UnarticulatedConstant error",
"Statement : SECOND_PERSON error StatementSymbol",
"Statement : SECOND_PERSON BE Equality Value error",
"Statement : SECOND_PERSON BE Equality error StatementSymbol",
"Statement : SECOND_PERSON BE error Value StatementSymbol",
"Statement : SECOND_PERSON error Equality Value StatementSymbol",
"StatementSymbol : EXCLAMATION_MARK",
"StatementSymbol : PERIOD",
"String : StringSymbol",
"String : String StringSymbol",
"StringSymbol : ARTICLE",
"StringSymbol : BE",
"StringSymbol : CHARACTER",
"StringSymbol : FIRST_PERSON",
"StringSymbol : FIRST_PERSON_POSSESSIVE",
"StringSymbol : FIRST_PERSON_REFLEXIVE",
"StringSymbol : NEGATIVE_ADJECTIVE",
"StringSymbol : NEGATIVE_COMPARATIVE",
"StringSymbol : NEGATIVE_NOUN",
"StringSymbol : NEUTRAL_ADJECTIVE",
"StringSymbol : NEUTRAL_NOUN",
"StringSymbol : NOTHING",
"StringSymbol : POSITIVE_ADJECTIVE",
"StringSymbol : POSITIVE_COMPARATIVE",
"StringSymbol : POSITIVE_NOUN",
"StringSymbol : SECOND_PERSON",
"StringSymbol : SECOND_PERSON_POSSESSIVE",
"StringSymbol : SECOND_PERSON_REFLEXIVE",
"StringSymbol : THIRD_PERSON_POSSESSIVE",
"StringSymbol : COMMA",
"StringSymbol : AND",
"StringSymbol : AS",
"StringSymbol : ENTER",
"StringSymbol : EXEUNT",
"StringSymbol : EXIT",
"StringSymbol : HEART",
"StringSymbol : IF_NOT",
"StringSymbol : IF_SO",
"StringSymbol : LESS",
"StringSymbol : LET_US",
"StringSymbol : LISTEN_TO",
"StringSymbol : MIND",
"StringSymbol : MORE",
"StringSymbol : NOT",
"StringSymbol : OPEN",
"StringSymbol : PROCEED_TO",
"StringSymbol : RECALL",
"StringSymbol : REMEMBER",
"StringSymbol : RETURN_TO",
"StringSymbol : SPEAK",
"StringSymbol : THAN",
"StringSymbol : THE_CUBE_OF",
"StringSymbol : THE_DIFFERENCE_BETWEEN",
"StringSymbol : THE_FACTORIAL_OF",
"StringSymbol : THE_PRODUCT_OF",
"StringSymbol : THE_QUOTIENT_BETWEEN",
"StringSymbol : THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN",
"StringSymbol : THE_SQUARE_OF",
"StringSymbol : THE_SQUARE_ROOT_OF",
"StringSymbol : THE_SUM_OF",
"StringSymbol : TWICE",
"StringSymbol : WE_MUST",
"StringSymbol : WE_SHALL",
"StringSymbol : ACT_ROMAN",
"StringSymbol : SCENE_ROMAN",
"StringSymbol : ROMAN_NUMBER",
"StringSymbol : NONMATCH",
"Title : String EndSymbol",
"UnarticulatedConstant : PositiveConstant",
"UnarticulatedConstant : NegativeConstant",
"UnaryOperator : THE_CUBE_OF",
"UnaryOperator : THE_FACTORIAL_OF",
"UnaryOperator : THE_SQUARE_OF",
"UnaryOperator : THE_SQUARE_ROOT_OF",
"UnaryOperator : TWICE",
"UnconditionalSentence : InOut",
"UnconditionalSentence : Jump",
"UnconditionalSentence : Question",
"UnconditionalSentence : Recall",
"UnconditionalSentence : Remember",
"UnconditionalSentence : Statement",
"Value : CHARACTER",
"Value : Constant",
"Value : Pronoun",
"Value : BinaryOperator Value AND Value",
"Value : UnaryOperator Value",
"Value : BinaryOperator Value AND error",
"Value : BinaryOperator Value error Value",
"Value : BinaryOperator error AND Value",
"Value : UnaryOperator error",
);

sub yyclearin { $yychar = -1; }
sub yyerrok { $yyerrflag = 0; }
sub YYERROR { ++$yynerrs; &yy_err_recover; }
sub yy_err_recover
{
  if ($yyerrflag < 3)
  {
    $yyerrflag = 3;
    while (1)
    {
      if (($yyn = $yysindex[$yyss[$yyssp]]) &&
          ($yyn += constYYERRCODE()) >= 0 &&
          $yyn <= $#yycheck && $yycheck[$yyn] == constYYERRCODE())
      {

       print "yydebug: state $yyss[$yyssp], error recovery shifting",
             " to state $yytable[$yyn]\n" if $yydebug;

        $yyss[++$yyssp] = $yystate = $yytable[$yyn];
        $yyvs[++$yyvsp] = $yylval;
        next yyloop;
      }
      else
      {

        print "yydebug: error recovery discarding state ",
              $yyss[$yyssp], "\n" if $yydebug;

        return(1) if $yyssp <= 0;
        --$yyssp;
        --$yyvsp;
      }
    }
  }
  else
  {
    return (1) if $yychar == 0;

    if ($yydebug)
    {
      $yys = '';
      if ($yychar <= constYYMAXTOKEN()) { $yys = $yyname[$yychar]; }
      if (!$yys) { $yys = 'illegal-symbol'; }
      print "yydebug: state $yystate, error recovery discards ",
            "token $yychar ($yys)\n";
    }

    $yychar = -1;
    next yyloop;
  }
0;
} # yy_err_recover

sub yyparse
{

  if ($yys = $ENV{'YYDEBUG'})
  {
    $yydebug = int($1) if $yys =~ /^(\d)/;
  }


  $yynerrs = 0;
  $yyerrflag = 0;
  $yychar = (-1);

  $yyssp = 0;
  $yyvsp = 0;
  $yyss[$yyssp] = $yystate = 0;

yyloop: while(1)
  {
    yyreduce: {
      last yyreduce if ($yyn = $yydefred[$yystate]);
      if ($yychar < 0)
      {
        if (($yychar = &yylex) < 0) { $yychar = 0; }

        if ($yydebug)
        {
          $yys = '';
          if ($yychar <= $#yyname) { $yys = $yyname[$yychar]; }
          if (!$yys) { $yys = 'illegal-symbol'; };
          print "yydebug: state $yystate, reading $yychar ($yys)\n";
        }

      }
      if (($yyn = $yysindex[$yystate]) && ($yyn += $yychar) >= 0 &&
              $yyn <= $#yycheck && $yycheck[$yyn] == $yychar)
      {

        print "yydebug: state $yystate, shifting to state ",
              $yytable[$yyn], "\n" if $yydebug;

        $yyss[++$yyssp] = $yystate = $yytable[$yyn];
        $yyvs[++$yyvsp] = $yylval;
        $yychar = (-1);
        --$yyerrflag if $yyerrflag > 0;
        next yyloop;
      }
      if (($yyn = $yyrindex[$yystate]) && ($yyn += $yychar) >= 0 &&
            $yyn <= $#yycheck && $yycheck[$yyn] == $yychar)
      {
        $yyn = $yytable[$yyn];
        last yyreduce;
      }
      if (! $yyerrflag) {
        &yyerror('syntax error');
        ++$yynerrs;
      }
      return undef if &yy_err_recover;
    } # yyreduce

    print "yydebug: state $yystate, reducing by rule ",
          "$yyn ($yyrule[$yyn])\n" if $yydebug;

    $yym = $yylen[$yyn];
    $yyval = $yyvs[$yyvsp+1-$yym];
    switch:
    {
my $label = "State$yyn";
goto $label if exists $yystate{$label};
last switch;
State1: {
# 165 "Shakespeare.y"
{ $output = $yyvs[$yyvsp-0] unless $num_errors;
last switch;
} }
State2: {
# 168 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . ";\n" . $yyvs[$yyvsp-0];
last switch;
} }
State3: {
# 169 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . $yyvs[$yyvsp-0];
last switch;
} }
State4: {
# 173 "Shakespeare.y"
{
                  ($current_act = uc $yyvs[$yyvsp-3]) =~ tr/ /_/;
                  $yyval = "\n\n$current_act:\t" . $yyvs[$yyvsp-1];

last switch;
} }
State5: {
# 178 "Shakespeare.y"
{
                  report_warning("period or exclamation mark");
                  ($current_act = uc $yyvs[$yyvsp-3]) =~ tr/ /_/;
                  $yyval = "\n\n$current_act:\t" . $yyvs[$yyvsp-1];

last switch;
} }
State6: {
# 184 "Shakespeare.y"
{
                  report_warning("colon");
                  ($current_act = uc $yyvs[$yyvsp-3]) =~ tr/ /_/;
                  $yyval = "\n\n$current_act:\t" . $yyvs[$yyvsp-1];

last switch;
} }
State7: {
# 191 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State8: {
# 192 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State9: {
# 193 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State10: {
# 196 "Shakespeare.y"
{ $yyval = "int_sub";
last switch;
} }
State11: {
# 197 "Shakespeare.y"
{ $yyval = "int_mul" ;
last switch;
} }
State12: {
# 198 "Shakespeare.y"
{ $yyval = "int_div";
last switch;
} }
State13: {
# 199 "Shakespeare.y"
{ $yyval = "int_mod" ;
last switch;
} }
State14: {
# 200 "Shakespeare.y"
{ $yyval = "int_add";
last switch;
} }
State15: {
# 204 "Shakespeare.y"
{
                          $yyval = set_line()
                            . "my " . varname($yyvs[$yyvsp-3]) . " = "
                            . "\$play->declare_character('" . $yyvs[$yyvsp-3] . "');\t"
                            . $yyvs[$yyvsp-1];

last switch;
} }
State16: {
# 211 "Shakespeare.y"
{ $yyval = report_error("character name");
last switch;
} }
State17: {
# 213 "Shakespeare.y"
{ $yyval = report_error("comma");
last switch;
} }
State18: {
# 217 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State19: {
# 219 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . $yyvs[$yyvsp-0];
last switch;
} }
State20: {
# 223 "Shakespeare.y"
{ $yyval = [ $yyvs[$yyvsp-2], $yyvs[$yyvsp-0]];
last switch;
} }
State21: {
# 225 "Shakespeare.y"
{ push @{ $yyval = $yyvs[$yyvsp-0] }, $yyvs[$yyvsp-2];
last switch;
} }
State22: {
# 228 "Shakespeare.y"
{ $yyval = "# " . $yyvs[$yyvsp-0] . "\n";
last switch;
} }
State23: {
# 229 "Shakespeare.y"
{ report_warning("comment"); $yyval="";
last switch;
} }
State24: {
# 232 "Shakespeare.y"
{ $yyval = q{$comp1 < $comp2};
last switch;
} }
State25: {
# 233 "Shakespeare.y"
{ $yyval = q{$comp1 > $comp2};
last switch;
} }
State26: {
# 236 "Shakespeare.y"
{ $yyval = "!" . $yyvs[$yyvsp-0];
last switch;
} }
State27: {
# 237 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State28: {
# 240 "Shakespeare.y"
{ $yyval = q{$truth_flag};
last switch;
} }
State29: {
# 241 "Shakespeare.y"
{ $yyval = q{not($truth_flag)};
last switch;
} }
State30: {
# 244 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State31: {
# 245 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State32: {
# 246 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State33: {
# 247 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State34: {
# 248 "Shakespeare.y"
{ $yyval = "0";
last switch;
} }
State35: {
# 251 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State36: {
# 252 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State37: {
# 256 "Shakespeare.y"
{
                  $yyval = set_line() . '$play->enter_scene(' . varname($yyvs[$yyvsp-1]) . ");\n";

last switch;
} }
State38: {
# 260 "Shakespeare.y"
{
                  $yyval = "";
                  foreach my $character (@{ $yyvs[$yyvsp-1] }) {
                    $yyval .= set_line() . '$play->enter_scene(' . varname($character) . ");\n";
                  }

last switch;
} }
State39: {
# 267 "Shakespeare.y"
{
                  $yyval = set_line() . '$play->exit_scene(' . varname($yyvs[$yyvsp-1]) . ");\n";

last switch;
} }
State40: {
# 271 "Shakespeare.y"
{
                  $yyval = "";
                  foreach my $character (@{ $yyvs[$yyvsp-1] }) {
                    $yyval .= set_line() . '$play->exit_scene(' . varname($character) . ");\n";
                  }

last switch;
} }
State41: {
# 278 "Shakespeare.y"
{
                  $yyval = set_line() . "\$play->exit_scene_all;\n";

last switch;
} }
State42: {
# 282 "Shakespeare.y"
{
                  $yyval = report_error("character or character list");

last switch;
} }
State43: {
# 286 "Shakespeare.y"
{
                  $yyval = report_error("character");

last switch;
} }
State44: {
# 290 "Shakespeare.y"
{
                  $yyval = report_error("character list or nothing");

last switch;
} }
State45: {
# 294 "Shakespeare.y"
{
                  $yyval = report_error("'enter', 'exit' or 'exeunt'");

last switch;
} }
State46: {
# 299 "Shakespeare.y"
{ $yyval = q{$comp1 == $comp2};
last switch;
} }
State47: {
# 300 "Shakespeare.y"
{ $yyval = report_error("adjective");
last switch;
} }
State48: {
# 301 "Shakespeare.y"
{ $yyval = report_error("as");
last switch;
} }
State49: {
# 304 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1];
last switch;
} }
State50: {
# 305 "Shakespeare.y"
{ report_warning("'than'"); $yyval = $yyvs[$yyvsp-1];
last switch;
} }
State51: {
# 309 "Shakespeare.y"
{ $yyval = set_line() . "\$play->second_person->int_output;\n";
last switch;
} }
State52: {
# 311 "Shakespeare.y"
{ $yyval = set_line() . "\$play->second_person->char_output;\n";
last switch;
} }
State53: {
# 313 "Shakespeare.y"
{ $yyval = set_line() . "\$play->second_person->int_input;\n";
last switch;
} }
State54: {
# 315 "Shakespeare.y"
{ $yyval = set_line() . "\$play->second_person->char_input;\n";
last switch;
} }
State55: {
# 317 "Shakespeare.y"
{ $yyval = report_error("'mind' or 'heart'");
last switch;
} }
State56: {
# 319 "Shakespeare.y"
{
          report_warning("possessive pronoun, second person");
          $yyval = set_line() . "\$play->second_person->char_output;\n";

last switch;
} }
State57: {
# 324 "Shakespeare.y"
{
          report_warning("possessive pronoun, second person");
          $yyval = set_line() . "\$play->second_person->int_input;\n";

last switch;
} }
State58: {
# 329 "Shakespeare.y"
{
          report_warning("'mind'");
          $yyval = set_line() . "\$play->second_person->char_output;\n";

last switch;
} }
State59: {
# 334 "Shakespeare.y"
{
          report_warning("'heart'");
          $yyval = set_line() . "\$play->second_person->int_input;\n";

last switch;
} }
State60: {
# 339 "Shakespeare.y"
{
          report_warning("period or exclamation mark");
          $yyval = set_line() . "\$play->second_person->int_output;\n";

last switch;
} }
State61: {
# 344 "Shakespeare.y"
{
          report_warning("period or exclamation mark");
          $yyval = set_line() . "\$play->second_person->char_output;\n";

last switch;
} }
State62: {
# 349 "Shakespeare.y"
{
          report_warning("period or exclamation mark");
          $yyval = set_line() . "\$play->second_person->int_input;\n";

last switch;
} }
State63: {
# 354 "Shakespeare.y"
{
          report_warning("period or exclamation mark");
          $yyval = set_line() . "\$play->second_person->char_input;\n";

last switch;
} }
State64: {
# 361 "Shakespeare.y"
{
          ( my $label = uc $yyvs[$yyvsp-1]) =~ tr/ /_/;
          $yyval = "goto $label;\n";

last switch;
} }
State65: {
# 366 "Shakespeare.y"
{
          ( my $label = uc "$current_act " . uc $yyvs[$yyvsp-1]) =~ tr/ /_/;
          $yyval = "goto $label;\n";

last switch;
} }
State66: {
# 371 "Shakespeare.y"
{ $yyval = report_error("'act [roman number]' or 'scene [roman number]'");
last switch;
} }
State67: {
# 374 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . " " . $yyvs[$yyvsp-0];
last switch;
} }
State68: {
# 375 "Shakespeare.y"
{ $yyval = report_warning("'let us', 'we must' or 'we shall'");
last switch;
} }
State69: {
# 376 "Shakespeare.y"
{ $yyval = report_warning("'proceed to' or 'return to'");
last switch;
} }
State70: {
# 379 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State71: {
# 380 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State72: {
# 381 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State73: {
# 384 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State74: {
# 385 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State75: {
# 389 "Shakespeare.y"
{ $yyval = set_line() . '$play->activate_character(' . varname($yyvs[$yyvsp-2]) . ");\n" . $yyvs[$yyvsp-0];
last switch;
} }
State76: {
# 391 "Shakespeare.y"
{ $yyval = report_error("sentence list");
last switch;
} }
State77: {
# 393 "Shakespeare.y"
{ $yyval = report_error("colon");
last switch;
} }
State78: {
# 396 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State79: {
# 397 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . " " . $yyvs[$yyvsp-0];
last switch;
} }
State80: {
# 398 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . " " . $yyvs[$yyvsp-0];
last switch;
} }
State81: {
# 401 "Shakespeare.y"
{ $yyval = "(-1)";
last switch;
} }
State82: {
# 402 "Shakespeare.y"
{ $yyval = "2*" . $yyvs[$yyvsp-0];
last switch;
} }
State83: {
# 403 "Shakespeare.y"
{ $yyval = "2*" . $yyvs[$yyvsp-0];
last switch;
} }
State84: {
# 406 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State85: {
# 409 "Shakespeare.y"
{ $yyval = "(" . $yyvs[$yyvsp-0] . ")";
last switch;
} }
State86: {
# 410 "Shakespeare.y"
{ $yyval = "(" . $yyvs[$yyvsp-0] . ")";
last switch;
} }
State87: {
# 413 "Shakespeare.y"
{ $yyval = "";
last switch;
} }
State88: {
# 414 "Shakespeare.y"
{ $yyval = report_warning("possessive pronoun, second person");
last switch;
} }
State89: {
# 418 "Shakespeare.y"
{ $yyval = "# " . $yyvs[$yyvsp-2] . "\n" . $preamble . $yyvs[$yyvsp-1] . $yyvs[$yyvsp-0];
last switch;
} }
State90: {
# 420 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . $yyvs[$yyvsp-0];
last switch;
} }
State91: {
# 422 "Shakespeare.y"
{ $yyval = report_error("act");
last switch;
} }
State92: {
# 424 "Shakespeare.y"
{ $yyval = report_error("character declaration list");
last switch;
} }
State93: {
# 426 "Shakespeare.y"
{ report_warning("title"); $yyval = $preamble . $yyvs[$yyvsp-1] . $yyvs[$yyvsp-0];
last switch;
} }
State94: {
# 429 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State95: {
# 430 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . " " . $yyvs[$yyvsp-0];
last switch;
} }
State96: {
# 431 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . " " . $yyvs[$yyvsp-0];
last switch;
} }
State97: {
# 434 "Shakespeare.y"
{ $yyval = "1";
last switch;
} }
State98: {
# 435 "Shakespeare.y"
{ $yyval = "2*" . $yyvs[$yyvsp-0];
last switch;
} }
State99: {
# 436 "Shakespeare.y"
{ $yyval = "2*" . $yyvs[$yyvsp-0];
last switch;
} }
State100: {
# 439 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State101: {
# 440 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State102: {
# 443 "Shakespeare.y"
{ $yyval = '$play->first_person';
last switch;
} }
State103: {
# 444 "Shakespeare.y"
{ $yyval = '$play->first_person';
last switch;
} }
State104: {
# 445 "Shakespeare.y"
{ $yyval = '$play->second_person';
last switch;
} }
State105: {
# 446 "Shakespeare.y"
{ $yyval = '$play->second_person';
last switch;
} }
State106: {
# 450 "Shakespeare.y"
{
              $yyval = "\$comp1 = " . $yyvs[$yyvsp-3] . ";\n";
              $yyval .= "\$comp2 = " . $yyvs[$yyvsp-1] . ";\n";
              $yyval .= "\$truth_flag = " . $yyvs[$yyvsp-2] . ";\n";

last switch;
} }
State107: {
# 456 "Shakespeare.y"
{
              $yyval = report_error("value");

last switch;
} }
State108: {
# 460 "Shakespeare.y"
{
              $yyval = report_error("comparison");

last switch;
} }
State109: {
# 464 "Shakespeare.y"
{
              $yyval = report_error("value");

last switch;
} }
State111: {
# 473 "Shakespeare.y"
{
          $yyval = "\$play->second_person->pop;\n";

last switch;
} }
State112: {
# 477 "Shakespeare.y"
{
          report_warning("string");
          $yyval = "\$play->second_person->pop;\n";

last switch;
} }
State113: {
# 482 "Shakespeare.y"
{
          report_warning("period or exclamation mark");
          $yyval = "\$play->second_person->pop;\n";

last switch;
} }
State114: {
# 489 "Shakespeare.y"
{
            $yyval = '$play->second_person->push(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State115: {
# 493 "Shakespeare.y"
{
            $yyval = report_error("value");

last switch;
} }
State116: {
# 497 "Shakespeare.y"
{
            report_warning("period or exclamation mark");
            $yyval = '$play->second_person->push(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State117: {
# 503 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . $yyvs[$yyvsp-0];
last switch;
} }
State118: {
# 506 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State119: {
# 507 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State120: {
# 508 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . $yyvs[$yyvsp-0];
last switch;
} }
State121: {
# 509 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . $yyvs[$yyvsp-0];
last switch;
} }
State122: {
# 513 "Shakespeare.y"
{
                  ($current_scene = $current_act . "_" . uc $yyvs[$yyvsp-3]) =~ tr/ /_/;
                  $yyval = "\n$current_scene:\t" . $yyvs[$yyvsp-1] . "\n";

last switch;
} }
State123: {
# 518 "Shakespeare.y"
{
                  report_warning("period or exclamation mark");
                  ($current_scene = $current_act . "_" . uc $yyvs[$yyvsp-3]) =~ tr/ /_/;
                  $yyval = "\n$current_scene:\t" . $yyvs[$yyvsp-1] . "\n";

last switch;
} }
State124: {
# 524 "Shakespeare.y"
{
                  report_warning("colon");
                  ($current_scene = $current_act . "_" . uc $yyvs[$yyvsp-3]) =~ tr/ /_/;
                  $yyval = "\n$current_scene:\t" . $yyvs[$yyvsp-1] . "\n";

last switch;
} }
State125: {
# 532 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State126: {
# 534 "Shakespeare.y"
{ $yyval = "if (" . $yyvs[$yyvsp-2] . ") {\n" . $yyvs[$yyvsp-0] . "}\n";
last switch;
} }
State127: {
# 536 "Shakespeare.y"
{
                  report_warning("comma");
                  $yyval = "if (" . $yyvs[$yyvsp-2] . ") {\n" . $yyvs[$yyvsp-0] . "}\n";

last switch;
} }
State128: {
# 542 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State129: {
# 543 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . $yyvs[$yyvsp-0];
last switch;
} }
State130: {
# 547 "Shakespeare.y"
{
                $yyval = set_line() . '$play->second_person->assign(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State131: {
# 551 "Shakespeare.y"
{
                $yyval = set_line() . '$play->second_person->assign(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State132: {
# 555 "Shakespeare.y"
{
                $yyval = set_line() . '$play->second_person->assign(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State133: {
# 559 "Shakespeare.y"
{
                report_warning("period or exclamation mark");
                $yyval = set_line() . '$play->second_person->assign(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State134: {
# 564 "Shakespeare.y"
{
                $yyval = report_error("constant");

last switch;
} }
State135: {
# 568 "Shakespeare.y"
{
                report_warning("be");
                $yyval = set_line() . '$play->second_person->assign(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State136: {
# 573 "Shakespeare.y"
{
                report_warning("period or exclamation mark");
                $yyval = set_line() . '$play->second_person->assign(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State137: {
# 578 "Shakespeare.y"
{
                $yyval = report_error("constant without article");

last switch;
} }
State138: {
# 582 "Shakespeare.y"
{
                report_warning("period or exclamation mark");
                $yyval = set_line() . '$play->second_person->assign(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State139: {
# 587 "Shakespeare.y"
{
                $yyval = report_error("value");

last switch;
} }
State140: {
# 591 "Shakespeare.y"
{
                report_warning("equality");
                $yyval = set_line() . '$play->second_person->assign(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State141: {
# 596 "Shakespeare.y"
{
                report_warning("be");
                $yyval = set_line() . '$play->second_person->assign(' . $yyvs[$yyvsp-1] . ");\n";

last switch;
} }
State144: {
# 606 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State145: {
# 607 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1] . " " . $yyvs[$yyvsp-0];
last switch;
} }
State146: {
# 610 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State147: {
# 611 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State148: {
# 612 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State149: {
# 613 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State150: {
# 614 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State151: {
# 615 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State152: {
# 616 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State153: {
# 617 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State154: {
# 618 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State155: {
# 619 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State156: {
# 620 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State157: {
# 621 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State158: {
# 622 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State159: {
# 623 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State160: {
# 624 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State161: {
# 625 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State162: {
# 626 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State163: {
# 627 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State164: {
# 628 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State165: {
# 630 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State166: {
# 632 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State167: {
# 633 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State168: {
# 634 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State169: {
# 635 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State170: {
# 636 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State171: {
# 637 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State172: {
# 638 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State173: {
# 639 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State174: {
# 640 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State175: {
# 641 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State176: {
# 642 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State177: {
# 643 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State178: {
# 644 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State179: {
# 645 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State180: {
# 646 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State181: {
# 647 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State182: {
# 648 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State183: {
# 649 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State184: {
# 650 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State185: {
# 651 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State186: {
# 652 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State187: {
# 653 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State188: {
# 654 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State189: {
# 655 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State190: {
# 656 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State191: {
# 657 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State192: {
# 658 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State193: {
# 659 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State194: {
# 660 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State195: {
# 661 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State196: {
# 662 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State197: {
# 663 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State198: {
# 664 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State199: {
# 666 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State200: {
# 667 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State201: {
# 668 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State202: {
# 670 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State203: {
# 673 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-1];
last switch;
} }
State204: {
# 676 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State205: {
# 677 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State206: {
# 680 "Shakespeare.y"
{ $yyval = "int_cube";
last switch;
} }
State207: {
# 681 "Shakespeare.y"
{ $yyval = "int_factorial";
last switch;
} }
State208: {
# 682 "Shakespeare.y"
{ $yyval = "int_square";
last switch;
} }
State209: {
# 683 "Shakespeare.y"
{ $yyval = "int_sqrt";
last switch;
} }
State210: {
# 684 "Shakespeare.y"
{ $yyval = "int_twice";
last switch;
} }
State211: {
# 687 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State212: {
# 688 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State213: {
# 689 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State214: {
# 690 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State215: {
# 691 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State216: {
# 692 "Shakespeare.y"
{ $yyval = $yyvs[$yyvsp-0];
last switch;
} }
State217: {
# 696 "Shakespeare.y"
{
            $yyval = varname($yyvs[$yyvsp-0]) . '->value';

last switch;
} }
State218: {
# 700 "Shakespeare.y"
{
            $yyval = $yyvs[$yyvsp-0];

last switch;
} }
State219: {
# 704 "Shakespeare.y"
{
            $yyval = $yyvs[$yyvsp-0] . '->value';

last switch;
} }
State220: {
# 708 "Shakespeare.y"
{
            $yyval = '$play->' . $yyvs[$yyvsp-3] . "(" . $yyvs[$yyvsp-2] . "," . $yyvs[$yyvsp-0] . ")";

last switch;
} }
State221: {
# 712 "Shakespeare.y"
{
            $yyval = '$play->' . $yyvs[$yyvsp-1] . "(" . $yyvs[$yyvsp-0] . ")";

last switch;
} }
State222: {
# 716 "Shakespeare.y"
{
            $yyval = report_error("value");

last switch;
} }
State223: {
# 720 "Shakespeare.y"
{
            report_warning("'and'");
            $yyval = '$play->' . $yyvs[$yyvsp-3] . "(" . $yyvs[$yyvsp-2] . "," . $yyvs[$yyvsp-0] . ")";

last switch;
} }
State224: {
# 725 "Shakespeare.y"
{
            $yyval = report_error("value");

last switch;
} }
State225: {
# 729 "Shakespeare.y"
{
            $yyval = report_error("value");

last switch;
} }
# 2137 "y.tab.pl"
    } # switch
    $yyssp -= $yym;
    $yystate = $yyss[$yyssp];
    $yyvsp -= $yym;
    $yym = $yylhs[$yyn];
    if ($yystate == 0 && $yym == 0)
    {

      print "yydebug: after reduction, shifting from state 0 ",
            "to state constYYFINAL()\n" if $yydebug;

      $yystate = constYYFINAL();
      $yyss[++$yyssp] = constYYFINAL();
      $yyvs[++$yyvsp] = $yyval;
      if ($yychar < 0)
      {
        if (($yychar = &yylex) < 0) { $yychar = 0; }

        if ($yydebug)
        {
          $yys = '';
          if ($yychar <= $#yyname) { $yys = $yyname[$yychar]; }
          if (!$yys) { $yys = 'illegal-symbol'; }
          print "yydebug: state constYYFINAL(), reading $yychar ($yys)\n";
        }

      }
      return $yyvs[$yyvsp] if $yychar == 0;
      next yyloop;
    }
    if (($yyn = $yygindex[$yym]) && ($yyn += $yystate) >= 0 &&
        $yyn <= $#yycheck && $yycheck[$yyn] == $yystate)
    {
        $yystate = $yytable[$yyn];
    } else {
        $yystate = $yydgoto[$yym];
    }

    print "yydebug: after reduction, shifting from state ",
        "$yyss[$yyssp] to state $yystate\n" if $yydebug;

    $yyss[++$yyssp] = $yystate;
    $yyvs[++$yyvsp] = $yyval;
  } # yyloop
} # yyparse
# 735 "Shakespeare.y"
@yystate{qw(
State64 State61 State119 State201 State11 State115 State208 State79 State48 
State106 State98 State219 State206 State69 State105 State15 State157 
State196 State188 State221 State80 State90 State45 State167 State53 State2 
State151 State180 State92 State191 State29 State44 State23 State194 State73 
State7 State85 State39 State214 State134 State210 State153 State56 State55 
State224 State12 State197 State21 State216 State156 State139 State198 
State148 State155 State83 State203 State169 State130 State182 State160 
State109 State172 State66 State162 State82 State205 State135 State30 
State126 State102 State77 State42 State101 State89 State35 State63 State178 
State87 State131 State120 State74 State140 State122 State174 State186 
State138 State124 State94 State17 State68 State164 State46 State51 State96 
State133 State112 State19 State1 State144 State177 State200 State185 
State25 State137 State22 State4 State147 State128 State3 State213 State132 
State179 State78 State114 State14 State59 State195 State16 State49 State218 
State152 State107 State125 State189 State10 State65 State190 State38 
State57 State211 State33 State71 State99 State8 State36 State181 State54 
State158 State84 State215 State222 State166 State28 State225 State202 
State6 State170 State13 State93 State26 State72 State199 State173 State207 
State192 State41 State161 State116 State175 State20 State146 State31 
State159 State129 State168 State121 State34 State27 State150 State127 
State223 State5 State37 State67 State220 State176 State136 State47 State165 
State111 State62 State43 State91 State163 State100 State32 State52 State9 
State209 State103 State145 State97 State104 State76 State81 State154 
State58 State187 State50 State149 State18 State75 State212 State113 
State108 State171 State88 State118 State184 State40 State117 State141 
State60 State204 State183 State86 State217 State70 State95 State193 State24 
State123
)} = ();

my %act_or_scene = ( act => constACT_ROMAN(), scene => constSCENE_ROMAN() );


my %R2A = qw(
        I 1 IV 4 V 5 IX 9
        X 10 XL 40 L 50 XC 90
        C 100 CD 400 D 500 CM 900
        M 1000
);

sub roman {
  my $r = uc(shift);

  return unless length($r) and $r =~ /^M*(C[DM]|D?C{1,3}ID)?(X[LC]|L?X{1,3}|L)?(I[VX]|V?I{1,3}|V)?$/;
  my $n = 0;
  while($r =~ /\G(I[VX]?|X[LC]?|C[DM]|[VLMD])/g) {
    $n += $R2A{$1};
  }
  $n
}


my $type = 0;
my %word;
while(<DATA>) {
  chomp;
  if (s/^\$//) {
    no strict;
    $type = eval "const$_();";
  }
  else {
    my @words = split(/\s+/, lc $_);
    my $parent = \(\%word );
    foreach my $w (@words) {
      $$parent ||= {};
      $$parent = { '' => $$parent } if 'HASH' ne ref $$parent;
      $parent = \(${$parent}->{$w});
    }
   $$parent = $type;
  }
}


sub get_tokens {
  local $_ = "";
  while (filter_read() > 0) {
    ++$yylineno;
    push @token, /[-\w']+|[:,!\[.\?\]]/g and return 1; # '
  }
  return 0;
}

sub __yylex { my $n = _yylex(); warn "$n $yylval\n"; $n }

sub yylex {
  get_tokens() or return -1
    unless @token;
  $yylval = shift @token;
  my $type = $word{lc $yylval};

  if (defined $type) {
    return $type unless ref $type;
    my @word = ($yylval);
    my @type = ($type);
    while (1) {
      get_tokens() or last
        unless @token;
      my $next_type = $type->{lc $token[0]} or last;
      push @word, shift @token;
      $yylval = join(" ",@word), return $next_type unless ref $next_type;
      push @type, ($type = $next_type);
    }
    while ($type = pop @type) {
      if ($type = $type->{''}) {
        $yylval = join(" ",@word);
        return $type;
      }
      last if @word == 1;
    }
  }

  if ($yylval =~ /^(act|scene)$/i and (@token or get_tokens()) and roman($token[0])) {
    my $n = $act_or_scene{lc $yylval};
    $yylval .= " " . shift @token;
    return $n;
  }

  if (roman($yylval)) {
    return constROMAN_NUMBER();
  }

  return constNONMATCH();
}

sub yyerror {
  $yyerrflag = 0;
}

sub report_error {
  my $expected_symbol = shift;
  warn sprintf("Error at line %d: %s expected\n", $yylineno, $expected_symbol);
  $num_errors++;
  "";
}

sub report_warning {
  my $expected_symbol = shift;
  warn sprintf("Warning at line %d: %s expected\n", $yylineno, $expected_symbol);
  $num_warnings++;
  "";
}


sub filter {
  $num_errors = $num_warnings = 0;
  @token = ();

  get_tokens() or return 0;

  yyparse();

  die("$num_errors errors and $num_warnings warnings found. No code output.\n")
    if $num_errors;

  warn("$num_warnings warnings found. Code may be defective.\n")
    if $num_warnings;

  $_ = $output;

  return 1;
}

1;
# 2320 "y.tab.pl"
__DATA__
$ARTICLE
a
an
the
$BE
am
are
art
be
is
$CHARACTER
Achilles
Adonis
Adriana
Aegeon
Aemilia
Agamemnon
Agrippa
Ajax
Alonso
Andromache
Angelo
Antiochus
Antonio
Arthur
Autolycus
Balthazar
Banquo
Beatrice
Benedick
Benvolio
Bianca
Brabantio
Brutus
Capulet
Cassandra
Cassius
Christopher Sly
Cicero
Claudio
Claudius
Cleopatra
Cordelia
Cornelius
Cressida
Cymberline
Demetrius
Desdemona
Dionyza
Doctor Caius
Dogberry
Don John
Don Pedro
Donalbain
Dorcas
Duncan
Egeus
Emilia
Escalus
Falstaff
Fenton
Ferdinand
Ford
Fortinbras
Francisca
Friar John
Friar Laurence
Gertrude
Goneril
Hamlet
Hecate
Hector
Helen
Helena
Hermia
Hermonie
Hippolyta
Horatio
Imogen
Isabella
John of Gaunt
John of Lancaster
Julia
Juliet
Julius Caesar
King Henry
King John
King Lear
King Richard
Lady Capulet
Lady Macbeth
Lady Macduff
Lady Montague
Lennox
Leonato
Luciana
Lucio
Lychorida
Lysander
Macbeth
Macduff
Malcolm
Mariana
Mark Antony
Mercutio
Miranda
Mistress Ford
Mistress Overdone
Mistress Page
Montague
Mopsa
Oberon
Octavia
Octavius Caesar
Olivia
Ophelia
Orlando
Orsino
Othello
Page
Pantino
Paris
Pericles
Pinch
Polonius
Pompeius
Portia
Priam
Prince Henry
Prospero
Proteus
Publius
Puck
Queen Elinor
Regan
Robin
Romeo
Rosalind
Sebastian
Shallow
Shylock
Slender
Solinus
Stephano
Thaisa
The Abbot of Westminster
The Apothecary
The Archbishop of Canterbury
The Duke of Milan
The Duke of Venice
The Ghost
Theseus
Thurio
Timon
Titania
Titus
Troilus
Tybalt
Ulysses
Valentine
Venus
Vincentio
Viola
$FIRST_PERSON
I
me
$FIRST_PERSON_POSSESSIVE
mine
my
$FIRST_PERSON_REFLEXIVE
myself
$NEGATIVE_ADJECTIVE
bad
cowardly
cursed
damned
dirty
disgusting
distasteful
dusty
evil
fat
fat-kidneyed
fatherless
foul
hairy
half-witted
horrible
horrid
infected
lying
miserable
misused
oozing
rotten
rotten
smelly
snotty
sorry
stinking
stuffed
stupid
vile
villainous
worried
$NEGATIVE_COMPARATIVE
punier
smaller
worse
$NEGATIVE_NOUN
Hell
Microsoft
bastard
beggar
blister
codpiece
coward
curse
death
devil
draught
famine
flirt-gill
goat
hate
hog
hound
leech
lie
pig
plague
starvation
toad
war
wolf
$NEUTRAL_ADJECTIVE
big
black
blue
bluest
bottomless
furry
green
hard
huge
large
little
normal
old
purple
red
rural
small
tiny
white
yellow
$NEUTRAL_NOUN
animal
aunt
brother
cat
chihuahua
cousin
cow
daughter
door
face
father
fellow
granddaughter
grandfather
grandmother
grandson
hair
hamster
horse
lamp
lantern
mistletoe
moon
morning
mother
nephew
niece
nose
purse
road
roman
sister
sky
son
squirrel
stone wall
thing
town
tree
uncle
wind
$NOTHING
nothing
zero
$POSITIVE_ADJECTIVE
amazing
beautiful
blossoming
bold
brave
charming
clearest
cunning
cute
delicious
embroidered
fair
fine
gentle
golden
good
handsome
happy
healthy
honest
lovely
loving
mighty
noble
peaceful
pretty
prompt
proud
reddest
rich
smooth
sunny
sweet
sweetest
trustworthy
warm
$POSITIVE_COMPARATIVE
better
bigger
fresher
friendlier
nicer
jollier
$POSITIVE_NOUN
Heaven
King
Lord
angel
flower
happiness
joy
plum
summer's day
hero
rose
kingdom
pony
$SECOND_PERSON
thee
thou
you
$SECOND_PERSON_POSSESSIVE
thine
thy
your
$SECOND_PERSON_REFLEXIVE
thyself
yourself
$THIRD_PERSON_POSSESSIVE
his
her
its
their
$AND
and                                    
$AS
as                                    
$ENTER
enter                                    
$EXEUNT
exeunt                                    
$EXIT
exit                                    
$HEART
heart                                    
$IF_NOT
if not                                    
$IF_SO
if so                                    
$LESS
less                                    
$LET_US
let us                                    
$LISTEN_TO
listen to                                    
$MIND
mind                                    
$MORE
more                                    
$NOT
not                                    
$OPEN
open                                    
$PROCEED_TO
proceed to                                    
$RECALL
recall                                    
$REMEMBER
remember                                    
$RETURN_TO
return to                                    
$SPEAK
speak                                    
$THAN
than                                    
$THE_CUBE_OF
the cube of                                    
$THE_DIFFERENCE_BETWEEN
the difference between                                    
$THE_FACTORIAL_OF
the factorial of                                    
$THE_PRODUCT_OF
the product of                                    
$THE_QUOTIENT_BETWEEN
the quotient between                                    
$THE_REMAINDER_OF_THE_QUOTIENT_BETWEEN
the remainder of the quotient between                                    
$THE_SQUARE_OF
the square of                                    
$THE_SQUARE_ROOT_OF
the square root of                                    
$THE_SUM_OF
the sum of                                    
$TWICE
twice                                    
$WE_MUST
we must                                    
$WE_SHALL
we shall                                    
$COLON
:
$COMMA
,
$EXCLAMATION_MARK
!
$LEFT_BRACKET
[
$PERIOD
.
$QUESTION_MARK
?
$RIGHT_BRACKET
]
