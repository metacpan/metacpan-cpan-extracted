use strict;
use warnings;
use 5.010;

package EntityModel::Plugin::Test;
use EntityModel::Class {
	_isa => [qw(EntityModel::Plugin)],
	test => { type => 'string' },
};
use Test::More;

sub setup {
	my $self = shift;
	my $v = shift;
	ok(defined $v, "Test option received");
}

package EntityModel::TestBasic;
use parent qw{Test::Class};
use Test::More;
use Test::Fatal;
use EntityModel;
no if $] >= 5.017011, warnings => "experimental::smartmatch";

use constant ARTICLE_XML => q{
<entitymodel>
  <name>EMTest</name>
  <schema>emtest</schema>
  <table>
    <name>article</name>
    <schema>emtest</schema>
    <primary>idarticle</primary>
    <field>
      <name>idarticle</name>
      <type>bigserial</type>
      <null>false</null>
    </field>
    <field>
      <name>title</name>
      <type>varchar</type>
      <null>true</null>
    </field>
    <field>
      <name>content</name>
      <type>varchar</type>
      <null>true</null>
    </field>
  </table>
</entitymodel>
};

# Connect to the database on startup
sub init_dbh : Test(startup) {
	my $self = shift;
	my $db = EntityModel::DB->new;
	$self->{db} = $db;
}

# Check the basic option handling for ->new
sub instantiate_option_handling : Test(5) {
	my $self = shift;
	ok(EntityModel->new, 'can init without options');
	ok(EntityModel->new(Test => ''), 'can init with single option');
	ok(EntityModel->new({Test => ''}), 'can init with hashref');
}

# Work out whether we can deal with plugins properly
sub instantiate_plugins : Test(7) {
	my $self = shift;
	ok(my $em = EntityModel->new(), 'init with no options');
	is($em->plugin->count, 0, 'have no plugins loaded');
	ok($em = EntityModel->new(
		Test => ''
	), 'can init with Test plugin');
	is($em->plugin->count, 1, 'have one plugin with Test loaded');
	ok($em = EntityModel->new(
		Test => [ 1 ]
	), 'try options with Test plugin');
}

# Now try bringing in the XML handling
sub use_xml_plugin : Test(6) {
	my $self = shift;
	ok(my $em = EntityModel->new(
		'Load::XML' => \ARTICLE_XML
	), 'use XML plugin');
	is($em->entity->count, 1, 'have a single entity');
	my $e = $em->entity->first;
	isa_ok($e, 'EntityModel::Entity');
	is($e->name, 'article', 'name is correct');
	is(scalar(grep { $_->name ~~ 'title' } $e->field->list), 1, 'have title field');
	is(scalar(grep { $_->name ~~ 'content' } $e->field->list), 1, 'have content field');
}

# Then XML and Perl together
sub use_xml_with_perl_plugin : Test(8) {
	my $self = shift;
	ok(!eval { Entity::Article->can('new') }, 'no Entity::Article yet');
	note "Load XML and apply to Perl";
	{
		ok(my $em = EntityModel->new(
			'Load::XML' => \ARTICLE_XML,
			'Apply::Perl' => {
				namespace => 'Entity',
				baseclass => 'EntityModel::EntityBase',
			}
		), 'use XML and Perl plugins');
		is($em->entity->count, 1, 'have a single entity');
		my $e = $em->entity->first;
		isa_ok($e, 'EntityModel::Entity');
		is($e->name, 'article', 'name is correct');
		can_ok('Entity::Article', 'new', 'create', 'find');
		isa_ok('Entity::Article', 'EntityModel::EntityBase');
		note "Unload EntityModel";
	}
	ok(!eval { Entity::Article->can('new') }, 'no Entity::Article any more');
}

sub checkTable {
	my $self = shift;
	my $tbl = shift;
	my $opt = shift || {};
	$self->{db}->transaction(sub {
		my $db = shift;
		my $sql = q{select 1 from emtest.} . $tbl . q{ limit 1};
		if($opt->{exists}) {
			dies_ok { $db->dbh->do($sql) } "table $tbl exists";
		} else {
			lives_ok { $db->dbh->do($sql) } "table $tbl exists";
		}
	});
}

# Then XML and Perl together
sub use_xml_with_sql_plugin : Test(7) {
	my $self = shift;
	$self->checkTable('article', { exists => 0 });
	$self->{db}->transaction(sub {
		my $db = shift;
		note "Load XML and apply to SQL";
		ok(my $em = EntityModel->new(
			'Load::XML'	=> \ARTICLE_XML,
			'DB'		=> {
				db	=> $db,
			},
			'Apply::SQL'	=> {
				schema	=> 'emtest',
			}
		), 'use XML and SQL plugins');
		is($em->entity->count, 1, 'have a single entity');
		my $e = $em->entity->first;
		isa_ok($e, 'EntityModel::Entity');
		is($e->name, 'article', 'name is correct');
		$self->checkTable('article', { exists => 1 });
		note "Unload EntityModel";
		die "rollback";
	});
	$self->checkTable('article', { exists => 0 });
}

# Then XML, Perl and SQL together
sub use_xml_with_sql_with_perl_plugin : Test(15) {
	my $self = shift;
	$self->checkTable('article', { exists => 0 });
	$self->{db}->transaction(sub {
		my $db = shift;
		note "Load XML and apply to Perl and SQL";
		ok(my $em = EntityModel->new(
			'Load::XML' => \ARTICLE_XML,
			'DB'		=> {
				db	=> $self->{db},
			},
			'Apply::SQL' => { schema => 'emtest' },
			'Apply::Perl' => {
				namespace => 'Entity',
				baseclass => 'EntityModel::EntityBase',
			}
		), 'use XML, SQL and Perl plugins');
		is($em->entity->count, 1, 'have a single entity');
		my $e = $em->entity->first;
		isa_ok($e, 'EntityModel::Entity');
		is($e->name, 'article', 'name is correct');
		$self->checkTable('article', { exists => 1 });
		can_ok('Entity::Article', 'new', 'create', 'find');
		isa_ok('Entity::Article', 'EntityModel::EntityBase');
		ok(my $article = Entity::Article->create({
			content => 'test',
			title => 'test article'
		})->commit, 'create article');
		isa_ok($article, 'Entity::Article');
		my ($rslt) = Entity::Article->find({});
		ok($rslt, 'found article');
		isa_ok($rslt, 'Entity::Article');
		is($rslt->title, $article->title, 'title matches');
		is($rslt->content, $article->content, 'content matches');
		note "Roll back and unload EntityModel";
		die "rollback";
	});
	$self->checkTable('article', { exists => 0 });
}

sub sql_diff_handling : Test(13) {
	my $self = shift;
	$self->checkTable('article', { exists => 0 });
	{
		note "Load XML and apply to SQL";
		ok(my $em = EntityModel->new(
			'Load::XML' => \q{
<entitymodel>
  <name>EMTest</name>
  <schema>emtest</schema>
  <table>
    <name>article</name>
    <schema>emtest</schema>
    <primary>idarticle</primary>
    <field>
      <name>idarticle</name>
      <type>bigserial</type>
      <null>false</null>
    </field>
    <field>
      <name>title</name>
      <type>varchar</type>
      <null>true</null>
    </field>
  </table>
</entitymodel>
},
			'DB'		=> {
				db	=> $self->{db},
			},
			'Apply::SQL' => {
				schema	=> 'emtest',
			}
		), 'use XML and SQL plugins');
		is($em->entity->count, 1, 'have a single entity');
		my $e = $em->entity->first;
		isa_ok($e, 'EntityModel::Entity');
		is($e->name, 'article', 'name is correct');
		lives_ok { $self->{dbh}->do(q{select 1 from emtest.article limit 1}) } 'article table exists';
		ok(hasColumn($self->{dbh}, 'emtest.article', 'title'), 'have title column');
		ok(!hasColumn($self->{dbh}, 'emtest.article', 'content'), 'do not have content column');
		ok($em = EntityModel->new(
			'Load::XML' => \q{
<entitymodel>
  <name>EMTest</name>
  <schema>emtest</schema>
  <table>
    <name>article</name>
    <schema>emtest</schema>
    <primary>idarticle</primary>
    <field>
      <name>idarticle</name>
      <type>bigserial</type>
      <null>false</null>
    </field>
    <field>
      <name>title</name>
      <type>varchar</type>
      <null>true</null>
    </field>
    <field>
      <name>content</name>
      <type>varchar</type>
      <null>true</null>
    </field>
  </table>
</entitymodel>
},
			'DB'		=> {
				db	=> $self->{db},
			},
			'Apply::SQL' => {
				schema	=> 'emtest',
			}
		), 'load article def with extra column');
		lives_ok { $self->{dbh}->do(q{select 1 from emtest.article limit 1}) } 'article table exists';
		ok(hasColumn($self->{dbh}, 'emtest.article', 'title'), 'still have title column');
		ok(hasColumn($self->{dbh}, 'emtest.article', 'content'), 'now have content column');
		note "Unload EntityModel";
	}
	$self->{dbh}->rollback;
	dies_ok { $self->{dbh}->do(q{select 1 from emtest.article limit 1}) } 'article table does not exist any more';
	$self->{dbh}->rollback;
}

sub hasColumn {
	my $dbh = shift;
	my $tbl = shift;
	my $col = shift;
	my $sth = $dbh->column_info(undef, split(/\./, $tbl), $col);
	my $rslt = $sth->fetchall_arrayref
		or return undef;
	return scalar(@$rslt);
}

package main;
use Test::More skip_all => 'incomplete';
Test::Class->runtests;
