# labels

use strict;
use Test::More tests => 13;
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't04';
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

# Hashref labels
my $labels = {};
is(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels), $result{bog});
$labels = { '/foo' => 'Foo Foo' };
is(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels), $result{foo});
$labels = { '/foo/' => 'Foo Foo' };
is(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels), $result{foo});
$labels = { 'foo' => 'Foo Foo' };
is(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels), $result{foo});
$labels = { '/bar' => 'Bar Bar' };
is(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels), $result{bog});
$labels = { '/foo/bar' => 'Bar Bar' };
is(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels), $result{bar});
$labels = { '/foo/bar/' => 'Bar Bar' };
is(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels), $result{bar});
$labels = { 'bar' => 'Bar Bar' };
is(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels), $result{bar});
$labels = { '/foo/bar/bog.html' => 'All Things Bog' };
is(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels), $result{bog2});
$labels = { 'bog.html' => 'All Things Bog' };
is(breadcrumbs(path => '/foo/bar/bog.html', labels => $labels), $result{bog2});

# Subref labels
is(breadcrumbs(path => '/foo/bar/bog.html', labels => sub { } ), $result{bog});
is(breadcrumbs(path => '/foo/bar/bog.html', labels => sub { $_[0] eq '/' ? 'HOME' : uc($_[1]) } ), $result{uc});
sub label1 {
  my ($fq_elt, $elt, $last) = @_;
  $elt =~ s/\.[^.]+// if $last;
  return $fq_elt eq '/' ? 'TOP' : uc($elt);
}
is(breadcrumbs(path => '/foo/bar/bog.html', labels => \&label1 ), $result{uc2});
