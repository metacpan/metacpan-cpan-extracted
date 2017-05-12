# -*- perl -*-
# t/003-get-commits-range.t
use strict;
use warnings;
use Devel::Git::MultiBisect::AllCommits;
use Devel::Git::MultiBisect::Opts qw( process_options );
use Test::More tests => 10;
use Cwd;
use File::Spec;

my $cwd = cwd();

my (%args, $params, $self);
my ($this_commit_range, @commit_ranges, $expect);

my ($good_gitdir, @good_targets, $good_last_before, $good_last);
$good_gitdir = File::Spec->catdir($cwd, qw| t lib list-compare |);
@good_targets = (
    File::Spec->catdir( qw| t 44_func_hashes_mult_unsorted.t |),
    File::Spec->catdir( qw| t 45_func_hashes_alt_dual_sorted.t |),
);
$good_last_before = '2614b2c2f1e4c10fe297acbbea60cf30e457e7af';
$good_last = 'd304a207329e6bd7e62354df4f561d9a7ce1c8c2';
%args = (
    gitdir => $good_gitdir,
    targets => [ @good_targets ],
    last_before => $good_last_before,
    last => $good_last,
);
$params = process_options(%args);
$self = Devel::Git::MultiBisect::AllCommits->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');
$this_commit_range = $self->get_commits_range();
ok($this_commit_range, "get_commits_range() returned true value");
is(ref($this_commit_range), 'ARRAY', "get_commits_range() returned array ref");
$expect = [ qw|
2a2e54af709f17cc6186b42840549c46478b6467
a624024294a56964eca53ec4617a58a138e91568
5c8159f2edd242d04c2203e01b8883d73c44f8ad
99e2ff9c7b1c48c99d5d09527a34cd1f5f2a3ce5
f9c4fa66a23460fa27838e46642bdc9ed204d38c
15f1cd1902f5b929c1b913f72415d559acef1f6c
de0975860ef3f86bcbe9337a4ee1f030ff0a7740
85c6bc9ec7994c9b51d171688b49b089c5db8795
4e55377d7437dac882f90ece86e55e46cef6f43a
d304a207329e6bd7e62354df4f561d9a7ce1c8c2
| ];
is_deeply($this_commit_range, $expect,
	"Got expected commit range");
push @commit_ranges, $this_commit_range;
undef $self;


my ($good_first);
delete $args{last_before};
$good_first = '2a2e54af709f17cc6186b42840549c46478b6467';
$args{first} = $good_first;
$params = process_options(%args);
$self = Devel::Git::MultiBisect::AllCommits->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');
$this_commit_range = $self->get_commits_range();
ok($this_commit_range, "get_commits_range() returned true value");
is(ref($this_commit_range), 'ARRAY', "get_commits_range() returned array ref");
push @commit_ranges, $this_commit_range;
is_deeply($commit_ranges[0], $commit_ranges[1],
	"Got same commit range via either 'last_before' or 'first'");
