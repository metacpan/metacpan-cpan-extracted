# Base functionality

use Test;
BEGIN { plan tests => 28 };
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't01';
my %result = ();
$test = "t/$test" if -d "t/$test";
die "missing data dir $test" unless -d $test;
opendir DATADIR, "$test" or die "can't open $test";
for (readdir DATADIR) {
  next if m/^\./;
  open FILE, "<$test/$_" or die "can't read $test/$_";
  $result{$_} = <FILE>;
  chomp $result{$_};
  close FILE;
}
close DATADIR;

# Procedural interface
$ENV{SCRIPT_NAME} = '/foo/bar/bog.html';
ok($ENV{SCRIPT_NAME} eq '/foo/bar/bog.html');
ok(breadcrumbs() eq $result{bog});
delete $ENV{SCRIPT_NAME};
ok(! exists $ENV{SCRIPT_NAME});
ok(! defined eval { breadcrumbs() });
ok(! defined eval { breadcrumbs( foo => 1 ) });
ok(! defined eval { breadcrumbs( path => 'foo' ) });
ok(breadcrumbs(path => '/foo/bar/bog.html') eq $result{bog});
ok(breadcrumbs(path => '/foo/bar/') eq $result{bar});
ok(breadcrumbs(path => '/foo/bar') eq $result{bar});
ok(breadcrumbs(path => '/foo/') eq $result{foo});
ok(breadcrumbs(path => '/foo') eq $result{foo});
ok(breadcrumbs(path => '/') eq $result{home});
ok(breadcrumbs(path => '/cgi-bin/barBar/bar345/bog.html') eq $result{bog2});
ok(breadcrumbs(path => '/Level 1/The Next Level/bar/bog.html') eq $result{bog3});

# OO interface
$ENV{SCRIPT_NAME} = '/foo/bar/bog.html';
ok($ENV{SCRIPT_NAME} eq '/foo/bar/bog.html');
ok(HTML::Breadcrumbs->new()->render() eq $result{bog});
delete $ENV{SCRIPT_NAME};
ok(! exists $ENV{SCRIPT_NAME});
ok(! defined eval { HTML::Breadcrumbs->new()->render() });
ok(! defined eval { HTML::Breadcrumbs->new( foo => 1 ) });
ok(! defined eval { HTML::Breadcrumbs->new( path => 'foo' )->render() });
ok(HTML::Breadcrumbs->new(path => '/foo/bar/bog.html')->render() eq $result{bog});
ok(HTML::Breadcrumbs->new(path => '/foo/bar/')->render() eq $result{bar});
ok(HTML::Breadcrumbs->new(path => '/foo/bar')->render() eq $result{bar});
ok(HTML::Breadcrumbs->new(path => '/foo/')->to_string() eq $result{foo});
ok(HTML::Breadcrumbs->new(path => '/foo')->render() eq $result{foo});
ok(HTML::Breadcrumbs->new(path => '/')->to_string() eq $result{home});
ok(HTML::Breadcrumbs->new(path => '/cgi-bin/barBar/bar345/bog.html')->render() eq $result{bog2});
ok(HTML::Breadcrumbs->new(path => '/Level 1/The Next Level/bar/bog.html')->render() eq $result{bog3});
