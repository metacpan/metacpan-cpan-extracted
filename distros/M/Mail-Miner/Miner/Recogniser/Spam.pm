#!/usr/bin/perl -w

package Mail::Miner::Recogniser::Spam;
use strict;

my $spamtest;

eval "use Mail::SpamAssassin";
unless ($@) {
    $spamtest = Mail::SpamAssassin->new({local_tests_only => 1});

    $Mail::Miner::recognisers{"".__PACKAGE__} =
        {
         title => "Spam",
         help  => "Tag a message with a spam score",
         keyword => "spam", # Not that this is particularly useful
         type => "=s",
         nodisplay => 1,
        };
}

sub process {
    my ($class, %hash) = @_;
    my $string = $hash{gethead}->()."\n".$hash{getbody}->();
    if ($hash{gethead}->() =~ /X-Spam-Status: .*hits=(-?[\d\.]+)/) { return $1 }
    my $spamscore = $spamtest->check_message_text($string);
    my $score = $spamscore->get_hits;
    $spamscore->finish;
    return $score;
}

1;
