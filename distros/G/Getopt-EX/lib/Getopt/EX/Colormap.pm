package Getopt::EX::Colormap;
use version; our $VERSION = version->declare("v1.26.0");

use v5.14;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT      = qw();
our @EXPORT_OK   = qw(
    colorize colorize24 ansi_code ansi_pair csi_code
    colortable colortable6 colortable12 colortable24
    );
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);
our @ISA         = qw(Getopt::EX::LabeledParam);

use Carp;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use List::Util qw(min max first);

use Getopt::EX::LabeledParam;
use Getopt::EX::Util;
use Getopt::EX::Func qw(callable);

our $NO_NO_COLOR //= $ENV{GETOPTEX_NO_NO_COLOR};
our $NO_COLOR    //= !$NO_NO_COLOR && defined $ENV{NO_COLOR};
our $RGB24       //= $ENV{COLORTERM}//'' eq 'truecolor' || $ENV{GETOPTEX_RGB24};
our $LINEAR256   //= $ENV{GETOPTEX_LINEAR256};
our $LINEAR_GREY //= $ENV{GETOPTEX_LINEARGREY};
our $NO_RESET_EL //= $ENV{GETOPTEX_NO_RESET_EL};
our $SPLIT_ANSI  //= $ENV{GETOPTEX_SPLIT_ANSI};

my @nonlinear = do {
    map { ( $_->[0] ) x $_->[1] } (
	[ 0, 75 ], #   0 ..  74
	[ 1, 40 ], #  75 .. 114
	[ 2, 40 ], # 115 .. 154
	[ 3, 40 ], # 155 .. 194
	[ 4, 40 ], # 195 .. 234
	[ 5, 21 ], # 235 .. 255
    );
};

sub map_256_to_6 {
    use integer;
    my $i = shift;
    if ($LINEAR256) {
	5 * $i / 255;
    } else {
	# ( $i - 35 ) / 40;
	$nonlinear[$i];
    }
}

sub map_to_256 {
    my($base, $i) = @_;
    if    ($i == 0)     { 0 }
    elsif ($base ==  6) { $i * 40 + 55 }
    elsif ($base == 12) { $i * 20 + 35 }
    elsif ($base == 24) { $i * 10 + 25 }
    else  { die }
}

sub ansi256_number {
    my $code = shift;
    my($r, $g, $b, $grey);
    if ($code =~ /^([0-5])([0-5])([0-5])$/) {
	($r, $g, $b) = ($1, $2, $3);
    }
    elsif (my($n) = $code =~ /^L(\d+)/i) {
	$n > 25 and croak "Color spec error: $code.";
	if ($n == 0 or $n == 25) {
	    $r = $g = $b = $n / 5;
	} else {
	    $grey = $n - 1;
	}
    }
    else {
	croak "Color spec error: $code.";
    }
    defined $grey ? ($grey + 232) : ($r*36 + $g*6 + $b + 16);
}

sub rgb24_number {
    use integer;
    my($rx, $gx, $bx) = @_;
    my($r, $g, $b, $grey);
    if ($rx != 0 and $rx != 255 and $rx == $gx and $rx == $bx) {
	if ($LINEAR_GREY) {
	    ##
	    ## Divide area into 25 segments, and map to BLACK and 24 GREYS
	    ##
	    $grey = $rx * 25 / 255 - 1;
	    if ($grey < 0) {
		$r = $g = $b = 0;
		$grey = undef;
	    }
	} else {
	    ## map to 8, 18, 28, ... 238
	    $grey = min(23, ($rx - 3) / 10);
	}
    } else {
	($r, $g, $b) = map { map_256_to_6 $_ } $rx, $gx, $bx;
    }
    defined $grey ? ($grey + 232) : ($r*36 + $g*6 + $b + 16);
}

sub rgbhex {
    my $rgb = shift =~ s/^#//r;
    my $len = length $rgb;
    croak "$rgb: Invalid RGB value." if $len == 0 || $len % 3;
    $len /= 3;
    my $max = (2 ** ($len * 4)) - 1;
    my @rgb24 = map { hex($_) * 255 / $max } $rgb =~ /[0-9a-z]{$len}/gi or die;
    if ($RGB24) {
	return (2, @rgb24);
    } else {
	return (5, rgb24_number @rgb24);
    }
}

my %numbers = (
    ';' => undef,	# ; : NOP
    N   => undef,	# N : None (NOP)
    E => 'EL',		# E : Erase Line
    Z => 0,		# Z : Zero (Reset)
    D => 1,		# D : Double Strike (Bold)
    P => 2,		# P : Pale (Dark)
    I => 3,		# I : Italic
    U => 4,		# U : Underline
    F => 5,		# F : Flash (Blink: Slow)
    Q => 6,		# Q : Quick (Blink: Rapid)
    S => 7,		# S : Stand out (Reverse)
    H => 8,		# H : Hide (Concealed)
    V => 8,		# V : Vanish (Concealed)
    X => 9,		# X : Cross out
    K => 30, k => 90,	# K : Kuro (Black)
    R => 31, r => 91,	# R : Red  
    G => 32, g => 92,	# G : Green
    Y => 33, y => 93,	# Y : Yellow
    B => 34, b => 94,	# B : Blue 
    M => 35, m => 95,	# M : Magenta
    C => 36, c => 96,	# C : Cyan 
    W => 37, w => 97,	# W : White
    );

my $colorspec_re = qr{
      (?<toggle> /)			 # /
    | (?<reset> \^)			 # ^
    | (?<hex>	 [0-9a-f]{6}		 # 24bit hex
	     | \#[0-9a-f]{3,} )		 # generic hex
    | (?<rgb>  \(\d+,\d+,\d+\) )	 # 24bit decimal
    | (?<c256>	 [0-5][0-5][0-5]	 # 216 (6x6x6) colors
	     | L(?:[01][0-9]|[2][0-5]) ) # 24 grey levels + B/W
    | (?<c16>  [KRGYBMCW] )		 # 16 colors
    | (?<efct> ~?[;NZDPIUFQSHVX] )	 # effects
    | (?<csi>  { (?<csi_name>[A-Z]+)	 # other CSI
		 (?<P> \( )?		 # optional (
		 (?<csi_param>[\d,;]*)	 # 0;1;2
		 (?(<P>) \) )		 # closing )
	       }
	     | (?<csi_abbr>[E]) )	 # abbreviation
    | < (?<name> \w+ ) >		 # <colorname>
}xi;

sub ansi_numbers {
    local $_ = shift // '';
    my @numbers;
    my $toggle = Getopt::EX::ToggleValue->new(value => 10);

    while (m{\G (?: $colorspec_re | (?<err> .+ ) ) }xig) {
	if ($+{toggle}) {
	    $toggle->toggle;
	}
	elsif ($+{reset}) {
	    $toggle->reset;
	}
	elsif ($+{hex}) {
	    push @numbers, 38 + $toggle->value, rgbhex($+{hex});
	}
	elsif (my $rgb = $+{rgb}) {
	    my @rgb = $rgb =~ /(\d+)/g;
	    croak "Unexpected value: $rgb." if grep { $_ > 255 } @rgb;
	    my $hex = sprintf "%02X%02X%02X", @rgb;
	    push @numbers, 38 + $toggle->value, rgbhex($hex);
	}
	elsif ($+{c256}) {
	    push @numbers, 38 + $toggle->value, 5, ansi256_number $+{c256};
	}
	elsif ($+{c16}) {
	    push @numbers, $numbers{$+{c16}} + $toggle->value;
	}
	elsif ($+{efct}) {
	    my $efct = uc $+{efct};
	    my $offset = $efct =~ s/^~// ? 20 : 0;
	    if (defined (my $n = $numbers{$efct})) {
		push @numbers, $n + $offset;
	    }
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
		Graphics::ColorNames->new;
	    };
	    if (my $rgb = $colornames->hex($+{name})) {
		push @numbers, 38 + $toggle->value, rgbhex($rgb);
	    } else {
		croak "Unknown color name: $+{name}.";
	    }
	}
	elsif (my $err = $+{err}) {
	    croak "Color spec error: \"$err\" in \"$_\"."
	}
	else {
	    croak "$_: Something strange.";
	}
    } continue {
	if ($SPLIT_ANSI) {
	    my $index = first { not ref $numbers[$_] } 0 .. $#numbers;
	    if (defined $index) {
		my @sgr = splice @numbers, $index;
		push @numbers, [ 'SGR', @sgr ];
	    }
	}
    }
    @numbers;
}

use constant {
    CSI   => "\e[",	# Control Sequence Introducer
    RESET => "\e[m",	# SGR Reset
    EL    => "\e[K",	# Erase Line
};

my %csi_terminator = (
    CUU => 'A',		# Cursor up
    CUD => 'B',		# Cursor Down
    CUF => 'C',		# Cursor Forward
    CUB => 'D',		# Cursor Back
    CNL => 'E',		# Cursor Next Line
    CPL => 'F',		# Cursor Previous line
    CHA => 'G',		# Cursor Horizontal Absolute
    CUP => 'H',		# Cursor Position
    ED  => 'J',		# Erase in Display (0 after, 1 before, 2 entire, 3 w/buffer)
    EL  => 'K',		# Erase in Line (0 after, 1 before, 2 entire)
    SU  => 'S',		# Scroll Up
    SD  => 'T',		# Scroll Down
    HVP => 'f',		# Horizontal Vertical Position
    SGR => 'm',		# Select Graphic Rendition
    SCP => 's',		# Save Cursor Position
    RCP => 'u',		# Restore Cursor Position
    );

my %other_sequence = (
    RIS   => "\ec",	# Reset to Initial State
    DECSC => "\e7",	# DEC Save Cursor
    DECRC => "\e8",	# DEC Restore Cursor
    );

sub csi_code {
    my $name = shift;
    if (my $seq = $other_sequence{$name}) {
	return $seq;
    }
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
    my $el = 0;
    my $start = ansi_code $spec // '';
    my $end = $start eq '' ? '' : do {
	if ($start =~ /(.*)(\e\[[0;]*K)(.*)/) {
	    $el = 1;
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
    ($start, $end, $el);
}

sub colorize {
    cached_colorize(state $cache = {}, @_);
}

sub colorize24 {
    local $RGB24 = 1;
    cached_colorize(state $cache = {}, @_);
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
    croak "Wrong number of parameters." if @_;
    join '', @result;
}

sub apply_color {
    my($cache, $color, $text) = @_;
    if (callable $color) {
	return $color->call for $text;
    }
    elsif ($NO_COLOR) {
        return $text;
    }
    else {
	my($s, $e, $el) = @{ $cache->{$color} //= [ ansi_pair($color) ] };
	state $reset = qr{ \e\[[0;]*m (?: \e\[[0;]*[Km] )* }x;
	if ($el) {
	    $text =~ s/(^|$reset)([^\e\r\n]*)/${1}${s}${2}${e}/mg;
	} else {
	    $text =~ s/(^|$reset)([^\e\r\n]+)/${1}${s}${2}${e}/mg;
	}
	return $text;
    }
}

sub new {
    my $class = shift;
    my $obj = $class->SUPER::new;
    my %opt = @_;

    $obj->{CACHE} = {};
    $opt{CONCAT} //= "^"; # Reset character for LabeledParam object
    $obj->configure(%opt);

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
	"\t\$<ignore>\n",
	);
}

sub colortable6 {
    colortableN(
	step   => 6,
	string => "    ",
	line   => 2,
	x => 1, y => 1, z => 1,
	@_
	);
}

sub colortable12 {
    colortableN(
	step   => 12,
	string => "  ",
	x => 1, y => 1, z => 2,
	@_
	);
}

# use charnames ':full';

sub colortable24 {
    colortableN(
	step   => 24,
	string => "\N{U+2580}", # "\N{UPPER HALF BLOCK}",
	shift  => 1,
	x => 1, y => 2, z => 4,
	@_
	);
}

sub colortableN {
    my %arg = (
	shift => 0,
	line  => 1,
	row   => 3,
	@_);
    my @combi = do {
	my @default = qw( XYZ YZX ZXY  YXZ XZY ZYX );
	if (my @s = $arg{row} =~ /[xyz]{3}/ig) {
	    @s;
	} else {
	    @default[0 .. $arg{row} - 1];
	}
    };
    my @order = map {
	my @ord = map { { X=>0, Y=>1, Z=>2 }->{$_} } /[XYZ]/g;
	sub { @_[@ord] }
    } map { uc } @combi;
    binmode STDOUT, ":utf8";
    for my $order (@order) {
	my $rgb = sub {
	    sprintf "#%02x%02x%02x",
		map { map_to_256($arg{step}, $_) } $order->(@_);
	};
	for (my $y = 0; $y < $arg{step}; $y += $arg{y}) {
	    my @out;
	    for (my $z = 0; $z < $arg{step}; $z += $arg{z}) {
		for (my $x = 0; $x < $arg{step}; $x += $arg{x}) {
		    my $fg = $rgb->($x, $y, $z);
		    my $bg = $rgb->($x, $y + $arg{shift}, $z);
		    push @out, colorize "$fg/$bg", $arg{string};
		}
	    }
	    print((@out, "\n") x $arg{line});
	}
    }
}

sub colortable {
    my $width = shift || 144;
    my $column = min 6, $width / (4 * 6);
    for my $c (0..5) {
	for my $b (0..5) {
	    my @format =
		("%d$b$c", "$c%d$b", "$b$c%d", "$b%d$c", "$c$b%d", "%d$c$b")
		[0 .. $column - 1];
	    for my $format (@format) {
		for my $a (0..5) {
		    my $rgb = sprintf $format, $a;
		    print colorize "$rgb/$rgb", " $rgb";
		}
	    }
	    print "\n";
	}
    }
    for my $g (0..5) {
	my $grey = $g x 3;
	print colorize "$grey/$grey", sprintf(" %-19s", $grey);
    }
    print "\n";
    for ('L00' .. 'L25') {
	print colorize "$_/$_", " $_";
    }
    print "\n";
    for my $rgb ("RGBCMYKW", "rgbcmykw") {
	for my $c (split //, $rgb) {
	    print colorize "$c/$c", "  $c ";
	}
	print "\n";
    }
    for my $rgb (qw(500 050 005 055 505 550 000 555)) {
	print colorize "$rgb/$rgb", " $rgb";
    }
    print "\n";
}

1;

__END__


=head1 NAME

Getopt::EX::Colormap - ANSI terminal color and option support


=head1 SYNOPSIS

  GetOptions('colormap|cm:s' => @opt_colormap);

  require Getopt::EX::Colormap;
  my $cm = Getopt::EX::Colormap
      ->new
      ->load_params(@opt_colormap);  

  print $cm->color('FILE', 'FILE labeled text');

  print $cm->index_color($index, 'TEXT');

    or

  use Getopt::EX::Colormap qw(colorize);
  $text = colorize(SPEC, TEXT);
  $text = colorize(SPEC_1, TEXT_1, SPEC_2, TEXT_2, ...);

  $ perl -MGetopt::EX::Colormap=colortable -e colortable


=head1 DESCRIPTION

Text coloring capability is not strongly bound to option processing,
but it may be useful to give a simple uniform way to specify
complicated color setting from command line.

This module assumes color information is given in two ways: one in
labeled list, and one in indexed list.

Handler maintains hash and list objects, and labeled colors are stored
in hash, index colors are in list automatically.  User can mix both
specifications.

=head2 LABELED COLOR

This is an example of labeled list:

    --cm 'COMMAND=SE,OMARK=CS,NMARK=MS' \
    --cm 'OTEXT=C,NTEXT=M,*CHANGE=BD/445,DELETE=APPEND=RD/544' \
    --cm 'CMARK=GS,MMARK=YS,CTEXT=G,MTEXT=Y'

Each color definitions are separated by comma (C<,>) and labels are
specified by I<LABEL=> style precedence.  Multiple labels can be set
for same value by connecting them together.  Label name can be
specified with C<*> and C<?> wildcard characters.

If the color spec start with plus (C<+>) mark with labeled list
format, it is appended to the current value with reset mark (C<^>).
Next example uses wildcard to set all labels end with `CHANGE' to `R'
and set `R^S' to `OCHANGE' label.

    --cm '*CHANGE=R,OCHANGE=+S'

=head2 INDEX COLOR

Indexed list example is like this:

    --cm 555/100,555/010,555/001 \
    --cm 555/011,555/101,555/110 \
    --cm 555/021,555/201,555/210 \
    --cm 555/012,555/102,555/120

This is an example of RGB 6x6x6 216 colors specification.  Left side
of slash is foreground, and right side is for background color.  This
color list is accessed by index.

=head2 CALLING FUNCTIONS

Besides producing ANSI colored text, this module supports calling
arbitrary function to handle a string.  See L<FUNCTION SPEC> section
for more detail.

=head2 256 or 24bit COLORS

By default, this library produces ANSI 256 color sequence.  That is
eight standard colors, eight high intensity colors, 6x6x6 216 colors,
and grayscales from black to white in 24 steps.  12bit/24bit color is
converted to 6x6x6 216 color, or greyscale when all values are same.

To produce 24bit RGB color sequence, set C<$RGB24> module variable.

=head1 COLOR SPEC

Color specification is a combination of single uppercase character
representing 8 colors, and alternative (usually brighter) colors in
lowercase :

    R  r  Red
    G  g  Green
    B  b  Blue
    C  c  Cyan
    M  m  Magenta
    Y  y  Yellow
    K  k  Black
    W  w  White

or RGB values and 24 grey levels if using ANSI 256 or full color
terminal :

    (255,255,255)      : 24bit decimal RGB colors
    #000000 .. #FFFFFF : 24bit hex RGB colors
    #000    .. #FFF    : 12bit hex RGB 4096 colors
    000 .. 555         : 6x6x6 RGB 216 colors
    L00 .. L25         : Black (L00), 24 grey levels, White (L25)

=over 4

Beginning C<#> can be omitted in 24bit hex RGB notation.  So 6
consecutive digits means 24bit color, and 3 digits means 6x6x6 color.

=back

or color names enclosed by angle bracket :

    <red> <blue> <green> <cyan> <magenta> <yellow>
    <aliceblue> <honeydue> <hotpink> <mooccasin>
    <medium_aqua_marine>

with other special effects :

    N    None
    Z  0 Zero (reset)
    D  1 Double strike (boldface)
    P  2 Pale (dark)
    I  3 Italic
    U  4 Underline
    F  5 Flash (blink: slow)
    Q  6 Quick (blink: rapid)
    S  7 Stand out (reverse video)
    H  8 Hide (conceal)
    X  9 Cross out

    E    Erase Line

    ;    No effect
    /    Toggle foreground/background
    ^    Reset to foreground
    ~    Cancel following effect

=over 4

Symbol for concealing used to be B<V> (Vanish) before.  B<V> can still
be used for backward compatibility, but would be deprecated someday.

=back

At first the color is considered as foreground, and slash (C</>)
switches foreground and background.  If multiple colors are given in
the same spec, all indicators are produced in the order of their
presence.  Consequently, the last one takes effect.

If the character is preceded by tilde (C<~>), it means negation of
following effect; C<~S> reset the effect of C<S>.  There is a
discussion about negation of C<D> (Track Wikipedia link in SEE ALSO),
and Apple_Terminal (v2.10 433) does not reset at least.

If the spec start with plus (C<+>) or minus (C<->) character,
following characters are appended/deleted to/from previous
value. Reset mark (C<^>) is inserted before appended string.

Effect characters are case insensitive, and can be found anywhere and
in any order in color spec string.  Character C<;> does nothing and
can be used just for readability, like C<SD;K/544>.

Samples:

    RGB  6x6x6    12bit      24bit           color name
    ===  =======  =========  =============  ==================
    B    005      #00F       (0,0,255)      <blue>
     /M     /505      /#F0F   /(255,0,255)  /<magenta>
    K/W  000/555  #000/#FFF  000000/FFFFFF  <black>/<white>
    R/G  500/050  #F00/#0F0  FF0000/00FF00  <red>/<green>
    W/w  L03/L20  #333/#ccc  303030/c6c6c6  <dimgrey>/<lightgrey>

Character "E" is an abbreviation for "{EL}", and it clears the line
from cursor to the end of the line.  At this time, background color is
set to the area.  When this code is found in the start sequence, it is
copied to just before ending reset sequence, with preceding sequence
if necessary, to keep the effect even when the text is wrapped to
multiple lines.

Other ANSI CSI sequences are also available in the form of C<{NAME}>,
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

Some other escape sequences are supported in the form of C<{NAME}>.
These sequences do not start with CSI, and take no parameters.

    RIS     Reset to Initial State
    DECSC   DEC Save Cursor
    DECRC   DEC Restore Cursor

=head1 COLOR NAMES

Color names are experimentally supported in this version.  Currently
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
    my $handler = Getopt::EX::Colormap->new(
        HASH => \%colormap,
        LIST => \@colors,
        );
    
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
behavior.

=back

=back


=head1 FUNCTION

=over 4

=item B<colorize>(I<color_spec>, I<text>)

=item B<colorize24>(I<color_spec>, I<text>)

Return colorized version of given text.

B<colorize> produces 256 or 24bit colors depending on the setting,
while B<colorize24> always produces 24bit color sequence for
24bit/12bit color spec.  See L<ENVIRONMENT>.

=item B<ansi_code>(I<color_spec>)

Produces introducer sequence for given spec.  Reset code can be taken
by B<ansi_code("Z")>.

=item B<ansi_pair>(I<color_spec>)

Produces introducer and recover sequences for given spec. Recover
sequence includes I<Erase Line> related control with simple SGR reset
code.

=item B<csi_code>(I<name>, I<params>)

Produce CSI (Control Sequence Introducer) sequence by name with
numeric parameters.  I<name> is one of CUU, CUD, CUF, CUB, CNL, CPL,
CHA, CUP, ED, EL, SU, SD, HVP, SGR, SCP, RCP.

=item B<colortable>([I<width>])

Print visual 256 color matrix table on the screen.  Default I<width>
is 144.  Use like this:

    perl -MGetopt::EX::Colormap=colortable -e colortable

=back

=head2 EXAMPLE

If you want to use this module instead of L<Term::ANSIColor>, this
example code

    use Term::ANSIColor;
    print color 'bold blue';
    print "This text is bold blue.\n";
    print color 'reset';
    print "This text is normal.\n";
    print colored("Yellow on magenta.", 'yellow on_magenta'), "\n";
    print "This text is normal.\n";
    print colored ['yellow on_magenta'], 'Yellow on magenta.', "\n";
    print colored ['red on_bright_yellow'], 'Red on bright yellow.', "\n";
    print colored ['bright_red on_black'], 'Bright red on black.', "\n";
    print "\n";

can be written with L<Getopt::EX::Colormap> like:

    use Getopt::EX::Colormap qw(colorize ansi_code);
    print ansi_code 'DB';
    print "This text is bold blue.\n";
    print ansi_code 'Z';
    print "This text is normal.\n";
    print colorize('Y/M', "Yellow on magenta."), "\n";
    print "This text is normal.\n";
    print colorize('Y/M', 'Yellow on magenta.'), "\n";
    print colorize('R/y', 'Red on bright yellow.'), "\n";
    print colorize('r/K', 'Bright red on black.'), "\n";
    print "\n";


=head1 RESET SEQUENCE

This module produces I<RESET> and I<Erase Line> sequence to recover
from colored text.  This is preferable to clear background color set
by scrolling in the middle of colored text at the bottom line of the
terminal.

However, on some terminal, including Apple_Terminal, I<Erase Line>
sequence clear the text on the cursor position when it is at the
rightmost column of the screen.  In other words, rightmost character
sometimes mysteriously disappear when it is the last character in the
colored region.  If you do not like this behavior, set module variable
C<$NO_RESET_EL> or C<GETOPTEX_NO_RESET_EL> environment.


=head1 ENVIRONMENT

If the environment variable C<NO_COLOR> is set, regardless of its
value, colorizing interface in this module never produce color
sequence.  Primitive function such as C<ansi_code> is not the case.
See L<https://no-color.org/>.

If the module variable C<$NO_NO_COLOR> or C<GETOPTEX_NO_NO_COLOR>
environment is true, C<NO_COLOR> value is ignored.

B<color> method and B<colorize> function produces 256 or 24bit colors
depending on the value of C<$RGB24> module variable.  Also 24bit mode
is enabled when environment C<GETOPTEX_RGB24> is set or C<COLORTERM>
is C<truecolor>.

If the module variable C<$NO_RESET_EL> set, or C<GETOPTEX_NO_RESET_EL>
environment, I<Erace Line> sequence is not produced after RESET code.
See L<RESET SEQUENCE>.


=head1 SEE ALSO

L<Getopt::EX>,
L<Getopt::EX::LabeledParam>

L<https://en.wikipedia.org/wiki/ANSI_escape_code>

L<Graphics::ColorNames::X>

L<https://en.wikipedia.org/wiki/X11_color_names>

L<https://no-color.org/>

=head1 AUTHOR

Kazumasa Utashiro

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2015-2021 Kazumasa Utashiro

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  colormap colorize Cyan RGB cyan Wikipedia CSI ansi
#  LocalWords:  SGR
