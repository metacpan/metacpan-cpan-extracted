package Font::Selector;

use strict;
use warnings;

our $VERSION = '0.02';

use Font::Fontconfig;

use List::Util qw/all/;

use Exporter 'import';
our @EXPORT_OK = qw/&grep_from_fontnames/;



# grep_from_fontnames
#
# This works on font-names, the litteral string, not on fontconfig patterns.
#
sub grep_from_fontnames {
    my $class     = shift;
    my $string    = shift;
    my @fontnames = @_;
    
    grep { _test_glyphs_for_fontname( $string, $_ ) } @fontnames
    
}



# _test_glyphs_for_fontname
#
# Hopefully we do the right thing here, further investigation might be needed to
# check against Unicode libraries, where we can have canonical glyphs, combined
# or split.
#
# There are opertunities to optimize the code:
# - cache the font-pattern returned from Font::Fontconfig->list
# - cache the results per fontname/glyph combination
# - cache the results per fontname/string
#
sub _test_glyphs_for_fontname {
    my $string = shift;
    my $fontname = shift;
    
    my ($fc_pattern) = Font::Fontconfig->list( $fontname );
    
    return !undef if
        defined $fc_pattern
    and
        all { $fc_pattern->contains_codepoint( ord $_ ) } split //, $string
    ;

}



1;
