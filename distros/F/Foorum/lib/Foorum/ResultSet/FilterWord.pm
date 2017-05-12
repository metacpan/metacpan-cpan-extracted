package Foorum::ResultSet::FilterWord;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

sub get_data {
    my ( $self, $type ) = @_;

    return unless ($type);

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key   = "filter_word|type=$type";
    my $cache_value = $cache->get($cache_key);
    return wantarray ? @{ $cache_value->{value} } : $cache_value->{value}
        if ($cache_value);

    my @value;
    my @rs = $self->search( { type => $type } )->all;
    push @value, $_->word foreach (@rs);
    $cache_value = { value => \@value };
    $cache->set( $cache_key, $cache_value, 3600 );    # 1 hour

    return wantarray ? @value : \@value;
}

# for offensive word, we just convert part of the word into '*' by default
# for bad word, return 1 when matched

sub has_bad_word {
    my ( $self, $text ) = @_;

    my @bad_words = $self->get_data('bad_word');
    foreach my $word (@bad_words) {
        if ( $text =~ /$word/is ) {
            return $word;
        }
    }
    return 0;
}

sub convert_offensive_word {
    my ( $self, $text ) = @_;

    my @offensive_words = $self->get_data('offensive_word');
    foreach my $word (@offensive_words) {
        if ( $text =~ /$word/is ) {
            my $asterisk_word   = $word;
            my $converted_chars = 0;
            foreach my $offset ( 2 .. length($word) ) {
                next
                    if ( int( rand(10) ) % 2 == 1 )
                    ;    # randomly skip some chars
                substr( $asterisk_word, $offset - 1, 1 ) = '*';
                $converted_chars++;
                last if ( $converted_chars == 2 );    # that's enough
            }
            substr( $asterisk_word, 1, 1 ) = '*'
                unless ( $asterisk_word =~ /\*/is );
            $text =~ s/\b$word\b/$asterisk_word/isg;
        }
    }
    return $text;
}

1;
