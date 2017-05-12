package Mandel::Relationship::BelongsTo;

=head1 NAME

Mandel::Relationship::BelongsTo - A document is owned by another mongodb document

=head1 DESCRIPTION

L<Mandel::Relationship::BelongsTo> is a class used to describe the relationship
between one document that belongs to another document. The connection
between the documents is described in the database using
L<DBRef|http://docs.mongodb.org/manual/reference/database-references/>.

=head1 DATABASE STRUCTURE

A "cat" that I<belongs to> a "person" will look like this in the database:

  mongodb# db.persons.find();
  { "_id" : ObjectId("5352abb0c5483e591a010000") }

  mongodb# db.cats.find({ "person.$id": ObjectId("5352abb0c5483e591a010000") })
  {
    "_id" : ObjectId("5352abb0c5483e591a020000"),
    "person" : DBRef("persons", ObjectId("5352abb0c5483e591a010000"))
  }

=head1 SYNOPSIS

=head2 Using DSL

  package MyModel::Cat;
  use Mandel::Document;
  belongs_to owner => 'MyModel::Person';

=head2 Using object oriented interface

  MyModel::Cat
    ->model
    ->relationship(belongs_to => owner => 'MyModel::Person');

See also L<Mandel::Model/relationship>.

=head2 Methods generated

  # non-blocking set
  $cat = MyModel::Cat->new->owner(\%args, sub {
           my($cat, $err, $person_obj) = @_;
           # ...
         });

  $cat = MyModel::Cat->new->owner($person_obj, sub {
           my($cat, $err, $person_obj) = @_;
           # ...
         });

  # non-blocking get
  $cat = MyModel::Cat->new->owner(sub {
           my($cat, $err, $person_obj) = @_;
           # ...
         });


  # blocking set
  $person_obj = MyModel::Cat->new->owner(\%args);
  $person_obj = MyModel::Cat->new->owner($person_obj);
  $person_obj = MyModel::Cat->new->owner($bson_oid);

  # blocking get
  $person = MyModel::Cat->new->owner;

=cut

use Mojo::Base 'Mandel::Relationship';
use Mojo::Util;
use Mango::BSON 'bson_dbref';

=head1 ATTRIBUTES

L<Mandel::Relationship::BelongsTo> inherits all attributes from
L<Mandel::Relationship> and implements the following new ones.

=head2 foreign_field

The name of the field in this class which hold the "_id" to the related doc.

=cut

has foreign_field => sub { shift->accessor };

=head1 METHODS

L<Mandel::Relationship::BelongsTo> inherits all methods from
L<Mandel::Relationship> and implements the following new ones.

=head2 monkey_patch

Add methods to L<Mandel::Relationship/document_class>.

=cut

sub monkey_patch {
  my $self          = shift;
  my $foreign_field = $self->foreign_field;
  my $accessor      = $self->accessor;

  Mojo::Util::monkey_patch(
    $self->document_class,
    $accessor,
    sub {
      my $cb                 = ref $_[-1] eq 'CODE' ? pop : undef;
      my $doc                = shift;
      my $obj                = shift;
      my $related_model      = $self->_related_model;
      my $related_collection = $related_model->new_collection($doc->connection);

      if ($obj) {    # set
        if (UNIVERSAL::isa($obj, 'Mango::BSON::ObjectID')) {
          $doc->data->{$foreign_field} = bson_dbref $related_model->collection_name, $obj;
          return $obj;
        }
        if (ref $obj eq 'HASH') {
          $obj = $related_collection->create($obj);
        }

        $doc->data->{$foreign_field} = bson_dbref $related_model->collection_name, $obj->id;
        $doc->dirty->{$foreign_field} = 1 if $doc->dirty;

        # Blocking
        unless ($cb) {
          $obj->save;
          $doc->save;
          $doc->_cache($accessor => $obj);
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
            $doc->_cache($accessor => $obj) unless $err;
            $doc->$cb($err, $obj);
          },
        );
      }
      elsif (!delete $doc->{fresh} and my $cached = $doc->_cache($accessor)) {    # get cached
        return $cached unless $cb;
        $self->$cb('', $cached);
      }
      else {                                                                      # get
        my $cursor = $related_collection->search({_id => $doc->data->{$foreign_field}{'$id'}});
        return $doc->_cache($accessor => $cursor->single) unless $cb;
        $cursor->single(
          sub {
            my ($cursor, $err, $obj) = @_;
            $doc->_cache($accessor => $obj) unless $err;
            $doc->$cb($err, $obj);
          }
        );
      }

      $doc;
    }
  );

  return $self;
}

=head1 SEE ALSO

L<Mojolicious>, L<Mango>, L<Mandel::Relationship>

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
