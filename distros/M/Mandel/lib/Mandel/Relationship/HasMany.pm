package Mandel::Relationship::HasMany;
use Mojo::Base 'Mandel::Relationship';
use Mojo::Util;
use Mango::BSON 'bson_dbref';

has add_method_name    => sub { sprintf 'add_%s',    shift->accessor };
has search_method_name => sub { sprintf 'search_%s', shift->accessor };

sub monkey_patch {
  shift->_monkey_patch_all_method->_monkey_patch_add_method->_monkey_patch_search_method;
}

sub _monkey_patch_all_method {
  my $self     = shift;
  my $search   = $self->search_method_name;
  my $accessor = $self->accessor;

  Mojo::Util::monkey_patch(
    $self->document_class,
    $accessor,
    sub {
      my ($doc, $cb) = @_;
      my $cached = delete $doc->{fresh} ? undef : $doc->_cache($accessor);

      # Blocking
      unless ($cb) {
        return $cached if $cached;
        return $doc->_cache($accessor => $doc->$search->all);
      }

      if ($cached) {
        $doc->$cb('', $cached);
      }
      else {
        $doc->$search->all(
          sub {
            my ($collection, $err, $objs) = @_;
            $doc->_cache($accessor => $objs) unless $err;
            $doc->$cb($err, $objs);
          }
        );
      }

      return $doc;
    }
  );

  return $self;
}

sub _monkey_patch_add_method {
  my $self          = shift;
  my $foreign_field = $self->foreign_field;
  my $accessor      = $self->accessor;

  Mojo::Util::monkey_patch(
    $self->document_class,
    $self->add_method_name,
    sub {
      my ($doc, $obj, $cb) = @_;
      my $cached = $doc->_cache($accessor);

      if (ref $obj eq 'HASH') {
        $obj = $self->_related_model->new_collection($doc->connection)->create($obj);
      }

      $obj->data->{$foreign_field} = bson_dbref $doc->model->collection_name, $doc->id;
      $obj->dirty->{$foreign_field} = 1 if $obj->dirty;

      # Blocking
      unless ($cb) {
        push @$cached, $obj if $cached;
        $obj->save;
        $doc->save;
        return $obj;
      }

      # Non-blocking
      Mojo::IOLoop->delay(
        sub {
          my ($delay) = @_;
          $obj->save($delay->begin);
          $doc->save($delay->begin);
        },
        sub {
          my ($delay, $o_err, $d_err) = @_;
          my $err = $o_err || $d_err;
          push @$cached, $obj if !$err and $cached;
          $doc->$cb($err, $obj);
        },
      );

      return $doc;
    }
  );

  return $self;
}

sub _monkey_patch_search_method {
  my $self          = shift;
  my $foreign_field = $self->foreign_field;
  my $related_class = $self->related_class;

  Mojo::Util::monkey_patch(
    $self->document_class,
    $self->search_method_name,
    sub {
      my ($doc, $query, $extra) = @_;
      my $related_model = $self->_related_model;

      return $related_model->new_collection(
        $doc->connection,
        extra => $extra || {},
        query => {%{$query || {}}, sprintf('%s.$id', $foreign_field) => $doc->id},
      );
    }
  );

  return $self;
}

1;

=encoding utf8

=head1 NAME

Mandel::Relationship::HasMany - A field relates to many other mongodb document

=head1 DESCRIPTION

L<Mandel::Relationship::HasMany> is a class used to describe the relationship
between one document that has a relationship to many other documents.
The connection between the documents is described in the database using
L<DBRef|http://docs.mongodb.org/manual/reference/database-references/>.

=head1 DATABASE STRUCTURE

A "person" that I<has many> "cats" will look like this in the database:

  mongodb# db.persons.find();
  { "_id" : ObjectId("53529f28c5483e4977020000") }

  mongodb# db.cats.find({ "person.$id": ObjectId("53529f28c5483e4977020000") })
  {
    "_id" : ObjectId("53529f28c5483e5077040000"),
    "person" : DBRef("persons", ObjectId("53529f28c5483e4977020000"))
  }
  {
    "_id" : ObjectId("6432574384483e4978010000"),
    "person" : DBRef("persons", ObjectId("53529f28c5483e4977020000"))
  }

A "has many" on one side is L<Mandel::Relationship::BelongsTo> on the other
side.

=head1 SYNOPSIS

=head2 Using DSL

  package MyModel::Person;
  use Mandel::Document;
  has_many cats => 'MyModel::Cat';

=head2 Using object oriented interface

  MyModel::Person->model->relationship(
    "has_many",
    "cats",
    "MyModel::Cat",
  );

See also L<Mandel::Model/relationship>.

=head2 Methods generated

  # non-blocking
  $person = MyModel::Person->new->add_cats(\%constructor_args, sub {
              my($person, $err, $cat_obj) = @_;
              # ...
            });

  $person = MyModel::Person->new->add_cats($cat_obj, sub {
              my($person, $err, $cat_obj) = @_;
              # ...
            });

  $person = MyModel::Cat->new->cats(sub {
              my($self, $err, $array_of_cats) = @_;
              # ...
            });

  # blocking
  $cat_obj = MyModel::Person->new->add_cats(\%args);
  $cat_obj = MyModel::Person->new->add_cats($cat_obj);
  $array_of_cats = MyModel::Person->new->cats;

  $cat_collection = MyModel::Person->new->search_cats;

=head1 ATTRIBUTES

L<Mandel::Relationship::HasMany> inherits all attributes from
L<Mandel::Relationship> and implements the following new ones.

=head2 add_method_name

The name of the method used to add another document to the relationship.

=head2 search_method_name

The name of the method used to search related documents.

=head1 METHODS

L<Mandel::Relationship::HasMany> inherits all methods from
L<Mandel::Relationship> and implements the following new ones.

=head2 monkey_patch

Add methods to L<Mandel::Relationship/document_class>.

=head1 SEE ALSO

L<Mojolicious>, L<Mango>, L<Mandel::Relationship>

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
