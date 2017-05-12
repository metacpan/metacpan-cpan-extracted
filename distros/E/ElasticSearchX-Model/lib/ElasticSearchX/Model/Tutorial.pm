#
# This file is part of ElasticSearchX-Model
#
# This software is Copyright (c) 2016 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package ElasticSearchX::Model::Tutorial;
$ElasticSearchX::Model::Tutorial::VERSION = '1.0.2';
# ABSTRACT: Tutorial for ElasticSearchX::Model
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ElasticSearchX::Model::Tutorial - Tutorial for ElasticSearchX::Model

=head1 VERSION

version 1.0.2

=head1 INTRODUCTION

In this tutorial we are going to walk through the Elasticsearch example
on L<http://www.elasticsearch.org/>. Go ahead and read it first,
this gives you a good insight into how Elasticsearch works and how
L<ElasticSearchX::Model> can help to make it even more elastic.

=head1 DOCUMENTS

Elasticsearch is a document-based storage system. Even though it states
that it is schema free, it is not recommended to use Elasticsearch
without defining a proper schema or mapping, as Elasticsearch calls it.

L<ElasticSearchX::Model::Document> takes care of that. The Elasticsearch example
consists of two types: C<tweet> and C<user>. The C<tweet> type
contains the properties C<user>, C<post_date> and C<message>. The C<user>
type contains only the C<name> property. Using L<ElasticSearchX::Model::Document>
this looks like:

 package MyModel::Tweet;
 use Moose;
 use ElasticSearchX::Model::Document;

 has id        => ( is => 'ro', id => [qw(user post_date)] );
 has user      => ( is => 'ro', isa => 'Str' );
 has post_date => ( is => 'ro', isa => 'DateTime', required => 1, default => sub { DateTime->now } );
 has message   => ( is => 'rw', isa => 'Str', index => 'analyzed' );

 package MyModel::User;
 use Moose;
 use ElasticSearchX::Model::Document;

 has nickname => ( is => 'ro', isa => 'Str', id => 1 );
 has name     => ( is => 'ro', isa => 'Str' );

You might be wondering why there is an additional C<id> attribute and a
C<nickname>. The C<id> attribute in the Tweet class is build dynamically
by concatenating the values of C<user> and C<post_date>. this value is
digested using SHA1 and used as id for the document. If you want to
change the message of the tweet, you don't have to delete the old record
and add a new one but simply change the message and reindex the document.
Since the id will stay the same, the new record will overwrite the old one.
Also, you don't have to keep track of incrementing numerical document ids.

In the C<User> class, the C<nickname> attribute acts as id. Since it does not
depend on the value of any other attribute, the id matches the nickname.

Elasticsearch will assign a random id to the document if there is
no id attribute.

=head1 MAPPING

Each document belongs to a type. Think of it as a table in a relational
database. And each type belongs to an index, which corresponds to a database.

Modeling indices and types with L<ElasticSearchX::Model> is pretty easy
and the types have actually already been built: the meta objects of the
document classes describe the types. They include all the necessary
information to build a type mapping. You can even use L<MooseX::Types::Structured>
to build deepy nested structures that will be translated to C<object>
properties in Elasticsearch. L<DateTime> attributes become a C<Date> type
and so on.

Indices are defined in a model class:

 package MyModel;
 use Moose;
 use ElasticSearchX::Model;

 index twitter => ( namespace => 'MyModel' );

This is all you need to define the index and its types. The namespace option
of the index C<twitter> will load all classes in the C<MyModel> namespace
and add them to the twitter index. Actually, you don't even have to define
the namespace in this case, since the namespace defaults to the name of the
model class. You can also load types explicitly by defining a C<types> option:

 index twitter => ( types => [qw(MyModel::Tweet MyModel::User)] );

Make sure that the classes are loaded. See L<ElasticSearchX::Model::Index> for all
the available options.

To deploy the indices and mappings to Elasticsearch, simply call

 my $model = MyModel->new;
 $model->deploy;

This will try to connect to an Elasticsearch instance on 127.0.0.1:9200.
See L<ElasticSearchX::Model/es> for more information.

=head1 INDEXING

Indexing describes the process of adding documents to types.

 use DateTime;

 my $twitter = $model->index('twitter');
 my $timestamp = DateTime->now;
 my $tweet = $twitter->type('tweet')->put({
     user => 'mo',
     post_date => $timestamp,
     message => 'Elastic baby!',
 }, { refresh => 1 });

 $twitter->type('tweet')->count; # 1

The first parameter contains the property/value pairs. The C<post_date>
property is special because it is a L<DateTime> object. Objects are
being deflated prior to insertion. This is handled by
L<MooseX::Attribute::Deflator> and is configured in
L<ElasticSearchX::Model::Document::Types>. You can easily add deflators
for other objects.

Since the C<post_date> property is required and has a C<default>, you
don't even have to it to C<put>. ElasticSearchX::Model will automatically
build values from required attributes. If there is no builder or default,
it will throw an exception.

The second parameter to L<ElasticSearchX::Model::Document::Set/put> tells
Elasticsearch to refresh the index immediately. Otherwise it can
take up to one second for the server to refresh and the subsequent
call to L<ElasticSearchX::Model::Document::Set/count> will return C<0>.

If you index large numbers of documents, it is advised to call
L<ElasticSearchX::Model::Index/refresh> once you are finished and not
on every put.

=head1 RETRIEVING

Documents can be retrieved either with their id or by providing
the properties that define the id:

 my $tweet_copy = $twitter->type('tweet')->get($tweet->id);
 # or
 my $tweet_copy = $twitter->type('tweet')->get({
     user      => 'mo',
     post_date => $timestamp,
 });

Objects that have been deflated (i.e. C<post_date>) will be inflated
again. Thus, C<< $tweet_copy->post_date >> is a DateTime object
again.

If you don't really care about objects or need extra speed, you can set
L<ElasticSearchX::Model::Documents::Set/inflate> to C<0>. This will return
the raw response from Elasticsearch.

 $twitter->type('tweet')->raw->get($tweet->id);

=head1 SEARCHING AND SCROLLING

Elasticsearch is I<You know, for Search>. L<ElasticSearchX::Model::Set> tries
to help you with its very verbose query syntax.

 my @tweets = $twitter->type('tweet')->filter({
      term => { user => 'mo' }
  })->query({
      field => { 'message.analyzed' => 'baby' }
  })->size(100)->all;

If you need to retrieve large amounts of data, you probably want to scroll
through the results, which is much faster and safer than scrolling manually
using L<ElasticSearchX::Model::Set/from>.

 my $iterator = $twitter->type('tweet')->scroll;
 while(my $tweet = $iterator->next) {
     # do something with $tweet
 }

For extra speed use C<< $twitter->type('tweet')->raw->scroll >> which will
skip the object inflation and give you the raw HashRef.

=head1 REINDEXING

Elasticsearch allows you to create aliases for each index. This makes it easy
to reindex to a new index, and change the alias once the reindexing is done,
to the new index. This is how you do it with ElasticSearchX::Model.

 package MyModel;
 use Moose;
 use ElasticSearchX::Model;

 index twitter => ( namespace => 'MyModel', alias_for => 'twitter_v1' );

This will create an index called C<twitter_v1> in Elasticsearch and an
alias C<twitter>. To reindex data, you simply add a second index with
a different name but the same document classes:

 index twitter_v2 => ( namespace => 'MyModel' );

Now deploy the new index and start reindexing your data to the new index:

 $model->deploy;

 my $old = $model->index('twitter');
 my $new = $model->index('twitter_v2');
 my $iterator = $old->type('tweet')->size(1000)->scroll;
 while(my $tweet = $iterator->next) {
     $tweet->message('something else');
     $tweet->index($new);
     $tweet->put;
 }

Afterwards, you simply remove the C<twitter_v2> index and set the C<alias_for>
attribute on index C<twitter> to C<twitter_v2>. You have to call
C<< $model->deploy >> again, which will automatically update the aliases.

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
