use 5.020;
use strict;
use warnings;
use Test::More;
use Devel::XSCover::Build ();

my @flags = Devel::XSCover::Build->new->flags;
is(scalar @flags, 2, 'two make macros');
like($flags[0], qr/^OPTIMIZE=-O0 -g -fprofile-arcs -ftest-coverage -fprofile-update=atomic(?: -fcondition-coverage)?$/, 'OPTIMIZE, with condition coverage when the compiler here is gcc 14 or later');
like($flags[1], qr/^OTHERLDFLAGS=-fprofile-arcs -ftest-coverage$/, 'OTHERLDFLAGS');

my $out = '';
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    my $status = Devel::XSCover::Build->new(dry => 1, make => 'false')->build;
    select $old;
    is($status, 0, 'a dry build runs nothing, so false never fails it');
}
like($out, qr/^xs_cover: running false OPTIMIZE=-O0 -g .* OTHERLDFLAGS=-fprofile-arcs -ftest-coverage$/m, 'the dry build prints the make line');

$out = '';
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    Devel::XSCover::Build->new(dry => 1, silent => 1, make => 'false')->build;
    select $old;
}
is($out, '', 'silent prints nothing');

done_testing;
