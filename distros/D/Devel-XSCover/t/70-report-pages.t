use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Spec ();
use XSCoverTest ();

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
plan skip_all => 'no cover script found' unless XSCoverTest::cover_script();

my ($tmp, $db, $dir, $perl_tmp, $perl) = XSCoverTest::report_db();
my $out = XSCoverTest::run_report($db, $dir);
unlike($out, qr/error|Can't|warn/i, 'cover ran the report without complaint') or diag $out;

opendir my $dh, $db or die;
my @html = sort grep { /\.html\z/ } readdir $dh;
is_deeply(\@html, [ sort
    'Spike-xs.html', 'coverage.html', 'include-spike-h.html',
    (map { (my $n = $_) =~ s/\W/-/g; "$n.html" } "$perl/lib/Spike.pm"),
    'src-helper-c.html', 'xs-more-xs.html',
], 'the summary and one page per file, nothing else');
rewinddir $dh;
my @other = grep { !/\.html\z/ && !/^\./ } readdir $dh;
is_deeply([sort @other], [qw(cover.14 digests runs structure)], 'no other file written beside the database');

done_testing;
