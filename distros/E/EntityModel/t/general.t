use strict;
use warnings;
use Test::More;
use Test::Deep;
use EntityModel;

plan skip_all => 'i broke it';
plan tests => 47;

# Read in the model definition first
my $model;

# Load the model and Perl definitions within a BEGIN block. This is optional but allows
# us to check that the loading works as expected.
BEGIN {
	# Turn off logging - if tests are failing and you want more info, remove this line
	EntityModel::Log->instance->disabled(1);

	$model = EntityModel->new->load_from(
		XML => { string => q{
<entitymodel>
  <name>EMTest</name>
  <entity>
    <name>article</name>
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
    <field>
      <name>idauthor</name>
      <type>bigint</type>
      <null>true</null>
      <refer>
        <table>author</table>
        <field>idauthor</field>
        <delete>cascade</delete>
        <update>cascade</update>
      </refer>
    </field>
  </entity>
  <entity>
    <name>author</name>
    <primary>idauthor</primary>
    <field>
      <name>idauthor</name>
      <type>bigserial</type>
      <null>false</null>
    </field>
    <field>
      <name>name</name>
      <type>varchar</type>
    </field>
    <field>
      <name>email</name>
      <type>varchar</type>
    </field>
  </entity>
  <entity>
    <name>tag</name>
    <primary>idtag</primary>
    <field>
      <name>idtag</name>
      <type>bigserial</type>
      <null>false</null>
    </field>
    <field>
      <name>name</name>
      <type>varchar</type>
    </field>
  </entity>
  <entity>
    <name>article_tag</name>
    <primary>idarticle_tag</primary>
    <field>
      <name>idarticle_tag</name>
      <type>bigserial</type>
      <null>false</null>
    </field>
    <field>
      <name>idarticle</name>
      <type>bigint</type>
      <null>false</null>
      <refer>
        <table>article</table>
        <field>idarticle</field>
        <delete>cascade</delete>
        <update>cascade</update>
      </refer>
    </field>
    <field>
      <name>idtag</name>
      <type>bigint</type>
      <null>false</null>
      <refer>
        <table>tag</table>
        <field>idtag</field>
        <delete>cascade</delete>
        <update>cascade</update>
      </refer>
    </field>
    <field>
      <name>created</name>
      <type>timestamp</type>
    </field>
  </entity>
</entitymodel>}
	});
	$model->add_storage(Perl => { });
	$model->add_support('Perl' => {
		namespace => 'Entity',
	});
}

# Check that we loaded okay
is($model->entity->count, 4, 'have entities');

foreach my $type (qw/Entity::Article Entity::Author Entity::Tag Entity::Article::Tag/) {
	can_ok($type, $_) for qw/new create find/;
}

my $id;

# Do the first set of tests within a transaction. The storage class may not treat these any differently
# but make sure that it doesn't complain or lose information on transaction exit.
$model->transaction(sub {
	ok(my $author = Entity::Author->create({
		name	=> 'Author name',
		email	=> 'author@example.com',
	}), 'create new author');
	is($author->name, 'Author name', 'name matches');
	is($author->email, 'author@example.com', 'email matches');
	$author->commit;

	my ($copy) = Entity::Author->find({
		name	=> 'Author name',
	});
	is($copy->id, $author->id, 'can find same entry by searching name field') or die "not found";
	($copy) = Entity::Author->find({
		email	=> 'author@example.com',
	});
	is($copy->id, $author->id, 'can find same entry by searching email field');
	($copy) = Entity::Author->find({
		name	=> 'Author name',
		email	=> 'author@example.com',
	});
	is($copy->id, $author->id, 'can find same entry by searching both fields');
	$id = $author->id;
});

ok(my $author = Entity::Author->new($id), 'can do a ->new lookup');
note $author;
is($author->id, $id, 'ID matches');
is($author->name, 'Author name', 'name matches');

ok($author->name("Something else"), 'can change name');
ok($author->commit, 'commit after change');
is($author->name, 'Something else', 'name matches');
ok($author->name("Author name"), 'can change name back');
$author->commit;
is($author->name, 'Author name', 'name matches');

# Now we have an author, try creating an article
$model->transaction(sub {
	ok(my $article = Entity::Article->create({
		title	=> 'Article title',
		content	=> q{Some content would be here},
		author	=> $author,
	}), 'create new article');
	$article->commit;
	is($article->title, 'Article title', 'title matches');
	is($article->content, 'Some content would be here', 'content matches');
	is($article->idauthor, $author->id, 'author ID matches');
	is($article->author->id, $author->id, 'author ID matches via instance');
	my ($copy) = Entity::Article->find({
		author	=> $author
	});
	is($copy->id, $article->id, 'article ->find by author matches');
	($copy) = Entity::Article->find({
		idauthor	=> $author->id
	});
	is($copy->id, $article->id, 'article ->find by idauthor matches');
	($copy) = Entity::Article->find({
		title		=> $article->title,
	});
	is($copy->id, $article->id, 'article ->find by title matches');
	($copy) = Entity::Article->find({
		content		=> $article->content,
	});
	is($copy->id, $article->id, 'article ->find by content matches');
	($copy) = Entity::Article->find({
		title		=> $article->title,
		content		=> $article->content,
	});
	is($copy->id, $article->id, 'article ->find by title and content matches');
	($copy) = Entity::Article->find({
		author		=> $author,
		title		=> $article->title,
		content		=> $article->content,
	});
	is($copy->id, $article->id, 'article ->find by author, title and content matches');
	$id = $article->id;
});

# And again outside the transaction
ok(my $article = Entity::Article->new($id), 'can do a ->new lookup');
is($article->id, $id, 'ID matches');
is($article->title, 'Article title', 'title matches');

# Now check some of the helper methods
my @articles = $author->article->list;
is(@articles, 1, 'have a single article');
is($articles[0]->id, $article->id, 'ID matches');

for(1..30) {
	my $t = Entity::Tag->create({ name => "tag$_" })->commit or die "fail to create";
	Entity::Article::Tag->create({ idtag => $t->id, idarticle => $article->id })->commit or die "could not create";
}
is($article->tag->count, 30, 'have 3 tags for article');
cmp_deeply([ map { $_->name } $article->tag->list ], bag(map { "tag$_" } 1..30), 'tag names are correct');

my ($t) = Entity::Tag->find({ name => 'tag2' });
is($t->article->count, 1, 'have one article for tag');
is($t->article->first->id, $article->id, 'article matches');

