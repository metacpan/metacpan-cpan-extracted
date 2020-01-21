use Test::Most;
use Test::MockModule;
use Test::MockObject;

use List::Util;
use Font::Selector;

subtest 'grep' => sub {
    
    my $mocked_fontconfig = _mock_mod_fontconfig(
        Foo => [ qw/x y z/ ],
        Bar => [ qw/a b c/ ],
        Baz => [ qw/a b c k l m/ ],
    );
    
    cmp_deeply(
        [ Font::Selector->grep_from_fontnames( a => qw/Foo/ ) ],
        [ ],
        "Returns nothing unless glyph is present in named font"
    );
    
    cmp_deeply(
        [ Font::Selector->grep_from_fontnames( a => qw/Bar/ ) ],
        [
            'Bar',
        ],
        "Returns 'Bar' font for 1 character [a], present in named font"
    );
    
    cmp_deeply(
        [ Font::Selector->grep_from_fontnames( bx => qw/Bar/ ) ],
        [ ],
        "Returns nothing unless all glyphs are present in named font"
    );
    
    cmp_deeply(
        [ Font::Selector->grep_from_fontnames( a => qw/Bar Baz/ ) ],
        [
            'Bar', 'Baz',
        ],
        "Returns 'Bar' and 'Baz' font for all glyphs present in named fonts"
    );
    
};



# _mock_fontconfig
#
# turn a hash with 'fontname', 'char-list' pairs into mocked Font::Fontconfig
# objects etc.
#
sub _mock_mod_fontconfig {
    my %fontconfig = @_;
    
    my $fontconfig_patterns = {};
    
    my $mocked_mod = Test::MockModule->new( 'Font::Fontconfig' );
    $mocked_mod->mock( list =>
        sub {
            my $self = shift;
            my $fontname_lookup = shift;
            
            return $fontconfig_patterns->{ $fontname_lookup }
        }
    );
    
    # add fontconfig_patterns
    #
    foreach my $pattern_name ( keys %fontconfig ) {
        
        my $mocked_pattern = _mock_obj_fontconfig_pattern(
            $pattern_name,
            $fontconfig{ $pattern_name },
        );
        
        $fontconfig_patterns->{ $pattern_name } = $mocked_pattern;
    }
    
    
    return $mocked_mod;
}



# _mock_obj_fontconfig_pattern
#
# create a mocked `Font::Fontconfig::Pattern` object
# that has one method: `contains_codepoint`
#
sub _mock_obj_fontconfig_pattern {
    my $pattern_name = shift;
    my $char_list = shift;
    
    my $mocked_obj = Test::MockObject->new;
    
    $mocked_obj->mock( contains_codepoint =>
        sub {
            my $self = shift;
            my $codepoint = shift;
            
            my $exists = List::Util::any { $codepoint == ord($_) } @$char_list;
            
            return $exists
        }
    );
    
    return $mocked_obj

}



done_testing;