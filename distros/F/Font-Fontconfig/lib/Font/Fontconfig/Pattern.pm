package Font::Fontconfig::Pattern;

use strict;
use warnings;

use Carp;

our @_internal_attributes = qw/
    charset
    family
    familylang
    file
    fontformat
    foundry
    fullname
    fullnamelang
    postscriptname
    style
    stylelang
    weight
    width
/;



# new_from_string
#
# The (only) constructor to create a new object. It takes a string returned by
# `fc-list`
#
sub new_from_string {
    my $class = shift;
    my $string = shift
        // croak "'new_from_string' requires a string";
    
    my $struct = _parse_fc_line( $string );
    
    bless $struct, $class
}



# contains_codepoint
#
#   my $bool = $font_pattern->contains_codepoint( $ordinal )
#
# Returns 'true' if a font, described by the C<$font_pattern> contains the given
# codepoint.
#
sub contains_codepoint {
    my $self = shift;
    my $codepoint = shift
        // croak "'contains_codepoint' requires a codepoint (int)";
    
    my $codepoints = _parse_charset( $self->{charset} );
    
    return !!$codepoints->[ $codepoint ];
}


# _parse_fc_line( $return_string )
#
# takes a string from `fc-list` and decomposes it into a HashRef
#
# strings look like:
# /path/to/font_file.ext: Family Name:key_1=value_1:key_2=value2 ..
#
sub _parse_fc_line {
    my $string = shift // return;
    
    my $struct = {};
    
    if ($string =~ /^(?<file>.*): /) {
        $struct->{file} = $+{file};
        $string =~ s/^$+{file}: //;
    }
    
    if ($string =~ /^(?<family>[^:]+)/) {
        $struct->{family} = $+{family};
        $string =~ s/^$+{family}//;
    }
    
    if ($string =~ /^:/) {
        $string =~ s/^://;
        foreach my $element ( split q{:}, $string ) {
            my ($key, $value) = split q{=}, $element;
            $struct->{$key} = $value;
        }
    }
    
    return $struct;
}



# _parse_charset( $$charset )
#
# turns a charset string into an array of `1` for existing codepoints
#
# strins look like:
# 14c-17e 192 1a0-1a1
#
sub _parse_charset {
    my $charset = shift // return;
    
    my @codepoints=();
    my @chunks = split ' ', $charset;
    for my $chunk (@chunks) {
        if ($chunk =~ /-/) {
            my @range_ends = split '-', $chunk;
            my $start = hex $range_ends[0];
            my $finish = hex $range_ends[1];
            for my $codepoint ($start .. $finish) {
                $codepoints[ $codepoint ] = 1;
            }
        }
        else {
            $codepoints[ hex $chunk ] = 1;
        }
    }
    
    return \@codepoints;
}
#
# thanks to Harry Wozniak!



# copyrighted: 2019 Perceptyx Inc, Th. J. van Hoesel

1;
