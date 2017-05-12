# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 1;
use Path::Class qw{file};

BEGIN { use_ok( 'GD::Graph::Cartesian' ); }

if (-w ".") {
  my $obj=GD::Graph::Cartesian->new(width=>400, height=>100);
  foreach (-5 .. 5) {
    $obj->addPoint($_=>$_, [192,0,0]);
    $obj->addString($_=>$_, "$_,$_", [192,192,192]);
  }
  $obj->addLabel(4, 45, "Hello World!...  1, 2, 3...  Farewell...", [0,0,255]);

  my $fh=file("lable-test.png")->openw;
  print $fh $obj->draw;
} else {
  diag("Warning: Current directory is not writeable");
}
