#!/usr/bin/perl
use strict;
use Lingua::LinkParser;

## Demonstrates a parse with extended options.

my $parser = new Lingua::LinkParser;

while (1) {
  print "Enter a sentence: ";
  my $text = <STDIN>;
  $parser->opts(
                'max_sentence_length' => 70,
                'panic_mode'          => 1,
                'max_parse_time'      => 30,
                'linkage_limit'       => 1000,
                'short_length'        => 10,
                'disjunct_cost'       => 2,
                'min_null_count'      => 0,
                'max_null_count'      => 0,
              );

  print "short: ", $parser->opts('short_length'), "\n";
  print "max_time: ", $parser->opts('max_parse_time'), "\n";

  my $sentence = $parser->create_sentence($text);
  print "linkages found: ", $sentence->num_linkages, "\n";

  if ($sentence->num_linkages == 0) {
      $parser->opts('min_null_count' => 1,
                    'max_null_count' => $sentence->length);

      print "length: ", $sentence->length, "\n";

      $sentence = $parser->create_sentence($text);
      print "null linkages found: ", $sentence->num_linkages, "\n";

      if ($sentence->num_linkages == 0) {
          $parser->opts('disjunct_cost'    => 3,
                        'min_null_count'   => 1,
                        'max_null_count'   => 30,
                        'max_parse_time'   => 60,
                        'islands_ok'       => 1,
                        'short_length'     => 6,
                        'all_short_connectors' => 1,
                        'linkage_limit'    => 100
          );
           my $sentence = $parser->create_sentence($text);
           print "panic linkages found: ", $sentence->num_linkages, "\n";
      }
  }

  for my $i (1 .. $sentence->num_linkages) {
      my $linkage = $sentence->linkage($i);
      $linkage->compute_union;
      my $sublinkage = $linkage->sublinkage($linkage->num_sublinkages);
      print $parser->get_diagram($sublinkage), "\n";
  }
}

