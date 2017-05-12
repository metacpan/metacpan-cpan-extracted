package Lingua::Stem::Any;

use v5.8.1;
use utf8;
use Carp;
use List::Util qw( any first );
use Unicode::CaseFold qw( fc );
use Unicode::Normalize qw( NFC );

use Moo;
use namespace::clean;

our $VERSION = '0.05';

my %language_alias = (
    nb => 'no',
    nn => 'no',
);

has language => (
    is      => 'rw',
    isa     => sub {
        croak "Language is not defined"  unless defined $_[0];
        croak "Invalid language '$_[0]'" unless _is_language($_[0]);
    },
    coerce  => sub { $_[0] && ($language_alias{lc $_[0]} || lc $_[0]) },
    trigger => 1,
    default => 'en',
);

has source => (
    is      => 'rw',
    isa     => sub {
        croak "Source is not defined"  unless defined $_[0];
        croak "Invalid source '$_[0]'" unless _is_source($_[0]);
    },
    trigger => 1,
);

has cache => (
    is      => 'rw',
    coerce  => sub { !!$_[0] },
    default => 0,
    trigger => 1,
);

has exceptions => (
    is      => 'rw',
    isa     => sub {
        croak 'Exceptions must be a hashref'
            if ref $_[0] ne 'HASH';
        croak 'Exceptions must only include hashref values'
            if any { ref $_ ne 'HASH' } values %{$_[0]};
    },
    default => sub { {} },
);

has normalize => (
    is      => 'rw',
    coerce  => sub { !!$_[0] },
    default => 1,
);

has casefold => (
    is      => 'rw',
    coerce  => sub { !!$_[0] },
    default => 1,
);

has _stemmer => (
    is      => 'ro',
    builder => '_build_stemmer',
    clearer => 1,
    lazy    => 1,
);

has _stemmers => (
    is      => 'ro',
    default => sub { {} },
);

has _cache_data => (
    is      => 'rw',
    default => sub { {} },
);

my %sources = (
    'Lingua::Stem::Snowball' => {
        languages => {map { $_ => 1 } qw(
            da de en es fi fr hu it la nl no pt ro ru sv tr
        )},
        builder => sub {
            my $language = shift;
            require Lingua::Stem::Snowball;
            my $stemmer = Lingua::Stem::Snowball->new(
                lang     => $language,
                encoding => 'UTF-8',
            );
            return {
                stem     => sub { $stemmer->stem(shift) },
                language => sub { $stemmer->lang(shift) },
            };
        },
    },
    'Lingua::Stem::UniNE' => {
        languages => {map { $_ => 1 } qw(
            bg cs de fa
        )},
        builder => sub {
            my $language = shift;
            require Lingua::Stem::UniNE;
            my $stemmer = Lingua::Stem::UniNE->new(language => $language);
            return {
                stem     => sub { $stemmer->stem(shift) },
                language => sub { $stemmer->language(shift) },
            };
        },
    },
    'Lingua::Stem' => {
        languages => {map { $_ => 1 } qw(
            da de en fr gl it no pt ru sv
        )},
        builder => sub {
            my $language = shift;
            require Lingua::Stem;
            my $stemmer = Lingua::Stem->new(-locale => $language);
            return {
                stem     => sub { @{ $stemmer->stem(shift) }[0] },
                language => sub { $stemmer->set_locale(shift) },
            };
        },
    },
    'Lingua::Stem::Patch' => {
        languages => {map { $_ => 1 } qw(
            eo io pl
        )},
        builder => sub {
            my $language = shift;
            require Lingua::Stem::Patch;
            my $stemmer = Lingua::Stem::Patch->new(language => $language);
            return {
                stem     => sub { $stemmer->stem(shift) },
                language => sub { $stemmer->language(shift) },
            };
        },
    },
);

my %languages = map { %{$_->{languages}} } values %sources;

my @source_order = qw(
    Lingua::Stem::Snowball
    Lingua::Stem::UniNE
    Lingua::Stem
    Lingua::Stem::Patch
);

# functions

sub _is_language { exists $languages{ $_[0] } }
sub _is_source   { exists $sources{   $_[0] } }

# methods

sub BUILD {
    my ($self) = @_;

    $self->_trigger_language;
}

# the stemmer is cleared whenever a language or source is updated
sub _trigger_language {
    my ($self) = @_;

    $self->_clear_stemmer;

    # keep current source if it supports this language
    return if $self->source
           && $sources{$self->source}{languages}{$self->language};

    # use the first supported source for this language
    $self->source(
        first { $sources{$_}{languages}{$self->language} } @source_order
    );
}

sub _trigger_source {
    my ($self) = @_;

    $self->_clear_stemmer;
}

# the stemmer is built lazily on first use
sub _build_stemmer {
    my ($self) = @_;

    croak sprintf "Invalid source '%s' for language '%s'" => (
        $self->source, $self->language
    ) unless $sources{$self->source}{languages}{$self->language};

    my $stemmer
        = $self->_stemmers->{$self->source}
            ||= $sources{$self->source}{builder}( $self->language );

    $stemmer->{language}( $self->language );

    return $stemmer;
}

sub _get_stem {
    my ($self, $word) = @_;
    my $exceptions = $self->exceptions->{$self->language};

    return $word unless $word;

    $word = fc  $word if $self->casefold;
    $word = NFC $word if $self->normalize;

    # get from exceptions
    return $exceptions->{$word}
        if $exceptions
        && exists $exceptions->{$word};

    # stem without caching
    return $self->_stemmer->{stem}($word)
        unless $self->cache;

    # get from cache
    return $self->_cache_data->{$self->source}{$self->language}{$word}
        if exists $self->_cache_data->{$self->source}{$self->language}{$word};

    # stem and add to cache
    return $self->_cache_data->{$self->source}{$self->language}{$word}
         = $self->_stemmer->{stem}($word);
}

sub stem {
    my $self = shift;

    return map { $self->_get_stem($_) } @_
        if wantarray;

    return $self->_get_stem(pop)
        if @_;

    return;
}

sub stem_in_place {
    my ($self, $words) = @_;

    croak 'Argument to stem_in_place() must be an arrayref'
        if ref $words ne 'ARRAY';

    for my $word (@$words) {
        $word = $self->_get_stem($word);
    }

    return;
}

sub languages {
    my ($self, $source) = @_;
    my @languages;

    if ($source && $sources{$source}) {
        @languages = sort keys %{$sources{$source}{languages}};
    }
    elsif (!$source) {
        @languages = sort keys %languages;
    }

    return @languages;
}

sub sources {
    my ($self, $language) = @_;

    return @source_order unless $language;

    return grep {
        $sources{$_} && $sources{$_}{languages}{$language}
    } @source_order;
}

sub clear_cache {
    my ($self) = @_;

    $self->_cache_data( {} );
}

sub _trigger_cache {
    my ($self) = @_;

    if ( !$self->cache ) {
        $self->clear_cache;
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Lingua::Stem::Any - Unified interface to any stemmer on CPAN

=head1 VERSION

This document describes Lingua::Stem::Any v0.05.

=head1 SYNOPSIS

    use Lingua::Stem::Any;

    # create German stemmer using the default source module
    $stemmer = Lingua::Stem::Any->new(language => 'de');

    # create German stemmer explicitly using Lingua::Stem::Snowball
    $stemmer = Lingua::Stem::Any->new(
        language => 'de',
        source   => 'Lingua::Stem::Snowball',
    );

    # get stem for word
    $stem = $stemmer->stem($word);

    # get list of stems for list of words
    @stems = $stemmer->stem(@words);

=head1 DESCRIPTION

This module aims to provide a simple unified interface to any stemmer on CPAN.
It will provide a default available source module when a language is requested
but no source is requested.

=head2 Attributes

=over

=item language

The following language codes are currently supported.

    ┌────────────┬────┐
    │ Bulgarian  │ bg │
    │ Czech      │ cs │
    │ Danish     │ da │
    │ Dutch      │ nl │
    │ English    │ en │
    │ Esperanto  │ eo │
    │ Finnish    │ fi │
    │ French     │ fr │
    │ Galician   │ gl │
    │ German     │ de │
    │ Hungarian  │ hu │
    │ Ido        │ io │
    │ Italian    │ it │
    │ Latin      │ la │
    │ Norwegian  │ no │
    │ Persian    │ fa │
    │ Polish     │ pl │
    │ Portuguese │ pt │
    │ Romanian   │ ro │
    │ Russian    │ ru │
    │ Spanish    │ es │
    │ Swedish    │ sv │
    │ Turkish    │ tr │
    └────────────┴────┘

They are in the two-letter ISO 639-1 format and are case-insensitive but are
always returned in lowercase when requested.

    # instantiate a stemmer object
    $stemmer = Lingua::Stem::Any->new(language => $language);

    # get current language
    $language = $stemmer->language;

    # change language
    $stemmer->language($language);

The default language is C<en> (English). The values C<nb> (Norwegian Bokmål)
and C<nn> (Norwegian Nynorsk) are aliases for C<no> (Norwegian). Country codes
such as C<CZ> for the Czech Republic are not supported, as opposed to C<cs> for
the Czech language, nor are full IETF language tags or Unicode locale
identifiers such as C<pt-PT> or C<pt-BR>.

=item source

The following source modules are currently supported.

    ┌────────────────────────┬──────────────────────────────────────────────┐
    │ Module                 │ Languages                                    │
    ├────────────────────────┼──────────────────────────────────────────────┤
    │ Lingua::Stem::Snowball │ da de en es fi fr hu it nl no pt ro ru sv tr │
    │ Lingua::Stem::UniNE    │ bg cs de fa                                  │
    │ Lingua::Stem           │ da de en fr gl it no pt ru sv                │
    │ Lingua::Stem::Patch    │ eo io pl                                     │
    └────────────────────────┴──────────────────────────────────────────────┘

A module name is used to specify the source. If no source is specified, the
first available source in the above list with support for the current language
is used.

    # get current source
    $source = $stemmer->source;

    # change source
    $stemmer->source('Lingua::Stem::UniNE');

=item cache

Boolean value specifying whether to cache the stem for each word. This will
increase performance when stemming the same word multiple times at the expense
of increased memory consumption. When enabled, the stems are cached for the life
of the object or until the L</clear_cache> method is called. The same cache is
not shared among different languages, sources, or different instances of the
stemmer object.

=item exceptions

Exceptions may be desired to bypass stemming for specific words and use
predefined stems. For example, the plural English word C<mice> will not stem to
the singular word C<mouse> unless it is specified in the exception dictionary.
Another example is that by default the word C<pants> will stem to C<pant> even
though stemming is normally not desired in this example. The exception
dictionary can be provided as a hashref where the keys are language codes and
the values are hashrefs of exceptions.

    # instantiate stemmer object with exceptions
    $stemmer = Lingua::Stem::Any->new(
        language   => 'en',
        exceptions => {
            en => {
                mice  => 'mouse',
                pants => 'pants',
            }
        }
    );

    # add/change exceptions
    $stemmer->exceptions(
        en => {
            mice  => 'mouse',
            pants => 'pants',
        }
    );

    # alternately...
    $stemmer->exceptions->{en} = {
        mice  => 'mouse',
        pants => 'pants',
    };

=item casefold

Boolean value specifying whether to apply Unicode casefolding to words before
stemming them. This is enabled by default and is performed before normalization
when also enabled.

=item normalize

Boolean value specifying whether to apply Unicode NFC normalization to words
before stemming them. This is enabled by default and is performed after
casefolding when also enabled.

=back

=head2 Methods

=over

=item stem

Accepts a list of strings, stems each string, and returns a list of stems. The
list returned will always have the same number of elements in the same order as
the list provided. When no stemming rules apply to a word, the original word is
returned.

    @stems = $stemmer->stem(@words);

    # get the stem for a single word
    $stem = $stemmer->stem($word);

The words should be provided as character strings and the stems are returned as
character strings. Byte strings in arbitrary character encodings are not
supported.

=item stem_in_place

Accepts an array reference, stems each element, and replaces them with the
resulting stems.

    $stemmer->stem_in_place(\@words);

This method is provided for potential optimization when a large array of words
is to be stemmed. The return value is not defined.

=item languages

Returns a list of supported two-letter language codes using lowercase letters.

    # all languages
    @languages = $stemmer->languages;

    # languages supported by Lingua::Stem::Snowball
    @languages = $stemmer->languages('Lingua::Stem::Snowball');

=item sources

Returns a list of supported source module names.

    # all sources
    @sources = $stemmer->sources;

    # sources that support English
    @sources = $stemmer->sources('en');

=item clear_cache

Clears the stem cache for all languages and sources of this object instance when
the L</cache> attribute is enabled. Does not affect whether caching is enabled.

=back

=head1 SEE ALSO

L<Lingua::Stem::Snowball>, L<Lingua::Stem::UniNE>, L<Lingua::Stem>, L<Lingua::Stem::Patch>

=head1 AUTHOR

Nick Patch <patch@cpan.org>

This project is brought to you by L<Shutterstock|http://www.shutterstock.com/>.
Additional open source projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 COPYRIGHT AND LICENSE

© 2013–2014 Shutterstock, Inc.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
