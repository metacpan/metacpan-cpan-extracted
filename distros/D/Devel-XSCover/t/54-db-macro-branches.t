use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use File::Temp ();
use Devel::XSCover::DB ();

my $dir = File::Temp->newdir;
open my $fh, '>', File::Spec->catfile($dir, 'm.c') or die;
print $fh <<'C';
int f(int x)
{
    sv_setiv(GvSVn(gv), 0);
    if (!SvOK(sv))
        return 1;
    x = x > 0 ? x : -x;   /* if this were a comment it would not count */
    return a && b;
    /* if (never) */
    } while (0);
    SvGETMAGIC(sv);
}
C
close $fh;
my $files = { 'm.c' => {
    lines     => { 3 => 40, 4 => 40, 5 => 1, 6 => 40, 7 => 40, 8 => 0, 9 => 40, 10 => 40 },
    functions => [],
    blocks    => [
        { line => 3,  arms => [39, 0] },
        { line => 4,  arms => [40, 0] },
        { line => 4,  arms => [1, 39] },
        { line => 6,  arms => [20, 20] },
        { line => 7,  arms => [30, 10] },
        { line => 8,  arms => [0, 0] },
        { line => 9,  arms => [0, 40] },
        { line => 10, arms => [40, 0] },
    ],
} };

my $e = Devel::XSCover::DB->new(dir => "$dir", silent => 1)->entries($files, {});
is_deeply([ map { $_->[0] } @{ $e->{'m.c'}{branch} } ], [4, 4, 6, 7, 9],
    'kept: both blocks of the if line, the ?: line, the && line, the while line; dropped: the macro calls and the commented if');
$e = Devel::XSCover::DB->new(dir => "$dir", silent => 1, macro_branches => 1)->entries($files, {});
is(scalar @{ $e->{'m.c'}{branch} }, 8, 'macro_branches keeps every block');
is(scalar @{ $e->{'m.c'}{statement} }, 8, 'the statements are untouched either way');

done_testing;
