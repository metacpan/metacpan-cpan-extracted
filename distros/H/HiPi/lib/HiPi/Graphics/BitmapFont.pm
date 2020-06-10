#########################################################################################
# Package        HiPi::Graphics::BitmapFont
# Description  : Monochrome OLED Font
# Copyright    : Copyright (c) 2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Graphics::BitmapFont;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use UNIVERSAL::require;
use Carp;

__PACKAGE__->create_ro_accessors( qw( name char_height space_width gap_width
                                      symbols kerning class cols rows bytes
                                      line_spacing) );

our $VERSION ='0.81';

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
    MonoExtended38  => undef,
    
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
    SansExtended38  => undef,
    
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
    SerifExtended37  => undef,
    
    SansEPD15  => undef,
    SansEPD19  => undef,
    SansEPD23  => undef,
    SansEPD28  => undef,
    SansEPD31  => undef,
    SansEPD38  => undef,
    SansEPD50  => undef,
    SansEPD76  => undef,
    SansEPD102 => undef,
    
    MonoEPD15  => undef,
    MonoEPD19  => undef,
    MonoEPD23  => undef,
    MonoEPD28  => undef,
    MonoEPD31  => undef,
    MonoEPD38  => undef,
    MonoEPD50  => undef,
    MonoEPD76  => undef,
    MonoEPD102 => undef,
    
    SerifEPD16  => undef,
    SerifEPD20  => undef,
    SerifEPD22  => undef,
    SerifEPD27  => undef,
    SerifEPD33  => undef,
    SerifEPD37  => undef,
    SerifEPD50  => undef,
    SerifEPD76  => undef,
    SerifEPD103 => undef,
    
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
    SerifExtended38  => 'SerifExtended37',
    SerifEPD15  => 'SerifEPD16',
    SerifEPD19  => 'SerifEPD20',
    SerifEPD23  => 'SerifEPD22',
    SerifEPD28  => 'SerifEPD27',
    SerifEPD31  => 'SerifEPD33',
    SerifEPD38  => 'SerifEPD37',
    SerifEPD102  => 'SerifEPD103',
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
    my $fontclass = 'HiPi::Graphics::BitmapFont::' . $fontname;
    $fontclass->use;
    $fonts->{$fontname} = $fontclass->new();
    return $fonts->{$fontname};
}

1;

__END__