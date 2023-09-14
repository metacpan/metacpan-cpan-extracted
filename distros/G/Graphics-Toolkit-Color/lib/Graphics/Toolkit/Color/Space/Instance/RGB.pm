use v5.12;
use warnings;

# RGB color space specific code

package Graphics::Toolkit::Color::Space::Instance::RGB;
use Graphics::Toolkit::Color::Space;
use Graphics::Toolkit::Color::Space::Util ':all';
use Carp;

my $rgb_def = Graphics::Toolkit::Color::Space->new( axis => [qw/red green blue/], range => 255 );
   $rgb_def->add_formatter(   'hex',   \&hex_from_rgb );
   $rgb_def->add_deformatter( 'hex',   sub { rgb_from_hex(@_) if is_hex(@_) } );
   $rgb_def->add_deformatter( 'array', sub { @{$_[0]} if $rgb_def->is_array($_[0]) and $_[0][0] =~ /\d/} );


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
