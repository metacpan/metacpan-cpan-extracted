# bad data

use strict;
use vars q($count);

BEGIN { $count = 4 };
use Test::More tests => $count;
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't06';
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
    exit 0;
  }
  $t += $inc;
}

my $out;

# Standard 
$out = breadcrumbs(path => '/foo/bar/bog.html', sep => ' &gt; ',);
report $out, "standard";
is($out, $result{standard}, "standard path ok");

# Brackets in path
$out = breadcrumbs(path => '/foo/bar/bog()');
report $out, "brackets";
is($out, $result{brackets}, "bracket path ok");

# URL path should die not absolute path
ok(!defined eval { breadcrumbs(path => 'http://www.example.com/foo/bar/bog.html') },
    'url path dies');

# undef path
ok(!defined eval { breadcrumbs(path => undef) }, 'undef path dies');


# arch-tag: a94c9fc7-fb88-4ffd-838f-d80593ed3531
