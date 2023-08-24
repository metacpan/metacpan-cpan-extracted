use v5.12;
use warnings;

# check, convert and measure color values in RGB space

package Graphics::Toolkit::Color::Value::RGB;
use Carp;
use Graphics::Toolkit::Color::Util ':all';
use Graphics::Toolkit::Color::Space;

my $rgb_def = Graphics::Toolkit::Color::Space->new(qw/red green blue/);
   $rgb_def->add_formatter(   'hex',   \&hex_from_rgb );
   $rgb_def->add_deformatter( 'hex',   sub { rgb_from_hex(@_) if is_hex(@_) } );
   $rgb_def->add_deformatter( 'array', sub { @{$_[0]} if $rgb_def->is_array($_[0]) and $_[0][0] =~ /\d/} );
   $rgb_def->change_trim_routine( \&trim );

########################################################################

sub check { # carp returns 1
    my (@rgb) = @_;
    my $range_help = 'has to be an integer between 0 and 255';
    return carp "need exactly 3 positive integer values 0 <= n < 256 for rgb input" unless $rgb_def->is_array( \@rgb );
    return carp "red value $rgb[0] ".$range_help   unless int $rgb[0] == $rgb[0] and $rgb[0] >= 0 and $rgb[0] < 256;
    return carp "green value $rgb[1] ".$range_help unless int $rgb[1] == $rgb[1] and $rgb[1] >= 0 and $rgb[1] < 256;
    return carp "blue value $rgb[2] ".$range_help  unless int $rgb[2] == $rgb[2] and $rgb[2] >= 0 and $rgb[2] < 256;
    0;
}

sub trim { # cut values into the domain of definition of 0 .. 255
    map { round($_) } map {$_ < 0 ? 0 : $_} map {$_ > 255 ? 255 : $_}  @_;
}

sub hex_from_rgb {  return unless @_ == $rgb_def->dimensions;  sprintf "#%02x%02x%02x", @_ }

sub rgb_from_hex { # translate #000000 and #000 --> r, g, b
    my $hex = shift;
    return carp "hex color definition '$hex' has to start with # followed by 3 or 6 hex characters (0-9,a-f)"
    unless defined $hex and (length($hex) == 4 or length($hex) == 7) and $hex =~ /^#[\da-f]+$/i;
    $hex = substr $hex, 1;
    (length $hex == 3) ? (map { CORE::hex($_.$_) } unpack( "a1 a1 a1", $hex))
                       : (map { CORE::hex($_   ) } unpack( "a2 a2 a2", $hex));
}

sub is_hex { defined $_[0] and ($_[0] =~ /^#[[:xdigit:]]{3}$/ or $_[0] =~ /^#[[:xdigit:]]{6}$/)}


$rgb_def;
