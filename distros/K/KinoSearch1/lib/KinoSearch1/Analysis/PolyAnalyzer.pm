package KinoSearch1::Analysis::PolyAnalyzer;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Analysis::Analyzer );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        analyzers => undef,
    );
}

use KinoSearch1::Analysis::LCNormalizer;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::Analysis::Stemmer;

sub init_instance {
    my $self = shift;
    my $language = $self->{language} = lc( $self->{language} );

    # create a default set of analyzers if language was specified
    if ( !defined $self->{analyzers} ) {
        croak("Must specify either 'language' or 'analyzers'")
            unless $language;
        $self->{analyzers} = [
            KinoSearch1::Analysis::LCNormalizer->new( language => $language ),
            KinoSearch1::Analysis::Tokenizer->new( language => $language ),
            KinoSearch1::Analysis::Stemmer->new( language => $language ),
        ];
    }
}

sub analyze {
    my ( $self, $token_batch ) = @_;

    # iterate through each of the anayzers in order
    $token_batch = $_->analyze($token_batch) for @{ $self->{analyzers} };

    return $token_batch;
}

1;

__END__

=head1 NAME

KinoSearch1::Analysis::PolyAnalyzer - multiple analyzers in series 

=head1 SYNOPSIS

    my $analyzer = KinoSearch1::Analysis::PolyAnalyzer->new(
        language  => 'es',
    );
    
    # or...
    my $analyzer = KinoSearch1::Analysis::PolyAnalyzer->new(
        analyzers => [
            $lc_normalizer,
            $custom_tokenizer,
            $snowball_stemmer,
        ],
    );

=head1 DESCRIPTION

A PolyAnalyzer is a series of Analyzers -- objects which inherit from
L<KinoSearch1::Analysis::Analyzer|KinoSearch1::Analysis::Analyzer> -- each of
which will be called upon to "analyze" text in turn.  You can either provide
the Analyzers yourself, or you can specify a supported language, in which case
a PolyAnalyzer consisting of an
L<LCNormalizer|KinoSearch1::Analysis::LCNormalizer>, a
L<Tokenizer|KinoSearch1::Analysis::Tokenizer>, and a
L<Stemmer|KinoSearch1::Analysis::Stemmer> will be generated for you.

Supported languages:

    en => English,
    da => Danish,
    de => German,
    es => Spanish,
    fi => Finnish,
    fr => French,
    it => Italian,
    nl => Dutch,
    no => Norwegian,
    pt => Portuguese,
    ru => Russian,
    sv => Swedish,

=head1 CONSTRUCTOR

=head2 new()

    my $analyzer = KinoSearch1::Analysis::PolyAnalyzer->new(
        language   => 'en',
    );

Construct a PolyAnalyzer object.  If the parameter C<analyzers> is specified,
it will override C<language> and no attempt will be made to generate a default
set of Analyzers.

=over

=item

B<language> - Must be an ISO code from the list of supported languages.

=item

B<analyzers> - Must be an arrayref.  Each element in the array must inherit
from KinoSearch1::Analysis::Analyzer.  The order of the analyzers matters.
Don't put a Stemmer before a Tokenizer (can't stem whole documents or
paragraphs -- just individual words), or a Stopalizer after a Stemmer (stemmed
words, e.g. "themselv", will not appear in a stoplist).  In general, the
sequence should be: normalize, tokenize, stopalize, stem.

=back

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut
