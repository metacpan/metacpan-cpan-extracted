# omit

use Test::More tests => 27;
use HTML::Breadcrumbs qw(breadcrumbs);

# Load result strings
my $test = 't03';
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

# die on warnings
BEGIN { $SIG{'__WARN__'} = sub { die $_[0] } }

# omit
is(breadcrumbs(path => '/foo/bar/bog.html', omit => '/foo'), $result{foo}, 'omit absolute');
is(breadcrumbs(path => '/foo/bar/bog.html', omit => [ '/foo' ]), $result{foo}, 'omit absolute + arrayref');
is(breadcrumbs(path => '/cgi-bin/test/forms/help.html', omit => [ '/cgi-bin/', '/cgi-bin/test' ]), $result{cgi}, 'omit absolute + arrayref 2');
ok(! defined eval { breadcrumbs(path => '/cgi-bin/test/forms/help.html', omit => 'cgi-bin/test') }, 'omit non-absolute path');
is(breadcrumbs(path => '/foo/bar/bog.html', omit => 'foo'), $result{foo}, 'omit 1');
is(breadcrumbs(path => '/foo/bar/bog.html', omit => 'bar'), $result{bar}, 'omit 2');
is(breadcrumbs(path => '/foo/bar/bog.html', omit => 'bog.html'), $result{bog}, "omit element final");
is(breadcrumbs(path => '/foo/bar/bog.html', omit => '/foo/bar/bog.html'), $result{bog}, "omit absolute final");
is(breadcrumbs(path => '/cgi-bin/test/forms/help.html', omit => [ 'cgi-bin', 'test' ]), $result{cgi}, 'omit elements + arrayref 2');

# omit_regex
is(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => '\d+'), $result{bar}, 'omit_regex element');
is(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => '\d+$'), $result{bar}, 'omit_regex element anchored 1');
is(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => '^\d+$'), $result{n123}, 'omit_regex element anchored 2');
is(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => [ '\d+' ]), $result{bar}, 'omit_regex arrayref element');
is(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => [ '\d+$' ]), $result{bar}, 'omit_regex arrayref element anchored 1');
is(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => [ '^\d+$' ]), $result{n123}, 'omit_regex arrayref element anchored 2');
is(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => [ 'oo' ]), $result{foon}, 'omit_regex arrayref element');
is(breadcrumbs(path => '/foo/n123/bog.html', omit_regex => [ '/n\d+' ]), $result{n123}, 'omit_regex arrayref element anchored 1');
is(breadcrumbs(path => '/foo/n123/bar/n678/bog.html', omit_regex => [ '/foo/n\d+' ]), $result{n678}, 'omit_regex arrayref absolute 1');
is(breadcrumbs(path => '/foo/n123/bar/n678/bog.html', omit_regex => [ '/foo/n1' ]), $result{n678full}, 'omit_regex arrayref absolute 2');
is(breadcrumbs(path => '/foo/bar/bog.html', omit_regex => 'bog'), $result{bog}, "omit_regex element final");
is(breadcrumbs(path => '/foo/bar/bog.html', omit_regex => '^bog'), $result{bog}, "omit_regex element final");
is(breadcrumbs(path => '/foo/bar/bog.html', omit_regex => '.*\.html$'), $result{bog}, "omit_regex element final");
is(breadcrumbs(path => '/foo/bar/bog.html', omit_regex => '^og'), $result{full1}, "omit_regex element no-match");
is(breadcrumbs(path => '/foo/bar/bog.html', omit_regex => '/foo/bar/bog.*'), $result{bog}, "omit_regex absolute final");
is(breadcrumbs(path => '/foo/bar/bog.html', omit_regex => '/foo/bar/bog'), $result{full1}, "omit_regex absolute non-anchored no-match");
is(breadcrumbs(path => '/foo/bar/bog.html', omit_regex => '/foo/bar/.*\.html'), $result{bog}, "omit_regex absolute final");
is(breadcrumbs(path => '/foo/bar/bog.html', omit_regex => '/foo/bar/.*\.htm'), $result{full1}, "omit_regex absolute non-anchored no-match");

