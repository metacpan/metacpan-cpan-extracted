use t::Helper;
use t::User;

my $pg = t::Helper->sqlite;
my $user = t::User->new(db => $pg->db);
my $err;

$pg->db->query('CREATE TABLE mad_mapper_simple_users (id integer primary key autoincrement, email text, name text)');

ok !$user->in_storage, 'not in_storage';

$user->email('test@example.com');
is $user->save, $user, 'save() returned $self';
is $pg->db->query('SELECT COUNT(*) AS n FROM mad_mapper_simple_users')->hash->{n}, 1, 'one row in database';
ok $user->in_storage, 'user is in_storage';

$user->email('foo@example.com');
$user->save(
  sub {
    (my $user, $err) = @_;
    Mojo::IOLoop->stop;
  },
);
$err = 'not saved';
Mojo::IOLoop->start;
ok !$err, 'save() updated' or diag $err;
is $pg->db->query('SELECT COUNT(*) AS n FROM mad_mapper_simple_users')->hash->{n}, 1, 'one row in database';

$user = t::User->new(db => $pg->db, email => 'test@example.com')->load;
ok !$user->in_storage, 'could not find user in storage';
ok !$user->id,         'no id';

$user = t::User->new(db => $pg->db, email => 'foo@example.com')->load;
ok $user->in_storage, 'found user in storage';
ok $user->id,         'got id';

is $user->delete, $user, 'delete() return $self';
ok !$user->in_storage, 'not in_storage';

$pg->db->query('DROP TABLE mad_mapper_simple_users');

done_testing;
