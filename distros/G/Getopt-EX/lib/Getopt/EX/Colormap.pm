package Getopt::EX::Colormap;

use v5.014;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(colorize colorize24 ansi_code ansi_pair csi_code);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);
our @ISA         = qw(Getopt::EX::LabeledParam);

use Carp;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Getopt::EX::LabeledParam;
use Getopt::EX::Util;
use Getopt::EX::Func qw(callable);

our $RGB24       = $ENV{GETOPTEX_RGB24};
our $LINEAR256   = $ENV{GETOPTEX_LINEAR256};
our $NO_RESET_EL = $ENV{GETOPTEX_NO_RESET_EL};

my @nonlinear = do {
    map { ( $_->[0] ) x $_->[1] } (
	[ 0, 95 ], #   0 ..  94
	[ 1, 40 ], #  95 .. 134
	[ 2, 40 ], # 135 .. 174
	[ 3, 40 ], # 175 .. 224
	[ 4, 40 ], # 225 .. 254
	[ 5,  1 ], # 255
    );
};

sub map_256_to_6 {
    my $i = shift;
    if ($LINEAR256) {
	int ( 5 * $i / 255 );
    } else {
	$nonlinear[$i];
    }
}

sub ansi256_number {
    my $code = shift;
    my($r, $g, $b, $grey);
    if ($code =~ /^([0-5])([0-5])([0-5])$/) {
	($r, $g, $b) = ($1, $2, $3);
    }
    elsif (my($n) = $code =~ /^L(\d+)/i) {
	$n > 25 and die "Color spec error: $code";
	if ($n == 0 or $n == 25) {
	    $r = $g = $b = $n / 5;
	} else {
	    $grey = $n - 1;
	}
    }
    elsif ($code =~ m{^(?| \# ([0-9a-f])([0-9a-f])([0-9a-f])
			 | \#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2}) )$}xi) {
	my($rx, $gx, $bx) = map { hex } $1, $2, $3;
	do { $_ *= 0x11 for $rx, $gx, $bx } if length $1 == 1;
	if ($rx != 255 and $rx == $gx and $rx == $bx) {
	    ##
	    ## Divide area into 25 segments, and map to BLACK and 24 GREYS
	    ##
	    $grey = int ( $rx * 25 / 255 ) - 1;
	    if ($grey < 0) {
		$r = $g = $b = 0;
		$grey = undef;
	    }
	} else {
	    ($r, $g, $b) = map { map_256_to_6 $_ } $rx, $gx, $bx;
	}
    }
    else {
	die "Color spec error: $code";
    }
    defined $grey ? ($grey + 232) : ($r*36 + $g*6 + $b + 16);
}

my %numbers = (
    ';' => undef,	# ; : NOP
    X => undef,		# X : NOP
    N => undef,		# N : None (NOP)
    E => 'EL',		# E : Erase Line
    Z => 0,		# Z : Zero (Reset)
    D => 1,		# D : Double-Struck (Bold)
    P => 2,		# P : Pale (Dark)
    I => 3,		# I : Italic
    U => 4,		# U : Underline
    F => 5,		# F : Flash (Blink: Slow)
    Q => 6,		# Q : Quick (Blink: Rapid)
    S => 7,		# S : Standout (Reverse)
    V => 8,		# V : Vanish (Concealed)
    J => 9,		# J : Junk (Crossed out)
    K => 30, k => 90,	# K : Kuro (Black)
    R => 31, r => 91,	# R : Red  
    G => 32, g => 92,	# G : Green
    Y => 33, y => 93,	# Y : Yellow
    B => 34, b => 94,	# B : Blue 
    M => 35, m => 95,	# M : Magenta
    C => 36, c => 96,	# C : Cyan 
    W => 37, w => 97,	# W : White
    );

sub rgb24 {
    my $rgb = shift;
    if ($RGB24) {
	return (2,
		map { hex }
		$rgb =~ /^\#?([\da-f]{2})([\da-f]{2})([\da-f]{2})/i);
    } else {
	return (5, ansi256_number $rgb);
    }
}

sub rgb12 {
    my $rgb = shift;
    if ($RGB24) {
	return (2,
		map { 0x11 * hex }
		$rgb =~ /^#([\da-f])([\da-f])([\da-f])/i);
    } else {
	return (5, ansi256_number $rgb);
    }
}

sub ansi_numbers {
    local $_ = shift // '';
    my @numbers;
    my $toggle = new Getopt::EX::ToggleValue value => 10;

    while (m{\G
	     (?:
	       (?<toggle> /)				# /
	     | (?<reset> \^)				# ^
	     | (?<h24>  \#?[0-9a-f]{6} )		# 24bit hex
	     | (?<h12>  \# [0-9a-f]{3} )		# 12bit hex
	     | (?<rgb>  \(\d+,\d+,\d+\) )		# 24bit decimal
	     | (?<c256>   [0-5][0-5][0-5]		# 216 (6x6x6) colors
		      | L(?:[01][0-9]|[2][0-5]) )	# 24 grey levels + B/W
	     | (?<c16>  [KRGYBMCW] )			# 16 colors
	     | (?<efct> [;XNZDPIUFQSVJ] )		# effects
	     | (?<csi>  { (?<csi_name>[A-Z]+)		# other CSI
			  (?<P> \( )?			# optional (
			  (?<csi_param>[\d,;]*)		# 0;1;2
			  (?(<P>) \) )			# closing )
			}
		      | (?<csi_abbr>[E]) )		# abbreviation
	     | < (?<name> \w+ )	>			# <colorname>
	     | (?<err>  .+ )				# error
	     )
	    }xig) {
	if ($+{toggle}) {
	    $toggle->toggle;
	}
	elsif ($+{reset}) {
	    $toggle->reset;
	}
	elsif ($+{h24}) {
	    push @numbers, 38 + $toggle->value, rgb24($+{h24});
	}
	elsif ($+{h12}) {
	    push @numbers, 38 + $toggle->value, rgb12($+{h12});
	}
	elsif (my $rgb = $+{rgb}) {
	    my @rgb = $rgb =~ /(\d+)/g;
	    die "Unexpected value: $rgb\n" if grep { $_ > 255 } @rgb;
	    my $hex = sprintf "%02X%02X%02X", @rgb;
	    push @numbers, 38 + $toggle->value, rgb24($hex);
	}
	elsif ($+{c256}) {
	    push @numbers, 38 + $toggle->value, 5, ansi256_number $+{c256};
	}
	elsif ($+{c16}) {
	    push @numbers, $numbers{$+{c16}} + $toggle->value;
	}
	elsif ($+{efct}) {
	    my $efct = uc $+{efct};
	    push @numbers, $numbers{$efct} if defined $numbers{$efct};
	}
	elsif ($+{csi}) {
	    push @numbers, do {
		if ($+{csi_abbr}) {
		    [ $numbers{uc $+{csi_abbr}} ];
		} else {
		    [ uc $+{csi_name}, $+{csi_param} =~ /\d+/g ];
		}
	    };
	}
	elsif ($+{name}) {
	    state $colornames = do {
		require Graphics::ColorNames;
		new     Graphics::ColorNames;
	    };
	    if (my $rgb = $colornames->hex($+{name})) {
		push @numbers, 38 + $toggle->value, rgb24($rgb);
	    } else {
		die "Unknown color name: $+{name}\n";
	    }
	}
	elsif (my $err = $+{err}) {
	    die "Color spec error: \"$err\" in \"$_\".\n"
	}
	else {
	    die "$_: Something strange.\n";
	}
	
    }
    @numbers;
}

use constant {
    CSI   => "\e[",
    RESET => "\e[m",
    EL    => "\e[K",
};

my %csi_terminator = (
    CUU	=> 'A',    # Cursor up
    CUD	=> 'B',    # Cursor Down
    CUF	=> 'C',    # Cursor Forward
    CUB	=> 'D',    # Cursor Back
    CNL	=> 'E',    # Cursor Next Line
    CPL	=> 'F',    # Cursor Previous line
    CHA	=> 'G',    # Cursor Horizontal Absolute
    CUP	=> 'H',    # Cursor Position
    ED  => 'J',    # Erase in Display (0 after, 1 before, 2 entire, 3 w/buffer)
    EL  => 'K',    # Erase in Line (0 after, 1 before, 2 entire)
    SU  => 'S',    # Scroll Up
    SD  => 'T',    # Scroll Down
    HVP	=> 'f',    # Horizontal Vertical Position
    SGR	=> 'm',    # Select Graphic Rendition
    SCP	=> 's',    # Save Cursor Position
    RCP	=> 'u',    # Restore Cursor Position
    );

sub csi_code {
    my $name = shift;
    my $c = $csi_terminator{$name} or do {
	warn "$name: Unknown ANSI name.\n";
	return '';
    };
    if ($name eq 'SGR' and @_ == 1 and $_[0] == 0) {
	@_ = ();
    }
    CSI . join(';', @_) . $c;
}

sub ansi_code {
    my $spec = shift;
    my @numbers = ansi_numbers $spec;
    my @code;
    while (@numbers) {
	my $item = shift @numbers;
	if (ref($item) eq 'ARRAY') {
	    push @code, csi_code @$item;
	} else {
	    my @sgr = ($item);
	    while (@numbers and not ref $numbers[0]) {
		push @sgr, shift @numbers;
	    }
	    push @code, csi_code 'SGR', @sgr;
	}
    }
    join '', @code;
}

sub ansi_pair {
    my $spec = shift;
    my $start = ansi_code $spec // '';
    my $end = $start eq '' ? '' : do {
	if ($start =~ /(.*)(\e\[[0;]*K)(.*)/) {
	    if ($3) {
		$1 . EL . RESET;
	    } else {
		EL . RESET;
	    }
	} else {
	    if ($NO_RESET_EL) {
		RESET;
	    } else {
		RESET . EL;
	    }
	}
    };
    ($start, $end);
}

my %colorcache;
my $reset_re;
BEGIN {
    $reset_re = qr{ \e\[[0;]*m (?: \e\[[0;]*[Km] )* }x;
}

sub colorize {
    cached_colorize(\%colorcache, @_);
}

sub colorize24 {
    local $RGB24 = 1;
    cached_colorize(\%colorcache, @_);
}

sub cached_colorize {
    my $cache = shift;
    my @result;
    while (@_ >= 2) {
	my($spec, $text) = splice @_, 0, 2;
	for my $color (ref $spec eq 'ARRAY' ? @$spec : $spec) {
	    $text = apply_color($cache, $color, $text);
	}
	push @result, $text;
    }
    croak "Wrong number of parameters" if @_;
    join '', @result;
}

sub apply_color {
    my($cache, $color, $text) = @_;
    if (callable $color) {
	return $color->call for $text;
    }
    else {
	my($s, $e) = @{ $cache->{$color} //= [ ansi_pair($color) ] };
	$text =~ s/(^|$reset_re)([^\e\r\n]*)/${1}${s}${2}${e}/mg;
	return $text;
    }
}

sub new {
    my $class = shift;
    my $obj = SUPER::new $class;
    my %opt = @_;

    $obj->{CACHE} = {};
    $opt{CONCAT} //= "^"; # Reset character for LabeledParam object
    configure $obj %opt;

    $obj;
}

sub index_color {
    my $obj = shift;
    my $index = shift;
    my $text = shift;

    my $list = $obj->{LIST};
    if (@$list) {
	$text = $obj->color($list->[$index % @$list], $text, $index);
    }
    $text;
}

sub color {
    my $obj = shift;
    my $color = shift;
    my $text = shift;

    my $map = $obj->{HASH};
    my $c = exists $map->{$color} ? $map->{$color} : $color;

    return $text unless $c;

    cached_colorize($obj->{CACHE}, $c, $text);
}

sub colormap {
    my $obj = shift;
    my %opt = @_;
    $opt{name}    //= "--newopt";
    $opt{option}  //= "--colormap";
    $opt{sort}    //= "length";

    my $hash = $obj->{HASH};
    join "\n", (
	"option $opt{name} \\",
	do {
	    my $maxlen = $opt{noalign} ? "" : do {
		use List::Util qw(max);
		max map { length } keys %{$hash};
	    };
	    my $format = "\t%s %${maxlen}s=%s \\";
	    my $compare = do {
		if ($opt{sort} eq "length") {
		    sub { length $a <=> length $b or $a cmp $b };
		} else {
		    sub { $a cmp $b };
		}
	    };
	    map {
		sprintf $format, $opt{option}, $_, $hash->{$_} // "";
	    } sort $compare keys %{$hash};
	},
	"\t\$<move(0,0)>\n",
	);
}

1;

__END__


=head1 NAME

Getopt::EX::Colormap - ANSI terminal color and option support


=head1 SYNOPSIS

  GetOptions('colormap|cm:s' => @opt_colormap);

  require Getopt::EX::Colormap;
  my $cm = new Getopt::EX::Colormap;
  $cm->load_params(@opt_colormap);  

  print $cm->color('FILE', 'FILE labeled text');

  print $cm->index_color($index, 'TEXT');

    or

  use Getopt::EX::Colormap qw(colorize);
  $text = colorize(SPEC, TEXT);
  $text = colorize(SPEC_1, TEXT_1, SPEC_2, TEXT_2, ...);


=head1 DESCRIPTION

Coloring text capability is not strongly bound to option processing,
but it may be useful to give simple uniform way to specify complicated
color setting from command line.

This module assumes the color information is given in two ways: one in
labeled list, and one in indexed list.

This is an example of labeled list:

    --cm 'COMMAND=SE,OMARK=CS,NMARK=MS' \
    --cm 'OTEXT=C,NTEXT=M,*CHANGE=BD/445,DELETE=APPEND=RD/544' \
    --cm 'CMARK=GS,MMARK=YS,CTEXT=G,MTEXT=Y'

Each color definitions are separated by comma (C<,>) and label is
specified by I<LABEL=> style precedence.  Multiple labels can be set
for same value by connecting them together.  Label name can be
specified with C<*> and C<?> wildcard characters.

If the color spec start with plus (C<+>) mark with labeled list
format, it is appended to the current value with reset mark (C<^>).
Next example uses wildcard to set all labels end with `CHANGE' to `R'
and set `R^S' to `OCHANGE' label.

    --cm '*CHANGE=R,OCHANGE=+S'

Indexed list example is like this:

    --cm 555/100,555/010,555/001 \
    --cm 555/011,555/101,555/110 \
    --cm 555/021,555/201,555/210 \
    --cm 555/012,555/102,555/120

This is the example of RGB 6x6x6 216 colors specification.  Left
side of slash is foreground color, and right side is for background.
This color list is accessed by index.

Handler maintains hash and list objects, and labeled colors are stored
in hash, non-label colors are in list automatically.  User can mix
both specifications.

Besides producing ANSI colored text, this module supports calling
arbitrary function to handle a string.  See L<FUNCTION SPEC> section
for more detail.


=head1 COLOR SPEC

Color specification is a combination of single uppercase character
representing 8 colors :

    R  Red
    G  Green
    B  Blue
    C  Cyan
    M  Magenta
    Y  Yellow
    K  Black
    W  White

and alternative (usually brighter) colors in lowercase :

    r, g, b, c, m, y, k, w

or RGB values and 24 grey levels if using ANSI 256 or full color
terminal :

    (255,255,255)      : 24bit decimal RGB colors
    #000000 .. #FFFFFF : 24bit hex RGB colors
    #000    .. #FFF    : 12bit hex RGB 4096 colors
    000 .. 555         : 6x6x6 RGB 216 colors
    L00 .. L25         : Black (L00), 24 grey levels, White (L25)

=over 4

Begining # can be omitted in 24bit RGB notation.

When values are all same in 24bit or 12bit RGB, it is converted to 24
grey level, otherwise 6x6x6 216 color.

Until version v1.9.0, grey levels were assigned to L00-L23.  In this
version, L00 and L25 represent black and white, and 24 grey levels are
assigned to L01-L24.

=back

or color names enclosed by angle bracket :

    <red> <blue> <green> <cyan> <magenta> <yellow>
    <aliceblue> <honeydue> <hotpink> <mooccasin>
    <medium_aqua_marine>

with other special effects :

    Z  0 Zero (reset)
    D  1 Double-struck (boldface)
    P  2 Pale (dark)
    I  3 Italic
    U  4 Underline
    F  5 Flash (blink: slow)
    Q  6 Quick (blink: rapid)
    S  7 Stand-out (reverse video)
    V  8 Vanish (concealed)
    J  9 Junk (crossed out)

    E    Erase Line

    ;    No effect
    X    No effect
    /    Toggle foreground/background
    ^    Reset to foreground

At first the color is considered as foreground, and slash (C</>)
switches foreground and background.  If multiple colors are given in
the same spec, all indicators are produced in the order of their
presence.  Consequently, the last one takes effect.

If the spec start with plus (C<+>) or minus (C<->) character,
following characters are appneded/deleted from previous value. Reset
mark (C<^>) is inserted before appended string.

Effect characters are case insensitive, and can be found anywhere and
in any order in color spec string.  Because C<X> and C<;> takes no
effect, you can use them to improve readability, like C<SxD;K/544>.

Samples:

    RGB  6x6x6    12bit      24bit           color name
    ===  =======  =========  =============  ==================
    B    005      #00F       (0,0,255)      <blue>
     /M     /505      /#F0F   /(255,0,255)  /<magenta>
    K/W  000/555  #000/#FFF  000000/FFFFFF  <black>/<white>
    R/G  500/050  #F00/#0F0  FF0000/00FF00  <red>/<green>
    W/w  L03/L20  #333/#ccc  303030/c6c6c6  <dimgrey>/<lightgrey>

24-bit RGB color sequence is supported but disabled by default.  Set
C<$RGB24> module variable to enable it.

Character "E" is an abbreviation for "{EL}", and it clears the line
from cursor to the end of the line.  At this time, background color is
set to the area.  When this code is found in the start sequence, it is
copied to just before ending reset sequence, with preceding sequence
if necessary, to keep the effect even when the text is wrapped to
multiple lines.

Other ANSI CSI sequences are also available in the form of "{NAME}",
despite there are few reasons to use them.

    CUU n   Cursor up
    CUD n   Cursor Down
    CUF n   Cursor Forward
    CUB n   Cursor Back
    CNL n   Cursor Next Line
    CPL n   Cursor Previous line
    CHA n   Cursor Horizontal Absolute
    CUP n,m Cursor Position
    ED  n   Erase in Display (0 after, 1 before, 2 entire, 3 w/buffer)
    EL  n   Erase in Line (0 after, 1 before, 2 entire)
    SU  n   Scroll Up
    SD  n   Scroll Down
    HVP n,m Horizontal Vertical Position
    SGR n*  Select Graphic Rendition
    SCP     Save Cursor Position
    RCP     Restore Cursor Position

These name accept following optional numerical parameters, using comma
(',') or semicolon (';') to separate multiple ones, with optional
braces.  For example, color spec C<DK/544> can be described as
C<{SGR1;30;48;5;224}> or more readable C<{SGR(1,30,48,5,224)}>.

=head1 COLOR NAMES

Color names are experimentaly supported in this version.  Currently
names are listed in L<Graphics::ColorNames::X> module.  Following
colors are available.

See L<https://en.wikipedia.org/wiki/X11_color_names>.

    gray gray0 .. gray100
    grey grey0 .. grey100

    aliceblue antiquewhite antiquewhite1 antiquewhite2 antiquewhite3
    antiquewhite4 aqua aquamarine aquamarine1 aquamarine2 aquamarine3
    aquamarine4 azure azure1 azure2 azure3 azure4 beige bisque bisque1
    bisque2 bisque3 bisque4 black blanchedalmond blue blue1 blue2 blue3
    blue4 blueviolet brown brown1 brown2 brown3 brown4 burlywood
    burlywood1 burlywood2 burlywood3 burlywood4 cadetblue cadetblue1
    cadetblue2 cadetblue3 cadetblue4 chartreuse chartreuse1 chartreuse2
    chartreuse3 chartreuse4 chocolate chocolate1 chocolate2 chocolate3
    chocolate4 coral coral1 coral2 coral3 coral4 cornflowerblue cornsilk
    cornsilk1 cornsilk2 cornsilk3 cornsilk4 crimson cyan cyan1 cyan2 cyan3
    cyan4 darkblue darkcyan darkgoldenrod darkgoldenrod1 darkgoldenrod2
    darkgoldenrod3 darkgoldenrod4 darkgray darkgreen darkgrey darkkhaki
    darkmagenta darkolivegreen darkolivegreen1 darkolivegreen2
    darkolivegreen3 darkolivegreen4 darkorange darkorange1 darkorange2
    darkorange3 darkorange4 darkorchid darkorchid1 darkorchid2 darkorchid3
    darkorchid4 darkred darksalmon darkseagreen darkseagreen1
    darkseagreen2 darkseagreen3 darkseagreen4 darkslateblue darkslategray
    darkslategray1 darkslategray2 darkslategray3 darkslategray4
    darkslategrey darkturquoise darkviolet deeppink deeppink1 deeppink2
    deeppink3 deeppink4 deepskyblue deepskyblue1 deepskyblue2 deepskyblue3
    deepskyblue4 dimgray dimgrey dodgerblue dodgerblue1 dodgerblue2
    dodgerblue3 dodgerblue4 firebrick firebrick1 firebrick2 firebrick3
    firebrick4 floralwhite forestgreen fuchsia gainsboro ghostwhite gold
    gold1 gold2 gold3 gold4 goldenrod goldenrod1 goldenrod2 goldenrod3
    goldenrod4 honeydew honeydew1 honeydew2 honeydew3 honeydew4 hotpink
    hotpink1 hotpink2 hotpink3 hotpink4 indianred indianred1 indianred2
    indianred3 indianred4 indigo ivory ivory1 ivory2 ivory3 ivory4 khaki
    khaki1 khaki2 khaki3 khaki4 lavender lavenderblush lavenderblush1
    lavenderblush2 lavenderblush3 lavenderblush4 lawngreen lemonchiffon
    lemonchiffon1 lemonchiffon2 lemonchiffon3 lemonchiffon4 lightblue
    lightblue1 lightblue2 lightblue3 lightblue4 lightcoral lightcyan
    lightcyan1 lightcyan2 lightcyan3 lightcyan4 lightgoldenrod
    lightgoldenrod1 lightgoldenrod2 lightgoldenrod3 lightgoldenrod4
    lightgoldenrodyellow lightgray lightgreen lightgrey lightpink
    lightpink1 lightpink2 lightpink3 lightpink4 lightsalmon lightsalmon1
    lightsalmon2 lightsalmon3 lightsalmon4 lightseagreen lightskyblue
    lightskyblue1 lightskyblue2 lightskyblue3 lightskyblue4 lightslateblue
    lightslategray lightslategrey lightsteelblue lightsteelblue1
    lightsteelblue2 lightsteelblue3 lightsteelblue4 lightyellow
    lightyellow1 lightyellow2 lightyellow3 lightyellow4 lime limegreen
    linen magenta magenta1 magenta2 magenta3 magenta4 maroon maroon1
    maroon2 maroon3 maroon4 mediumaquamarine mediumblue mediumorchid
    mediumorchid1 mediumorchid2 mediumorchid3 mediumorchid4 mediumpurple
    mediumpurple1 mediumpurple2 mediumpurple3 mediumpurple4 mediumseagreen
    mediumslateblue mediumspringgreen mediumturquoise mediumvioletred
    midnightblue mintcream mistyrose mistyrose1 mistyrose2 mistyrose3
    mistyrose4 moccasin navajowhite navajowhite1 navajowhite2 navajowhite3
    navajowhite4 navy navyblue oldlace olive olivedrab olivedrab1
    olivedrab2 olivedrab3 olivedrab4 orange orange1 orange2 orange3
    orange4 orangered orangered1 orangered2 orangered3 orangered4 orchid
    orchid1 orchid2 orchid3 orchid4 palegoldenrod palegreen palegreen1
    palegreen2 palegreen3 palegreen4 paleturquoise paleturquoise1
    paleturquoise2 paleturquoise3 paleturquoise4 palevioletred
    palevioletred1 palevioletred2 palevioletred3 palevioletred4 papayawhip
    peachpuff peachpuff1 peachpuff2 peachpuff3 peachpuff4 peru pink pink1
    pink2 pink3 pink4 plum plum1 plum2 plum3 plum4 powderblue purple
    purple1 purple2 purple3 purple4 rebeccapurple red red1 red2 red3 red4
    rosybrown rosybrown1 rosybrown2 rosybrown3 rosybrown4 royalblue
    royalblue1 royalblue2 royalblue3 royalblue4 saddlebrown salmon salmon1
    salmon2 salmon3 salmon4 sandybrown seagreen seagreen1 seagreen2
    seagreen3 seagreen4 seashell seashell1 seashell2 seashell3 seashell4
    sienna sienna1 sienna2 sienna3 sienna4 silver skyblue skyblue1
    skyblue2 skyblue3 skyblue4 slateblue slateblue1 slateblue2 slateblue3
    slateblue4 slategray slategray1 slategray2 slategray3 slategray4
    slategrey snow snow1 snow2 snow3 snow4 springgreen springgreen1
    springgreen2 springgreen3 springgreen4 steelblue steelblue1 steelblue2
    steelblue3 steelblue4 tan tan1 tan2 tan3 tan4 teal thistle thistle1
    thistle2 thistle3 thistle4 tomato tomato1 tomato2 tomato3 tomato4
    turquoise turquoise1 turquoise2 turquoise3 turquoise4 violet violetred
    violetred1 violetred2 violetred3 violetred4 webgray webgreen webgrey
    webmaroon webpurple wheat wheat1 wheat2 wheat3 wheat4 white whitesmoke
    x11gray x11green x11grey x11maroon x11purple yellow yellow1 yellow2
    yellow3 yellow4 yellowgreen

Enclose them by angle bracket to use, like:

    <deeppink>/<lightyellow>

Although these colors are defined in 24bit value, they are mapped to
6x6x6 216 colors by default.  Set C<$RGB24> module variable to use
24bit color mode.

=head1 FUNCTION SPEC

It is also possible to set arbitrary function which is called to
handle string in place of color, and that is not necessarily concerned
with color.  This scheme is quite powerful and the module name itself
may be somewhat misleading.  Spec string which start with C<sub{> is
considered as a function definition.  So

    % example --cm 'sub{uc}'

set the function object in the color entry.  And when C<color> method
is called with that object, specified function is called instead of
producing ANSI color sequence.  Function is supposed to get the target
text as a global variable C<$_>, and return the result as a string.
Function C<sub{uc}> in the above example returns uppercase version of
C<$_>.

If your script prints file name according to the color spec labeled by
B<FILE>, then

    % example --cm FILE=R

prints the file name in red, but

    % example --cm FILE=sub{uc}

will print the name in uppercases.

Spec start with C<&> is considered as a function name.  If the
function C<double> is defined like:

    sub double { $_ . $_ }

then, command

    % example --cm '&double'

produces doubled text by C<color> method.  Function can also take
parameters, so the next example

    sub repeat {
	my %opt = @_;
	$_ x $opt{count} // 1;
    }

    % example --cm '&repeat(count=3)'

produces tripled text.

Function object is created by <Getopt::EX::Func> module.  Take a look
at the module for detail.


=head1 EXAMPLE CODE

    #!/usr/bin/perl
    
    use strict;
    use warnings;

    my @opt_colormap;
    use Getopt::EX::Long;
    GetOptions("colormap|cm=s" => \@opt_colormap);
    
    my %colormap = ( # default color map
        FILE => 'R',
        LINE => 'G',
        TEXT => 'B',
        );
    my @colors;
    
    require Getopt::EX::Colormap;
    my $handler = new Getopt::EX::Colormap
        HASH => \%colormap,
        LIST => \@colors;
    
    $handler->load_params(@opt_colormap);

    for (0 .. $#colors) {
        print $handler->index_color($_, "COLOR $_"), "\n";
    }
    
    for (sort keys %colormap) {
        print $handler->color($_, $_), "\n";
    }

This sample program is complete to work.  If you save this script as a
file F<example>, try to put following contents in F<~/.examplerc> and
see what happens.

    option default \
        --cm 555/100,555/010,555/001 \
        --cm 555/011,555/101,555/110 \
        --cm 555/021,555/201,555/210 \
        --cm 555/012,555/102,555/120


=head1 METHOD

=over 4

=item B<color> I<label>, TEXT

=item B<color> I<color_spec>, TEXT

Return colored text indicated by label or color spec string.

=item B<index_color> I<index>, TEXT

Return colored text indicated by I<index>.  If the index is bigger
than color list, it rounds up.

=item B<new>

=item B<append>

=item B<load_params>

See super class L<Getopt::EX::LabeledParam>.

=item B<colormap>

Return string which can be used for option definition.  Some
parameters can be specified like:

    $obj->colormap(name => "--newopt", option => "--colormap");

=over 4

=item B<name>

Specify new option name.

=item B<option>

Specify option name for colormap setup.

=item B<sort>

Default value is C<length> and sort options by their length.  Use
C<alphabet> to sort them alphabetically.

=item B<noalign>

Colormap label is aligned so that `=' marks are lined vertically.
Give true value to B<noalign> parameter, if you don't like this
behaviour.

=back

=back


=head1 FUNCTION

=over 4

=item B<colorize>(I<color_spec>, I<text>)

=item B<colorize24>(I<color_spec>, I<text>)

Return colorized version of given text.

B<colorize> produces 256 or 24bit colors depending on the value of
C<Getopt::EX::Colormap::RGB24> variable and environment
C<GETOPTEX_RGB24>.

B<colorize24> always produces 24bit color sequence for 24bit/12bit
color spec.

=item B<ansi_code>(I<color_spec>)

Produces introducer sequence for given spec.  Reset code can be taken
by B<ansi_code("Z")>.

=item B<ansi_pair>(I<color_spec>)

Produces introducer and recover sequences for given spec. Recover
sequence includes I<Erace Line> related control with simple SGR reset
code.

=item B<csi_code>(I<name>, I<params>)

Produce CSI (Control Sequence Introducer) sequence by name with
numeric parameters.  I<name> is one of CUU, CUD, CUF, CUB, CNL, CPL,
CHA, CUP, ED, EL, SU, SD, HVP, SGR, SCP, RCP.

=back


=head1 SEE ALSO

L<Getopt::EX>,
L<Getopt::EX::LabeledParam>

L<https://en.wikipedia.org/wiki/ANSI_escape_code>

L<Graphics::ColorNames::X>

L<https://en.wikipedia.org/wiki/X11_color_names>

=cut
