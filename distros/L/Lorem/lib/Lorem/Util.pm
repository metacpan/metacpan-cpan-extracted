package Lorem::Util;
{
  $Lorem::Util::VERSION = '0.22';
}
use strict;
use warnings;
use Carp 'confess';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( color2rgb in2pt pt2in escape_ampersand percent_of escape_entities escape_entity);

use FindBin qw($Bin);

use Convert::Color::X11;
push @Convert::Color::X11::RGB_TXT, 'share/X11/rgb.txt';


sub color2rgb {
    my ( $in ) = @_;
    my $color = Convert::Color::X11->new( $in );
    no warnings;
    $color->as_rgb16->rgb16;
}

sub in2pt {
    my $inches = shift;
    $inches * 72;
}

sub pt2in {
    my $points = shift;
    $points / 72;
}

sub percent_of {
    my ($percent, $of) = @_;
    $percent =~ s/%//;
    
    confess 'invalid args' if ! defined $percent || ! defined $of;
    
    return ($percent / 100) * $of;
}

sub escape_ampersand {
    my $string = shift;
    confess 'usage is escape_ampersand( $string )' if ! defined $string;
    $string =~ s/&/&amp;/g;
    return $string;
}

sub escape_entity {
    my $string = shift;
    
    warn 'Lore::Util::escape_entity is deprecated, use Lorem::Util::escape_entities instead';
    
    confess 'usage is escape_ampersand( $string )' if ! defined $string;
    $string =~ s/&/&amp;/g;
    return $string;
}

sub escape_entities {
    my $string = shift;
    confess 'usage is escape_ampersand( $string )' if ! defined $string;
    $string =~ s/&/&amp;/g;
    return $string;
}

1;
