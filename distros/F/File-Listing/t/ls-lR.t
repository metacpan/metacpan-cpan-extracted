use strict;
use warnings;
use Test::More;

plan tests => 22;

use File::Listing;

my $dir = do {
  open my $fh, '<', 'corpus/ls-lR.txt';
  local $/;
  <$fh>;
};

{
  check_output( parse_dir($dir, undef, 'unix') );
}

{
  open LISTING, '<', 'corpus/ls-lR.txt';  ## no critic
  check_output( parse_dir(\*LISTING, undef, 'unix') );
}

{
  open my $fh, '<', 'corpus/ls-lR.txt';
  check_output( parse_dir($fh, undef, 'unix') );
}

sub check_output {
  my @dir = @_;

  ok(@dir, 'ok 25');

  for (@dir) {
     my ($name, $type, $size, $mtime, $mode) = @$_;
     $size ||= 0;  # ensure that it is defined
     printf "# %-25s $type %6d  ", $name, $size;
     print scalar(localtime($mtime));
     printf "  %06o", $mode;
     print "\n";
  }

  # Pick out the Socket.pm line as the sample we check carefully
  my ($name, $type, $size, $mtime, $mode) = @{$dir[9]};

  ok($name, "Socket.pm");
  ok($type, "f");
  ok($size, 'ok 8817');

  # Must be careful when checking the time stamps because we don't know
  # which year if this script lives for a long time.
  my $timestring = scalar(localtime($mtime));
  ok($timestring =~ /Mar\s+15\s+18:05/);

  ok($mode, 'mode 0100644');
}

{
  my @dir = parse_dir(<<'EOT');
drwxr-xr-x 21 root root 704 2007-03-22 21:48 dir
EOT

  ok(@dir, 'ok 1');
  ok($dir[0][0], "dir");
  ok($dir[0][1], "d");

  my $timestring = scalar(localtime($dir[0][3]));
  print "# $timestring\n";
  ok($timestring =~ /^Thu Mar 22 21:48/);
}
