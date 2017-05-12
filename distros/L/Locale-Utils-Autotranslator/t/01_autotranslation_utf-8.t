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
    Locale::Utils::Autotranslator
);

my $char = 1;
sub translate_text {
    my ($self, $msgid) = @_;

    return 'text ' . $char++;
}

my $output_filename = './translated de_utf-8.po';
my @debug;
is
    __PACKAGE__
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
        )
        ->translate(
            't/LocaleData/untranslated de_utf-8.po',
            $output_filename,
        )
        ->translation_count,
    11,
    'translation count';

my $content = path($output_filename)->slurp_utf8;
unlink $output_filename;

eq_or_diff
    [ split qr{ \r? \n }xms, $content ],
    [ split qr{ \n }xms, <<"EOT" ],
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

msgid "Number of %1: %2"
msgstr "text 1"

msgid "Number of {post items}: {count :num}"
msgstr "text 2"

msgid "Please write %1 %*(%2,postcard,postcards), %quant(%3,postcard,postcards) or %*(%4,letter,letters,no letter) today."
msgstr "text 8"

# comment2
# comment1
#. automatic2
#. automatic1
#: reference:3 reference:2
#: reference:1
msgid "He is overtaking the seagull named „bear“."
msgstr "text 9"

msgid "Please write {name} {count :num} postcard today."
msgid_plural "Please write {name} {count :num} postcards today."
msgstr[0] "text 10"
msgstr[1] "text 11"

EOT
    'translated file content';

eq_or_diff
    \@debug,
    [
        'en: Number of XXXDBXZ: XXXDCXZ',
        'de: text 1',
        'en: Number of XXPOSTYXITEMSXZ: 1',
        'de: text 2',
        'en: postcard',
        'de: text 3',
        'en: postcards',
        'de: text 4',
        'en: letter',
        'de: text 5',
        'en: letters',
        'de: text 6',
        'en: no letter',
        'de: text 7',
        'en: Please write XXXDBXZ XXXCKXCMXDCXCMPOSTCARDXCMPOSTCARDSXZ, XXQUANTXCMXDDXCMPOSTCARDXCMPOSTCARDSXZ or XXXCKXCMXDEXCMLETTERXCMLETTERSXCMNOYXLETTERXZ today.',
        'de: text 8',
        'en: He is overtaking the seagull named „bear“.',
        'de: text 9',
        'en: Please write XXNAMEXZ 1 postcard today.',
        'de: text 10',
        'en: Please write XXNAMEXZ 0 postcards today.',
        'de: text 11',
    ],
    'debug';
