
# sRGB color space IEC 61966-2-1 has two special formats

package Graphics::Toolkit::Color::Space::Instance::RGB;
use v5.12;
use warnings;
use Graphics::Toolkit::Color::Space;

sub hex_from_tuple { uc sprintf("#%02x%02x%02x", @{$_[1]} ) } # translate [ r, g, b ]     --> #000000
sub tuple_from_hex {                                          # translate #000000 or #000 --> [ r, g, b ]
    my ($self, $hex) = @_;
    return "hex color definition '$hex' has to start with # followed by 3 or 6 hex characters (0-9,a-f)"
        unless defined $hex and not ref $hex
           and (length($hex) == 4 or length($hex) == 7)
           and substr($hex, 0, 1) eq '#' and $hex =~ /^#[\da-f]+$/i; # ($_[0] =~ /^#[[:xdigit:]]{3}$/ or $_[0] =~ /^#[[:xdigit:]]{6}$/)
    $hex = substr $hex, 1;
    [(length $hex == 3) ? (map { hex($_.$_) } unpack( "a1 a1 a1", $hex))
                        : (map { hex($_   ) } unpack( "a2 a2 a2", $hex))];
}

Graphics::Toolkit::Color::Space->new (
         axis => [qw/red green blue/],
        range => 255,
    precision => 0,
       format => { 'hex_string' => [\&hex_from_tuple, \&tuple_from_hex],
                        'array' => [ sub { $_[1] }, sub { $_[1] } ] },
);
