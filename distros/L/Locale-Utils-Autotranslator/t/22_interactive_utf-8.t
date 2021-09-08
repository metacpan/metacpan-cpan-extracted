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
    Locale::Utils::Autotranslator::Interactive
);

my $output_filename = './translated interactive de_utf-8.po';
local *STDIN;
my @files = (
    't/LocaleData/STDIN.interactive.txt',
    't/LocaleData/STDIN.interactive_end.txt',
);
{
    local $_ = shift @files;
    open STDIN, '<', $_
        or die "Can't open '$_': $!";
}

my $obj = Locale::Utils::Autotranslator::Interactive
    ->new(
        language                => 'de',
        after_translation_code  => sub {
        my ( $self, $msgid, $msgstr ) = @_;
            local $_ = shift @files;
            open STDIN, '<', $_
                or die "Can't open '$_': $!";
            return 1;
        },
    )
    ->translate(
        't/LocaleData/untranslated de_utf-8.po',
        $output_filename,
    );
is
    do {
        local $_ = $obj->error;
        s{\r? \n}{}xms;
        $_;
    },
    "API error: __END__",
    'end error'
    or exit;
is
    $obj->translation_count,
    1,
    'translation count';

my $content = path($output_filename)->slurp_utf8;
unlink $output_filename;

eq_or_diff
    [ split m{ \r? \n }xms, $content ],
    [ split m{ \r? \n }xms, <<"EOT" ],
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

# translated by: interactive
msgid "Number of %1: %2"
msgstr "Anzahl der %1: %2"

msgid "Number of {post items}: {count :num}"
msgstr ""

msgid "Please write %1 %*(%2,postcard,postcards), %quant(%3,postcard,postcards) or %*(%4,letter,letters,no letter) today."
msgstr ""

# comment2
# comment1
#. automatic2
#. automatic1
#: reference:3 reference:2
#: reference:1
msgid "He is overtaking the seagull named „bear“."
msgstr ""

msgid "Please write {name} {count :num} postcard today."
msgid_plural "Please write {name} {count :num} postcards today."
msgstr[0] ""
msgstr[1] ""

EOT
    'translated 1 line of file content';
