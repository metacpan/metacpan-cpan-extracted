#!/opt/bin/perl

#########################
# Usage: ./benchmark-stemmers.pl voc.txt
#
# Runs speed (words/second) tests using randomly selected
# words from a word list.
#

use strict;
use warnings;

use lib qw(../lib);

use Lingua::Stem qw ();
use Lingua::Stem::En qw ();
use Time::HiRes qw(gettimeofday tv_interval);

my $snowball = eval { require Lingua::Stem::Snowball; };
if ($@) {
    $snowball = 0;
}

my $loops   = 100;
my $n_words = 3000;

my @word = grep chomp, <ARGV>;

#################################################
# Preload word list so we have identical runs
my @word_list = ();
my $s = $n_words;
print "Generating base word list...\n";
for (1..$s) {
  my $result;
  my $w = @word[rand(scalar(@word))];
  push (@word_list,$w);
}
print "Generating long word list...\n";
my $n = $n_words * $loops;
my @big_word_list = ();
foreach my $count (1..$loops) {
    push (@big_word_list, @word_list);
}
print "$n_words words repeated $loops times\n\n";
# Word by word, Lingua::Stem::Snowball
if ($snowball) {
    my $start_time = [gettimeofday];
    for (my $i = 0; $i < $loops; $i++) { 
        foreach my $w (@word_list) {
            my ($result) = Lingua::Stem::Snowball::stem('en', $w);
        }
    }
    my $elapsed = tv_interval($start_time);
    printf  "Lingua::Stem::Snowball, one word at a time, no caching: %8s words/second\n", int($n/$elapsed);
}

# Processed in batches, Lingua::Stem::Snowball
if ($snowball) {
    eval {
        my $start_time = [gettimeofday];
        for (my $i = 0; $i < $loops; $i++) { 
            my @results = Lingua::Stem::Snowball::stem('en',\@word_list);
            my $n_words_returned = @results;
            if ($n_words_returned <= 1) {
                use Data::Dumper; warn(Dumper(\@results));
                die(sprintf("Lingua::Stem::Snowball, %6s word batches, no caching:         failed\n", $n_words));
            }
        }
        my $elapsed = tv_interval($start_time);
        printf  "Lingua::Stem::Snowball, %6s word batches, no caching:%8s words/second\n", $n_words, int($n/$elapsed);
    };
    if ($@) {
        print "$@";
    }
 }

# Processed in one batch, Lingua::Stem::Snowball
if ($snowball) {
    eval {
        my $start_time = [gettimeofday];
        my @results = Lingua::Stem::Snowball::stem('en',\@big_word_list);
        my $n_words_returned = @results;
        if ($n_words_returned <= 1) {
            die(sprintf("Lingua::Stem::Snowball, one batch, no caching:                   failed\n", $n_words));
        }
        my $elapsed = tv_interval($start_time);
        printf  "Lingua::Stem::Snowball, one batch, no caching:          %8s words/second\n", int($n/$elapsed);
    };
    if ($@) {
        print "$@";
    }
}

# Word by word, Lingua::Stem
{
    my $start_time = [gettimeofday];
    for (my $i = 0; $i < $loops; $i++) { 
        foreach my $w (@word_list) {
            my ($result) = Lingua::Stem::stem($w);
        }
    }
    my $elapsed = tv_interval($start_time);
    printf  "Lingua::Stem, one word at a time, no caching:           %8s words/second\n", int($n/$elapsed);
}


# Processed in batches, Lingua::Stem
{
    my $start_time = [gettimeofday];
    for (my $i = 0; $i < $loops; $i++) { 
        my ($result) = Lingua::Stem::stem(@word_list);
    }
    my $elapsed = tv_interval($start_time);
    printf  "Lingua::Stem, %6s word batches, no caching:          %8s words/second\n", $n_words, int($n/$elapsed);
}

# Processed in one batch, Lingua::Stem
{
    my $start_time = [gettimeofday];
    my ($result) = Lingua::Stem::stem(@big_word_list);
    my $elapsed = tv_interval($start_time);
    printf  "Lingua::Stem, one batch, no caching:                    %8s words/second\n", int($n/$elapsed);
}

# Word by word, Lingua::Stem, with caching
{
    Lingua::Stem::stem_caching({ -level => 2});
    my $start_time = [gettimeofday];
    for (my $i = 0; $i < $loops; $i++) { 
        foreach my $w (@word_list) {
            my ($result) = Lingua::Stem::stem($w);
        }
    }
    my $elapsed = tv_interval($start_time);
    printf  "Lingua::Stem, one word at a time, cache level 2:        %8s words/second\n", int($n/$elapsed);
}

# Processed in batches with caching, Lingua::Stem
{
    Lingua::Stem::stem_caching({ -level => 2});
    my $start_time = [gettimeofday];
    for (my $i = 0; $i < $loops; $i++) { 
        my ($result) = Lingua::Stem::stem(@word_list);
    }
    my $elapsed = tv_interval($start_time);
    printf  "Lingua::Stem, %6s word batches, cache level 2:       %8s words/second\n", $n_words, int($n/$elapsed);
}
# Processed in one batch with caching, Lingua::Stem
{
    Lingua::Stem::stem_caching({ -level => 2});
    my $start_time = [gettimeofday];
    my ($result) = Lingua::Stem::stem(@big_word_list);
    my $elapsed = tv_interval($start_time);
    printf  "Lingua::Stem, one batch, cache level 2:                 %8s words/second\n", int($n/$elapsed);
}

# Word by word, Lingua::Stem, with caching
{
    Lingua::Stem::En::stem_caching({ -level => 2});
    my $start_time = [gettimeofday];
    for (my $i = 0; $i < $loops; $i++) { 
        foreach my $w (@word_list) {
            my ($result) = Lingua::Stem::En::stem($w);
        }
    }
    my $elapsed = tv_interval($start_time);
    printf  "Lingua::Stem, one word at a time, cache level 2:        %8s words/second\n", int($n/$elapsed);
}

# Processed in batches with caching, Lingua::Stem
{
    Lingua::Stem::En::stem_caching({ -level => 2});
    my $start_time = [gettimeofday];
    for (my $i = 0; $i < $loops; $i++) { 
        my ($result) = Lingua::Stem::En::stem(@word_list);
    }
    my $elapsed = tv_interval($start_time);
    printf  "Lingua::Stem, %6s word batches, cache level 2:       %8s words/second\n", $n_words, int($n/$elapsed);
}
# Processed in one batch with caching, Lingua::Stem
{
    Lingua::Stem::En::stem_caching({ -level => 2});
    my $start_time = [gettimeofday];
    my ($result) = Lingua::Stem::En::stem(@big_word_list);
    my $elapsed = tv_interval($start_time);
    printf  "Lingua::Stem, one batch, cache level 2:                 %8s words/second\n", int($n/$elapsed);
}
