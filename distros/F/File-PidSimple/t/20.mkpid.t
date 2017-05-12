use Test::More tests => 4;
use File::Spec;

BEGIN {
  use_ok('File::PidSimple');
}

my $p = File::PidSimple->new( piddir => File::Spec->tmpdir );
ok( !defined( $p->running ), "We should not run" );
$p->write;
my $pid = $p->running;
ok( ( $pid and $pid == $$ ), "Pid is not the same as in pidfile $$ <=> $pid" );
$p->remove;
ok( !defined( $p->running ), "We should not have a pidfile" );
