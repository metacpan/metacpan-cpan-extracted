#########################################################################################
# Package        HiPi::Interface::MonoOLED::Font
# Description  : Monochrome OLED Font
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::MonoOLED::Font;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use UNIVERSAL::require;
use Carp;

__PACKAGE__->create_ro_accessors( qw( name char_height space_width gap_width
                                      symbols kerning class cols rows bytes
                                      line_spacing) );

our $VERSION ='0.70';

use constant {
    MONO_OLED_DEFAULT_FONT => 'Mono10',
};
                                      
my $fonts = {
    
    Mono10        => undef,
    Mono12        => undef,
    Mono14        => undef,
    Mono15        => undef,
    Mono19        => undef,
    Mono20        => undef,
    Mono26        => undef,
    Mono33        => undef,
    
    MonoExtended11  => undef,
    MonoExtended13  => undef,
    MonoExtended15  => undef,
    MonoExtended17  => undef,
    MonoExtended21  => undef,
    MonoExtended23  => undef,
    MonoExtended30  => undef,
    
    Sans10         => undef,
    Sans12        => undef,
    Sans14        => undef,
    Sans15        => undef,
    Sans19        => undef,
    Sans20        => undef,
    Sans26        => undef,
    Sans33        => undef,
    
    SansExtended11  => undef,
    SansExtended13  => undef,
    SansExtended15  => undef,
    SansExtended17  => undef,
    SansExtended21  => undef,
    SansExtended23  => undef,
    SansExtended30  => undef,
    
    Serif9        => undef,
    Serif11       => undef,
    Serif14       => undef,
    Serif15       => undef,
    Serif17       => undef,
    Serif21       => undef,
    Serif26       => undef,
    Serif33       => undef,
    
    SerifExtended9  => undef,
    SerifExtended12  => undef,
    SerifExtended16  => undef,
    SerifExtended17  => undef,
    SerifExtended20  => undef,
    SerifExtended24  => undef,
    SerifExtended29  => undef,
};

my $fontaliases = {
    Serif10       => 'Serif9',
    Serif12       => 'Serif11',
    Serif19       => 'Serif17',
    SerifExtended11  => 'SerifExtended9',
    SerifExtended13  => 'SerifExtended12',
    SerifExtended15  => 'SerifExtended16',
    SerifExtended21  => 'SerifExtended20',
    SerifExtended23  => 'SerifExtended24',
    SerifExtended30  => 'SerifExtended29',
};
                                      
sub new {
    my($class, %params ) = @_;
    $params{class} //= 'hipi_2';
    my $self = $class->SUPER::new(%params);
}

sub get_font {
    my($ref, $fontname) = @_;
    $fontname ||= MONO_OLED_DEFAULT_FONT;
    if( $fontaliases->{$fontname} ) {
        $fontname = $fontaliases->{$fontname};
    }
    unless(exists($fonts->{$fontname})) {
        my $default = MONO_OLED_DEFAULT_FONT;
        carp(qq('$fontname' is not a valid fontname. Substituted $default font));
        $fontname = $default;
    }
    
    return $fonts->{$fontname} if $fonts->{$fontname};
    my $fontclass = 'HiPi::Interface::MonoOLED::Font::' . $fontname;
    $fontclass->use;
    $fonts->{$fontname} = $fontclass->new();
    return $fonts->{$fontname};
}

1;

__END__