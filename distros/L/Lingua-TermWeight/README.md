# SYNOPSIS

    use Lingua::TermWeight;
    use Lingua::TermWeight::WordSegmenter::SplitBySpace;

    my $tf_idf_calc = Lingua::TermWeight->new(
      word_segmenter => Lingua::TermWeight::WordSegmenter::SplitBySpace->new,
    );

    my $document1 = 'Humpty Dumpty sat on a wall...';
    my $document2 = 'Remember, remember, the fifth of November...';

    my $tf = $tf_idf_calc->tf(document => $document1);
    # TF of word "Dumpty" in $document1.
    say $tf->{'Dumpty'};  # 2, if you are referring same text as mine.

    my $idf = $tf_idf_calc->idf(documents => [$document1, $document2]);
    say $idf->{'Dumpty'};  # log(2/1) ≒ 0.693147

    my $tf_idfs = $tf_idf_calc->tf_idf(documents => [$document1, $document2]);
    # TF-IDF of word "Dumpty" in $document1.
    say $tf_idfs->[0]{'Dumpty'};  # 2 log(2/1) ≒ 1.386294
    # Ditto. But in $document2.
    say $tf_idfs->[1]{'Dumpty'};  # 0

# DESCRIPTION

Quoting [Wikipedia](http://en.wikipedia.org/wiki/Tf%E2%80%93idf):

    tf–idf, short for term frequency–inverse document frequency, is a numerical
    statistic that is intended to reflect how important a word is to a document
    in a collection or corpus. It is often used as a weighting factor in
    information retrieval and text mining.

This module provides feature for calculating TF, IDF and TF-IDF.

# METHODS

## new(word\_segmenter => $segmenter)

Constructor. Takes 1 mandatory parameter `word_segmenter`.

### CUSTOM WORD SEGMENTER

Although this distribution bundles some language-independent word segmenter,
like [Lingua::TermWeight::WordSegmenter::SplitBySpace](https://metacpan.org/pod/Lingua%3A%3ATermWeight%3A%3AWordSegmenter%3A%3ASplitBySpace), sometimes
language-specifiec word segmenters are more appropriate. You can pass a custom
word segmenter object to the calculator.

The word segmenter is a plain Perl object that implements `segment` method.
The method takes 1 positional argument `$document`, which is a string or a
**reference** to string. It is expected to return an word iterator as CodeRef.

Roughly speaking, given custom word segmenter will be used like:

    my $document = 'foo bar baz';

    # Can be called with a reference, like |->segment(\$document)|.
    # Detecting data type is callee's responsibility.
    my $iter = $word_segmenter->segment($document);

    while (defined(my $word = $iter->())) {
       ...
    }

## idf(documents => \\@documents)

Calculates IDFs. Result is returned as HashRef, which the keys and values are
words and corresponding IDFs respectively.

## tf(document => $document | \\$document \[, normalize => 0\])

Calculates TFs. Result is returned as HashRef, which the keys and values are
words and corresponding TFs respectively.

If optional parameter &lt;normalize> is set true, the TFs are devided by the
number of words in the `$document`. It is useful when comparing TFs with other
documents.

## tf\_idf(documents => \\@documents \[, normalize => 0\])

Calculates TF-IDFs. Result is returned as ArrayRef of HashRef. Each HashRef
contains TF-IDF values for corresponding document.

# SEE ALSO

- [Lingua::TermWeight::WordSegmenter::LetterNgram](https://metacpan.org/pod/Lingua%3A%3ATermWeight%3A%3AWordSegmenter%3A%3ALetterNgram)
- [Lingua::TermWeight::WordSegmenter::SplitBySpace](https://metacpan.org/pod/Lingua%3A%3ATermWeight%3A%3AWordSegmenter%3A%3ASplitBySpace)

## Fork of Lingua::TFIDF

This is fork of [Lingua::TFIDF](https://metacpan.org/pod/Lingua%3A%3ATFIDF) which excludes dependencies to the Japanese
language which seem to be breaking installations on both Linux and MacOS. As
the original module has not been updated for over 12 years I've decided to fork
the project and use [Object::Pad](https://metacpan.org/pod/Object%3A%3APad) as the OO base for the new module. The API
will stay the same (for now), the dependency graph will stay lighter.

The original source code is available via [Lingua::TFIDF](https://metacpan.org/pod/Lingua%3A%3ATFIDF). I thank the author
Koichi Satoh for their original work and will continue to use it in my own
implemention.
