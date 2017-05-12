# bad data

use strict;
use vars q($count);

BEGIN { $count = 2 };
use Test::More tests => $count;
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't07';
my %result = ();
$test = "t/$test" if -d "t/$test";
die "missing data dir $test" unless -d "$test";
{
  opendir my $dir, "$test" or die "can't open $test";
  for (readdir $dir) {
    next if m/^\./;
    open my $file, "<$test/$_" or die "can't read $test/$_";
    {
      local $/ = undef;
      $result{$_} = <$file>;
    }
    chomp $result{$_};
  }
}

my $print = shift @ARGV || 0;
my $t = 1;
sub report {
  my ($data, $file, $inc) = @_;
  $inc ||= 1;
  if ($print == $t) {
    print STDERR "--> $file\n";
    print $data;
    print "\n";
    exit 0;
  }
  $t += $inc;
}

my $out;

# Simple root map
$out = breadcrumbs(path => '/foo/bar/bog.html', 
    map => { '/' => '/home.html' });
report $out, "map1";
is($out, $result{map1}, "map1 ok");

# More complex mappings
$out = breadcrumbs(path => '/foo/bar/bog.html', 
  map => { 
    '/' => '/home.html',
    '/foo/bar' => '/foo/bar/home.html',
    'foo' => '/foo.html',
  });
report $out, "map2";
is($out, $result{map2}, "map2 ok");


# arch-tag: 0c057a20-5e7f-431a-a1a9-6c095c4f8473
