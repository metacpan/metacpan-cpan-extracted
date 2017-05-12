package MyAutotranslatorCache; ## no critic (TidyCode)

use strict;
use warnings;
use Moo;
use Carp qw(confess);
use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;
use Try::Tiny;

use MyDummyAutotranslator;

our $VERSION = 0;

with 'MooX::Singleton';

sub fetch_from_lexicon {
    my ( $self, $lexicon_key, $message_key ) = @_;

    my $key_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;
    my $lexicon_key_ref = $key_util->split_lexicon_key($lexicon_key);
    # $lexicon_key_ref e.g. { category => 'cache_en', domain => q{}, language => 'de' }
    my $message_key_ref = $key_util->split_message_key($message_key);
    # $message_key_ref e.g. { msgid => 'not in po file' }

    my ( $data_language ) = $lexicon_key_ref->{category} =~ m{ \A cache_ ( en ) \z }xms
        or confess 'Unexpected category ', $lexicon_key_ref->{category};
    my $auto_translator = MyDummyAutotranslator->new(
        language           => $lexicon_key_ref->{language},
        developer_language => $data_language,
    );

    # dummy sub to check how often the translator api is called and if call possible
    my $is_allowed_to_autotranslate = sub {
        # check update timestamp
        return 1;
    };
    # dummy sub to fake a translation call
    my $database_table_search = sub {
        my ( $lex_key, $_msg_key ) = @_;
        my $result;
        return $result;
    };
    # dummy sub to update the database
    my $database_table_create_or_update = sub {
        my ( $lex_key, $msg_key ) = @_;
        my $result;
        return $result;
    };

    my $database_result = $database_table_search->($lexicon_key, $message_key);
    my $msgstr;
    if ( $database_result ) {
        $msgstr = $database_result->{message_value};
    }
    elsif ( ! $is_allowed_to_autotranslate->() ) {
        ;
    }
    else {
        my $translation
            = try {
                $auto_translator->translate_text( $message_key_ref->{msgid} );
            }
            catch {
                # auto set update timestamp
                $database_table_create_or_update->($lexicon_key, $message_key);
                () = print "LOG: $_\n";
                undef;
            };
        if ( length $translation ) {
            $translation =~ tr{\0\4}{};
            # also auto set update timestamp
            $database_table_create_or_update->($lexicon_key, $message_key, $translation );
            $msgstr = $translation;
        }
    }

    return {
        msgstr => $msgstr,
    };
}

__PACKAGE__->meta->make_immutable;

1;
