package IUP::Constants;
use strict;
use warnings;

use base 'Exporter';

my @ex_basic = qw(
  IUP_ERROR
  IUP_NOERROR
  IUP_OPENED
  IUP_INVALID

  IUP_CENTER
  IUP_LEFT
  IUP_RIGHT
  IUP_MOUSEPOS
  IUP_CURRENT
  IUP_CENTERPARENT
  IUP_TOP
  IUP_BOTTOM

  IUP_BUTTON1
  IUP_BUTTON2
  IUP_BUTTON3
  IUP_BUTTON4
  IUP_BUTTON5

  IUP_IGNORE
  IUP_DEFAULT
  IUP_CLOSE
  IUP_CONTINUE

  IUP_SBUP
  IUP_SBDN
  IUP_SBPGUP
  IUP_SBPGDN
  IUP_SBPOSV
  IUP_SBDRAGV
  IUP_SBLEFT
  IUP_SBRIGHT
  IUP_SBPGLEFT
  IUP_SBPGRIGHT
  IUP_SBPOSH
  IUP_SBDRAGH

  IUP_SHOW
  IUP_RESTORE
  IUP_MINIMIZE
  IUP_MAXIMIZE
  IUP_HIDE

  IUP_MASK_FLOAT
  IUP_MASK_UFLOAT
  IUP_MASK_EFLOAT
  IUP_MASK_INT
  IUP_MASK_UINT

  IUP_RED
  IUP_GREEN
  IUP_BLUE
  IUP_BLACK
  IUP_WHITE
  IUP_YELLOW

  IUP_PRIMARY
  IUP_SECONDARY
  IUP_RECBINARY
  IUP_RECTEXT
);

my @ex_keys = qw(
  K_SP
  K_exclam
  K_quotedbl
  K_numbersign
  K_dollar
  K_percent
  K_ampersand
  K_apostrophe
  K_parentleft
  K_parentright
  K_asterisk
  K_plus
  K_comma
  K_minus
  K_period
  K_slash
  K_0
  K_1
  K_2
  K_3
  K_4
  K_5
  K_6
  K_7
  K_8
  K_9
  K_colon
  K_semicolon
  K_less
  K_equal
  K_greater
  K_question
  K_at
  K_A
  K_B
  K_C
  K_D
  K_E
  K_F
  K_G
  K_H
  K_I
  K_J
  K_K
  K_L
  K_M
  K_N
  K_O
  K_P
  K_Q
  K_R
  K_S
  K_T
  K_U
  K_V
  K_W
  K_X
  K_Y
  K_Z
  K_bracketleft
  K_backslash
  K_bracketright
  K_circum
  K_underscore
  K_grave
  K_a
  K_b
  K_c
  K_d
  K_e
  K_f
  K_g
  K_h
  K_i
  K_j
  K_k
  K_l
  K_m
  K_n
  K_o
  K_p
  K_q
  K_r
  K_s
  K_t
  K_u
  K_v
  K_w
  K_x
  K_y
  K_z
  K_braceleft
  K_bar
  K_braceright
  K_tilde
  K_BS
  K_TAB
  K_LF
  K_CR
  K_quoteleft
  K_quoteright
  K_PAUSE
  K_ESC
  K_HOME
  K_LEFT
  K_UP
  K_RIGHT
  K_DOWN
  K_PGUP
  K_PGDN
  K_END
  K_MIDDLE
  K_Print
  K_INS
  K_Menu
  K_DEL
  K_F1
  K_F2
  K_F3
  K_F4
  K_F5
  K_F6
  K_F7
  K_F8
  K_F9
  K_F10
  K_F11
  K_F12
  K_LSHIFT
  K_RSHIFT
  K_LCTRL
  K_RCTRL
  K_LALT
  K_RALT
  K_NUM
  K_SCROLL
  K_CAPS
  K_ccedilla
  K_Ccedilla
  K_acute
  K_diaeresis
  K_sHOME
  K_sUP
  K_sPGUP
  K_sLEFT
  K_sMIDDLE
  K_sRIGHT
  K_sEND
  K_sDOWN
  K_sPGDN
  K_sINS
  K_sDEL
  K_sSP
  K_sTAB
  K_sCR
  K_sBS
  K_sPAUSE
  K_sESC
  K_sF1
  K_sF2
  K_sF3
  K_sF4
  K_sF5
  K_sF6
  K_sF7
  K_sF8
  K_sF9
  K_sF10
  K_sF11
  K_sF12
  K_sPrint
  K_sMenu
  K_cHOME
  K_cUP
  K_cPGUP
  K_cLEFT
  K_cMIDDLE
  K_cRIGHT
  K_cEND
  K_cDOWN
  K_cPGDN
  K_cINS
  K_cDEL
  K_cSP
  K_cTAB
  K_cCR
  K_cBS
  K_cPAUSE
  K_cESC
  K_cCcedilla
  K_cF1
  K_cF2
  K_cF3
  K_cF4
  K_cF5
  K_cF6
  K_cF7
  K_cF8
  K_cF9
  K_cF10
  K_cF11
  K_cF12
  K_cPrint
  K_cMenu
  K_mHOME
  K_mUP
  K_mPGUP
  K_mLEFT
  K_mMIDDLE
  K_mRIGHT
  K_mEND
  K_mDOWN
  K_mPGDN
  K_mINS
  K_mDEL
  K_mSP
  K_mTAB
  K_mCR
  K_mBS
  K_mPAUSE
  K_mESC
  K_mCcedilla
  K_mF1
  K_mF2
  K_mF3
  K_mF4
  K_mF5
  K_mF6
  K_mF7
  K_mF8
  K_mF9
  K_mF10
  K_mF11
  K_mF12
  K_mPrint
  K_mMenu
  K_yHOME
  K_yUP
  K_yPGUP
  K_yLEFT
  K_yMIDDLE
  K_yRIGHT
  K_yEND
  K_yDOWN
  K_yPGDN
  K_yINS
  K_yDEL
  K_ySP
  K_yTAB
  K_yCR
  K_yBS
  K_yPAUSE
  K_yESC
  K_yCcedilla
  K_yF1
  K_yF2
  K_yF3
  K_yF4
  K_yF5
  K_yF6
  K_yF7
  K_yF8
  K_yF9
  K_yF10
  K_yF11
  K_yF12
  K_yPrint
  K_yMenu
  K_sPlus
  K_sComma
  K_sMinus
  K_sPeriod
  K_sSlash
  K_sAsterisk
  K_cA
  K_cB
  K_cC
  K_cD
  K_cE
  K_cF
  K_cG
  K_cH
  K_cI
  K_cJ
  K_cK
  K_cL
  K_cM
  K_cN
  K_cO
  K_cP
  K_cQ
  K_cR
  K_cS
  K_cT
  K_cU
  K_cV
  K_cW
  K_cX
  K_cY
  K_cZ
  K_c1
  K_c2
  K_c3
  K_c4
  K_c5
  K_c6
  K_c7
  K_c8
  K_c9
  K_c0
  K_cPlus
  K_cComma
  K_cMinus
  K_cPeriod
  K_cSlash
  K_cSemicolon
  K_cEqual
  K_cBracketleft
  K_cBracketright
  K_cBackslash
  K_cAsterisk
  K_mA
  K_mB
  K_mC
  K_mD
  K_mE
  K_mF
  K_mG
  K_mH
  K_mI
  K_mJ
  K_mK
  K_mL
  K_mM
  K_mN
  K_mO
  K_mP
  K_mQ
  K_mR
  K_mS
  K_mT
  K_mU
  K_mV
  K_mW
  K_mX
  K_mY
  K_mZ
  K_m1
  K_m2
  K_m3
  K_m4
  K_m5
  K_m6
  K_m7
  K_m8
  K_m9
  K_m0
  K_mPlus
  K_mComma
  K_mMinus
  K_mPeriod
  K_mSlash
  K_mSemicolon
  K_mEqual
  K_mBracketleft
  K_mBracketright
  K_mBackslash
  K_mAsterisk
  K_yA
  K_yB
  K_yC
  K_yD
  K_yE
  K_yF
  K_yG
  K_yH
  K_yI
  K_yJ
  K_yK
  K_yL
  K_yM
  K_yN
  K_yO
  K_yP
  K_yQ
  K_yR
  K_yS
  K_yT
  K_yU
  K_yV
  K_yW
  K_yX
  K_yY
  K_yZ
  K_y1
  K_y2
  K_y3
  K_y4
  K_y5
  K_y6
  K_y7
  K_y8
  K_y9
  K_y0
  K_yPlus
  K_yComma
  K_yMinus
  K_yPeriod
  K_ySlash
  K_ySemicolon
  K_yEqual
  K_yBracketleft
  K_yBracketright
  K_yBackslash
  K_yAsterisk
);

my @ex_cd = qw(
  CD_QUERY
  CD_RGB
  CD_MAP
  CD_RGBA
  CD_IRED
  CD_IGREEN
  CD_IBLUE
  CD_IALPHA
  CD_INDEX
  CD_COLORS
  CD_ERROR
  CD_OK
  CD_CLIPOFF
  CD_CLIPAREA
  CD_CLIPPOLYGON
  CD_CLIPREGION
  CD_UNION
  CD_INTERSECT
  CD_DIFFERENCE
  CD_NOTINTERSECT
  CD_FILL
  CD_OPEN_LINES
  CD_CLOSED_LINES
  CD_CLIP
  CD_BEZIER
  CD_REGION
  CD_PATH
  CD_POLYCUSTOM
  CD_PATH_NEW
  CD_PATH_MOVETO
  CD_PATH_LINETO
  CD_PATH_ARC
  CD_PATH_CURVETO
  CD_PATH_CLOSE
  CD_PATH_FILL
  CD_PATH_STROKE
  CD_PATH_FILLSTROKE
  CD_PATH_CLIP
  CD_EVENODD
  CD_WINDING
  CD_MITER
  CD_BEVEL
  CD_ROUND
  CD_CAPFLAT
  CD_CAPSQUARE
  CD_CAPROUND
  CD_OPAQUE
  CD_TRANSPARENT
  CD_REPLACE
  CD_XOR
  CD_NOT_XOR
  CD_POLITE
  CD_FORCE
  CD_CONTINUOUS
  CD_DASHED
  CD_DOTTED
  CD_DASH_DOT
  CD_DASH_DOT_DOT
  CD_CUSTOM
  CD_PLUS
  CD_STAR
  CD_CIRCLE
  CD_X
  CD_BOX
  CD_DIAMOND
  CD_HOLLOW_CIRCLE
  CD_HOLLOW_BOX
  CD_HOLLOW_DIAMOND
  CD_HORIZONTAL
  CD_VERTICAL
  CD_FDIAGONAL
  CD_BDIAGONAL
  CD_CROSS
  CD_DIAGCROSS
  CD_SOLID
  CD_HATCH
  CD_STIPPLE
  CD_PATTERN
  CD_HOLLOW
  CD_NORTH
  CD_SOUTH
  CD_EAST
  CD_WEST
  CD_NORTH_EAST
  CD_NORTH_WEST
  CD_SOUTH_EAST
  CD_SOUTH_WEST
  CD_CENTER
  CD_BASE_LEFT
  CD_BASE_CENTER
  CD_BASE_RIGHT
  CD_PLAIN
  CD_BOLD
  CD_ITALIC
  CD_UNDERLINE
  CD_STRIKEOUT
  CD_BOLD_ITALIC
  CD_SMALL
  CD_STANDARD
  CD_LARGE
  CD_CAP_NONE
  CD_CAP_FLUSH
  CD_CAP_CLEAR
  CD_CAP_PLAY
  CD_CAP_YAXIS
  CD_CAP_CLIPAREA
  CD_CAP_CLIPPOLY
  CD_CAP_REGION
  CD_CAP_RECT
  CD_CAP_CHORD
  CD_CAP_IMAGERGB
  CD_CAP_IMAGERGBA
  CD_CAP_IMAGEMAP
  CD_CAP_GETIMAGERGB
  CD_CAP_IMAGESRV
  CD_CAP_BACKGROUND
  CD_CAP_BACKOPACITY
  CD_CAP_WRITEMODE
  CD_CAP_LINESTYLE
  CD_CAP_LINEWITH
  CD_CAP_FPRIMTIVES
  CD_CAP_HATCH
  CD_CAP_STIPPLE
  CD_CAP_PATTERN
  CD_CAP_FONT
  CD_CAP_FONTDIM
  CD_CAP_TEXTSIZE
  CD_CAP_TEXTORIENTATION
  CD_CAP_PALETTE
  CD_CAP_LINECAP
  CD_CAP_LINEJOIN
  CD_CAP_PATH
  CD_CAP_BEZIER
  CD_CAP_ALL
  CD_ABORT
  CD_CONTINUE
  CD_SIM_NONE
  CD_SIM_LINE
  CD_SIM_RECT
  CD_SIM_BOX
  CD_SIM_ARC
  CD_SIM_SECTOR
  CD_SIM_CHORD
  CD_SIM_POLYLINE
  CD_SIM_POLYGON
  CD_SIM_TEXT
  CD_SIM_ALL
  CD_SIM_LINES
  CD_SIM_FILLS
  CD_RED
  CD_DARK_RED
  CD_GREEN
  CD_DARK_GREEN
  CD_BLUE
  CD_DARK_BLUE
  CD_YELLOW
  CD_DARK_YELLOW
  CD_MAGENTA
  CD_DARK_MAGENTA
  CD_CYAN
  CD_DARK_CYAN
  CD_WHITE
  CD_BLACK
  CD_DARK_GRAY
  CD_GRAY
  CD_MM2PT
  CD_RAD2DEG
  CD_DEG2RAD
  CD_A0
  CD_A1
  CD_A2
  CD_A3
  CD_A4
  CD_A5
  CD_LETTER
  CD_LEGAL
);

our %EXPORT_TAGS = (
  basic => [@ex_basic],
  keys  => [@ex_keys],
  cd    => [@ex_cd],
  all   => [@ex_basic, @ex_keys, @ex_cd],
);
our @EXPORT_OK = (@ex_basic, @ex_keys, @ex_cd);
our @EXPORT = @ex_basic;

##TAG: basic ##

# Common return values
use constant IUP_ERROR         => 1;
use constant IUP_NOERROR       => 0;
use constant IUP_OPENED        => -1;
use constant IUP_INVALID       => -1;

# IupPopup e IupShowXY
use constant IUP_CENTER        => 0xFFFF; # 65535
use constant IUP_LEFT          => 0xFFFE; # 65534
use constant IUP_RIGHT         => 0xFFFD; # 65533
use constant IUP_MOUSEPOS      => 0xFFFC; # 65532
use constant IUP_CURRENT       => 0xFFFB; # 65531
use constant IUP_CENTERPARENT  => 0xFFFA; # 65530
use constant IUP_TOP           => 0xFFFE; # = IUP_LEFT
use constant IUP_BOTTOM        => 0xFFFD; # = IUP_RIGHT

# BUTTON_CB
use constant IUP_BUTTON1       => 49; # char '1'
use constant IUP_BUTTON2       => 50; # char '2'
use constant IUP_BUTTON3       => 51; # char '3'
use constant IUP_BUTTON4       => 52; # char '4'
use constant IUP_BUTTON5       => 53; # char '5'

# Callback return values
use constant IUP_IGNORE        => -1;
use constant IUP_DEFAULT       => -2;
use constant IUP_CLOSE         => -3;
use constant IUP_CONTINUE      => -4;

# Scrollbar
use constant IUP_SBUP          => 0;
use constant IUP_SBDN          => 1;
use constant IUP_SBPGUP        => 2;
use constant IUP_SBPGDN        => 3;
use constant IUP_SBPOSV        => 4;
use constant IUP_SBDRAGV       => 5;
use constant IUP_SBLEFT        => 6;
use constant IUP_SBRIGHT       => 7;
use constant IUP_SBPGLEFT      => 8;
use constant IUP_SBPGRIGHT     => 9;
use constant IUP_SBPOSH        => 10;
use constant IUP_SBDRAGH       => 11;

# SHOW_CB
use constant IUP_SHOW          => 0;
use constant IUP_RESTORE       => 1;
use constant IUP_MINIMIZE      => 2;
use constant IUP_MAXIMIZE      => 3;
use constant IUP_HIDE          => 4;

# record/play constants
use constant IUP_RECBINARY => 0;
use constant IUP_RECTEXT   => 1;

# Pre-Defined Colors
use constant IUP_RED           => "255 0 0";
use constant IUP_GREEN         => "0 255 0";
use constant IUP_BLUE          => "0 0 255";
use constant IUP_BLACK         => "0 0 0";
use constant IUP_WHITE         => "1 1 1";
use constant IUP_YELLOW        => "1 1 0";

# Pre-Defined Masks
use constant IUP_MASK_FLOAT    => "[+/-]?(/d+/.?/d*|/./d+)";
use constant IUP_MASK_UFLOAT   => "(/d+/.?/d*|/./d+)";
use constant IUP_MASK_EFLOAT   => "[+/-]?(/d+/.?/d*|/./d+)([eE][+/-]?/d+)?";
use constant IUP_MASK_INT      => "[+/-]?/d+";
use constant IUP_MASK_UINT     => "/d+";

# Used by IupColorbar
use constant IUP_PRIMARY   => -1;
use constant IUP_SECONDARY => -2;

##TAG: keys ##
use constant K_SP             => 0x20;
use constant K_exclam         => 0x21;
use constant K_quotedbl       => 0x22;
use constant K_numbersign     => 0x23;
use constant K_dollar         => 0x24;
use constant K_percent        => 0x25;
use constant K_ampersand      => 0x26;
use constant K_apostrophe     => 0x27;
use constant K_parentleft     => 0x28;
use constant K_parentright    => 0x29;
use constant K_asterisk       => 0x2a;
use constant K_plus           => 0x2b;
use constant K_comma          => 0x2c;
use constant K_minus          => 0x2d;
use constant K_period         => 0x2e;
use constant K_slash          => 0x2f;
use constant K_0              => 0x30;
use constant K_1              => 0x31;
use constant K_2              => 0x32;
use constant K_3              => 0x33;
use constant K_4              => 0x34;
use constant K_5              => 0x35;
use constant K_6              => 0x36;
use constant K_7              => 0x37;
use constant K_8              => 0x38;
use constant K_9              => 0x39;
use constant K_colon          => 0x3a;
use constant K_semicolon      => 0x3b;
use constant K_less           => 0x3c;
use constant K_equal          => 0x3d;
use constant K_greater        => 0x3e;
use constant K_question       => 0x3f;
use constant K_at             => 0x40;
use constant K_A              => 0x41;
use constant K_B              => 0x42;
use constant K_C              => 0x43;
use constant K_D              => 0x44;
use constant K_E              => 0x45;
use constant K_F              => 0x46;
use constant K_G              => 0x47;
use constant K_H              => 0x48;
use constant K_I              => 0x49;
use constant K_J              => 0x4a;
use constant K_K              => 0x4b;
use constant K_L              => 0x4c;
use constant K_M              => 0x4d;
use constant K_N              => 0x4e;
use constant K_O              => 0x4f;
use constant K_P              => 0x50;
use constant K_Q              => 0x51;
use constant K_R              => 0x52;
use constant K_S              => 0x53;
use constant K_T              => 0x54;
use constant K_U              => 0x55;
use constant K_V              => 0x56;
use constant K_W              => 0x57;
use constant K_X              => 0x58;
use constant K_Y              => 0x59;
use constant K_Z              => 0x5a;
use constant K_bracketleft    => 0x5b;
use constant K_backslash      => 0x5c;
use constant K_bracketright   => 0x5d;
use constant K_circum         => 0x5e;
use constant K_underscore     => 0x5f;
use constant K_grave          => 0x60;
use constant K_a              => 0x61;
use constant K_b              => 0x62;
use constant K_c              => 0x63;
use constant K_d              => 0x64;
use constant K_e              => 0x65;
use constant K_f              => 0x66;
use constant K_g              => 0x67;
use constant K_h              => 0x68;
use constant K_i              => 0x69;
use constant K_j              => 0x6a;
use constant K_k              => 0x6b;
use constant K_l              => 0x6c;
use constant K_m              => 0x6d;
use constant K_n              => 0x6e;
use constant K_o              => 0x6f;
use constant K_p              => 0x70;
use constant K_q              => 0x71;
use constant K_r              => 0x72;
use constant K_s              => 0x73;
use constant K_t              => 0x74;
use constant K_u              => 0x75;
use constant K_v              => 0x76;
use constant K_w              => 0x77;
use constant K_x              => 0x78;
use constant K_y              => 0x79;
use constant K_z              => 0x7a;
use constant K_braceleft      => 0x7b;
use constant K_bar            => 0x7c;
use constant K_braceright     => 0x7d;
use constant K_tilde          => 0x7e;
use constant K_BS             => 0x8;
use constant K_TAB            => 0x9;
use constant K_LF             => 0xa;
use constant K_CR             => 0xd;
use constant K_quoteleft      => 0x60;
use constant K_quoteright     => 0x27;
use constant K_PAUSE          => 0xff13;
use constant K_ESC            => 0xff1b;
use constant K_HOME           => 0xff50;
use constant K_LEFT           => 0xff51;
use constant K_UP             => 0xff52;
use constant K_RIGHT          => 0xff53;
use constant K_DOWN           => 0xff54;
use constant K_PGUP           => 0xff55;
use constant K_PGDN           => 0xff56;
use constant K_END            => 0xff57;
use constant K_MIDDLE         => 0xff0b;
use constant K_Print          => 0xff61;
use constant K_INS            => 0xff63;
use constant K_Menu           => 0xff67;
use constant K_DEL            => 0xffff;
use constant K_F1             => 0xffbe;
use constant K_F2             => 0xffbf;
use constant K_F3             => 0xffc0;
use constant K_F4             => 0xffc1;
use constant K_F5             => 0xffc2;
use constant K_F6             => 0xffc3;
use constant K_F7             => 0xffc4;
use constant K_F8             => 0xffc5;
use constant K_F9             => 0xffc6;
use constant K_F10            => 0xffc7;
use constant K_F11            => 0xffc8;
use constant K_F12            => 0xffc9;
use constant K_LSHIFT         => 0xffe1;
use constant K_RSHIFT         => 0xffe2;
use constant K_LCTRL          => 0xffe3;
use constant K_RCTRL          => 0xffe4;
use constant K_LALT           => 0xffe9;
use constant K_RALT           => 0xffea;
use constant K_NUM            => 0xff7f;
use constant K_SCROLL         => 0xff14;
use constant K_CAPS           => 0xffe5;
use constant K_ccedilla       => 0xe7;
use constant K_Ccedilla       => 0xc7;
use constant K_acute          => 0xb4;
use constant K_diaeresis      => 0xa8;
use constant K_sHOME          => 0x1000ff50;
use constant K_sUP            => 0x1000ff52;
use constant K_sPGUP          => 0x1000ff55;
use constant K_sLEFT          => 0x1000ff51;
use constant K_sMIDDLE        => 0x1000ff0b;
use constant K_sRIGHT         => 0x1000ff53;
use constant K_sEND           => 0x1000ff57;
use constant K_sDOWN          => 0x1000ff54;
use constant K_sPGDN          => 0x1000ff56;
use constant K_sINS           => 0x1000ff63;
use constant K_sDEL           => 0x1000ffff;
use constant K_sSP            => 0x10000020;
use constant K_sTAB           => 0x10000009;
use constant K_sCR            => 0x1000000d;
use constant K_sBS            => 0x10000008;
use constant K_sPAUSE         => 0x1000ff13;
use constant K_sESC           => 0x1000ff1b;
use constant K_sF1            => 0x1000ffbe;
use constant K_sF2            => 0x1000ffbf;
use constant K_sF3            => 0x1000ffc0;
use constant K_sF4            => 0x1000ffc1;
use constant K_sF5            => 0x1000ffc2;
use constant K_sF6            => 0x1000ffc3;
use constant K_sF7            => 0x1000ffc4;
use constant K_sF8            => 0x1000ffc5;
use constant K_sF9            => 0x1000ffc6;
use constant K_sF10           => 0x1000ffc7;
use constant K_sF11           => 0x1000ffc8;
use constant K_sF12           => 0x1000ffc9;
use constant K_sPrint         => 0x1000ff61;
use constant K_sMenu          => 0x1000ff67;
use constant K_cHOME          => 0x2000ff50;
use constant K_cUP            => 0x2000ff52;
use constant K_cPGUP          => 0x2000ff55;
use constant K_cLEFT          => 0x2000ff51;
use constant K_cMIDDLE        => 0x2000ff0b;
use constant K_cRIGHT         => 0x2000ff53;
use constant K_cEND           => 0x2000ff57;
use constant K_cDOWN          => 0x2000ff54;
use constant K_cPGDN          => 0x2000ff56;
use constant K_cINS           => 0x2000ff63;
use constant K_cDEL           => 0x2000ffff;
use constant K_cSP            => 0x20000020;
use constant K_cTAB           => 0x20000009;
use constant K_cCR            => 0x2000000d;
use constant K_cBS            => 0x20000008;
use constant K_cPAUSE         => 0x2000ff13;
use constant K_cESC           => 0x2000ff1b;
use constant K_cCcedilla      => 0x200000c7;
use constant K_cF1            => 0x2000ffbe;
use constant K_cF2            => 0x2000ffbf;
use constant K_cF3            => 0x2000ffc0;
use constant K_cF4            => 0x2000ffc1;
use constant K_cF5            => 0x2000ffc2;
use constant K_cF6            => 0x2000ffc3;
use constant K_cF7            => 0x2000ffc4;
use constant K_cF8            => 0x2000ffc5;
use constant K_cF9            => 0x2000ffc6;
use constant K_cF10           => 0x2000ffc7;
use constant K_cF11           => 0x2000ffc8;
use constant K_cF12           => 0x2000ffc9;
use constant K_cPrint         => 0x2000ff61;
use constant K_cMenu          => 0x2000ff67;
use constant K_mHOME          => 0x4000ff50;
use constant K_mUP            => 0x4000ff52;
use constant K_mPGUP          => 0x4000ff55;
use constant K_mLEFT          => 0x4000ff51;
use constant K_mMIDDLE        => 0x4000ff0b;
use constant K_mRIGHT         => 0x4000ff53;
use constant K_mEND           => 0x4000ff57;
use constant K_mDOWN          => 0x4000ff54;
use constant K_mPGDN          => 0x4000ff56;
use constant K_mINS           => 0x4000ff63;
use constant K_mDEL           => 0x4000ffff;
use constant K_mSP            => 0x40000020;
use constant K_mTAB           => 0x40000009;
use constant K_mCR            => 0x4000000d;
use constant K_mBS            => 0x40000008;
use constant K_mPAUSE         => 0x4000ff13;
use constant K_mESC           => 0x4000ff1b;
use constant K_mCcedilla      => 0x400000c7;
use constant K_mF1            => 0x4000ffbe;
use constant K_mF2            => 0x4000ffbf;
use constant K_mF3            => 0x4000ffc0;
use constant K_mF4            => 0x4000ffc1;
use constant K_mF5            => 0x4000ffc2;
use constant K_mF6            => 0x4000ffc3;
use constant K_mF7            => 0x4000ffc4;
use constant K_mF8            => 0x4000ffc5;
use constant K_mF9            => 0x4000ffc6;
use constant K_mF10           => 0x4000ffc7;
use constant K_mF11           => 0x4000ffc8;
use constant K_mF12           => 0x4000ffc9;
use constant K_mPrint         => 0x4000ff61;
use constant K_mMenu          => 0x4000ff67;
use constant K_yHOME          => 0x8000ff50;
use constant K_yUP            => 0x8000ff52;
use constant K_yPGUP          => 0x8000ff55;
use constant K_yLEFT          => 0x8000ff51;
use constant K_yMIDDLE        => 0x8000ff0b;
use constant K_yRIGHT         => 0x8000ff53;
use constant K_yEND           => 0x8000ff57;
use constant K_yDOWN          => 0x8000ff54;
use constant K_yPGDN          => 0x8000ff56;
use constant K_yINS           => 0x8000ff63;
use constant K_yDEL           => 0x8000ffff;
use constant K_ySP            => 0x80000020;
use constant K_yTAB           => 0x80000009;
use constant K_yCR            => 0x8000000d;
use constant K_yBS            => 0x80000008;
use constant K_yPAUSE         => 0x8000ff13;
use constant K_yESC           => 0x8000ff1b;
use constant K_yCcedilla      => 0x800000c7;
use constant K_yF1            => 0x8000ffbe;
use constant K_yF2            => 0x8000ffbf;
use constant K_yF3            => 0x8000ffc0;
use constant K_yF4            => 0x8000ffc1;
use constant K_yF5            => 0x8000ffc2;
use constant K_yF6            => 0x8000ffc3;
use constant K_yF7            => 0x8000ffc4;
use constant K_yF8            => 0x8000ffc5;
use constant K_yF9            => 0x8000ffc6;
use constant K_yF10           => 0x8000ffc7;
use constant K_yF11           => 0x8000ffc8;
use constant K_yF12           => 0x8000ffc9;
use constant K_yPrint         => 0x8000ff61;
use constant K_yMenu          => 0x8000ff67;
use constant K_sPlus          => 0x1000002b;
use constant K_sComma         => 0x1000002c;
use constant K_sMinus         => 0x1000002d;
use constant K_sPeriod        => 0x1000002e;
use constant K_sSlash         => 0x1000002f;
use constant K_sAsterisk      => 0x1000002a;
use constant K_cA             => 0x20000041;
use constant K_cB             => 0x20000042;
use constant K_cC             => 0x20000043;
use constant K_cD             => 0x20000044;
use constant K_cE             => 0x20000045;
use constant K_cF             => 0x20000046;
use constant K_cG             => 0x20000047;
use constant K_cH             => 0x20000048;
use constant K_cI             => 0x20000049;
use constant K_cJ             => 0x2000004a;
use constant K_cK             => 0x2000004b;
use constant K_cL             => 0x2000004c;
use constant K_cM             => 0x2000004d;
use constant K_cN             => 0x2000004e;
use constant K_cO             => 0x2000004f;
use constant K_cP             => 0x20000050;
use constant K_cQ             => 0x20000051;
use constant K_cR             => 0x20000052;
use constant K_cS             => 0x20000053;
use constant K_cT             => 0x20000054;
use constant K_cU             => 0x20000055;
use constant K_cV             => 0x20000056;
use constant K_cW             => 0x20000057;
use constant K_cX             => 0x20000058;
use constant K_cY             => 0x20000059;
use constant K_cZ             => 0x2000005a;
use constant K_c1             => 0x20000031;
use constant K_c2             => 0x20000032;
use constant K_c3             => 0x20000033;
use constant K_c4             => 0x20000034;
use constant K_c5             => 0x20000035;
use constant K_c6             => 0x20000036;
use constant K_c7             => 0x20000037;
use constant K_c8             => 0x20000038;
use constant K_c9             => 0x20000039;
use constant K_c0             => 0x20000030;
use constant K_cPlus          => 0x2000002b;
use constant K_cComma         => 0x2000002c;
use constant K_cMinus         => 0x2000002d;
use constant K_cPeriod        => 0x2000002e;
use constant K_cSlash         => 0x2000002f;
use constant K_cSemicolon     => 0x2000003b;
use constant K_cEqual         => 0x2000003d;
use constant K_cBracketleft   => 0x2000005b;
use constant K_cBracketright  => 0x2000005d;
use constant K_cBackslash     => 0x2000005c;
use constant K_cAsterisk      => 0x2000002a;
use constant K_mA             => 0x40000041;
use constant K_mB             => 0x40000042;
use constant K_mC             => 0x40000043;
use constant K_mD             => 0x40000044;
use constant K_mE             => 0x40000045;
use constant K_mF             => 0x40000046;
use constant K_mG             => 0x40000047;
use constant K_mH             => 0x40000048;
use constant K_mI             => 0x40000049;
use constant K_mJ             => 0x4000004a;
use constant K_mK             => 0x4000004b;
use constant K_mL             => 0x4000004c;
use constant K_mM             => 0x4000004d;
use constant K_mN             => 0x4000004e;
use constant K_mO             => 0x4000004f;
use constant K_mP             => 0x40000050;
use constant K_mQ             => 0x40000051;
use constant K_mR             => 0x40000052;
use constant K_mS             => 0x40000053;
use constant K_mT             => 0x40000054;
use constant K_mU             => 0x40000055;
use constant K_mV             => 0x40000056;
use constant K_mW             => 0x40000057;
use constant K_mX             => 0x40000058;
use constant K_mY             => 0x40000059;
use constant K_mZ             => 0x4000005a;
use constant K_m1             => 0x40000031;
use constant K_m2             => 0x40000032;
use constant K_m3             => 0x40000033;
use constant K_m4             => 0x40000034;
use constant K_m5             => 0x40000035;
use constant K_m6             => 0x40000036;
use constant K_m7             => 0x40000037;
use constant K_m8             => 0x40000038;
use constant K_m9             => 0x40000039;
use constant K_m0             => 0x40000030;
use constant K_mPlus          => 0x4000002b;
use constant K_mComma         => 0x4000002c;
use constant K_mMinus         => 0x4000002d;
use constant K_mPeriod        => 0x4000002e;
use constant K_mSlash         => 0x4000002f;
use constant K_mSemicolon     => 0x4000003b;
use constant K_mEqual         => 0x4000003d;
use constant K_mBracketleft   => 0x4000005b;
use constant K_mBracketright  => 0x4000005d;
use constant K_mBackslash     => 0x4000005c;
use constant K_mAsterisk      => 0x4000002a;
use constant K_yA             => 0x80000041;
use constant K_yB             => 0x80000042;
use constant K_yC             => 0x80000043;
use constant K_yD             => 0x80000044;
use constant K_yE             => 0x80000045;
use constant K_yF             => 0x80000046;
use constant K_yG             => 0x80000047;
use constant K_yH             => 0x80000048;
use constant K_yI             => 0x80000049;
use constant K_yJ             => 0x8000004a;
use constant K_yK             => 0x8000004b;
use constant K_yL             => 0x8000004c;
use constant K_yM             => 0x8000004d;
use constant K_yN             => 0x8000004e;
use constant K_yO             => 0x8000004f;
use constant K_yP             => 0x80000050;
use constant K_yQ             => 0x80000051;
use constant K_yR             => 0x80000052;
use constant K_yS             => 0x80000053;
use constant K_yT             => 0x80000054;
use constant K_yU             => 0x80000055;
use constant K_yV             => 0x80000056;
use constant K_yW             => 0x80000057;
use constant K_yX             => 0x80000058;
use constant K_yY             => 0x80000059;
use constant K_yZ             => 0x8000005a;
use constant K_y1             => 0x80000031;
use constant K_y2             => 0x80000032;
use constant K_y3             => 0x80000033;
use constant K_y4             => 0x80000034;
use constant K_y5             => 0x80000035;
use constant K_y6             => 0x80000036;
use constant K_y7             => 0x80000037;
use constant K_y8             => 0x80000038;
use constant K_y9             => 0x80000039;
use constant K_y0             => 0x80000030;
use constant K_yPlus          => 0x8000002b;
use constant K_yComma         => 0x8000002c;
use constant K_yMinus         => 0x8000002d;
use constant K_yPeriod        => 0x8000002e;
use constant K_ySlash         => 0x8000002f;
use constant K_ySemicolon     => 0x8000003b;
use constant K_yEqual         => 0x8000003d;
use constant K_yBracketleft   => 0x8000005b;
use constant K_yBracketright  => 0x8000005d;
use constant K_yBackslash     => 0x8000005c;
use constant K_yAsterisk      => 0x8000002a;

##TAG: cd ##

#query value
use constant CD_QUERY => -1;

# bitmap type - these definitions are compatible with the IM library
use constant CD_RGB  => 0;
use constant CD_MAP  => 1;
use constant CD_RGBA => 0x100;

# bitmap data
use constant CD_IRED   => 0;
use constant CD_IGREEN => 1;
use constant CD_IBLUE  => 2;
use constant CD_IALPHA => 3;
use constant CD_INDEX  => 4; 
use constant CD_COLORS => 5;

# status report
use constant CD_ERROR => -1;
use constant CD_OK    =>  0;

# clip mode
use constant CD_CLIPOFF     => 0;
use constant CD_CLIPAREA    => 1;
use constant CD_CLIPPOLYGON => 2;
use constant CD_CLIPREGION  => 3;

# region combine mode
use constant CD_UNION        => 0;
use constant CD_INTERSECT    => 1;
use constant CD_DIFFERENCE   => 2;
use constant CD_NOTINTERSECT => 3;

# polygon mode (begin...end)
use constant CD_FILL         => 0;
use constant CD_OPEN_LINES   => 1;
use constant CD_CLOSED_LINES => 2;
use constant CD_CLIP         => 3;
use constant CD_BEZIER       => 4;
use constant CD_REGION       => 5;
use constant CD_PATH         => 6;
use constant CD_POLYCUSTOM   => 10;

# path actions
use constant CD_PATH_NEW        => 0;
use constant CD_PATH_MOVETO     => 1;
use constant CD_PATH_LINETO     => 2;
use constant CD_PATH_ARC        => 3;
use constant CD_PATH_CURVETO    => 4;
use constant CD_PATH_CLOSE      => 5;
use constant CD_PATH_FILL       => 6;
use constant CD_PATH_STROKE     => 7;
use constant CD_PATH_FILLSTROKE => 8;
use constant CD_PATH_CLIP       => 9;

# fill mode
use constant CD_EVENODD => 0;
use constant CD_WINDING => 1;

# line join 
use constant CD_MITER => 0;
use constant CD_BEVEL => 1;
use constant CD_ROUND => 2;

# line cap 
use constant CD_CAPFLAT   => 0;
use constant CD_CAPSQUARE => 1;
use constant CD_CAPROUND  => 2;

# background opacity mode
use constant CD_OPAQUE      => 0;
use constant CD_TRANSPARENT => 1;

# write mode
use constant CD_REPLACE => 0;
use constant CD_XOR     => 1;
use constant CD_NOT_XOR => 2;

# color allocation mode (palette)
use constant CD_POLITE => 0;
use constant CD_FORCE  => 1;

# line style
use constant CD_CONTINUOUS => 0;
use constant CD_DASHED     => 1;
use constant CD_DOTTED     => 2;
use constant CD_DASH_DOT   => 3;
use constant CD_DASH_DOT_DOT => 4;
use constant CD_CUSTOM     => 5;

# marker type
use constant CD_PLUS           => 0;
use constant CD_STAR           => 1;
use constant CD_CIRCLE         => 2;
use constant CD_X              => 3;
use constant CD_BOX            => 4;
use constant CD_DIAMOND        => 5;
use constant CD_HOLLOW_CIRCLE  => 6;
use constant CD_HOLLOW_BOX     => 7;
use constant CD_HOLLOW_DIAMOND => 8;

# hatch type
use constant CD_HORIZONTAL => 0;
use constant CD_VERTICAL   => 1;
use constant CD_FDIAGONAL  => 2;
use constant CD_BDIAGONAL  => 3;
use constant CD_CROSS      => 4;
use constant CD_DIAGCROSS  => 5;

# interior style
use constant CD_SOLID   => 0;
use constant CD_HATCH   => 1;
use constant CD_STIPPLE => 2;
use constant CD_PATTERN => 3;
use constant CD_HOLLOW  => 4;

# text alignment
use constant CD_NORTH       => 0;
use constant CD_SOUTH       => 1;
use constant CD_EAST        => 2;
use constant CD_WEST        => 3;
use constant CD_NORTH_EAST  => 4;
use constant CD_NORTH_WEST  => 5;
use constant CD_SOUTH_EAST  => 6;
use constant CD_SOUTH_WEST  => 7;
use constant CD_CENTER      => 8;
use constant CD_BASE_LEFT   => 9;
use constant CD_BASE_CENTER => 10;
use constant CD_BASE_RIGHT  => 11;

# style
use constant CD_PLAIN     => 0;
use constant CD_BOLD      => 1;
use constant CD_ITALIC    => 2;
use constant CD_UNDERLINE => 4;
use constant CD_STRIKEOUT => 8;
use constant CD_BOLD_ITALIC => (CD_BOLD|CD_ITALIC);  # compatibility name

# some font sizes
use constant CD_SMALL    =>  8;
use constant CD_STANDARD => 12;
use constant CD_LARGE    => 18;

# Canvas Capabilities
use constant CD_CAP_NONE             => 0x00000000;
use constant CD_CAP_FLUSH            => 0x00000001;
use constant CD_CAP_CLEAR            => 0x00000002;
use constant CD_CAP_PLAY             => 0x00000004;
use constant CD_CAP_YAXIS            => 0x00000008;
use constant CD_CAP_CLIPAREA         => 0x00000010;
use constant CD_CAP_CLIPPOLY         => 0x00000020;
use constant CD_CAP_REGION           => 0x00000040;
use constant CD_CAP_RECT             => 0x00000080;
use constant CD_CAP_CHORD            => 0x00000100;
use constant CD_CAP_IMAGERGB         => 0x00000200;
use constant CD_CAP_IMAGERGBA        => 0x00000400;
use constant CD_CAP_IMAGEMAP         => 0x00000800;
use constant CD_CAP_GETIMAGERGB      => 0x00001000;
use constant CD_CAP_IMAGESRV         => 0x00002000;
use constant CD_CAP_BACKGROUND       => 0x00004000;
use constant CD_CAP_BACKOPACITY      => 0x00008000;
use constant CD_CAP_WRITEMODE        => 0x00010000;
use constant CD_CAP_LINESTYLE        => 0x00020000;
use constant CD_CAP_LINEWITH         => 0x00040000;
use constant CD_CAP_FPRIMTIVES       => 0x00080000;
use constant CD_CAP_HATCH            => 0x00100000;
use constant CD_CAP_STIPPLE          => 0x00200000;
use constant CD_CAP_PATTERN          => 0x00400000;
use constant CD_CAP_FONT             => 0x00800000;
use constant CD_CAP_FONTDIM          => 0x01000000;
use constant CD_CAP_TEXTSIZE         => 0x02000000;
use constant CD_CAP_TEXTORIENTATION  => 0x04000000;
use constant CD_CAP_PALETTE          => 0x08000000;
use constant CD_CAP_LINECAP          => 0x10000000;
use constant CD_CAP_LINEJOIN         => 0x20000000;
use constant CD_CAP_PATH             => 0x40000000;
use constant CD_CAP_BEZIER           => 0x80000000;
use constant CD_CAP_ALL              => 0xFFFFFFFF;

# cdPlay definitions
use constant CD_ABORT    => 1;
use constant CD_CONTINUE => 0;

# simulation flags
use constant CD_SIM_NONE         => 0x0000;
use constant CD_SIM_LINE         => 0x0001;
use constant CD_SIM_RECT         => 0x0002;
use constant CD_SIM_BOX          => 0x0004;
use constant CD_SIM_ARC          => 0x0008;
use constant CD_SIM_SECTOR       => 0x0010;
use constant CD_SIM_CHORD        => 0x0020;
use constant CD_SIM_POLYLINE     => 0x0040;
use constant CD_SIM_POLYGON      => 0x0080;
use constant CD_SIM_TEXT         => 0x0100;
use constant CD_SIM_ALL          => 0xFFFF;
use constant CD_SIM_LINES => (CD_SIM_LINE | CD_SIM_RECT | CD_SIM_ARC | CD_SIM_POLYLINE);
use constant CD_SIM_FILLS => (CD_SIM_BOX | CD_SIM_SECTOR | CD_SIM_CHORD | CD_SIM_POLYGON);

# some predefined colors for convenience
use constant CD_RED           => 0xFF0000;   # 255,  0,  0
use constant CD_DARK_RED      => 0x800000;   # 128,  0,  0
use constant CD_GREEN         => 0x00FF00;   #   0,255,  0
use constant CD_DARK_GREEN    => 0x008000;   #   0,128,  0
use constant CD_BLUE          => 0x0000FF;   #   0,  0,255
use constant CD_DARK_BLUE     => 0x000080;   #   0,  0,128
use constant CD_YELLOW        => 0xFFFF00;   # 255,255,  0
use constant CD_DARK_YELLOW   => 0x808000;   # 128,128,  0
use constant CD_MAGENTA       => 0xFF00FF;   # 255,  0,255
use constant CD_DARK_MAGENTA  => 0x800080;   # 128,  0,128
use constant CD_CYAN          => 0x00FFFF;   #   0,255,255
use constant CD_DARK_CYAN     => 0x008080;   #   0,128,128
use constant CD_WHITE         => 0xFFFFFF;   # 255,255,255
use constant CD_BLACK         => 0x000000;   #   0,  0,  0
use constant CD_DARK_GRAY     => 0x808080;   # 128,128,128
use constant CD_GRAY          => 0xC0C0C0;   # 192,192,192

# some usefull conversion factors
use constant CD_MM2PT   =>  2.834645669;    # milimeters to points (pt = CD_MM2PT * mm)
use constant CD_RAD2DEG => 57.295779513;    # radians to degrees (deg = CD_RAD2DEG * rad)
use constant CD_DEG2RAD =>  0.01745329252;  # degrees to radians (rad = CD_DEG2RAD * deg)

# paper sizes
use constant CD_A0     => 0;
use constant CD_A1     => 1;
use constant CD_A2     => 2;
use constant CD_A3     => 3;
use constant CD_A4     => 4;
use constant CD_A5     => 5; 
use constant CD_LETTER => 6;
use constant CD_LEGAL  => 7;

1;
