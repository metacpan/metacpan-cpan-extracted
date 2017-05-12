package Locale::Maketext::Utils::Phrase::Core;

###############################################################
# UNTESTED, INCOMPLETE, BRAINDUMP, SCRATCH PAD–DO NOT USE YET #
# Completely subject to go away, don't base anything on this! #
###############################################################

use Module::Want ();

our %Lexicon = (
    '[quant,_1,%s byte,%s bytes]' => '',    # The space between the '%s' and the 'b' is a non-break-space (e.g. option-spacebar, not spacebar). See POD for more info.
);

sub get_core_lex {
    my ( $lh, $loc ) = @_;

    my $my_lexicon;

    for my $core_phrase ( keys %Locale::Maketext::Utils::Phrase::Core::Lexicon ) {
        $my_lexicon->{$core_phrase} = $lh->get_asset(
            sub {
                my $ns = "Locale::Maketext::Utils::Phrase::Core::$_[0]";
                if ( Module::Want::have_mod($ns) ) {
                    no strict 'refs';
                    if ( exists ${ $ns . '::Lexicon' }{$core_phrase} ) {
                        my $val = ${ $ns . '::Lexicon' }{$core_phrase};
                        return $val if defined $val && $val ne '';
                    }
                }
                return;
            },
            $loc
        );

        $my_lexicon->{$core_phrase} ||= $Locale::Maketext::Utils::Phrase::Core::Lexicon{$core_phrase};
    }

    return $my_lexicon;
}

1;

# =PURPOSE
#
# To provide a place to keep “Core phrases”, namely, phrases used internally.
#
# This should be a very short list and not contain much an end user could use directly.
#
# = USAGE
#
# =head2 Locale::Maketext::Utils::Phrase::Core::get_core_lex($lh)
#
# =head2 Locale::Maketext::Utils::Phrase::Core::get_core_lex($lh, $specific_locale_tag)
#
# = TRANSLATIONS
#
# = LEXICON
#
# =over 4
#
# =item '[quant,_1,%s byte,%s bytes]'
#
# The space between the '%s' and the 'b' is a non-break-space (e.g. option-spacebar, not spacebar).
#
# We do not use a variable or "\xC2\xA0" since:
#    * parsers would need to know how to interpolate them in order to work with the phrase in the context of the system
#    * the non-breaking-space character behaves as you'd expect it’s various representations to
#
# =back
