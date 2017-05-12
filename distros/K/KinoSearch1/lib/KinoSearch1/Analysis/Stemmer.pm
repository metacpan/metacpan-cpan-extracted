package KinoSearch1::Analysis::Stemmer;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Analysis::Analyzer );

our %supported_languages;

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        stemmifier => undef,
    );
}

use Lingua::Stem::Snowball qw( stemmers );

# build a list of supported languages.
$supported_languages{$_} = 1 for stemmers();

sub init_instance {
    my $self = shift;

    # verify language param
    my $language = $self->{language} = lc( $self->{language} );
    croak("Unsupported language: '$language'")
        unless $supported_languages{$language};

    # create instance of Snowball stemmer
    $self->{stemmifier} = Lingua::Stem::Snowball->new( lang => $language );
}

sub analyze {
    my ( $self, $batch ) = @_;

    # replace terms with stemmed versions.
    my $all_texts = $batch->get_all_texts;
    $self->{stemmifier}->stem_in_place($all_texts);
    $batch->set_all_texts($all_texts);

    $batch->reset;
    return $batch;
}

1;

__END__

=head1 NAME

KinoSearch1::Analysis::Stemmer - reduce related words to a shared root

=head1 SYNOPSIS

    my $stemmer = KinoSearch1::Analysis::Stemmer->new( language => 'es' );
    
    my $polyanalyzer = KinoSearch1::Analysis::PolyAnalyzer->new(
        analyzers => [ $lc_normalizer, $tokenizer, $stemmer ],
    );

=head1 DESCRIPTION

Stemming reduces words to a root form.  For instance, "horse", "horses",
and "horsing" all become "hors" -- so that a search for 'horse' will also
match documents containing 'horses' and 'horsing'.  

This class is a wrapper around
L<Lingua::Stem::Snowball|Lingua::Stem::Snowball>, so it supports the same
languages.  

=head1 METHODS 

=head2 new

Create a new stemmer.  Takes a single named parameter, C<language>, which must
be an ISO two-letter code that Lingua::Stem::Snowball understands.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut

