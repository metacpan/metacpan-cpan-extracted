#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use utf8;
use Path::Tiny qw(path);

# inlined translator package
{
    package MyTranslator;

    use strict;
    use warnings;
    use Carp qw(cluck);
    use Moo;
    use Path::Tiny qw(path);

    our $VERSION = 0;

    extends qw(
        Locale::Utils::Autotranslator
    );

    my %translation_memory_of = (
        'en|de' => {
            'Number of XXXDBXZ: XXXDCXZ',
            'Anzahl von XXXDBXZ: XXXDCXZ',
            'Number of XXPOSTYXITEMSXZ: 1',
            'Anzahl von XXPOSTYXITEMSXZ: 1',
            'postcard',
            'Postkarte',
            'postcards',
            'Postkarten',
            'Please write XXXDBXZ XXXCKXCMXDCXCMPOSTCARDXCMPOSTCARDSXZ today.',
            'Bitte schreiben Sie XXXDBXZ heute XXXCKXCMXDCXCMPOSTCARDXCMPOSTCARDSXZ.',
            'He is overtaking the seagull named „bear“.',
            'Er überholt eine Möwe mit dem Name „Bär“.',
            'Please write XXNAMEXZ 1 postcard today.',
            'Bitte schreiben Sie XXNAMEXZ heute 1 Postkarte.',
            'Please write XXNAMEXZ 0 postcards today.',
            'Bitte schreiben Sie XXNAMEXZ heute 0 Postkarten.',
        },
    );

    sub translate_text {
        my ( $self, $text ) = @_;

        $self->comment('translated by: MyTranslator');
        my $language_pair = join q{|}, $self->developer_language, $self->language;
        if ( ! exists $translation_memory_of{$language_pair}->{$text} ) {
            cluck qq{No translation found for $language_pair and "$text"};
            return q{};
        };

        return $translation_memory_of{$language_pair}->{$text};
    }

    1;
}

binmode *STDOUT, ':encoding(UTF-8)';
my $output_filename = './LocaleData/translated de_utf-8.po';
my $obj = MyTranslator
    ->new(
        language                => 'de',
        before_translation_code => sub {
            my ($self, $msgid) = @_;
            () = printf "%s: %s\n", $self->developer_language, $msgid;
            1; # true, do not skip translation
        },
        after_translation_code  => sub {
            my ($self, $msgid, $msgstr) = @_;
            () = printf "%s: %s\n", $self->language, $msgstr;
            1; # true, do not skip translation
        },
    )
    ->translate(
        './LocaleData/untranslated de_utf-8.po',
        $output_filename,
    );

print "\nError: ", $obj->error || 'no error', "\n";

my $content = path($output_filename)->slurp_utf8;
unlink $output_filename;
$content =~ s{ \r? \n }{\n}xmsg;
() = print "\n", $content;

# $Id: 01_my_translator_utf-8.pl 614 2015-08-17 10:28:48Z steffenw $

__END__

Output:

en: Number of XXXDBXZ: XXXDCXZ
de: Anzahl von XXXDBXZ: XXXDCXZ
en: Number of XXPOSTYXITEMSXZ: 1
de: Anzahl von XXPOSTYXITEMSXZ: 1
en: postcard
de: Postkarte
en: postcards
de: Postkarten
en: Please write XXXDBXZ XXXCKXCMXDCXCMPOSTCARDXCMPOSTCARDSXZ today.
de: Bitte schreiben Sie XXXDBXZ heute XXXCKXCMXDCXCMPOSTCARDXCMPOSTCARDSXZ.
en: He is overtaking the seagull named „bear“.
de: Er überholt eine Möwe mit dem Name „Bär“.
en: Please write XXNAMEXZ 1 postcard today.
de: Bitte schreiben Sie XXNAMEXZ heute 1 Postkarte.
en: Please write XXNAMEXZ 0 postcards today.
de: Bitte schreiben Sie XXNAMEXZ heute 0 Postkarten.

Error: no error

msgid ""
msgstr ""
"Project-Id-Version: \n"
"POT-Creation-Date: \n"
"PO-Revision-Date: \n"
"Last-Translator: \n"
"Language-Team: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=n != 1;\n"

# translated by: MyTranslator
msgid "Number of %1: %2"
msgstr "Anzahl von %1: %2"

# translated by: MyTranslator
msgid "Number of {post items}: {count :num}"
msgstr "Anzahl von {post items}: {count :num}"

# translated by: MyTranslator
msgid "Please write %1 %*(%2,postcard,postcards) today."
msgstr "Bitte schreiben Sie %1 heute %*(%2,Postkarte,Postkarten)."

# translated by: MyTranslator
# comment2
# comment1
#. automatic2
#. automatic1
#: reference:3 reference:2
#: reference:1
msgid "He is overtaking the seagull named „bear“."
msgstr "Er überholt eine Möwe mit dem Name „Bär“."

# translated by: MyTranslator
msgid "Please write {name} {count :num} postcard today."
msgid_plural "Please write {name} {count :num} postcards today."
msgstr[0] "Bitte schreiben Sie {name} heute {count :num} Postkarte."
msgstr[1] "Bitte schreiben Sie {name} heute {count :num} Postkarten."
