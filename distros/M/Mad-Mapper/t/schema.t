use Mojo::Base -strict;
use Test::More;

eval <<'HERE' or die $@;
package User;
use Mad::Mapper -base;
use Mojo::UserAgent;
pk 'id';
col forename => '';
col surname => 'Doe';
col email => sub { lc sprintf '%s@%s.com', $_[0]->forename, $_[0]->surname };
has _ua => sub { Mojo::UserAgent->new };
sub name { sprintf '%s, %s', $_[0]->surname, $_[0]->forename }
1;
HERE

ok(User->can($_), "user can $_") for qw( id forename surname email _ua name );

is User->table, 'users', 'table';
is_deeply [User->columns], [qw( forename surname email )], 'columns';

my $user = User->new;
is $user->id,      undef, 'id';
is $user->surname, 'Doe', 'surname';
isa_ok($user->_ua, 'Mojo::UserAgent');
is $user->name, 'Doe, ', 'name';
is $user->forename('Lucy'), $user, 'forename';
is $user->email, 'lucy@doe.com', 'email';
is_deeply($user->TO_JSON, {id => undef, forename => 'Lucy', surname => 'Doe', email => 'lucy@doe.com'}, 'TO_JSON');

eval <<'HERE' or die $@;
package Model::UserAgent;
use Mad::Mapper -base;
pk 'id';
1;
HERE

ok(Model::UserAgent->can($_), "UserAgent can $_") for (qw( id table ));
is(Model::UserAgent->new->table, 'user_agents','class decamelized to table');

done_testing;
