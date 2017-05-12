#!/usr/bin/perl

use File::Path;

$DIR = './log/lots_of_contents.tmp';
$IN = '../doc/using.html';

$text = '';
open (IN, "<$IN") or die "cannot read $IN";
$text = join ('', <IN>);
close IN;

rmtree ("$DIR");
for ($i = 0; $i < 10; $i++) {
  mkpath ("$DIR/dir$i");
  for ($j = 0; $j < 10; $j++) {
    mkpath ("$DIR/dir$i/sub$j");
    for ($k = 0; $k < 50; $k++) {
      open (OUT, ">$DIR/dir$i/sub$j/content$k.html");
      print OUT $text;
      close OUT;
    }
  }
  print "Made $DIR/dir$i\n";
}
