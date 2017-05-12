package Mandel::Relationship::HasOne;

=head1 NAME

Mandel::Relationship::HasOne - A field relates to another mongodb document

=head1 DESCRIPTION

L<Mandel::Relationship::HasOne> is a class used to describe the relationship
between one document that has a relationship to one other documents.
The connection between the documents is described in the database using
L<DBRef|http://docs.mongodb.org/manual/reference/database-references/>.

=head1 DATABASE STRUCTURE

A "dinosaur" that I<has one> "cat" will look like this in the database:

  mongodb# db.dinosaurs.find({ })
  { "_id" : ObjectId("5352b4d8c5483e4502010000") }

  mongodb# db.cats.find({ "dinosaur.$id": ObjectId("53529f28c5483e4977020000") })
  {
    "_id" : ObjectId("5352b4d8c5483e4502040000"),
    "dinosaur" : DBRef("dinosaurs", ObjectId("5352b4d8c5483e4502010000"))
  }

=head1 SYNOPSIS

=head2 Using DSL

  package MyModel::Dinosaur;
  use Mandel::Document;
  has_one cat => 'MyModel::Cat';

=head2 Using object oriented interface

  MyModel::Dinosaur->model->relationship(
    "has_one",
    "cat",
    "MyModel::Cat",
  );

=head2 Methods generated

  $cat = MyModel::Dinosaur->new->cat(\%args, $cb);
  $cat = MyModel::Dinosaur->new->cat($person_obj, $cb);

  $person_obj = MyModel::Dinosaur->new->cat(\%args);
  $person_obj = MyModel::Dinosaur->new->cat($person_obj);

  $person = MyModel::Dinosaur->new->cat;
  $self = MyModel::Dinosaur->new->cat(sub { my($self, $err, $person) = @_; });

See also L<Mandel::Model/relationship>.

=cut

use Mojo::Base 'Mandel::Relationship';
use Mojo::Util;
use Mango::BSON 'bson_dbref';

=head1 METHODS

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

      if ($obj) {    # set ===========================================================
        if (ref $obj eq 'HASH') {
          $obj = $related_collection->create($obj);
        }

        $obj->data->{$foreign_field} = bson_dbref $doc->model->collection_name, $doc->id;

        # Blocking
        unless ($cb) {
          $related_collection->search({sprintf('%s.$id', $foreign_field), $doc->id})->remove();
          $obj->save;
          $doc->save;
          $doc->_cache($accessor => $obj);
          return $obj;
        }

        # Non-blocking
        Mojo::IOLoop->delay(
          sub {
            my ($delay) = @_;
            $related_collection->search({sprintf('%s.$id', $foreign_field), $doc->id})->remove($delay->begin);
          },
          sub {
            my ($delay, $err) = @_;
            return $delay->begin(0)->($err) if $err;
            $doc->save($delay->begin);
            $obj->save($delay->begin);
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
      else {    # get =============================================================
        my $cursor = $related_collection->search({sprintf('%s.$id', $foreign_field), $doc->id});
        return $cursor->single unless $cb;
        $cursor->single(sub { $doc->$cb(@_[1, 2]) });
      }

      return $doc;
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
