package HTML::Template::Compiled::Plugin::I18N::TestTranslator;

use strict;
use warnings;

use Carp qw(croak);
use HTML::Template::Compiled::Plugin::I18N;
# in mod_perl environment use Apache::Singleton::Request
use parent qw(Class::Singleton);

my %lexicon = (
    en => {
        'Hello <world>!' => 'Hello <world>!',
        ( ( '{link_begin}<link>{link_end}'     ) x 2 ),
        ( ( '{link_begin}<**link**>{link_end}' ) x 2 ),
    },
    de => {
        'Hello <world>!' => 'Hallo <Welt>!',
    },
);

sub new {
    my ($class, @more) = @_;

    return $class->instance(@more);
}

sub set_language {
    my ($self, $language) = @_;

    $self->{language} = $language;

    return $self;
}

sub get_language {
    my $self = shift;

    my $language = $self->{language}
        or croak 'No language set';

    return $language;
}

sub translate {
    my ($class, $arg_ref) = @_;

    my $self = $class->new();

    my $language = $self->get_language();
    exists $lexicon{$language}
        or return "Language $language is not in the lexicon";
    my $lexicon_of_language = $lexicon{$language};
    $arg_ref->{text}
        or return 'No text';
    exists $lexicon_of_language->{ $arg_ref->{text} }
        or return "No lexicon entry for: $arg_ref->{text}";
    my $translation = $lexicon_of_language->{ $arg_ref->{text} }
        or return "Translation result not found for: $arg_ref->{text}";
    if ( exists $arg_ref->{escape} ) {
        $translation = HTML::Template::Compiled::Plugin::I18N->escape(
            $translation,
            $arg_ref->{escape},
        );
    }
    if ( exists $arg_ref->{formatter} ) {
        my $formatter = $arg_ref->{formatter};
        if (lc $formatter->[0] eq lc 'Markdown') {
            $translation =~ s{\*\* ([^*]+) \*\*}{<strong>$1</strong>}xmsg;
        }
    }
    if ( exists $arg_ref->{unescaped} ) {
        $translation = HTML::Template::Compiled::Plugin::I18N->expand_unescaped(
            $translation,
            $arg_ref->{unescaped},
        );
    }

    return $translation;
}

1;