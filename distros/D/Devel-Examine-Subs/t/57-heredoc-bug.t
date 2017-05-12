use warnings;
use strict;

use Test::More;
use Test::More;
use File::Copy qw(copy);


BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";
}

my $file = 't/test/heredoc.pm';
my $copy = 't/heredoc.copy';

my $des = Devel::Examine::Subs->new(
	file => $file,
	copy => $copy,
);

my $rw = File::Edit::Portable->new;

$des->inject(
	inject_after_sub_def => ['test()'],
);


my @c = $rw->read($copy);

is_deeply([@c[4,5,6,7]], [qw(one two three DOC)], 'heredoc left intact');

is ($c[10], "    test()", 'injects test() properly after sub def');

is ($c[17], "    test()", 'injects test() properly after sub def');

unlink 't/heredoc.copy' or die "can't delete the heredoc.copy test file\n";

is -e 't/heredoc.copy', undef, "heredoc.copy deleted ok";

done_testing();
