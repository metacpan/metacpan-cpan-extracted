use Test::More tests => 11;
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
$s->filename=$fn.'/t/smaps';
$s->lasterror=undef;
$s->update;
ok( Linux::Smaps->can('size'),
    'VMA method "size" known after first smaps file read' );
ok( Linux::Smaps->can('shared_dirty'),
    'Smaps method "shared_dirty" known after first smaps file read' );

is( $s->size('/opt/apache22-worker/sbin/httpd'), 408, 'summary size' );
is( $s->rss('/opt/apache22-worker/sbin/httpd'), 32, 'summary rss' );
is( $s->shared_clean('/opt/apache22-worker/sbin/httpd'), 12,
    'summary shared_clean' );
is( $s->shared_dirty('/opt/apache22-worker/sbin/httpd'), 0,
    'summary shared_dirty' );
is( $s->private_clean('/opt/apache22-worker/sbin/httpd'), 12,
    'summary private_clean' );
is( $s->private_dirty('/opt/apache22-worker/sbin/httpd'), 8,
    'summary private_dirty' );

# Local Variables:
# mode: perl
# End:
