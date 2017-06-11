#!perl -T ## no critic (TidyCode)

use strict;
use warnings;
use utf8;

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
            'postcard',
            'Postkarte',
            'postcards',
            'Postkarten',
        },
    );

    sub translate_text {
        my ( $self, $text ) = @_;

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
my $obj = MyTranslator->new(
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
);
print
    $obj->translate_any_msgid('postcard'),
    "\n",
    'Error: ', $obj->error || 'no error',
    "\n",
    $obj->translate_any_msgid('postcards'),
    "\n",
    'Error: ', $obj->error || 'no error',
    "\n";


# $Id: 13_translate_any_msgid_utf-8.pl 653 2017-06-03 20:16:11Z steffenw $

__END__

Output:

en: postcard
de: Postkarte
en: postcards
de: Postkarten
Postkarte
Error: no error
Postkarten
Error: no error
