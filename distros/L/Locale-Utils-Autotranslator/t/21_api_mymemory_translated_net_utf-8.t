#!perl
#!perl -T

use strict;
use warnings;
use utf8;

use Moo;
use Path::Tiny qw(path);
use Test::More tests => 4;
use Test::NoWarnings;
use Test::Differences;

extends qw(
    Locale::Utils::Autotranslator::ApiMymemoryTranslatedNet
);

my %query_form_of;
{
    package MyResponse;
    use Encode qw(decode_utf8);
    use JSON qw(encode_json);
    sub new {
        return bless {}, __PACKAGE__;
    }
    sub is_success {
        return 1;
    }
    sub _translate {
        my ( undef, $langpair, $utf8_text ) = @_;
        $langpair eq 'en|de'
            or return $utf8_text;
        my $text = decode_utf8($utf8_text);
        my %translation_memory_of = (
            'Number of XXXDBXZ: XXXDCXZ',
            "Anzahl der XXXDBXZ:&#032;XXXDCXZ\0\4", # accept html and mo file critical control chars
            'Number of XXPOSTYXITEMSXZ: 1',
            'Anzahl XXPOSTYXITEMSXZ: 1',
            'postcard',
            'Postkarte',
            'postcards',
            'Postkarten',
            'letter',
            'Brief',
            'letters',
            'Briefe',
            'no letter',
            'kein Brief',
            'Please write XXXDBXZ XXXCKXCMXDCXCMPOSTCARDXCMPOSTCARDSXZ, XXQUANTXCMXDDXCMPOSTCARDXCMPOSTCARDSXZ or XXXCKXCMXDEXCMLETTERXCMLETTERSXCMNOYXLETTERXZ today.',
            'Bitte schreiben Sie XXXDBXZ XXXCKXCMXDCXCMPOSTCARDXCMPOSTCARDSXZ, XXQUANTXCMXDDXCMPOSTCARDXCMPOSTCARDSXZ oder XXXCKXCMXDEXCMLETTERXCMLETTERSXCMNOYXLETTERXZ heute.',
            'He is overtaking the seagull named „bear“.',
            'Er überholt die Möwe mit dem Namen "Bär".',
            'Please write XXNAMEXZ 1 postcard today.',
            'Bitte schreiben Sie XXNAMEXZ 1 Postkarte heute.',
            'Please write XXNAMEXZ 0 postcards today.',
            'Bitte schreiben Sie XXNAMEXZ 0 Postkarten heute.',
        );
        if ( ! exists $translation_memory_of{$text} ) {
            warn "No translation for: $text\n";
            return $text;
        }
        return $translation_memory_of{$text};
    }
    sub decoded_content {
        my $self = shift;
        my $translated_text = $self->_translate( @query_form_of{ qw( langpair q ) } );
        return encode_json({
            responseStatus  => 200,
            responseDetails => 'ok',
            responseData    => {
                translatedText => $translated_text,
            },
        });
    }
}
{
    package MyUserAgent;
    use Test::More;
    sub new { return bless {}, __PACKAGE__ }
    sub request {
        my ( undef, $request ) = @_;
        %query_form_of = $request->uri->query_form;
        return MyResponse->new;
    }
}

my $output_filename = './translated de_utf-8.po';
my @debug;
my $obj = Locale::Utils::Autotranslator::ApiMymemoryTranslatedNet
    ->new(
        language                => 'de',
        before_translation_code => sub {
            my ($self, $msgid) = @_;
            push @debug, sprintf '%s: %s', $self->developer_language, $msgid;
            1;
        },
        after_translation_code  => sub {
            my ($self, undef, $msgstr) = @_;
            push @debug, sprintf '%s: %s', $self->language, $msgstr;
            1;
        },
        user_agent              => MyUserAgent->new,
    )
    ->translate(
        't/LocaleData/untranslated de_utf-8.po',
        $output_filename,
    );
is
    $obj->error,
    undef,
    'no error'
    or exit;
is
    $obj->translation_count,
    11,
    'translation count';

my $content = path($output_filename)->slurp_utf8;
unlink $output_filename;

eq_or_diff
    [ split m{ \r? \n }xms, $content ],
    [ split m{ \n }xms, <<"EOT" ],
msgid ""
msgstr ""
"Project-Id-Version: \\n"
"POT-Creation-Date: \\n"
"PO-Revision-Date: \\n"
"Last-Translator: \\n"
"Language-Team: \\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=2; plural=n != 1;\\n"

# translated by: api.mymemory.translated.net
msgid "Number of %1: %2"
msgstr "Anzahl der %1: %2"

# translated by: api.mymemory.translated.net
msgid "Number of {post items}: {count :num}"
msgstr "Anzahl {post items}: {count :num}"

# translated by: api.mymemory.translated.net
msgid "Please write %1 %*(%2,postcard,postcards), %quant(%3,postcard,postcards) or %*(%4,letter,letters,no letter) today."
msgstr "Bitte schreiben Sie %1 %*(%2,Postkarte,Postkarten), %quant(%3,Postkarte,Postkarten) oder %*(%4,Brief,Briefe,kein Brief) heute."

# translated by: api.mymemory.translated.net
# comment2
# comment1
#. automatic2
#. automatic1
#: reference:3 reference:2
#: reference:1
msgid "He is overtaking the seagull named „bear“."
msgstr "Er überholt die Möwe mit dem Namen \\"Bär\\"."

# translated by: api.mymemory.translated.net
msgid "Please write {name} {count :num} postcard today."
msgid_plural "Please write {name} {count :num} postcards today."
msgstr[0] "Bitte schreiben Sie {name} {count :num} Postkarte heute."
msgstr[1] "Bitte schreiben Sie {name} {count :num} Postkarten heute."

EOT
    'translated file content';

__END__
eq_or_diff
    \@debug,
    [
        'en: Number of XXXDBXZ: XXXDCXZ',
        'de: Anzahl der XXXDBXZ: XXXDCXZ',
        'en: Number of XXPOSTYXITEMSXZ: 1',
        'de: Anzahl XXPOSTYXITEMSXZ: 1',
        'en: postcard',
        'de: Postkarte',
        'en: postcards',
        'de: Postkarten',
        'en: Please write XXXDBXZ XXXCKXDCXZ today.',
        'de: Bitte schreiben Sie XXXDBXZ XXXCKXDCXZ heute.',
        'en: He is overtaking the seagull named „bear“.',
        'de: Er ist Überholen der Möwe mit dem Namen "Bär".',
        'en: Please write XXNAMEXZ 1 postcard today.',
        'de: Bitte schreiben Sie XXNAMEXZ 1 Postkarte heute.',
        'en: Please write XXNAMEXZ 2 postcards today.',
        'de: Bitte schreiben Sie XXNAMEXZ 2 postkarten heute.',
    ],
    'debug';
