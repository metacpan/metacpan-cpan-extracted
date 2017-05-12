#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::Most;
use File::Temp;
use List::MoreUtils qw( zip );
use Iterator::Simple::Util::CSV qw( icsv );

my $test_data = File::Temp->new();
$test_data->print(<<'EOT');
"Name","Address","Floors","Donated last year","Contact"
"Charlotte French Cakes","1179 Glenhuntly Rd",1,"Y","John"
"Glenhuntly Pharmacy","1181 Glenhuntly Rd",1,"Y","Paul"
EOT
$test_data->close;

my @data_array = (
  ["Name","Address","Floors","Donated last year","Contact"],
  ["Charlotte French Cakes","1179 Glenhuntly Rd",1,"Y","John"],
  ["Glenhuntly Pharmacy","1181 Glenhuntly Rd",1,"Y","Paul"]
);

{
  ok my $it = icsv( $test_data->filename ), 'icsv, no options';
  for my $d ( @data_array ) {
    is_deeply $it->next, $d, 'Return arrayref';
  }
  ok ! $it->next, 'Iterator is exhausted';
}

{
  ok my $it = icsv( $test_data->filename, skip_header => 1 ), 'icsv, skip_header';
  for my $d ( @data_array[1,2] ) {
    is_deeply $it->next, $d, 'Return arrayref';
  }
  ok ! $it->next, 'Iterator is exhausted';
}

{
  ok my $it = icsv( $test_data->filename, {skip_header => 1} ), 'icsv, skip_header, options hash';
  for my $d ( @data_array[1,2] ) {
    is_deeply $it->next, $d, 'Return arrayref';
  }
  ok ! $it->next, 'Iterator is exhausted';
}

{
  my @data_href = map +{ zip @{$data_array[0]}, @{$_} }, @data_array[1,2];

  ok my $it = icsv( $test_data->filename, use_header => 1 ), 'icsv, use_header';
  for my $d ( @data_href ) {
    is_deeply $it->next, $d, 'Return hashref';
  }
  ok ! $it->next, 'Iterator is exhausted';
}

{
  my @cols = qw( foo bar baz quux quuux );
  my @data_href = map +{ zip @cols, @{$_} }, @data_array[1,2];

  ok my $it = icsv( $test_data->filename, skip_header => 1, column_names => \@cols ), 'icsv, skip_header, column_names';
  for my $d ( @data_href ) {
    is_deeply $it->next, $d, 'Return hashref';
  }
  ok ! $it->next, 'Iterator is exhausted';
}

done_testing;



