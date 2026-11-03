use 5.020;
use strict;
use warnings;
use Test::More;
use Cwd ();
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Gcov ();
use Devel::XSCover::XS ();
use Devel::XSCover::DB ();

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };

my $dir = 't/fixtures/spike';
sub slurp { my $f = File::Spec->catfile(qw(t fixtures gcov llvm), shift); open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }
my $reader = Devel::XSCover::Gcov->new(dir => $dir, silent => 1, generated => ['Spike.c']);
my ($kept, $aside) = $reader->filter($reader->parse(slurp('Spike.gcov.txt')));
my @maps = Devel::XSCover::XS->new(dir => $dir)->read;
my $tmp = File::Temp->newdir;
my $db  = Cwd::abs_path("$tmp");
my $writer = Devel::XSCover::DB->new(dir => $dir, db => $db, silent => 1);
$writer->write($writer->entries($writer->merge({ object => 'Spike.gcda', files => $kept, generated => $aside }), @maps));

my $here = Cwd::getcwd();
chdir $dir or die;
my $cover = Devel::Cover::DB->new(db => $db)->merge_runs->cover;
chdir $here;
my ($guard) = @{ $cover->file('Spike.xs')->branch->location(95) };
is_deeply([ $guard->values ], [1, 0], 'the guard: gcov arm 0 taken once, arm 1 never');
ok($guard->uncoverable(0), 'the comment "uncoverable branch true" marks arm 0, the one gcov lists first');
ok(!$guard->uncoverable(1), 'and not arm 1');
ok($guard->error, 'which leaves the line in error, since the marked arm is the covered one and the other is not');
my ($plain) = @{ $cover->file('Spike.xs')->branch->location(10) };
ok(!$plain->uncoverable(0) && !$plain->uncoverable(1), 'a line without the comment has no mark');

done_testing;
