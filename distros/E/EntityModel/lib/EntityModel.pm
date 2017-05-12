package EntityModel;
# ABSTRACT: Cross-language event-driven ORM

use EntityModel::Class {
	_isa => [qw(EntityModel::Model)],
	name => { type => 'string' },
	plugin => { type => 'array', subclass => 'EntityModel::Plugin' },
	support => { type => 'array', subclass => 'EntityModel::Support' },
	storage => { type => 'array', subclass => 'EntityModel::Storage' },
	storage_queued => { type => 'array', subclass => 'EntityModel::Storage' },
	cache => { type => 'array', subclass => 'EntityModel::Cache' },
	cache_queued => { type => 'array', subclass => 'EntityModel::Cache' },
	db => { type => 'EntityModel::DB' },
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

our $VERSION = '0.102';

=head1 NAME

EntityModel - manage entity model definitions

=head1 VERSION

version 0.102

=head1 SYNOPSIS

 use EntityModel;
 # Define model
 my $model = EntityModel->new->load_from(
 	JSON => { entity : [
		{ name : 'article', field : [
			{ name : 'idarticle', type : 'bigserial' },
			{ name : 'title', type : 'varchar' },
			{ name : 'content', type : 'text' }
		], primary => { field : [ 'idarticle' ], separator : ':' }
	 ] }
 );
 # Apply PostgreSQL schema (optional, only needed if the model changes)
 $model->apply('PostgreSQL' => { schema => 'datamodel', host => 'localhost', user => 'testuser' });
 # Create Perl classes
 $model->apply('Perl' => { namespace => 'Entity', baseclass => 'EntityModel::EntityBase' });

 my $article = Entity::Article->create(
 	title => 'Test article',
	content => 'Article content'
 )->done(sub {
  	my $article = shift;
	say "ID was " . $article->id;
 })->fail(sub {
 	die 'Failed to create new article';
 });
 Entity::Article->find(
 	title => 'Test article'
 )->first(sub {
 	my $match = shift;
 	$match->title('Revised title');
 	die "Instances of the same object should always be linked, consistent and up-to-date"
 		unless $article->title eq $match->title;
 });

=head1 DESCRIPTION

This module provides a data storage abstraction system (in the form of an Object Relational Model) for accessing
backend storage from Perl and other languages. The intent is to take a model definition and generate or update
database tables, caching layer and the corresponding code (Perl/C++/JS) for accessing data.

A brief comparison and list of alternatives is in the L</MOTIVATION> and L</SEE ALSO> sections, please check there
before investing any time into using this module.

Eventually a full set of documentation will be added to L<http://entitymodel.com/documentation.html>
but for now see the examples further down in this document.

=head1 METHODS

=cut

use Module::Load ();

use EntityModel::Transaction;
use EntityModel::Entity;
use EntityModel::Field;
use EntityModel::Query;

=head2 new

Constructor. Given a set of options, will load any plugins specified (and/or the defaults), applying
other config options via the appropriate plugins.

Typically run without options:

 my $model = EntityModel->new;

The exciting things happen elsewhere. See:

=over 4

=item * L</load_from>

=item * L</add_storage>

=item * L</add_plugin>

=back

=cut

sub new {
	my $class = shift;

	my @def;
	if(ref $_[0] ~~ 'HASH') {
		@def = %{$_[0]};
	} elsif(ref $_[0] ~~ 'ARRAY') {
		@def = @{$_[0]};
	} else {
		@def = @_;
	}

	my $self = bless { }, $class;

	# Apply plugins and options
	while(@def) {
		my ($k, $v) = splice @def, 0, 2;
		$self->load_plugin($k => $v);
	}

	return $self;
}

=head2 load_from

Read in a model definition from the given L<EntityModel::Definition>-based source.

Parameters:

=over 4

=item * Type - must be a valid L<EntityModel::Definition> subclass, such as 'Perl', 'JSON' or 'XML'.

=item * Definition - dependent on the subclass, typically the filename or raw string data.

=back

Common usage includes reading from inline Perl:

 $model->load_from(
  Perl => {
   name => 'kvstore',
   entity => [
    name => 'object',
    primary => 'iditem',
    field => [
     { name => 'iditem', type => 'bigserial' },
     { name => 'key', type => 'varchar' },
     { name => 'value', type => 'varchar' },
    ],
   ],
  }
 );

or the equivalent from JSON:

 $model->load_from(
  JSON => \q{
   "name" : "kvstore",
   "entity" : [
    "name" : "object",
    "primary" : "iditem",
    "field" : [
     { "name" : "iditem", "type" : "bigserial" },
     { "name" : "key", "type" : "varchar" },
     { "name" : "value", "type" : "varchar" }
    ]
   ]
  }
 );

=cut

sub load_from {
	my $self = shift;
	my ($type, $value) = @_;

	my $class = "EntityModel::Definition::$type";
	$self->load_component($class);

	$class->new->load(
		model	=> $self,
		source	=> $value
	);
	return $self;
}

=head2 save_to

Saves the current model definition to a definition.

Parameters:

=over 4

=item * Type - must be a valid L<EntityModel::Definition> subclass, such as 'Perl', 'JSON' or 'XML'.

=item * Definition - dependent on the subclass, typically the filename or scalarref to hold raw string data.

=back

You might use something like this to store the current model to a file in JSON format:

 $model->save_to(
  JSON => 'model.json'
 );

or this to copy everything from a source model to a target model (wiping everything
in the target in the process):

 my $target = EntityModel->new;
 $source->save_to(
  model => $target
 );

=cut

sub save_to {
	my $self = shift;
	my ($type, $value) = @_;

	my $class = "EntityModel::Definition::$type";
	$self->load_component($class);

	$class->new->save(
		model	=> $self,
		target	=> $value
	);
	return $self;
}

=head2 load_component

Brings in the given component if it hasn't already been loaded.

Typically used by internal methods only.

=cut

sub load_component {
	my $self = shift;
	my $class = shift;
	unless($class->can('new')) {
		Module::Load::load($class);
		$class->register;
	}
	return $self;
}

=head2 add_support

Bring in a new L<EntityModel::Support> class for this L<EntityModel::Model>.

Example:

 $model->add_support(Perl => { namespace => 'Entity' });

=cut

sub add_support {
	my ($self, $name, $v) = @_;
	logDebug("Load support for [%s]", $name);
	my $class = 'EntityModel::Support::' . $name;
	$self->load_component($class);

	my $obj = $class->new($self, $v);
	$obj->setup($v);
	$obj->apply_model($self);
	$self->support->push($obj);
	return $self;
}

=head2 add_storage

Add backend storage provided by an L<EntityModel::Storage> subclass.

Example:

 $model->add_storage(PostgreSQL => { service => ... });

=cut

sub add_storage {
	my ($self, $name, $v) = @_;
	delete $self->{backend_ready};
	logDebug("Load storage for [%s]", $name);
	my $class = $name;
	try { Module::Load::load($class) } unless try { $class->can('new') };
	unless(try { $class->can('new') }) {
		$class = 'EntityModel::Storage::' . $name;
		Module::Load::load($class);
	}

	my $obj = $class->new($self, $v);
	$self->storage_queued->push($obj);
	$self->add_handler_for_event(
		backend_ready => sub {
			my $self = shift;
			$self->{backend_ready} = 1;
			0 # one-shot
		}
	);
	$obj->setup($v);
	$obj->wait_for_backend($self->sap( sub {
		my ($model, $obj) = @_;
		$obj->apply_model($model);
		$model->storage->push($model->storage_queued->shift);
		$model->invoke_event(backend_ready =>) unless $model->storage_queued->count;
		0; # one-shot event
	}));
	return $self;
}

=head2 backend_ready

Returns true if all storage and cache backends are ready, false otherwise.

=cut

sub backend_ready { shift->{backend_ready} }

=head2 wait_for_backend

Requests an event to run after all backends signal readiness.

=cut

sub wait_for_backend {
	my $self = shift;
	my $code = shift;
	return $code->($self) if $self->backend_ready;
	$self->add_handler_for_event( backend_ready => sub { $code->(@_); 0 });
	return $self;
}

=head2 add_cache

Add backend cache provided by an L<EntityModel::Storage> subclass.

Example:

 $model->add_cache(PostgreSQL => { service => ... });

=cut

sub add_cache {
	my ($self, $name, $v) = @_;
	logDebug("Load cache for [%s]", $name);
	my $class = $name;
	try { Module::Load::load($class) } unless try { $class->can('new') };
	unless(try { $class->can('new') }) {
		$class = 'EntityModel::Cache::' . $name;
		Module::Load::load($class);
	}

	my $obj = $class->new($self, $v);
	$obj->setup($v);
	$obj->apply_model($self);
	$self->cache->push($obj);
	return $self;
}

=head2 add_plugin

Adds a plugin. Currently the definition of a 'plugin' is somewhat nebulous,
but L<EntityModel::Web> is one example.

=cut

sub add_plugin {
	my $self = shift;
	my ($name, $v) = @_;
	my $plugin;
	if(eval { $name->isa('EntityModel::Plugin') }) {
		$plugin = $name;
	} else {
		my $mod = 'EntityModel::' . $name;
		Module::Load::load($mod);
		$plugin = $mod->new;
	}
	$plugin->register($self);
	$self->plugin->push($plugin);
	return $self;
}

=head2 transaction

Run the coderef in a transaction.

Notifies all the attached L<EntityModel::Storage> instances that we want a transaction, runs the
code, then signals end-of-transaction.

=cut

sub transaction {
	my $self = shift;
	my $code = shift;
	return EntityModel::Transaction->new(
		code	=> $code,
		model	=> $self,
		param	=> [ @_ ]
	);
}

=head2 load_plugin

Used internally, see L</add_plugin>. Will disappear in the future.

=cut

sub load_plugin {
	my ($self, $name, $v) = @_;
	logDebug("Load plugin [%s]", $name);
	my $class = 'EntityModel::Plugin::' . $name;
	unless(eval { $class->can('new') }) {
		Module::Load::load($class);
	}
	logDebug("Activating plugin [%s]", $name);
	my $obj = $class->new($self, $v);
	$obj->setup($v);
	$self->plugin->push($obj);
	return $self;
}

=head2 handler_for

Returns the handler for a given entry in the L<EntityModel::Definition>.

=cut

sub handler_for {
	my $self = shift;
	my $name = shift;
	logDebug("Check for handlers for [%s] node", $name);
	my @handler;
	$self->plugin->each(sub {
		push @handler, $_[0]->handler_for($name);
	});
	return @handler;
}

sub defer {
	my $self = shift;
	my $code = shift;

}

{
my $model;
sub default_model {
	my $class = shift;
	if(@_) {
		my $old_model = $model;
		$model = shift;
		return $old_model;
	}
	$model ||= EntityModel->new;
	return $model
}
}

=head2 DESTROY

Unload all plugins on exit.

=cut

sub DESTROY {
	my $self = shift;
	$self->plugin->each(sub {
		$_[0]->unload;
	});
}

1;

__END__

=head2 ENTITY MODELS

A model contains metadata and zero or more entities.

Each entity typically represents something that is able to be instantiated as an object, such as a
row in a table. Since this module is heavily biased towards SQL-style applications, most of the entity
definition is similar to SQL-92, with some additional features suitable for ORM-style access via other
languages (Perl, JS, C++).

An entity definition primarily contains the following information - see L<EntityModel::Entity> for more
details:

=over 4

=item * B<name> - the name of the entity, must be unique in the model

=item * B<type> - typically 'table'

=item * B<description> - a more detailed description of the entity and purpose

=item * B<primary> - information about the primary key

=back

Each entity may have zero or more fields:

=over 4

=item * B<name> - the unique name for this field

=item * B<type> - standard SQL type for the field

=item * B<null> - true if this can be null

=item * B<reference> - foreign key information

=back

Additional metadata can be defined for entities and fields. Indexes apply at an entity level.
They are used in table construction and updates to ensure that common queries can be optimised,
and are also checked in query validation to highlight potential performance issues.

=over 4

=item * B<name> - unique name for the index

=item * B<type> - index type, typically one of 'gin', 'gist', or 'btree'

=item * B<fields> - list of fields that are indexed

=back

The fields in an index can be defined as functions.

Constraints include attributes such as unique column values.

Models can also contain additional information as defined by plugins - see L<EntityModel::Plugin>
for more details on this.

=head1 USAGE

An entity model can be loaded from several sources. If you have a database definition:

 create table test ( id int, name varchar(255), url text );

then loading the SQL plugin with the database name will create a single entity holding
two fields.

If you also load L<EntityModel::Plugin::Apply::Perl>, you can access this table as follows:

 my $tbl = Entity::Test->create({ name => 'Test', url => '/there' })->commit;
 my ($entity) = Entity::Test->find({ name => 'Test' });
 is($orig->id, $entity->id, 'found same id');

=head1 IMPLEMENTATION

Nearly all classes use L<EntityModel::Class> to provide basic structure including accessors
and helper functions and methods. This also enables strict, warnings and Perl 5.10 features.

Logging is handled through L<EntityModel::Log>, which imports functions such as logDebug.

Arrays and hashes are typically wrapped using L<EntityModel::Array> and L<EntityModel::Hash>
respectively, similar in concept to L<autobox>.

For error handling, an L<EntityModel::Error> object is returned - this allows chained method
calling without having to wrap in eval or check the result of each step when you don't care
about failure. The last method in the chain will return false in boolean context.

=head1 OVERVIEW

The current L<EntityModel::Model> can be read from a number of sources:

=over 4

=item * L<EntityModel::Definition::XML> - XML structured definition holding the entities, fields and any additional
plugin-specific data.  All information is held in the content - no attributes are used, allowing this format to be
interchangeable with JSON and internal Perl datastructures.

=item * L<EntityModel::Definition::JSON> - standard Javascript Object Notation format.

=item * L<EntityModel::Definition::Perl> - nested Perl datastructures, with the top level being a hashref. Note that
this is distinct from the Perl class/entity structure described later.

=back

Aside from entities, models can also contain plugin-specific information
such as site definition or database schema. It is also possible - but not
recommended - to store credentials such as database user and password.

Once a model definition has been loaded, it can be applied to one or more of the following:

=over 4

=item * L<EntityModel::Support::SQL> - database schema

=item * L<EntityModel::Support::Perl> - Perl classes

=item * L<EntityModel::Support::CPP> - C++ classes

=item * L<EntityModel::Support::JS> - Javascript code

=back

The SQL handling is provided as a generic DBI-compatible layer with additional support in subclasses
for specific databases. Again, Note that the L<EntityModel::Support::SQL> is intended for applying the
model to the database schema, rather than accessing the backend storage. The L<EntityModel::Support>
classes apply the model to the API, so in the case of the database this involves creating and updating
tables. For Perl, this dynamically creates a class structure in memory, and for C++ or JS this will
export the required support code for inclusion in other projects.

In terms of accessing backend storage, each of the language-specific support options provides an API
which can communicate with one or more backend storage implementations, rather than being tightly coupled
to a data storage method. Typically the Perl backend would interact directly with the database, and C++/JS
would use a REST API against a Perl server.

=head2 BACKEND STORAGE

Backend storage services are provided by subclasses of L<EntityModel::Storage>.

=over 4

=item * L<EntityModel::Storage::PostgreSQL> - PostgreSQL database support

=item * L<EntityModel::Storage::MySQL> - MySQL database support

=item * L<EntityModel::Storage::SQLite> - SQLite3 database support

=back

=head2 CACHING

Cache layers are handled by L<EntityModel::Cache> subclasses.

=over 4

=item * L<EntityModel::Cache::MemcachedFast> - memcached layer using L<Cache::Memcached::Fast>.

=item * L<EntityModel::Cache::Perl> - cache via Perl variables

=back

=head2 USAGE EXAMPLE

Given a simple JSON model definition:

 { entity : [
 	{ name : 'article', field : [
		{ name : 'idarticle', type : 'bigserial' },
		{ name : 'title', type : 'varchar' },
		{ name : 'content', type : 'text' }
	], primary => { field : [ 'idarticle' ], separator : ':' }
 ] }

this would create or alter the C<article> table to meet this definition:

 create table "article" (
 	idarticle bigserial,
	title varchar,
	content text,
	primary key (idarticle)
 )

Enabling the Perl plugin would grant access via Perl code:

 my $article = Entity::Article->create(title => 'Test article', content => 'Article content')
 say "ID was " . $article->id;
 my ($match) = Entity::Article->find(title => 'Test article');
 $match->title('Revised title');
 die "Instances of the same object should always be linked, consistent and up-to-date"
 	unless $article->title eq $match->title;

with the equivalent through Javascript being:

 var article = Entity.Article.create({ title : 'Test article', 'content' : 'Article content' });
 alert("ID was " + article.id());
 var match = Entity.Article.find({ title : 'Test article' })[0];
 match.title('Revised title');
 if(article.title() != match.title())
 	alert("Instances of the same object should always be linked, consistent and up-to-date");

or in C++:

 Entity::Article article = new Entity::Article().title('Test article').content('Article content');
 std::cout << "ID was a.id() << std::endl;
 Entity::Article *match = Entity::Article::find().title('Test article').begin();
 match->title('Revised title');
 if(article->title() != match->title())
	 throw new std::string("Instances of the same object should always be linked, consistent and up-to-date");

The actual backend implementation may vary between these, but the intention is to maintain a recognisable,
autogenerated API across all supported languages. The C++ implementation may inherit from a class that writes
directly to the database, for example, and the Javascript code could be designed to run in a web browser
accessing the resources through HTTP or as a node.js implementation linked directly to the database, but
the top-level code should not need to care which underlying storage method is being used.

=head2 ASYNCHRONOUS MODEL ACCESS

Since backend storage response times can vary, it may help to use an asynchronous API for accessing entities.
Given the 'article' example from earlier, the Perl code is now:

 my $article = Entity::Article->create(
 	title => 'Test article',
	content => 'Article content'
 )->done(sub {
 	my $a = shift;
	say "ID was " . $a->id;
 })->fail(sub {
 	die 'Failed to create the requested article :(';
 });
 Entity::Article->find(title => 'Test article')->each(sub {
 	my $match = shift;
	$match->title('Revised title');
	die "Instances of the same object should always be linked, consistent and up-to-date"
		unless $article->title eq $match->title;
 })->none(sub {
	die 'Nothing found';
 });

=head2 EXPORTING MODEL DEFINITIONS

Although it is possible to reverse-engineer the model in some cases, such as SQL, normally this is not
advised. This may be useful however for a one-off database structure import, by writing the results to
a model config file in JSON or XML format:

 my $model = EntityModel::Plugin::Apply::SQL->loadFrom(
 	db => $db,
	schema => $schema
 );
 $model->export(xml => 'model.xml');

Once the model has been exported any further updates should be done in the model definition file rather
than directly to the database if possible, since this would allow the generation of suitable upgrade/downgrade
scripts.

Currently there is support for SQL and Perl model export, but not for Javascript or C++.

=head3 AUDITING

Audit tables are generated by default in the _audit schema, following the same naming convention as the audited
tables with the addition of the following columns:

=over 4

=item * audit_action - one of:

=over 4

=item * B<Insert> - regular insert or mass import (such as PostgreSQL COPY statement)

=item * B<Update> - updates directly through database or through the L<EntityModel> API

=item * B<Delete> - manual or API removal

=back

and indicates the action that generated this audit entry.

=item * B<audit_date> - timestamp of this action

=item * B<audit_context> - description of the action, typically the command that was called

=back

=head2 CLASS STRUCTURE

The primary classes used for interaction with models include:

=over 4

=item * L<EntityModel> - top level class providing helper methods

=item * L<EntityModel::Definition> - classes for dealing with model definitions

=item * L<EntityModel::Support> - language-specific support

=back

The following classes provide features that are used throughout the code:

=over 4

=item * L<EntityModel::DB> - wrapper for DBI providing additional support for transaction handling

=item * L<EntityModel::Query> - database query handling

=item * L<EntityModel::Template> - wrapper around Template Toolkit

=item * L<EntityModel::Cache> - simple cache implementation using L<Cache::Memcached::Fast> by default

=back

See L<http://entitymodel.com/documentation.html> for more details and diagrams.

=head1 MOTIVATION

Some of the primary motivations for this distribution over any of the existing approaches (see next
section for some alternatives):

=over 4

=item * B<Event-based operation> - backend storage requests run 'asynchronously' where possible,
allowing the application to continue with other tasks while waiting for database queries to complete.

=item * B<Support for languages other than Perl> - most projects end up using at least one other
language, e.g. web-based projects typically have some Javascript on the frontend talking to the
Perl backend.

=item * B<Configurable with a single file> - I like to be able to export, backup and diff the entity
layout and having this in a single file as JSON or XML is more convenient for me than using multiple
Perl packages. This also allows the configuration to be used by non-Perl code, since it's a rare project
these days that only involves a single language.

=item * B<Backend abstraction> - the conceptual model generally doesn't need to be tied to a particular
backend, for example the Perl side of things could either talk directly to a database or use a webservice.

=item * B<Easy editing and visualisation> - I like to have the option of using other tools such as
diagram editors to add/modify the entity layout, rather than having to create or edit Perl files. This
helps to separate actual code changes from configuration / layout issues; the L<EntityModel> distribution
can be installed once and for many common applications no further custom code should be required.

=item * B<Flexibility> - although too much interdependence is generally a bad thing, being able to include
other concepts in the configuration file has been useful for tasks such as building websites with common
features.

=back

Clearly none of these features are necessarily unique to L<EntityModel>, and many of the alternative
systems described in the next section could be adapted to support the above requirements.

=head1 SEE ALSO

There are plenty of other ORM implementations available on CPAN, one of which may be more suited to your
needs than this is. These are the ones I've found so far:

=head2 Asynchronous ORMs

The list here is sadly lacking:

=over 4

=item * L<Async::ORM|https://github.com/vti/async-orm> - asynchronous ORM, see also article in L<http://showmetheco.de/articles/2010/1/mojolicious-async-orm-and-dbslayer.html>

=back

=head2 Synchronous ORMs

If you're happy for the database to tie up your process for an indefinite amount of time, you're in
luck - there's a nice long list of modules to choose from here:

=over 4

=item * L<DBIx::Class> - appears to be the most highly regarded and actively developed one out there, and
the available features, code quality and general stability are far in advance of this module. Unless you
need the L<EntityModel> multi-language or asynchronous support features I would strongly encourage looking
at L<DBIx::Class> first

=item * L<Rose::DB::Object> - written for speed, appears to cover most of the usual requirements, personally
found the API less intuitive than other options but it appears to be widely deployed

=item * L<Fey::ORM> - newer than the other options, also appears to be reasonably flexible

=item * L<DBIx::DataModel> - UML-based Object-Relational Mapping (ORM) framework

=item * L<Alzabo> - another ORM which includes features such as GUI schema editing and SQL diff

=item * L<Class::DBI> - generally considered to be superceded by L<DBIx::Class>, which provides a compatibility
layer for existing applications

=item * L<Class::DBI::Lite> - like L<Class::DBI> but lighter, presumably

=item * L<ORMesque> - lightweight class-based ORM using L<SQL::Abstract>

=item * L<Oryx> - Object persistence framework, meta-model based with support for both DBM and regular RDBMS
backends, uses tied hashes and arrays

=item * L<Tangram> - An object persistence layer

=item * L<KiokuDB> - described as an "Object Graph storage engine" rather than an ORM

=item * L<DBIx::DataModel> - ORM using UML definitions

=item * L<Jifty::DBI> - another ORM

=item * L<ORLite> - minimal SQLite-based ORM

=item * L<Ormlette> - object persistence, "heavily influenced by Adam Kennedy's L<ORLite>". "light and fluffy", apparently!

=item * L<ObjectDB> - another lightweight ORM, currently has only L<DBI> as a dependency

=item * L<ORM> - looks like it has support for MySQL, PostgreSQL and SQLite

=item * L<fytwORM> - described as a "bare minimum ORM used for prototyping / proof of concepts"

=item * L<DBR> - Database Repository ORM

=item * L<SweetPea::Application::Orm> - specific to the L<SweetPea> web framework

=item * L<Jorge> - ORM Made simple

=item * L<Persistence::ORM> - looks like a combination between persistent Perl objects and standard ORM

=item * L<Teng> - lightweight minimal ORM

=item * L<Class::orMapper> - DBI-based "easy O/R Mapper"

=item * L<UR|https://github.com/genome/UR> - class framework and object/relational mapper (ORM) for Perl

=item * L<DBIx::NinjaORM> - "Flexible Perl ORM for easy transitions from inline SQL to objects"

=item * L<DBIx::Oro> - Simple Relational Database Accessor

=item * L<LittleORM> - Moose-based ORM

=item * L<Storm> - another Moose-based ORM

=item * L<DBIx::Mint> - "A mostly class-based ORM for Perl"

=back

=head2 Database interaction

=over 4

=item * L<DBI::Easy> - seems to be a wrapper around L<DBI>

=item * L<AnyData> - interface between L<DBI> and arbitrary data sources such as XML or HTML

=item * L<DBIx::ThinSQL> - helpers for SQL statements

=item * L<DB::Evented> - event-based wrapper for L<DBI>-like behaviour, uses L<AnyEvent::DBI>

=back

Since this is Perl, there are probably many more, if you have something which isn't in the above list (or a better
description of any of the existing entries), please raise via RT or email.

Distributions which provide class structure and wrappers around the Perl OO mechanism are likewise covered by
several other CPAN modules, with the clear winner here in the forms of L<Moose>, L<Moo> and derivatives.

Eventually I'll try to put up a better set of comparisons on L<http://entitymodel.com>.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2013. Licensed under the same terms as Perl itself.
