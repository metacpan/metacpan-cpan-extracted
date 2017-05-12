#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Lingua::DE::ASCII;

use constant CHUNK_SIZE => 250;

local @ARGV = ( 
    "t/english.dat",
    map {"t/words_with_$_.dat"} 
    ("foreign", "ä", "ö", "ü", "ß", "ae", "oe", "ue", "ss")
);

chomp( my @all_words = <> );

my $progress    = eval {
    require Term::ProgressBar;
    Term::ProgressBar->new({
       name  => 'Words tested from the big dictionary',
       count => scalar(@all_words) / CHUNK_SIZE,
       ETA   => 'linear'
    });
};
my $last_perc = 0;

foreach my $chunk (0 .. (scalar(@all_words) / CHUNK_SIZE)) {

    my @range = ($chunk * CHUNK_SIZE .. (($chunk+1) * CHUNK_SIZE)-1);
    my @words = grep defined, @all_words[@range];

    # test each word in a random environment
    test_chunk_text(join "\n",
        map {join " ", $all_words[rand @all_words], $_, $all_words[rand @all_words]}
            @words
    );

    # test each word following by itselfs to check
    # whether all internal regexps are working global
    test_chunk_text(join "\n",
        map "$_ $_", @words
   );   



   $progress 
       ? $progress->update($chunk)
       : (     $last_perc < ($_ = int(100 * (CHUNK_SIZE * $chunk / @all_words))) 
           and $last_perc = $_ 
           and print STDERR "$_% "
         );
}

sub test_chunk_text {
    my $chunk_text = shift;    
    my $from_latin1_ascii = to_latin1(to_ascii($chunk_text));
    my $from_latin1       = to_latin1($chunk_text);

    assert_chunks_equal(
        $from_latin1_ascii, $chunk_text,
        "to_latin1(to_ascii(string)): "
    );
    assert_chunks_equal($from_latin1,$chunk_text, "to_latin1(string): ");

}   


sub assert_chunks_equal {
    my @got  = split /\n/, shift;
    my @orig = split /\n/, shift;
    my $msg  = shift;

    while (defined(my $got = shift(@got)) && defined(my $orig = shift(@orig))) {
        $got eq $orig or diag("$msg: $orig => $got"),fail,exit;
    }
}

ok(1);
