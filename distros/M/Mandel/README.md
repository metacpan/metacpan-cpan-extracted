# NAME

Mandel - Async model layer for MongoDB objects using Mango

# VERSION

0.31

# SYNOPSIS

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

# DESCRIPTION

THIS IS ALPHA SOFTWARE! THE API MAY BE CHANGED AT ANY TIME!
PLEASE CONTACT ME IF YOU HAVE ANY COMMENTS OR FEEDBACK.

[Mandel](https://metacpan.org/pod/Mandel) is an async object-document-mapper. It allows you to work with your
MongoDB documents in Perl as objects.

This class binds it all together:

- [Mandel::Model](https://metacpan.org/pod/Mandel::Model)

    An object modelling a document.

- [Mandel::Collection](https://metacpan.org/pod/Mandel::Collection)

    A collection of Mandel documents.

- [Mandel::Document](https://metacpan.org/pod/Mandel::Document)

    A single MongoDB document with logic.

# ATTRIBUTES

[Mandel](https://metacpan.org/pod/Mandel) inherits all attributes from [Mojo::Base](https://metacpan.org/pod/Mojo::Base) and implements the
following new ones.

## namespaces

The namespaces which will be searched when looking for Types. By default, the
(sub)class name of this module.

## model\_class

Returns [Mandel::Model](https://metacpan.org/pod/Mandel::Model).

## storage

An instance of [Mango](https://metacpan.org/pod/Mango) which acts as the database connection. If not
provided.

# METHODS

[Mandel](https://metacpan.org/pod/Mandel) inherits all methods from [Mojo::Base](https://metacpan.org/pod/Mojo::Base) and implements the following
new ones.

## connect

    $self = $class->connect(@connect_args);
    $clone = $self->connect(@connect_args);

`@connect_args` will be passed on to ["new" in Mango](https://metacpan.org/pod/Mango#new), which again will be set
as ["storage"](#storage).

Calling this on an object will return a clone, but with a fresh ["storage"](#storage)
object.

## all\_document\_names

    @names = $self->all_document_names;

Returns a list of all the documents in the ["namespaces"](#namespaces).

## class\_for

    $document_class = $self->class_for($name);

Given a document name, find the related class name, ensure that it is loaded
(or else die) and return it.

## collection

    $collection_obj = $self->collection($name);

Returns a [Mango::Collection](https://metacpan.org/pod/Mango::Collection) object.

## model

    $model = $self->model($name);
    $self = $self->model($name => \%model_args);
    $self = $self->model($name => $model_obj);

Define or returns a [Mandel::Model](https://metacpan.org/pod/Mandel::Model) object. Will die unless a model is
registered by that name or ["class\_for"](#class_for) returns a class which has the
`model()` method defined.

## initialize

    $self->initialize(@names, \%args);
    $self->initialize(\%args);

Takes a list of document names. Calls the ["initialize" in Mandel::Document](https://metacpan.org/pod/Mandel::Document#initialize) method
on any document given as input. `@names` default to ["all\_document\_names"](#all_document_names)
unless specified.

`%args` defaults to empty hash ref, unless specified as input.

The `initialize()` method will be called like this:

    $document_class->initialize($self, \%args);

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mango](https://metacpan.org/pod/Mango)

Still got MongoDB 2.4 on Ubuntu? Check out
[http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/](http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/)
to upgrade.

# SOURCE REPOSITORY

[http://github.com/jhthorsen/mandel](http://github.com/jhthorsen/mandel)

# AUTHORS

Jan Henning Thorsen - `jhthorsen@cpan.org`

Joel Berger - `joel.a.berger@gmail.com`

Holger Rupprecht - `Holger.Rupprecht@Itelligence.de`

Huo Linhe - `zitsen@cpan.org`

This project is a fork of [MangoModel](http://github.com/jberger/MangoModel),
created by Joel Berger, `joel.a.berger@gmail.com`.

# COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jan Henning Thorsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
