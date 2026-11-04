use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Cwd ();
use File::Spec ();
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover::Gcov ();
use Devel::XSCover::XS ();
use Devel::XSCover::DB ();

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
plan skip_all => 'no cover script found' unless XSCoverTest::cover_script();

my $dir = 't/fixtures/spike';
sub slurp { my $f = File::Spec->catfile(qw(t fixtures gcov llvm), shift); open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }
my $reader = Devel::XSCover::Gcov->new(dir => $dir, silent => 1, generated => ['Spike.c']);
my @objects = map { my ($k, $g) = $reader->filter($reader->parse(slurp($_))); { object => $_, files => $k, generated => $g } } qw(Spike.gcov.txt helper.gcov.txt);
my @maps = Devel::XSCover::XS->new(dir => $dir)->read;
my $tmp = File::Temp->newdir;
my $db  = Cwd::abs_path("$tmp");
my $writer = Devel::XSCover::DB->new(dir => $dir, db => $db, silent => 1);
$writer->write($writer->entries($writer->merge(@objects), @maps));

my $text = XSCoverTest::run_cover($db, $dir, '-silent', '-report', 'text');
like($text, qr/^Spike\.xs\s+88\.0\s+83\.3\s+100\.0\s/m, 'Spike.xs has stmt, bran and sub percentages');
like($text, qr/^File\s+stmt\s+bran\s+sub\s+total$/m, 'and the report has those three columns and no cond, pod or time');
like($text, qr/^xs\/more\.xs\s+50\.0\s+n\/a\s+50\.0\s+50\.0/m, 'the included file: half the statements, half the subs');
like($text, qr/^include\/spike\.h\s+100\.0/m, 'the header merged to full statement coverage');
unlike($text, qr/^Spike\.c\b/m, 'the generated c is not a file in the report');
unlike($text, qr/inline\.h/, 'nothing of perl');
like($text, qr/arm 4 of 5/, 'the switch arms are in the branch report');
like($text, qr/Spike::plus/, 'the alias is in the subroutine report');
like($text, qr/only_from_one/, 'and the C helper');

done_testing;
