package Mandel;
use Mojo::Base 'Mojo::Base';
use Mojo::Loader qw(find_modules load_class);
use Mojo::Util;
use Mandel::Collection;
use Mandel::Model;
use Mango;
use Carp 'confess';

our $VERSION = '0.31';

has model_class => sub { shift->_build_model_class };
has namespaces  => sub { shift->_build_namespaces };
has storage     => sub { shift->_build_storage };

sub _build_model_class {'Mandel::Model'}
sub _build_namespaces  { [ref $_[0]] }
sub _build_storage     { Mango->new('mongodb://localhost/mandeltest') }

sub connect {
  my ($self, @args) = @_;
  my $storage = Mango->new(@args);

  if (my $class = ref $self) {
    $self = $class->new(%$self, storage => $storage);
  }
  else {
    $self = $self->new(storage => $storage);
  }

  $self;
}

sub all_document_names {
  my $self = shift;
  my %names = map { $_, 1 } keys %{$self->{model} || {}};

  for my $ns (@{$self->namespaces}) {
    for my $name (find_modules $ns) {
      my $e = load_class $name;
      next unless $name->isa('Mandel::Document');
      $name =~ s/^${ns}:://;
      $names{Mojo::Util::decamelize($name)} = 1;
    }
  }

  keys %names;
}

sub class_for {
  my ($self, $name) = @_;

  if (my $class = $self->{loaded}{$name}) {
    return $class;
  }

  for my $ns (@{$self->namespaces}) {
    my $class = $ns . '::' . Mojo::Util::camelize($name);
    my $e     = load_class $class;
    die $e if ref $e;
    next   if $e;
    return $self->{loaded}{$name} = $class;
  }

  confess "Could not find class for $name";
}

sub collection {
  my ($self, $name) = @_;

  $self->model($name)->new_collection($self);
}

sub model {
  my ($self, $name, $model) = @_;

  if ($model) {
    $model = $self->model_class->new($model) if ref $model eq 'HASH';
    $model->name($name);
    $self->{loaded}{$name} = $model->document_class;
    $self->{model}{$name}  = $model;
    return $self;
  }
  else {
    return $self->{model}{$name} ||= $self->class_for($name)->model;
  }
}

sub initialize {
  my $args      = ref $_[-1] eq 'HASH' ? pop : {};
  my $self      = shift;
  my @documents = @_ ? @_ : $self->all_document_names;

  for my $document (@documents) {
    my $class = $self->class_for($document);
    $class->initialize($self, $args);
  }
}

sub _storage_collection {
  $_[0]->storage->db->collection($_[1]);
}

1;

=encoding utf8

=head1 NAME

Mandel - Async model layer for MongoDB objects using Mango

=head1 VERSION

0.31

=head1 SYNOPSIS

  # create your custom model class
  package MyModel;
  use Mojo::Base "Mandel";
  1;

  # create a document class
  package MyModel::Cat;
  use Mandel::Document;
  use Types::Standard 'Str';
  field name => ( isa => Str, builder => sub { "value" } );
  field 'type';
  belongs_to person => 'MyModel::Person';
  1;

  # create another document class
  package MyModel::Person;
  use Mandel::Document;
  use Types::Standard 'Int';
  field [qw(name)];
  field age => ( isa => Int );
  has_many cats => 'MyModel::Cat';
  has_one favorite_cat => 'MyModel::Cat';
  1;

  # use the model in your application
  package main;
  my $connection = MyModel->connect("mongodb://localhost/my_db");
  my $persons = $connection->collection('person');

  my $p1 = $persons->create({ name => 'Bruce', age => 30 });
  $p1->save(sub {
    my($p1, $err) = @_;
  });

  $persons->count(sub {
    my($persons, $err, $n_persons) = @_;
  });

  $persons->all(sub {
    my($persons, $err, $objs) = @_;
    for my $p (@$objs) {
      $p->age(25)->save(sub {});
    }
  });

  $persons->search({ name => 'Bruce' })->single(sub {
    my($persons, $err, $person) = @_;

    $person->cats(sub {
      my($person, $err, $cats) = @_;
      $_->remove(sub {}) for @$cats;
    });

    $person->remove(sub {
      my($person, $err) = @_;
    });
  });

=head1 DESCRIPTION

THIS IS ALPHA SOFTWARE! THE API MAY BE CHANGED AT ANY TIME!
PLEASE CONTACT ME IF YOU HAVE ANY COMMENTS OR FEEDBACK.

L<Mandel> is an async object-document-mapper. It allows you to work with your
MongoDB documents in Perl as objects.

This class binds it all together:

=over 4

=item * L<Mandel::Model>

An object modelling a document.

=item * L<Mandel::Collection>

A collection of Mandel documents.

=item * L<Mandel::Document>

A single MongoDB document with logic.

=back

=head1 ATTRIBUTES

L<Mandel> inherits all attributes from L<Mojo::Base> and implements the
following new ones.

=head2 namespaces

The namespaces which will be searched when looking for Types. By default, the
(sub)class name of this module.

=head2 model_class

Returns L<Mandel::Model>.

=head2 storage

An instance of L<Mango> which acts as the database connection. If not
provided.

=head1 METHODS

L<Mandel> inherits all methods from L<Mojo::Base> and implements the following
new ones.

=head2 connect

  $self = $class->connect(@connect_args);
  $clone = $self->connect(@connect_args);

C<@connect_args> will be passed on to L<Mango/new>, which again will be set
as L</storage>.

Calling this on an object will return a clone, but with a fresh L</storage>
object.

=head2 all_document_names

  @names = $self->all_document_names;

Returns a list of all the documents in the L</namespaces>.

=head2 class_for

  $document_class = $self->class_for($name);

Given a document name, find the related class name, ensure that it is loaded
(or else die) and return it.

=head2 collection

  $collection_obj = $self->collection($name);

Returns a L<Mango::Collection> object.

=head2 model

  $model = $self->model($name);
  $self = $self->model($name => \%model_args);
  $self = $self->model($name => $model_obj);

Define or returns a L<Mandel::Model> object. Will die unless a model is
registered by that name or L</class_for> returns a class which has the
C<model()> method defined.

=head2 initialize

  $self->initialize(@names, \%args);
  $self->initialize(\%args);

Takes a list of document names. Calls the L<Mandel::Document/initialize> method
on any document given as input. C<@names> default to L</all_document_names>
unless specified.

C<%args> defaults to empty hash ref, unless specified as input.

The C<initialize()> method will be called like this:

  $document_class->initialize($self, \%args);

=head1 SEE ALSO

L<Mojolicious>, L<Mango>

Still got MongoDB 2.4 on Ubuntu? Check out
L<http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/>
to upgrade.

=head1 SOURCE REPOSITORY

L<http://github.com/jhthorsen/mandel>

=head1 AUTHORS

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Joel Berger - C<joel.a.berger@gmail.com>

Holger Rupprecht - C<Holger.Rupprecht@Itelligence.de>

Huo Linhe - C<zitsen@cpan.org>

This project is a fork of L<MangoModel|http://github.com/jberger/MangoModel>,
created by Joel Berger, C<joel.a.berger@gmail.com>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jan Henning Thorsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
