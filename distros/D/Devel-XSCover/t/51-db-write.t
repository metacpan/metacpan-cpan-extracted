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
my @objects = map { my ($k, $g) = $reader->filter($reader->parse(slurp($_))); { object => $_, files => $k, generated => $g } } qw(Spike.gcov.txt helper.gcov.txt);
my $xs = Devel::XSCover::XS->new(dir => $dir);
my @maps = $xs->read;

my $tmp = File::Temp->newdir;
my $db  = Cwd::abs_path("$tmp");
my $writer = Devel::XSCover::DB->new(dir => $dir, db => $db, silent => 1);
my ($files, $generated) = $writer->merge(@objects);
my $entries = $writer->entries($files, $generated, @maps);

is_deeply([sort keys %$entries], ['Spike.xs', 'include/spike.h', 'src/helper.c', 'xs/more.xs'], 'four files, no Spike.c');
my $xse = $entries->{'Spike.xs'};
is(scalar @{ $xse->{statement} }, 26, '26 statements in Spike.xs');
is_deeply([ grep { $_->[0] == 47 } @{ $xse->{branch} } ], [
    [47, 'arm 1 of 5', [1, 3]], [47, 'arm 2 of 5', [1, 3]], [47, 'arm 3 of 5', [1, 3]], [47, 'arm 4 of 5', [0, 4]], [47, 'arm 5 of 5', [1, 3]],
], 'the switch is five branches, each arm against the rest');
is_deeply([ grep { $_->[0] == 36 } @{ $xse->{branch} } ], [[36, 'if (a && b)', [2, 1]], [36, 'if (a && b)', [1, 1]]], 'two two-arm branches with the source text');
is_deeply([ grep { $_->[0] == 20 } @{ $xse->{subroutine} } ], [[20, 'Spike::add', 353062], [20, 'Spike::plus', 353062]], 'the XSUB under both names with its wrapper count');
is_deeply([ grep { $_->[0] == 8 } @{ $xse->{subroutine} } ], [[8, 'only_from_one', 2]], 'a plain C function under its C name');
is_deeply($entries->{'xs/more.xs'}{subroutine}, [[4, 'Spike::More::triple', 1], [12, 'Spike::More::child_only', 1], [20, 'Spike::More::exit_only', 0], [28, 'Spike::More::never', 0]], 'the included file');
is_deeply([ map { $_->[1] } @{ $entries->{'include/spike.h'}{statement} } ], [2, 2, 1, 2, 1, 1], 'the header merged across both objects');

my $run = $writer->write($entries);
is($run->{files}, 4, 'four files written');
is($run->{statement}, 26 + 4 + 6 + 7, 'the statements');
is($run->{subroutine}, 9 + 4 + 2 + 1, 'the subroutines: seven XSUBs, the alias and the C helper, four, two, one');
ok(-d $run->{run}, 'the run directory exists');

my $here = Cwd::getcwd();
chdir $dir or die;
my $cover = Devel::Cover::DB->new(db => $db)->merge_runs->cover;
chdir $here;
is_deeply([sort $cover->items], ['Spike.xs', 'include/spike.h', 'src/helper.c', 'xs/more.xs'], 'cover reads the four files back');
my $f = $cover->file('Spike.xs');
is($f->statement->location(27)->[0]->covered, 353062, 'the add statement');
is(scalar @{ $f->branch->location(47) }, 5, 'five branches on the switch line');
is_deeply([ map { $_->name } @{ $f->subroutine->location(20) } ], ['Spike::add', 'Spike::plus'], 'both names on the declaration line');
is($f->subroutine->location(20)->[0]->covered, 353062, 'with the count');
is($cover->file('include/spike.h')->statement->location(7)->[0]->covered, 1, 'the header line summed across objects');
is($cover->file('xs/more.xs')->subroutine->location(20)->[0]->covered, 0, 'exit_only never entered');
is($cover->file('src/helper.c')->branch->location(5)->[0]->text, 'arm 1 of 4', 'the helper switch');

done_testing;
