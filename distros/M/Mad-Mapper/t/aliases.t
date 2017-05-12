use t::Helper;
use t::User;

my $pg = t::Helper->pg;

# change table name
t::User::table('mad_mapper_has_many_users');

# create tables
$pg->db->query('DROP TABLE IF EXISTS mad_mapper_has_many_groups');
$pg->db->query('DROP TABLE IF EXISTS mad_mapper_has_many_users');
$pg->db->query('CREATE TABLE mad_mapper_has_many_users (id SERIAL PRIMARY KEY, email TEXT, name TEXT)');
$pg->db->query(<<'HERE');
CREATE TABLE mad_mapper_has_many_groups
  (id SERIAL PRIMARY KEY, user_id INTEGER REFERENCES mad_mapper_has_many_users (id), name TEXT)
HERE

my $user = t::User->new(db => $pg->db);

$user->email('test@example.com');
is $user->save, $user, 'save() returned $self';
my $group = $user->add_group(name => 'foo')->save;

$user = t::User->new(db => $pg->db, group => $group->name)->load;
is $user->email, 'test@example.com', 'found user by group';

done_testing;
