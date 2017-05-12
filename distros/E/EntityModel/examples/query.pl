#!/usr/bin/perl
use strict;
use warnings;
use EntityModel;
my $model = EntityModel->new;

#$model->add_loop($loop);

# Simple query:
#  select idarticle
#  from article a
#  where title like 'Test%'
Entity::Article->find({
	title	=> qr/^Test/,
});

# Nested conditions
#  select idarticle
#  from article a
#  inner join author au
#  where au.name = 'Tom Molesworth'
Entity::Article->find({
	author	=> {
		name => 'Tom Molesworth'
	}
});

#  select idarticle
#  from article a
#  inner join author au
#  where au.name = 'Tom Molesworth'
#  or a.title = 'Test'
Entity::Article->find({
	author	=> {
		name => 'Tom Molesworth',
	},
	-or => title => 'Test'
});

#  select idarticle
#  from article a
#  inner join author au
#  where au.name = 'Tom Molesworth'
#  and a.title = 'Test'
Entity::Article->find({
	author	=> {
		name => 'Tom Molesworth',
	},
	-and => title => 'Test'
});

# 2-level nesting with no data from intermediate table required:
# just skip the table and go directly to the joining table.
#  select idarticle
#  from article a
#  inner join author_tag at on at.idauthor = a.idauthor
#  where at.name = 'editor'
Entity::Article->find({
	author	=> {
		tag	=> {
			name => 'editor'
		}
	},
});


#  select	ar.idarticle,
#  		sum(case t.name when 'staff' then 1 else 0 end) as "tagged_staff",
#  		sum(case t.name when 'editor' then 1 else 0 end) as "tagged_editor"
#  from		article ar
#  inner join	author_tag at
#  on		aut.idauthor = ar.idauthor
#  inner join	tag t
#  on		at.idtag = t.idtag
#  where	t.txt in ('staff', 'editor')
#  and		title ilike 'Test%'
#  group by	ar.idarticle
#  having	tagged_staff > 0
#  and		tagged_editor > 0
Entity::Article->find({
	author	=> {
		tag	=> {
			name	=> { -all => [qw(staff editor)] },
		}
	},
	title	=> qr/^Test/i,
})->each(sub {

})->done(sub {

});
# Alternative using subquery:
#  select	ar.idarticle
#  from		article ar
#  inner join	(
#  	select		at.idauthor
#  	from		author_tag at
#  	inner join	tag t on t.idtag = at.idtag
#  	group by	at.idauthor
#  	having		sum(case t.name when 'staff' then 1 else 0 end) > 0
#  	and		sum(case t.name when 'editor' then 1 else 0 end) > 0
#  ) as x
#  where	title ilike 'Test%'

# The find method returns a collection of all matched elements.
Entity::Article->find();

# ->create is used for single entities
Entity::Article->create({
	title	=> 'Test Article index ' . $_,
	content	=> 'Article content would be here'
}) for 0..999;

# Mass creation can be handled with the ->populate method. This will mass load data
# into the underlying tables and may disable indexes or perform other cleanup operations
# to ensure that large quantities of data can be loaded as quickly as possible.
Entity::Article->populate(
	fields	=> [qw(title content)],
	data	=> [
		[ ]
	],
);

# Individual entities can be updated or removed via ->update and ->remove.
# These actions can also be applied through the collection interface.
Entity::Article->update(thing => 17);
Entity::Article->find({ title => 'Test' })->remove;

# The entire table can be cleared using ->truncate
Entity::Article->truncate;

Entity::Article->populate(
);

=pod

Author -> author_tag -> Tag

Many-to-many relationships provide additional opportunities for linking. For a simple author/tag link,
you could list authors which have:
* All [these tags]
* None of [these tags]
* Any of [these tags]
* One of [these tags]
Each of these modes requires grouping on the main table, after which additional operations can be
performed using aggregate functions:
* all => sum(case field when value then 1 else 0) having field > 0 for values
* none => sum(case field when value then 1 when value2 then 1 else 0) for values having sum = 0
* any => sum(case field when value then 1 when value2 then 1 else 0) for values having sum > 0
* one => sum(case field when value then 1 else 0) having (sum field) + (sum field2) = 1 for values



 select		ar.idarticle
 from		article ar
 inner join	article_author aa on aa.idarticle = ar.idarticle
 inner join	(
  	select		at.idauthor
  	from		author_tag at
  	inner join	tag t on t.idtag = at.idtag
  	group by	at.idauthor
  	having		sum(case t.name when 'staff' then 1 else 0 end) > 0
  	and		sum(case t.name when 'editor' then 1 else 0 end) > 0
 ) as x on aa.idauthor = x.idauthor
 where	title like 'Test%';

Start off with all intermediate tables included. A later optimisation pass could perhpas elide any tables
which do not contribute to the final result.

Article -> Author -> Address -> City -> Tag

Project -> Issue -> Email -> Commit -> Tag


create table author (
	idauthor bigserial primary key,
	name text
);
create index a_name on author(name);

create table article (
	idarticle bigserial primary key,
	title text,
	content text
);
create index a_title on article(title);

create table tag (
	idtag bigserial primary key,
	name text
);
create index t_name on tag(name);

create table article_tag (
	idarticle_tag bigserial primary key,
	idarticle bigint references article(idarticle) on delete cascade on update cascade,
	idtag bigint references tag(idtag) on delete cascade on update cascade
);
create index at_article on article_tag(idarticle);
create index at_tag on article_tag(idtag);
create table author_tag (
	idauthor_tag bigserial primary key,
	idauthor bigint references author(idauthor) on delete cascade on update cascade,
	idtag bigint references tag(idtag) on delete cascade on update cascade
);
create index aut_author on author_tag(idauthor);
create index au_tag on author_tag(idtag);

create table article_author (
	idarticle_author bigserial primary key,
	idarticle bigint references article(idarticle) on delete cascade on update cascade,
	idauthor bigint references author(idauthor) on delete cascade on update cascade
);
create index aa_article on article_author(idarticle);
create index aa_author on article_author(idauthor);

=cut

