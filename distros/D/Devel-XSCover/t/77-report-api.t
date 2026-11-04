use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Cwd ();
use File::Spec ();
use File::Temp ();
use XSCoverTest ();

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
plan skip_all => 'no cover script found' unless XSCoverTest::cover_script();

my ($tmp, $db, $dir, $perl_tmp, $perl) = XSCoverTest::report_db();
my $out_tmp = File::Temp->newdir;
my $outdir  = Cwd::abs_path("$out_tmp");
my $here    = Cwd::getcwd();
my $lib     = Cwd::abs_path(-d 'blib/lib' ? 'blib/lib' : 'lib');
my $script  = File::Spec->catfile($outdir, 'report.pl');
open my $sh, '>', $script or die "$script: $!";
print $sh <<'PERL';
use Devel::Cover::DB ();
use Devel::Cover::Report::XSCover ();
my ($dbdir, $outdir) = @ARGV;
my $db = Devel::Cover::DB->new(db => $dbdir)->merge_runs;
my @criteria = $db->collected;
$db->calculate_summary(map { $_ => 1 } @criteria);
my @files = sort $db->cover->items;
Devel::Cover::Report::XSCover->report($db, { file => \@files, show => { map { $_ => 1 } @criteria, 'total' }, outputdir => $outdir });
PERL
close $sh;

chdir $dir or die "$dir: $!";
my $out = do {
    local $ENV{DEVEL_COVER_SELF}    = 1;
    local $ENV{DEVEL_COVER_OPTIONS} = "-dir,$here,+select,/Devel/Cover/Report/XSCover,+ignore,.";
    `"$^X" "-I$lib" "$script" "$db" "$outdir" 2>&1`;
};
chdir $here;

is($out, "done.\n", 'report called from Perl says done, since nothing asked it to be silent');
opendir my $dh, $outdir or die "$outdir: $!";
my @pages = sort grep { /\.html\z/ } readdir $dh;
is_deeply(\@pages, [ sort 'coverage.html', 'Spike-xs.html', 'include-spike-h.html', 'src-helper-c.html', 'xs-more-xs.html', map { (my $n = $_) =~ s/\W/-/g; "$n.html" } "$perl/lib/Spike.pm" ], 'the pages go to the output directory given');
open my $fh, '<', File::Spec->catfile($outdir, 'coverage.html') or die;
my $summary = do { local $/; <$fh> };
like($summary, qr/<title>Coverage summary<\/title>/, 'the summary page has its default title without get_options');
like($summary, qr/<td class="pc c\d st" data-v="88\.0" title="statements: 22 of 25">/, 'and the numbers of the database');
open $fh, '<', File::Spec->catfile($outdir, 'Spike-xs.html') or die;
my $xs = do { local $/; <$fh> };
like($xs, qr/<p class="crumb"><a href="coverage\.html">summary<\/a>/, 'a file page links to the default summary name');

done_testing;
