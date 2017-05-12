use Test::More tests => 10;

use Gitosis::Config;

ok( my $gc = Gitosis::Config->new(), 'new Gitosis::Config' );
like( $gc->to_string, qr|\Q[gitosis]\E|, 'containts [gitosis]' );
ok( $gc->gitweb('no'), 'set gitweb = no' );
like( $gc->to_string, qr[gitweb = no], 'contains gitweb = no' );
ok( $gc->add_group( { name => 'bar', writable => 'foo baz' } ), 'add group' );
ok( $group = $gc->find_group_by_name('bar'), 'lookup group by name' );
is_deeply( $group->writable, [qw(foo baz)], 'group repos look right' );
isa_ok( $group, 'Gitosis::Config::Group' );
like( $gc->to_string, qr|\Q[group bar]\E|, 'contains [group bar]' );
like( $gc->to_string, qr|\Qwritable = foo baz\E|, 'contains writable' );

