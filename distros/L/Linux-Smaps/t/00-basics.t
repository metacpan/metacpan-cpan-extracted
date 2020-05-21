use Test::More tests => 17;
use POSIX ();
BEGIN { require_ok('Linux::Smaps') };

POSIX::setlocale( &POSIX::LC_ALL, "C" );
my ($s, $old);

my $fn=$0;
$fn=~s!/*t/+[^/]*$!! or die "Wrong test script location: $0";
$fn='.' unless( length $fn );

$s=Linux::Smaps->new(uninitialized=>1);
ok( !Linux::Smaps::VMA->can('size'),
    'VMA method "size" unknown before first smaps file read' );
ok( !Linux::Smaps->can('shared_dirty'),
    'Smaps method "shared_dirty" unknown before first smaps file read' );
ok $s->new(uninitialized=>1), "Can create from a ref";

$s->filename=$fn.'/t/testcases/smaps32';
$s->lasterror=undef;
$s->update;
ok( Linux::Smaps->can('size'),
    'VMA method "size" known after first smaps file read' );
ok( Linux::Smaps->can('shared_dirty'),
    'Smaps method "shared_dirty" known after first smaps file read' );

is( $s->size('/usr/lib/i386-linux-gnu/libc-2.29.so'), 116 + 1324 + 436 + 8 + 8, 'summary size' );
is( $s->rss('/usr/lib/i386-linux-gnu/libc-2.29.so'), 112 + 788 + 120 + 8 + 8, 'summary rss' );

my $vmas = [
  grep {
    $_->file_name eq '/usr/lib/i386-linux-gnu/libc-2.29.so'
  } $s->vmas
];

is @$vmas, 5, "found 5 vmas for libc";
is_deeply [map { $_->thpeligible } @$vmas], [0, 0, 0, 0, 0], "generic special flags work";

is_deeply [sort $s->names], [
  qw!
/usr/bin/cat
/usr/lib/i386-linux-gnu/gconv/gconv-modules.cache
/usr/lib/i386-linux-gnu/ld-2.29.so
/usr/lib/i386-linux-gnu/libc-2.29.so
/usr/lib/locale/aa_DJ.utf8/LC_COLLATE
/usr/lib/locale/aa_DJ.utf8/LC_CTYPE
/usr/lib/locale/aa_ET/LC_NUMERIC
/usr/lib/locale/bi_VU/LC_NAME
/usr/lib/locale/chr_US/LC_MEASUREMENT
/usr/lib/locale/chr_US/LC_MONETARY
/usr/lib/locale/chr_US/LC_PAPER
/usr/lib/locale/chr_US/LC_TELEPHONE
/usr/lib/locale/en_AG/LC_MESSAGES/SYS_LC_MESSAGES
/usr/lib/locale/en_US.utf8/LC_ADDRESS
/usr/lib/locale/en_US.utf8/LC_IDENTIFICATION
/usr/lib/locale/en_US.utf8/LC_TIME
  !,
], "found all names";

is scalar @{[$s->all]}, scalar @{[$s->vmas]}, "->all in listcontext returns all vmas";
my $all_rss = 0;
$all_rss += $_->rss for $s->all;
is $s->all->rss, $all_rss, "all memory added correctly";

is scalar @{[$s->named]}, scalar @{[$s->all]} - 3, "all - three named sections";
is scalar @{[$s->unnamed]}, 3, "three unamed sections";
is $s->unnamed->rss, 24, "24 kB unnamed rss";
is $s->unnamed->rss + $s->named->rss, $s->all->rss, "unnamed rss + named rss = all rss";

# Local Variables:
# mode: cperl
# End:
