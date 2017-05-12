use strict;
use warnings;
use Test::More;

use_ok 'Lingua::TFIDF::WordSegmenter::SplitBySpace';

my $document = <<'EOT';
Humpty Dumpty sat on a wall,
Humpty Dumpty had a great fall.
All the king's horses and all the king's men
Couldn't put Humpty together again.
EOT

no warnings 'qw';
my @tests = (
  +{
    expected => [qw/Humpty Dumpty sat on a wall,
                    Humpty Dumpty had a great fall.
                    All the king's horses and all the king's men
                    Couldn't put Humpty together again./],
    name => 'Default',
    parameters => [],
  },
  +{
    expected => [qw/humpty dumpty sat on a wall,
                    humpty dumpty had a great fall.
                    all the king's horses and all the king's men
                    couldn't put humpty together again./],
    name => 'With |lower_case| option',
    parameters => [ lower_case => 1 ],
  },
  +{
    expected => [qw/Humpty Dumpty sat on a wall
                    Humpty Dumpty had a great fall
                    All the king's horses and all the king's men
                    Couldn't put Humpty together again/],
    name => 'With |remove_punctuations| option',
    parameters => [ remove_punctuations => 1 ],
  },
  +{
    expected => [qw/Humpty Dumpty sat on wall,
                    Humpty Dumpty had great fall.
                    All the king's horses and the king's men
                    Couldn't put Humpty together again./],
    name => 'With |stop_words| option',
    parameters => [ stop_words => ['a', 'all'] ],
  },
  +{
    # Filtering stop words is performed after case conversion. So not only
    # words "a" and "all" but also capital cased "All" will be excluded.
    expected => [qw/humpty dumpty sat on wall,
                    humpty dumpty had great fall.
                    the king's horses and the king's men
                    couldn't put humpty together again./],
    name => 'With |lower_case| and |stop_words| options',
    parameters => [ lower_case => 1, stop_words => ['a', 'all'] ],
  },
);

for my $test (@tests) {
  subtest $test->{name} => sub {
    my $segmenter = new_ok(
      'Lingua::TFIDF::WordSegmenter::SplitBySpace' => $test->{parameters},
    );

    my $iter = $segmenter->segment($document);
    my @segmented_words;
    while (defined(my $word = $iter->())) { push @segmented_words, $word }
    is_deeply \@segmented_words, $test->{expected};
  };
}

done_testing;
