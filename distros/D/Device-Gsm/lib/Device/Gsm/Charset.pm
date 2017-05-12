# Device::Gsm::Charset - GSM0338 <=> ASCII charset conversion module
# Copyright (C) 2004-2015 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.

package Device::Gsm::Charset;
$VERSION = $Device::Gsm::VERSION;

use strict;
use constant NPC7   => 0x3F;
use constant NPC8   => 0x3F;
use constant ESCAPE => 0x1B;

# The following is the GSM 3.38 standard charset, as shown
# on some Siemens documentation found on the internet

#my $gsm_charset = join('',
#	'@»$»»»»»»»'."\n".'»»'."\r".'»»»',  # 16
#	'»»»»»»»»»»»»ß»»',
#	' !"# %&‘()*+,-./',
#	'0123456789:;<=>?',
#	'-ABCDEFGHIJKLMNO',
#	'PQRSTUVWXYZÄÖ»Ü»',
#	'¨abcdefghijklmno',
#	'pqrstuvwxyzäö»ü»'
#);

#
# These conversion tables are taken from pduconv 0.1 library
# by Mats Engstrom <mats at nerdlabs dot org>. See also:
# http://www.mikrocontroller.net/attachment/104082/pduconv.c
# and
# https://github.com/rdmeneze/SMSBox-PIC/tree/master/source/pdu_conv
#
# Un grazie a Stefano!
#

@Device::Gsm::Charset::GSM0338_TO_ISO8859 = (
    64,      #  0      @  COMMERCIAL AT                           */
    163,     #  1      £  POUND SIGN                              */
    36,      #  2      $  DOLLAR SIGN                             */
    165,     #  3      ¥  YEN SIGN                                */
    232,     #  4      è  LATIN SMALL LETTER E WITH GRAVE         */
    233,     #  5      é  LATIN SMALL LETTER E WITH ACUTE         */
    249,     #  6      ù  LATIN SMALL LETTER U WITH GRAVE         */
    236,     #  7      ì  LATIN SMALL LETTER I WITH GRAVE         */
    242,     #  8      ò  LATIN SMALL LETTER O WITH GRAVE         */
    199,     #  9      Ç  LATIN CAPITAL LETTER C WITH CEDILLA     */
    10,      #  10        LINE FEED                               */
    216,     #  11     Ø  LATIN CAPITAL LETTER O WITH STROKE      */
    248,     #  12     ø  LATIN SMALL LETTER O WITH STROKE        */
    13,      #  13        CARRIAGE RETURN                         */
    197,     #  14     Å  LATIN CAPITAL LETTER A WITH RING ABOVE  */
    229,     #  15     å  LATIN SMALL LETTER A WITH RING ABOVE    */
    NPC8,    #  16        GREEK CAPITAL LETTER DELTA              */
    95,      #  17     _  LOW LINE                                */
    NPC8,    #  18        GREEK CAPITAL LETTER PHI                */
    NPC8,    #  19        GREEK CAPITAL LETTER GAMMA              */
    NPC8,    #  20        GREEK CAPITAL LETTER LAMBDA             */
    NPC8,    #  21        GREEK CAPITAL LETTER OMEGA              */
    NPC8,    #  22        GREEK CAPITAL LETTER PI                 */
    NPC8,    #  23        GREEK CAPITAL LETTER PSI                */
    NPC8,    #  24        GREEK CAPITAL LETTER SIGMA              */
    NPC8,    #  25        GREEK CAPITAL LETTER THETA              */
    NPC8,    #  26        GREEK CAPITAL LETTER XI                 */
    27,      #  27        ESCAPE TO EXTENSION TABLE               */
    198,     #  28     Æ  LATIN CAPITAL LETTER AE                 */
    230,     #  29     æ  LATIN SMALL LETTER AE                   */
    223,     #  30     ß  LATIN SMALL LETTER SHARP S (German)     */
    201,     #  31     É  LATIN CAPITAL LETTER E WITH ACUTE       */
    32,      #  32        SPACE                                   */
    33,      #  33     !  EXCLAMATION MARK                        */
    34,      #  34     "  QUOTATION MARK                          */
    35,      #  35     #  NUMBER SIGN                             */
    164,     #  36     ¤  CURRENCY SIGN                           */
    37,      #  37     %  PERCENT SIGN                            */
    38,      #  38     &  AMPERSAND                               */
    39,      #  39     '  APOSTROPHE                              */
    40,      #  40     (  LEFT PARENTHESIS                        */
    41,      #  41     )  RIGHT PARENTHESIS                       */
    42,      #  42     *  ASTERISK                                */
    43,      #  43     +  PLUS SIGN                               */
    44,      #  44     ,  COMMA                                   */
    45,      #  45     -  HYPHEN-MINUS                            */
    46,      #  46     .  FULL STOP                               */
    47,      #  47     /  SOLIDUS (SLASH)                         */
    48,      #  48     0  DIGIT ZERO                              */
    49,      #  49     1  DIGIT ONE                               */
    50,      #  50     2  DIGIT TWO                               */
    51,      #  51     3  DIGIT THREE                             */
    52,      #  52     4  DIGIT FOUR                              */
    53,      #  53     5  DIGIT FIVE                              */
    54,      #  54     6  DIGIT SIX                               */
    55,      #  55     7  DIGIT SEVEN                             */
    56,      #  56     8  DIGIT EIGHT                             */
    57,      #  57     9  DIGIT NINE                              */
    58,      #  58     :  COLON                                   */
    59,      #  59     ;  SEMICOLON                               */
    60,      #  60     <  LESS-THAN SIGN                          */
    61,      #  61     =  EQUALS SIGN                             */
    62,      #  62     >  GREATER-THAN SIGN                       */
    63,      #  63     ?  QUESTION MARK                           */
    161,     #  64     ¡  INVERTED EXCLAMATION MARK               */
    65,      #  65     A  LATIN CAPITAL LETTER A                  */
    66,      #  66     B  LATIN CAPITAL LETTER B                  */
    67,      #  67     C  LATIN CAPITAL LETTER C                  */
    68,      #  68     D  LATIN CAPITAL LETTER D                  */
    69,      #  69     E  LATIN CAPITAL LETTER E                  */
    70,      #  70     F  LATIN CAPITAL LETTER F                  */
    71,      #  71     G  LATIN CAPITAL LETTER G                  */
    72,      #  72     H  LATIN CAPITAL LETTER H                  */
    73,      #  73     I  LATIN CAPITAL LETTER I                  */
    74,      #  74     J  LATIN CAPITAL LETTER J                  */
    75,      #  75     K  LATIN CAPITAL LETTER K                  */
    76,      #  76     L  LATIN CAPITAL LETTER L                  */
    77,      #  77     M  LATIN CAPITAL LETTER M                  */
    78,      #  78     N  LATIN CAPITAL LETTER N                  */
    79,      #  79     O  LATIN CAPITAL LETTER O                  */
    80,      #  80     P  LATIN CAPITAL LETTER P                  */
    81,      #  81     Q  LATIN CAPITAL LETTER Q                  */
    82,      #  82     R  LATIN CAPITAL LETTER R                  */
    83,      #  83     S  LATIN CAPITAL LETTER S                  */
    84,      #  84     T  LATIN CAPITAL LETTER T                  */
    85,      #  85     U  LATIN CAPITAL LETTER U                  */
    86,      #  86     V  LATIN CAPITAL LETTER V                  */
    87,      #  87     W  LATIN CAPITAL LETTER W                  */
    88,      #  88     X  LATIN CAPITAL LETTER X                  */
    89,      #  89     Y  LATIN CAPITAL LETTER Y                  */
    90,      #  90     Z  LATIN CAPITAL LETTER Z                  */
    196,     #  91     Ä  LATIN CAPITAL LETTER A WITH DIAERESIS   */
    214,     #  92     Ö  LATIN CAPITAL LETTER O WITH DIAERESIS   */
    209,     #  93     Ñ  LATIN CAPITAL LETTER N WITH TILDE       */
    220,     #  94     Ü  LATIN CAPITAL LETTER U WITH DIAERESIS   */
    167,     #  95     §  SECTION SIGN                            */
    191,     #  96     ¿  INVERTED QUESTION MARK                  */
    97,      #  97     a  LATIN SMALL LETTER A                    */
    98,      #  98     b  LATIN SMALL LETTER B                    */
    99,      #  99     c  LATIN SMALL LETTER C                    */
    100,     #  100    d  LATIN SMALL LETTER D                    */
    101,     #  101    e  LATIN SMALL LETTER E                    */
    102,     #  102    f  LATIN SMALL LETTER F                    */
    103,     #  103    g  LATIN SMALL LETTER G                    */
    104,     #  104    h  LATIN SMALL LETTER H                    */
    105,     #  105    i  LATIN SMALL LETTER I                    */
    106,     #  106    j  LATIN SMALL LETTER J                    */
    107,     #  107    k  LATIN SMALL LETTER K                    */
    108,     #  108    l  LATIN SMALL LETTER L                    */
    109,     #  109    m  LATIN SMALL LETTER M                    */
    110,     #  110    n  LATIN SMALL LETTER N                    */
    111,     #  111    o  LATIN SMALL LETTER O                    */
    112,     #  112    p  LATIN SMALL LETTER P                    */
    113,     #  113    q  LATIN SMALL LETTER Q                    */
    114,     #  114    r  LATIN SMALL LETTER R                    */
    115,     #  115    s  LATIN SMALL LETTER S                    */
    116,     #  116    t  LATIN SMALL LETTER T                    */
    117,     #  117    u  LATIN SMALL LETTER U                    */
    118,     #  118    v  LATIN SMALL LETTER V                    */
    119,     #  119    w  LATIN SMALL LETTER W                    */
    120,     #  120    x  LATIN SMALL LETTER X                    */
    121,     #  121    y  LATIN SMALL LETTER Y                    */
    122,     #  122    z  LATIN SMALL LETTER Z                    */
    228,     #  123    ä  LATIN SMALL LETTER A WITH DIAERESIS     */
    246,     #  124    ö  LATIN SMALL LETTER O WITH DIAERESIS     */
    241,     #  125    ñ  LATIN SMALL LETTER N WITH TILDE         */
    252,     #  126    ü  LATIN SMALL LETTER U WITH DIAERESIS     */
    224,     #  127    à  LATIN SMALL LETTER A WITH GRAVE         */

    #   12             27 10      FORM FEED
    #   94             27 20   ^  CIRCUMFLEX ACCENT
    #   123            27 40   {  LEFT CURLY BRACKET
    #   125            27 41   }  RIGHT CURLY BRACKET
    #   92             27 47   \  REVERSE SOLIDUS (BACKSLASH)
    #   91             27 60   [  LEFT SQUARE BRACKET
    #   126            27 61   ~  TILDE
    #   93             27 62   ]  RIGHT SQUARE BRACKET
    #   124            27 64   |  VERTICAL BAR                             */
);

#my $gsm_charset = join '' => map chr => @GSM0338_TO_ISO8859;

@Device::Gsm::Charset::ISO8859_TO_GSM0338 = (
    NPC7,        #     0      null [NUL]                              */
    NPC7,        #     1      start of heading [SOH]                  */
    NPC7,        #     2      start of text [STX]                     */
    NPC7,        #     3      end of text [ETX]                       */
    NPC7,        #     4      end of transmission [EOT]               */
    NPC7,        #     5      enquiry [ENQ]                           */
    NPC7,        #     6      acknowledge [ACK]                       */
    NPC7,        #     7      bell [BEL]                              */
    NPC7,        #     8      backspace [BS]                          */
    NPC7,        #     9      horizontal tab [HT]                     */
    10,          #    10      line feed [LF]                          */
    NPC7,        #    11      vertical tab [VT]                       */
    10 + 256,    #    12      form feed [FF]                          */
    13,          #    13      carriage return [CR]                    */
    NPC7,        #    14      shift out [SO]                          */
    NPC7,        #    15      shift in [SI]                           */
    NPC7,        #    16      data link escape [DLE]                  */
    NPC7,        #    17      device control 1 [DC1]                  */
    NPC7,        #    18      device control 2 [DC2]                  */
    NPC7,        #    19      device control 3 [DC3]                  */
    NPC7,        #    20      device control 4 [DC4]                  */
    NPC7,        #    21      negative acknowledge [NAK]              */
    NPC7,        #    22      synchronous idle [SYN]                  */
    NPC7,        #    23      end of trans. block [ETB]               */
    NPC7,        #    24      cancel [CAN]                            */
    NPC7,        #    25      end of medium [EM]                      */
    NPC7,        #    26      substitute [SUB]                        */
    NPC7,        #    27      escape [ESC]                            */
    NPC7,        #    28      file separator [FS]                     */
    NPC7,        #    29      group separator [GS]                    */
    NPC7,        #    30      record separator [RS]                   */
    NPC7,        #    31      unit separator [US]                     */
    32,          #    32      space                                   */
    33,          #    33    ! exclamation mark                        */
    34,          #    34    " double quotation mark                   */
    35,          #    35    # number sign                             */
    2,           #    36    $ dollar sign                             */
    37,          #    37    % percent sign                            */
    38,          #    38    & ampersand                               */
    39,          #    39    ' apostrophe                              */
    40,          #    40    ( left parenthesis                        */
    41,          #    41    ) right parenthesis                       */
    42,          #    42    * asterisk                                */
    43,          #    43    + plus sign                               */
    44,          #    44    , comma                                   */
    45,          #    45    - hyphen                                  */
    46,          #    46    . period                                  */
    47,          #    47    / slash,                                  */
    48,          #    48    0 digit 0                                 */
    49,          #    49    1 digit 1                                 */
    50,          #    50    2 digit 2                                 */
    51,          #    51    3 digit 3                                 */
    52,          #    52    4 digit 4                                 */
    53,          #    53    5 digit 5                                 */
    54,          #    54    6 digit 6                                 */
    55,          #    55    7 digit 7                                 */
    56,          #    56    8 digit 8                                 */
    57,          #    57    9 digit 9                                 */
    58,          #    58    : colon                                   */
    59,          #    59    ; semicolon                               */
    60,          #    60    < less-than sign                          */
    61,          #    61    = equal sign                              */
    62,          #    62    > greater-than sign                       */
    63,          #    63    ? question mark                           */
    0,           #    64    @ commercial at sign                      */
    65,          #    65    A uppercase A                             */
    66,          #    66    B uppercase B                             */
    67,          #    67    C uppercase C                             */
    68,          #    68    D uppercase D                             */
    69,          #    69    E uppercase E                             */
    70,          #    70    F uppercase F                             */
    71,          #    71    G uppercase G                             */
    72,          #    72    H uppercase H                             */
    73,          #    73    I uppercase I                             */
    74,          #    74    J uppercase J                             */
    75,          #    75    K uppercase K                             */
    76,          #    76    L uppercase L                             */
    77,          #    77    M uppercase M                             */
    78,          #    78    N uppercase N                             */
    79,          #    79    O uppercase O                             */
    80,          #    80    P uppercase P                             */
    81,          #    81    Q uppercase Q                             */
    82,          #    82    R uppercase R                             */
    83,          #    83    S uppercase S                             */
    84,          #    84    T uppercase T                             */
    85,          #    85    U uppercase U                             */
    86,          #    86    V uppercase V                             */
    87,          #    87    W uppercase W                             */
    88,          #    88    X uppercase X                             */
    89,          #    89    Y uppercase Y                             */
    90,          #    90    Z uppercase Z                             */
    60 + 256,    #    91    [ left square bracket                     */
    47 + 256,    #    92    \ backslash                               */
    62 + 256,    #    93    ] right square bracket                    */
    20 + 256,    #    94    ^ circumflex accent                       */
    17,          #    95    _ underscore                              */
    -39,         #    96    ` back apostrophe                         */
    97,          #    97    a lowercase a                             */
    98,          #    98    b lowercase b                             */
    99,          #    99    c lowercase c                             */
    100,         #   100    d lowercase d                             */
    101,         #   101    e lowercase e                             */
    102,         #   102    f lowercase f                             */
    103,         #   103    g lowercase g                             */
    104,         #   104    h lowercase h                             */
    105,         #   105    i lowercase i                             */
    106,         #   106    j lowercase j                             */
    107,         #   107    k lowercase k                             */
    108,         #   108    l lowercase l                             */
    109,         #   109    m lowercase m                             */
    110,         #   110    n lowercase n                             */
    111,         #   111    o lowercase o                             */
    112,         #   112    p lowercase p                             */
    113,         #   113    q lowercase q                             */
    114,         #   114    r lowercase r                             */
    115,         #   115    s lowercase s                             */
    116,         #   116    t lowercase t                             */
    117,         #   117    u lowercase u                             */
    118,         #   118    v lowercase v                             */
    119,         #   119    w lowercase w                             */
    120,         #   120    x lowercase x                             */
    121,         #   121    y lowercase y                             */
    122,         #   122    z lowercase z                             */
    40 + 256,    #   123    { left brace                              */
    64 + 256,    #   124    | vertical bar                            */
    41 + 256,    #   125    } right brace                             */
    61 + 256,    #   126    ~ tilde accent                            */
    NPC7,        #   127      delete [DEL]                            */
    NPC7,        #   128                                              */
    NPC7,        #   129                                              */
    -39,         #   130      low left rising single quote            */
    -102,        #   131      lowercase italic f                      */
    -34,         #   132      low left rising double quote            */
    NPC7,        #   133      low horizontal ellipsis                 */
    NPC7,        #   134      dagger mark                             */
    NPC7,        #   135      double dagger mark                      */
    NPC7,        #   136      letter modifying circumflex             */
    NPC7,        #   137      per thousand (mille) sign               */
    -83,         #   138      uppercase S caron or hacek              */
    -39,         #   139      left single angle quote mark            */
    -214,        #   140      uppercase OE ligature                   */
    NPC7,        #   141                                              */
    NPC7,        #   142                                              */
    NPC7,        #   143                                              */
    NPC7,        #   144                                              */
    -39,         #   145      left single quotation mark              */
    -39,         #   146      right single quote mark                 */
    -34,         #   147      left double quotation mark              */
    -34,         #   148      right double quote mark                 */
    -42,         #   149      round filled bullet                     */
    -45,         #   150      en dash                                 */
    -45,         #   151      em dash                                 */
    -39,         #   152      small spacing tilde accent              */
    NPC7,        #   153      trademark sign                          */
    -115,        #   154      lowercase s caron or hacek              */
    -39,         #   155      right single angle quote mark           */
    -111,        #   156      lowercase oe ligature                   */
    NPC7,        #   157                                              */
    NPC7,        #   158                                              */
    -89,         #   159      uppercase Y dieresis or umlaut          */
    -32,         #   160      non-breaking space                      */
    64,          #   161    ¡ inverted exclamation mark               */
    -99,         #   162    ¢ cent sign                               */
    1,           #   163    £ pound sterling sign                     */
    36,          #   164    ¤ general currency sign                   */
    3,           #   165    ¥ yen sign                                */
    -33,         #   166    ¦ broken vertical bar                     */
    95,          #   167    § section sign                            */
    -34,         #   168    ¨ spacing dieresis or umlaut              */
    NPC7,        #   169    © copyright sign                          */
    NPC7,        #   170    ª feminine ordinal indicator              */
    -60,         #   171    « left (double) angle quote               */
    NPC7,        #   172    ¬ logical not sign                        */
    -45,         #   173    ­ soft hyphen                             */
    NPC7,        #   174    ® registered trademark sign               */
    NPC7,        #   175    ¯ spacing macron (long) accent            */
    NPC7,        #   176    ° degree sign                             */
    NPC7,        #   177    ± plus-or-minus sign                      */
    -50,         #   178    ² superscript 2                           */
    -51,         #   179    ³ superscript 3                           */
    -39,         #   180    ´ spacing acute accent                    */
    -117,        #   181    µ micro sign                              */
    NPC7,        #   182    ¶ paragraph sign, pilcrow sign            */
    NPC7,        #   183    · middle dot, centered dot                */
    NPC7,        #   184    ¸ spacing cedilla                         */
    -49,         #   185    ¹ superscript 1                           */
    NPC7,        #   186    º masculine ordinal indicator             */
    -62,         #   187    » right (double) angle quote (guillemet)  */
    NPC7,        #   188    ¼ fraction 1/4                            */
    NPC7,        #   189    ½ fraction 1/2                            */
    NPC7,        #   190    ¾ fraction 3/4                            */
    96,          #   191    ¿ inverted question mark                  */
    -65,         #   192    À uppercase A grave                       */
    -65,         #   193    Á uppercase A acute                       */
    -65,         #   194    Â uppercase A circumflex                  */
    -65,         #   195    Ã uppercase A tilde                       */
    91,          #   196    Ä uppercase A dieresis or umlaut          */
    14,          #   197    Å uppercase A ring                        */
    28,          #   198    Æ uppercase AE ligature                   */
    9,           #   199    Ç uppercase C cedilla                     */
    -31,         #   200    È uppercase E grave                       */
    31,          #   201    É uppercase E acute                       */
    -31,         #   202    Ê uppercase E circumflex                  */
    -31,         #   203    Ë uppercase E dieresis or umlaut          */
    -73,         #   204    Ì uppercase I grave                       */
    -73,         #   205    Í uppercase I acute                       */
    -73,         #   206    Î uppercase I circumflex                  */
    -73,         #   207    Ï uppercase I dieresis or umlaut          */
    -68,         #   208    Ð uppercase ETH                           */
    93,          #   209    Ñ uppercase N tilde                       */
    -79,         #   210    Ò uppercase O grave                       */
    -79,         #   211    Ó uppercase O acute                       */
    -79,         #   212    Ô uppercase O circumflex                  */
    -79,         #   213    Õ uppercase O tilde                       */
    92,          #   214    Ö uppercase O dieresis or umlaut          */
    -42,         #   215    × multiplication sign                     */
    11,          #   216    Ø uppercase O slash                       */
    -85,         #   217    Ù uppercase U grave                       */
    -85,         #   218    Ú uppercase U acute                       */
    -85,         #   219    Û uppercase U circumflex                  */
    94,          #   220    Ü uppercase U dieresis or umlaut          */
    -89,         #   221    Ý uppercase Y acute                       */
    NPC7,        #   222    Þ uppercase THORN                         */
    30,          #   223    ß lowercase sharp s, sz ligature          */
    127,         #   224    à lowercase a grave                       */
    -97,         #   225    á lowercase a acute                       */
    -97,         #   226    â lowercase a circumflex                  */
    -97,         #   227    ã lowercase a tilde                       */
    123,         #   228    ä lowercase a dieresis or umlaut          */
    15,          #   229    å lowercase a ring                        */
    29,          #   230    æ lowercase ae ligature                   */
    -9,          #   231    ç lowercase c cedilla                     */
    4,           #   232    è lowercase e grave                       */
    5,           #   233    é lowercase e acute                       */
    -101,        #   234    ê lowercase e circumflex                  */
    -101,        #   235    ë lowercase e dieresis or umlaut          */
    7,           #   236    ì lowercase i grave                       */
    -7,          #   237    í lowercase i acute                       */
    -105,        #   238    î lowercase i circumflex                  */
    -105,        #   239    ï lowercase i dieresis or umlaut          */
    NPC7,        #   240    ð lowercase eth                           */
    125,         #   241    ñ lowercase n tilde                       */
    8,           #   242    ò lowercase o grave                       */
    -111,        #   243    ó lowercase o acute                       */
    -111,        #   244    ô lowercase o circumflex                  */
    -111,        #   245    õ lowercase o tilde                       */
    124,         #   246    ö lowercase o dieresis or umlaut          */
    -47,         #   247    ÷ division sign                           */
    12,          #   248    ø lowercase o slash                       */
    6,           #   249    ù lowercase u grave                       */
    -117,        #   250    ú lowercase u acute                       */
    -117,        #   251    û lowercase u circumflex                  */
    126,         #   252    ü lowercase u dieresis or umlaut          */
    -121,        #   253    ý lowercase y acute                       */
    NPC7,        #   254    þ lowercase thorn                         */
    -121         #   255    ÿ lowercase y dieresis or umlaut          */
);

sub iso8859_to_gsm0338 {
    my $ascii = shift;
    return '' if !defined $ascii || $ascii eq '';

    my $gsm = '';
    my $n   = 0;
    for (; $n < length($ascii); $n++) {
        my $ch_ascii = ord(substr($ascii, $n, 1));
        my $ch_gsm = $Device::Gsm::Charset::ISO8859_TO_GSM0338[$ch_ascii];

        # Is this a "replaced" char?
        if ($ch_gsm <= 0xFF) {
            $ch_gsm = abs($ch_gsm);
        }
        else {

            # Prepend an escape char for extended char
            $gsm .= chr(ESCAPE);

            # Encode extended char
            $ch_gsm -= 256;
        }

        #warn('char ['.$ch_ascii.'] => ['.$ch_gsm.']');
        $gsm .= chr($ch_gsm);
    }
    return $gsm;
}

sub gsm0338_to_iso8859 {
    my $gsm = shift;
    return '' if !defined $gsm || $gsm eq '';

    my $ascii = '';
    my $n     = 0;

    for (; $n < length($gsm); $n++) {

        my $c = ord(substr($gsm, $n, 1));

        # Extended charset ?
        if ($c == ESCAPE) {    # "escape extended mode"
            $n++;
            $c = ord(substr($gsm, $n, 1));
            if ($c == 0x0A) {
                $ascii .= chr(12);
            }
            elsif ($c == 0x14) {
                $ascii .= '^';
            }
            elsif ($c == 0x28) {
                $ascii .= '{';
            }
            elsif ($c == 0x29) {
                $ascii .= '}';
            }
            elsif ($c == 0x2F) {
                $ascii .= '\\';
            }
            elsif ($c == 0x3C) {
                $ascii .= '[';
            }
            elsif ($c == 0x3D) {
                $ascii .= '~';
            }
            elsif ($c == 0x3E) {
                $ascii .= ']';
            }
            elsif ($c == 0x40) {
                $ascii .= '|';
            }
            elsif ($c == 0x65) {    # 'e'
                $ascii .= chr(164)
                    ;    # iso_8859_15 EURO SIGN or iso_8859_1 CURRENCY_SIGN
            }
            else {
                $ascii .= chr(NPC8);    # Non printable
            }

        }
        else {

            # Standard GSM 3.38 encoding
            $ascii .= chr($Device::Gsm::Charset::GSM0338_TO_ISO8859[$c]);
        }

        #warn('gsm char ['.$c.'] converted to ascii ['.ord(substr($ascii,-1)).']');
    }

    return $ascii;
}

sub gsm0338_length {
    my $ascii          = shift;
    my $gsm0338_length = 0;
    my $n              = 0;
    for (; $n < length($ascii); $n++) {
        my $ch_ascii = ord(substr($ascii, $n, 1));
        my $ch_gsm = $Device::Gsm::Charset::ISO8859_TO_GSM0338[$ch_ascii];

        # Is this a "replaced" char?
        if ($ch_gsm <= 0xFF) {
            $gsm0338_length++;
        }
        else {
            $gsm0338_length += 2;
        }
    }
    return $gsm0338_length;
}

sub gsm0338_split {
    my $ascii = shift;
    return '' if !defined $ascii || $ascii eq '';
    my @parts;
    my $part;
    my $chars_count  = 0;
    my $ascii_length = length($ascii);
    while ($ascii_length) {
        my $ch_ascii = substr($ascii, 0, 1);
        my $ch_gsm
            = $Device::Gsm::Charset::ISO8859_TO_GSM0338[ ord($ch_ascii) ];
        if ($chars_count < 153 and $ch_gsm <= 0xFF) {
            $part .= $ch_ascii;
            $chars_count++;
            $ascii = substr($ascii, 1, $ascii_length--);
        }
        elsif ($chars_count < 152 and $ch_gsm > 0xFF) {
            $part .= $ch_ascii;
            $chars_count += 2;
            $ascii = substr($ascii, 1, $ascii_length--);
        }
        else {
            push(@parts, $part);
            $part        = '';
            $chars_count = 0;
        }
    }
    push(@parts, $part);
    return (@parts);
}
1;

__END__

