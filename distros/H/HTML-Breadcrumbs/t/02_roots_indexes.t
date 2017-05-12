# roots and indexes functionality

use strict;
use vars q($count);

BEGIN { $count = 9 };
use Test::More tests => $count;
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't02';
my %result = ();
$test = "t/$test" if -d "t/$test";
die "missing data dir $test" unless -d "$test";
opendir DATADIR, "$test" or die "can't open $test";
for (readdir DATADIR) {
  next if m/^\./;
  open FILE, "<$test/$_" or die "can't read $test/$_";
  $result{$_} = <FILE>;
  chomp $result{$_};
  close FILE;
}
close DATADIR;

# roots
is(breadcrumbs(path => '/foo/bar/bog.html', roots => [ '/xxx' ]), $result{bog}, "roots 1 ok");
is(breadcrumbs(path => '/foo/bar/bog.html', roots => '/foo'), $result{foo}, "roots 2 ok");
is(breadcrumbs(path => '/foo/bar/bog.html', roots => [ '/', '/foo', '/foo/bar' ]), $result{bar}, "roots 3 ok");
is(breadcrumbs(path => '/foo/bar/bog.html', roots => [ '/', '/foo/bar', '/foo' ]), $result{bar}, "roots 4 ok");

# indexes
is(breadcrumbs(path => '/foo/bar/bog.html', indexes => [ 'index.html' ]), $result{bog}, "indexes 1 ok");
is(breadcrumbs(path => '/foo/bar/bog.html', indexes => [ 'bog.html' ]), $result{bar2}, "indexes 2 ok");
is(breadcrumbs(path => '/foo/bar/bog.html', indexes => [ 'index.html', 'index.php', 'bog.html' , 'home.html' ]), $result{bar2}, "indexes 3 ok");
is(breadcrumbs(path => '/foo/bar/bog.html', indexes => 'bog.html'), $result{bar2}, "indexes 4 ok");

is(breadcrumbs(path => '/foo/bar/index.html'), $result{bar2}, "standard ok");
