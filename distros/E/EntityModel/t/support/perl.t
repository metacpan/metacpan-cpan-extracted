use strict;
use warnings;
use Test::More tests => 4;
use EntityModel;

my $model = EntityModel->new(
)->load_from(
	Perl => {
		name => 'cpan',
		entity => [ {
			name => 'author',
			primary => 'cpan_id',
			field => [
				{ name => 'cpan_id', type => 'text' },
				{ name => 'fullname', type => 'text' },
				{ name => 'email', type => 'text' },
			],
		}, {
			name => 'distribution',
			primary => 'name',
			field => [
				{ name => 'name', type => 'text' },
				{ name => 'version', type => 'text' },
				{ name => 'file', type => 'text' },
				{ name => 'abstract', type => 'text' },
				{ name => 'idauthor', type => 'text', refer => [
					{ table => 'author', field => 'cpan_id' },
				] },
			],
		}, {
			name => 'module',
			primary => 'name',
			field => [
				{ name => 'name', type => 'text' },
				{ name => 'version', type => 'text' },
				{ name => 'iddistribution', type => 'text', refer => [
					{ table => 'distribution', field => 'name' },
				] },
				{ name => 'abstract', type => 'text' },
				{ name => 'dslip', type => 'text' },
				{ name => 'idauthor', type => 'text', refer => [
					{ table => 'author', field => 'cpan_id' },
				] },
			],
		} ],
	}
)->add_storage(
	'Perl'
)->add_support(
	Perl => { }
);

ok(my $author = Entity::Author->create({
	cpan_id => 'TEAM',
	fullname => 'Tom Molesworth',
	email => 'cpan@entitymodel.com',
}), 'create new author');
isa_ok($author, 'Entity::Author');
is($author->cpan_id, 'TEAM', 'cpan_id matches');
SKIP: {
	skip '::Perl enforces autoinc primary key :(' => 1;
	is($author->id, 'TEAM', 'and is the same as ->id');
}


