#! /usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use File::Slurp qw(slurp);
use Jmespath;
use JSON;
$ENV{JP_UNQUOTED} = 1;
use Try::Tiny;
use utf8;
use Encode;
#use open ':std', ':encoding(utf8)';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";


my $cdir = dirname(__FILE__) . '/compliance';

opendir(my $dh, $cdir) || die "can't opendir $cdir: $!";
my @files;
if ($ARGV[0]) {
  @files = $ARGV[0];
} else {
  @files = grep { /json$/ && -f "$cdir/$_" } readdir($dh);
}
closedir $dh;
$ENV{JP_UNQUOTED} = 1;

foreach my $file ( @files ) {
  next if $file eq 'benchmarks.json';
  my $json_data = slurp("$cdir/$file");
  my $perl_data = JSON->new->utf8(1)->allow_nonref->space_after->decode($json_data);
  my @parts = split /\./, $file;
  my $n = $parts[0];
  my $cn = 1;
  foreach my $block ( @$perl_data ) {
    my $text =$block->{ given };
    foreach my $case ( @{ $block->{cases} } ) {
      my $comment = exists $case->{comment} ? $case->{ comment } : $case->{ expression };
      my $deeply = exists $case->{is_deeply} ? $case->{is_deeply} : 0;
      my $msg = $n . ' case ' . $cn . ' : ' . $comment;
      my $expr   = $case->{expression};
      my $expect = $case->{result};
      my $r;
      if (exists $case->{error}) {
        try {
          my $r = Jmespath->search($expr, $text);
          fail($msg . ' : Expected exception');
        } catch {
          isa_ok $_, 'Jmespath::ValueException', $msg;
        };
      }
      else {
        try {
          my $r = Jmespath->search($expr, $text);
          if ($deeply) {
            $expect = $case->{result};
            $r = JSON->new->utf8->allow_nonref->space_after->decode($r);
            is_deeply $r, $expect, $msg;
          }
          else {
            is $r, $expect, $msg;
          }
        } catch {
           fail($msg . ' : ' . 'EXCEPTION MESSAGE: ' . $_->message )
        };
      }
      $cn++;
    }
  }
}


sub sq {
  my $string = shift;
  $string =~ s/^"|"$//g;
  return $string;
}

done_testing();
