# NAME

Lingua::JA::DocumentFrequency::AozoraBunko - Return the document frequency in Aozora Bunko

# SYNOPSIS

    use Lingua::JA::DocumentFrequency::AozoraBunko;
    use utf8;

    aozora_df('本');         # => 5180
    aozora_df('遊蕩');       # => 160
    aozora_df('チャカポコ'); # => 3
    aozora_df('しおらしい'); # => 149
    aozora_df('イチロー');   # => 0

    Lingua::JA::DocumentFrequency::AozoraBunko::df('ジャピイ'); # => 2
    Lingua::JA::DocumentFrequency::AozoraBunko::df('カア');     # => 23

    my $N = Lingua::JA::DocumentFrequency::AozoraBunko::number_of_documents(); # => 11176
    idf('ジャピイ'); # => 8.62837672037685
    idf('カア');     # => 6.18602968500765

    sub idf { log( $N / aozora_df(shift) ) }

# DESCRIPTION

Lingua::JA::DocumentFrequency::AozoraBunko returns the document frequency in Aozora Bunko.

# METHODS

## df($word)

Returns the document frequency of $word.

## aozora\_df($word)

Same as df method, but this method is exported by default.

## number\_of\_documents

Returns the number of the documents in Aozora Bunko.

# LICENSE

Copyright (C) pawa.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

pawa <pawapawa@cpan.org>
