#!/usr/bin/perl -w
require 5.005;
use strict;

use Message::Style;

my %scores;

sub scorethis {
  my($article)=@_;
  return unless @$article;
  my $from;
  foreach(@$article) {
    next unless /^From:\s+(.*)$/i;
    $from=$1;
    last;
  }
  my $score=Message::Style::score($article);
  $scores{$from}||=[];
  push @{ $scores{$from} }, $score;
}

sub scorethese {
  local(@ARGV)=@_;
  my @article;
  while(<>) {
    chomp;
    if(/^From /) {
      scorethis(\@article);
      undef @article;
    } else {
      push @article, $_;
    }
  }
  scorethis(\@article);
}

if(@ARGV>=2) {
  scorethese($_) foreach @ARGV;
} else {
  scorethese(@ARGV);
}

#use Data::Dumper;
#warn Dumper \%scores;

print "Score\n";
print "-Min- -Max- -Avg-  Name\n";
foreach my $name (sort keys %scores) {
  my(@scores)=@{ $scores{$name} };
  my($min, $max, $total)=(1<<31-1, 0, 0);
  foreach(@scores) {
    $min=($min<$_)?$min:$_;
    $max=($max>$_)?$max:$_;
    $total+=$_;
  }
  printf "%5d%6d%6d  %s\n",
    $min, $max, $total/@scores, $name;
}
