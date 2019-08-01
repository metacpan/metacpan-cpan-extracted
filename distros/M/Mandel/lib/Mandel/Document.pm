package Mandel::Document;
use Mojo::Base 'Mojo::Base';
use Mojo::JSON::Pointer;
use Mojo::Util 'monkey_patch';
use Mandel::Model;
use Mango::BSON ':bson';
use Scalar::Util 'looks_like_number';
use Carp 'confess';
use constant DEBUG => $ENV{MANDEL_CURSOR_DEBUG} ? eval 'require Data::Dumper;1' : 0;

my $POINTER = Mojo::JSON::Pointer->new;

sub id {
  my $self = shift;
  my $raw  = $self->data;

  if (@_) {
    $self->dirty->{_id} = 1;
    $raw->{_id} = ref $_[0] ? $_[0] : bson_oid $_[0];
    return $self;
  }
  elsif ($raw->{_id}) {
    return $raw->{_id};
  }
  else {
    $self->dirty->{_id} = 1;
    return $raw->{_id} = bson_oid;
  }
}

has connection => sub { confess "connection required in constructor" };
has model      => sub { confess "model required in constructor" };
has dirty      => sub { +{} };
has in_storage => 0;

has _storage_collection => sub {
  my $self = shift;
  $self->connection->_storage_collection($self->model->collection_name);
};

has data => sub { shift->_build_data };    # raw mongodb document data

sub _build_data { +{} }

sub new {
  my $self = shift->SUPER::new(@_);
  $self->id(delete $self->{id}) if $self->{id};
  $self;
}

sub initialize {shift}

sub contains {
  my $self = shift;
  $POINTER->data($self->data)->contains(@_);
}

sub fresh {
  $_[0]->{fresh} = 1;
  $_[0];
}

sub get {
  my $self = shift;
  $POINTER->data($self->data)->get(@_);
}

sub is_changed {
  return 0 unless $_[0]->{dirty};
  return 0 unless keys %{$_[0]->{dirty}};
  return 1;
}

sub patch {
  my ($self, $changes, $cb) = @_;
  my $data = $self->data;

  if ($changes) {
    @$data{keys %$changes} = values %$changes;
  }

  $data = {%$data};
  delete $data->{_id};    # Mod on _id not allowed

  $self->_storage_collection->update(
    {_id    => $self->id},
    {'$set' => $data},
    {upsert => bson_true},
    $cb
    ? (
      sub {
        $self->_mark_stored_clean unless $_[1];
        $self->$cb($_[1]);
      }
      )
    : (),
  );

  $self->_mark_stored_clean unless $cb;
  $self;
}

sub remove {
  my ($self, $cb) = @_;
  my $c = $self->_storage_collection;
  my @args = ({_id => $self->id}, {single => 1});

  warn "[$self\::remove] @{[$self->id]}\n" if DEBUG;

  if ($cb) {
    $c->remove(
      @args,
      sub {
        my ($collection, $err, $doc) = @_;
        $self->_mark_removed_dirty unless $err;
        $self->$cb($err);
      }
    );
  }
  else {
    $c->remove(@args);
    $self->_mark_removed_dirty;
  }

  return $self;
}

sub _mark_removed_dirty {
  my $self = shift;
  $self->dirty->{$_} = 1 for keys %{$self->data};
  $self->in_storage(0);
}

sub save {
  my ($self, $cb) = @_;

  if (!$self->is_changed and $self->in_storage) {
    $self->$cb('') if $cb;
    return $self;
  }

  $self->id;    # make sure we have an ObjectID

  warn "[$self\::save] ", Data::Dumper->new([$self->data])->Indent(1)->Sortkeys(1)->Terse(1)->Dump if DEBUG;
  my $c = $self->_storage_collection;

  if ($cb) {
    $c->save(
      $self->data,
      sub {
        my ($collection, $err, $doc) = @_;
        $self->_mark_stored_clean unless $err;
        $self->$cb($err);
      }
    );
  }
  else {
    $c->save($self->data);
    $self->_mark_stored_clean;
  }

  return $self;
}

sub _mark_stored_clean {
  my $self = shift;
  delete $self->{dirty};
  $self->in_storage(1);
}

sub set {
  my ($self, $pointer, $val) = @_;
  my $raw = $self->data;
  my (@path, $field);

  return $self unless $pointer =~ s!^/!!;
  @path = split '/', $pointer;
  $field = $path[0];

  while (@path) {
    my $p    = shift @path;
    my $type = ref $raw;
    my $want = looks_like_number $p ? 'INDEX' : 'KEY';

    if ($type eq 'HASH') {
      if (@path) {
        $raw = $raw->{$p} ||= looks_like_number $path[0] ? [] : {};
      }
      else {
        $raw->{$p} = $val;
      }
    }
    elsif ($type eq 'ARRAY') {
      if ($want ne 'INDEX') {
        confess "Cannot set $want in $type for /$pointer ($p)";
      }
      elsif (@path) {
        $raw = $raw->[$p] ||= looks_like_number $path[0] ? [] : {};
      }
      else {
        $raw->[$p] = $val;
      }
    }
    else {
      confess "Cannot set $want in SCALAR for /$pointer ($p)";
    }
  }

  $self->dirty->{$field} = 1 if defined $field;
  $self;
}

sub import {
  my $class      = shift;
  my %args       = @_ == 1 ? (name => shift) : @_;
  my $caller     = caller;
  my $model      = Mandel::Model->new(document_class => $caller, %args);
  my $base_class = 'Mandel::Document';

  for (qw(name extends)) {
    if ($args{$_} and $args{$_} =~ /::/) {
      $base_class = delete $args{$_};
    }
  }
  if (!$args{name}) {
    $args{name} = Mojo::Util::decamelize(($caller =~ /(\w+)$/)[0]);
    $model->name($args{name});
  }

  monkey_patch $caller, belongs_to => sub { $model->relationship(belongs_to => @_)->monkey_patch };
  monkey_patch $caller, field => sub { $model->field(shift, {@_}) };
  monkey_patch $caller, has_many => sub { $model->relationship(has_many => @_)->monkey_patch };
  monkey_patch $caller, has_one  => sub { $model->relationship(has_one  => @_)->monkey_patch };
  monkey_patch $caller, list_of  => sub { $model->relationship(list_of  => @_)->monkey_patch };
  monkey_patch $caller, model    => sub {$model};

  @_ = ($class, $base_class);
  goto &Mojo::Base::import;
}

sub TO_JSON { shift->data }

sub validate_fields {
  my $self = shift;
  if (ref $self->{data} eq 'HASH') {
    for (grep { $self->can($_) } keys %{ $self->{data} }) {
      $self->$_($self->{data}{$_});
    }
  }
  return $self;
}

sub _cache {
  my $self = shift;
  my $cache = $self->{cache} ||= {};

  return $cache->{$_[0]} if @_ == 1;    # get
  return $cache->{$_[0]} = $_[1];       # set
}

1;

=encoding utf8

=head1 NAME

Mandel::Document - A single MongoDB document with logic

=head1 SYNOPSIS

Extend a class with C<MyDocument::Class> instead of L<Mandel::Document>:

  package MyModel::Person;
  use Mandel::Document "MyDocument::Class";

Specify a default collection name, instead of the
L<default|Mandel::Model/collection>. L</import> will think you meant a base
class, if this argument contains "::".

  package MyModel::Person;
  use Mandel::Document "some_collection_name";
  use Types::Standard 'Str';

  field "foo";

  field "foo" => (
    isa => Str,
    builder => sub {
      my $self = shift;
      return "default value";
    },
  );


Spell out the options with a list:

  package MyModel::Person;

  use Mandel::Document (
    extends => "My::Document::Class",
    collection_name => "some_collection_name",
    collection_class => "My::Custom::Collection",
  );

=head1 DESCRIPTION

L<Mandel> is a simplistic model layer using the L<Mango> module to interact
with a MongoDB backend. The L<Mandel> class defines the overall model,
including high level interaction. Individual results, called Types inherit
from L<Mandel::Document>.

An object of this class gets automatically serialized by L<Mojo::JSON>.
See L</TO_JSON> and L<Mojo::JSON#DESCRIPTION> for details.

Example:

  use Mojolicious::Lite;
  # ...
  get '/some/resource' => sub {
    my $c = shift;
    # find some document...
    $c->render(json => $mandel_doc_object);
  };

=head1 ATTRIBUTES

L<Mandel> inherits all attributes from L<Mojo::Base> and implements the
following new ones.

=head2 id

  $object_id = $self->id;
  $self = $self->id("507f1f77bcf86cd799439011");
  $self = $self->id(Mango::BSON::ObjectID->new);

Returns the L<Mango::BSON::ObjectID> object for this document.
Will create one if it does not already exist.

This can field can also be set.

=head2 data

  $hash = $self->data;
  $self = $self->data($hash);

Holds the raw mongodb document. It is possible to define default values for
this attribute by defining L<builder|Mandel::Model::Field/builder> for the
fields.

=head2 in_storage

Boolean true if this document has been fetched from storage or L<saved|/save>
to storage.

=head2 connection

An instance of L<Mandel>. This is required.

=head2 model

Returns a L<Mandel::Model> object. This object is a class variable and
therefor shared between all instances.

=head2 dirty

This attribute holds a hash-ref where the keys are name of fields that has
been updated or otherwise not stored in database.

TODO: Define what the values should hold. Timestamp? A counter for how
many times the field has been updated before saved..?

=head1 METHODS

L<Mandel::Document> inherits all of the methods from L<Mojo::Base> and
implements the following new ones.

=head2 new

Constructs a new object.

=head2 initialize

A no-op placeholder useful for initialization. See L<Mandel/initialize>.

=head2 contains

  $bool = $self->contains('/json/2/pointer');

Use L<Mojo::JSON::Pointer/contains> to check if a value exists inside the raw
mongodb document.

=head2 fresh

  $self = $self->fresh;

Calling this method will force the next relationship call to return fresh
data from database instead of cached. Example:

  $self->fresh->cats(sub {
    my($self, $err, $cats) = @_;
  });

=head2 get

  $any = $self->get('/json/2/pointer');

Use L<Mojo::JSON::Pointer/get> to retrieve a value inside the raw mongodb
document.

=head2 is_changed

Returns true if L</dirty> contains any field names.

=head2 patch

  $self = $self->patch(\%changes, sub { my($self, $err) = @_ });
  $self = $self->patch(\%changes);

This method will insert/update a partial document. This is useful if C</data>
does not contain a complete document.

It will also insert the document if a document with L</id> does not already
exist.

=head2 remove

  $self = $self->remove(sub { my($self, $err) = @_; });
  $self = $self->remove;

Will remove this object from the L</collection> and set mark
all fields as L</dirty>.

=head2 save

  $self = $self->save(sub { my($self, $err) = @_; });
  $self = $self->save;

This method stores the raw data in the database and collection. It clear
the L</dirty> attribute.

NOTE: This method will call the callback (with $err set to empty string)
immediately unless L</is_changed> is true and L</in_storage> is false.

=head2 set

  $self = $self->set('/json/2/pointer', $val);

Use a JSON pointer to set data in the raw mongodb document. This method will
die if the pointer points to non-compatible data.

=head2 import

See L</SYNOPSIS>.

=head2 TO_JSON

Alias for L</data>.

This method allow the document to get automatically serialized by
L<Mojo::JSON>.

=head2 validate_fields

  $self = $self->validate_fields;

This method can be used to validate the content of the fields of a document
againt the types defined in the model. It can be called after a document has
been loaded from MongoDB, e.g. via L<Mandel::Collection/single>. It can be
useful if the data in MongoDB might have been altered by something else after
it was stored there.

=head1 SEE ALSO

L<Mojolicious>, L<Mango>, L<Mandel>

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
