# render

use Test;
BEGIN { plan tests => 6 };
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't05';
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

# sep
ok(breadcrumbs(path => '/foo/bar/bog.html', sep => '&nbsp;::&nbsp;') eq $result{sep1});
ok(breadcrumbs(path => '/foo/bar/bog.html', sep => ' | ') eq $result{sep2});

# format / format_last
ok(breadcrumbs(path => '/foo/bar/bog.html', sep => '|', format => '<a class="bc" href="%s">%s</a>') eq $result{format1});
ok(breadcrumbs(path => '/foo/bar/bog.html', format_last => '<span class="bclast">%s</span>') eq $result{format2});
ok(breadcrumbs(path => '/foo/bar/bog.html', 
  format => sub { sprintf '<a href="%s">%s</a>', shift, uc(shift) },
  format_last => sub { uc(shift) },
) eq $result{format3});
ok(breadcrumbs(path => '/foo/bar/bog.html', 
  format => sub { ($href, $label) = @_; sprintf '<a target="_blank" href="%s">%s</a>', $href, ($label x 2) },
  format_last => sub { $l = shift; $l x 2 },
) eq $result{format4});

