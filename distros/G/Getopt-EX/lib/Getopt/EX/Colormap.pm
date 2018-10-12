package Getopt::EX::Colormap;

use strict;
use warnings;
use Graphics::ColorNames;

use Exporter 'import';
our @EXPORT      = qw();
our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw(colorize ansi_code csi_code);
our @ISA         = qw(Getopt::EX::LabeledParam);

use Carp;
use Scalar::Util qw(blessed);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Getopt::EX::LabeledParam;

our $COLOR_RGB24 = 0;

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
	    $r = int ( 5 * $rx / 255 );
	    $g = int ( 5 * $gx / 255 );
	    $b = int ( 5 * $bx / 255 );
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
    E => 'EL',		# E : Erace Line
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

tie my %color_table, 'Graphics::ColorNames', qw(WWW);

sub rgb24 {
    my $rgb = shift;
    if ($COLOR_RGB24) {
	return (2,
		map { hex $_ }
		$rgb =~ /^\#?([\da-f]{2})([\da-f]{2})([\da-f]{2})/i);
    } else {
	return (5, ansi256_number $rgb);
    }
}

sub rgb12 {
    my $rgb = shift;
    if ($COLOR_RGB24) {
	return (2,
		map { 0x11 * hex }
		$rgb =~ /^#([\da-f])([\da-f])([\da-f])/i);
    } else {
	return (5, ansi256_number $rgb);
    }
}

package xg {
    sub new    { bless do { my $offset = 0; \$offset }, shift }
    sub toggle { ${+shift} ^= 10 }
    sub offset { ${+shift} }
}

sub ansi_numbers {
    local $_ = shift // '';
    my @numbers;
    my $xg = new xg;

    while (m{\G
	     (?:
	       (?<slash> /)				# /
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
	if ($+{slash}) {
	    $xg->toggle;
	}
	elsif ($+{h24}) {
	    push @numbers, 38 + $xg->offset, rgb24($+{h24});
	}
	elsif ($+{h12}) {
	    push @numbers, 38 + $xg->offset, rgb12($+{h12});
	}
	elsif (my $rgb = $+{rgb}) {
	    my @rgb = $rgb =~ /(\d+)/g;
	    die "Unexpected value: $rgb\n" if grep { $_ > 255 } @rgb;
	    my $hex = sprintf "%02X%02X%02X", @rgb;
	    push @numbers, 38 + $xg->offset, rgb24($hex);
	}
	elsif ($+{c256}) {
	    push @numbers, 38 + $xg->offset, 5, ansi256_number $+{c256};
	}
	elsif ($+{c16}) {
	    push @numbers, $numbers{$+{c16}} + $xg->offset;
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
	    if (my $rgb = $color_table{$+{name}}) {
		push @numbers, 38 + $xg->offset, rgb24($rgb);
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
    ED  => 'J',    # Erase in Display
    EL  => 'K',    # Erase in Line
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
	    RESET . EL;
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
    if (blessed $color and $color->can('call')) {
	return $color->call for $text;
    }
    else {
	$cache->{$color} //= [ ansi_pair($color) ];
	my($s, $e) = @{$cache->{$color}};
	$text =~ s/(^|$reset_re)([^\e\r\n]*)/${1}${s}${2}${e}/mg;
	return $text;
    }
}

sub new {
    my $class = shift;
    my $obj = SUPER::new $class;

    $obj->{CACHE} = {};
    configure $obj @_ if @_;

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
specified with C<*> and C<?> wild characters.

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

At first the color is considered as foreground, and slash (C</>)
switches foreground and background.  If multiple colors are given in
the same spec, all indicators are produced in the order of their
presence.  Consequently, the last one takes effect.

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
C<$COLOR_RGB24> module variable to enable it.

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
names are listed in L<Graphics::ColorNames::WWW> module.  Following
colors are available.

=over 4

aliceblue antiquewhite aqua aquamarine azure beige bisque black
blanchedalmond blue blueviolet brown burlywood cadetblue chartreuse
chocolate coral cornflowerblue cornsilk crimson cyan darkblue darkcyan
darkgoldenrod darkgray darkgreen darkgrey darkkhaki darkmagenta
darkolivegreen darkorange darkorchid darkred darksalmon darkseagreen
darkslateblue darkslategray darkslategrey darkturquoise darkviolet
deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite
forestgreen fuchsia fuscia gainsboro ghostwhite gold goldenrod gray
grey green greenyellow honeydew hotpink indianred indigo ivory khaki
lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral
lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey
lightpink lightsalmon lightseagreen lightskyblue lightslategray
lightslategrey lightsteelblue lightyellow lime limegreen linen magenta
maroon mediumaquamarine mediumblue mediumorchid mediumpurple
mediumseagreen mediumslateblue mediumspringgreen mediumturquoise
mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite
navy oldlace olive olivedrab orange orangered orchid palegoldenrod
palegreen paleturquoise palevioletred papayawhip peachpuff peru pink
plum powderblue purple red rosybrown royalblue saddlebrown salmon
sandybrown seagreen seashell sienna silver skyblue slateblue slategray
slategrey snow springgreen steelblue tan teal thistle tomato turquoise
violet wheat white whitesmoke yellow yellowgreen

=back

Enclose them by angle bracket to use, like:

    <deeppink>/<lightyellow>

Although these colors are defined in 24bit value, they are mapped to
6x6x6 216 colors by default.  Set C<$COLOR_RGB24> module variable to
use 24bit color mode.

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


=head1 METHODS

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

=back


=head1 SEE ALSO

L<Getopt::EX>,
L<Getopt::EX::LabeledParam>

L<https://en.wikipedia.org/wiki/ANSI_escape_code>
