package JiftyX::ModelHelpers;
our $VERSION = '0.23';

# ABSTRACT: Make it simpler to fetch records in Jifty.

use strict;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(M);

sub M {
    my ($model, @params) = @_;
    unless (@params) {
        my $record = Jifty->app_class(Model => $model)->new();
        $record->unlimit if index($model, "Collection") > 0;
        return $record;
    }

    my $params_to_new = pop @params;
    unless (ref($params_to_new) eq 'HASH') {
        push @params, $params_to_new;
        $params_to_new = {};
    }

    my $record = Jifty->app_class(Model => $model)->new(%$params_to_new);
    if (@params) {
        if (index($model, "Collection") > 0) {
            my %params = (@params);
            while (my ($k, $v) = each %params) {
                $record->limit(column => $k, value => $v);
            }
        }
        else {
            if (@params == 1) {
                unshift @params, "id";
            }
            $record->load_by_cols(@params);
        }
    }
    else {
        $record->unlimit if index($model, "Collection") > 0;
    }
    return $record;
}

sub import {
    my ($self, @tags) = @_;
    build_model_helpers();

    # Let the Exporter.pm do the heavy-liftingjobs
    local $Exporter::ExportLevel = $Exporter::ExportLevel + 1;
    Exporter::import($self, @tags);
}


my $built = 0;
sub build_model_helpers {
    return if $built;

    require Jifty::Schema;
    my @models = map { s/.*::(.+)$/$1/;  $_; } Jifty::Schema->new->models;

    no strict 'refs';
    for my $model (@models) {
        *{"$model"} = sub {
            return M($model, @_);
        };
        push @EXPORT, "&${model}";
    }

    $built = 1;
}

1;



__END__
=head1 NAME

JiftyX::ModelHelpers - Make it simpler to fetch records in Jifty.

=head1 VERSION

version 0.23

=head1 SYNOPSIS

Suppose you have a "Book" model in your app:

    use JiftyX::ModelHelper;

    # Load the record of book with id = $id
    $book = M(Book => $id);

    # Another way.
    $book = M(Book => id => $id);

    # Load by other criteria
    $book = M(Book => isbn => " 978-0099410676");

    # Load a colllection of books
    $books = M("BookCollection", author => "Jesse");

Or, even better:

    use JiftyX::ModelHelper;

    # Load the record of book with id = $id
    $book  = Book($id);
    $book  = Book(isbn => " 978-0099410676");
    $books = BookCollection(author => "Jesse");

=head1 DESCRIPTION

Jifty programmers may find them self very tired of typing in their
View or Dispatcher when it comes to retrieve records or collection of
records. That is why this module was borned.

When used, this module export a function named C<M> by default.
This function takes one model name and returns its record object:

    $book = M("Book");

Effectively, this is the same as doing:

    $book = Jifty->app_class(Model => "Book")->new;

It also works for collections:

    $book = M("BookCollection");

=head2 The M() function

The C<M> function is a short-hand to create both record and collection
objects. The first argument is reqruied and has to be one of the model
name existed in your application. For example, this creates an
I<blank> record object of Book model:

    $book = M("Book");

It's said to be I<blank> because it is not associated with a record
stored in the database, and does not have any meaningful properties.
However, it is useful to create records with this representation:

    M("Book")->create({
        name => "RT Essentials",
        author => "Jesse Vincent"
    });

Thanks to the design of C<Jifty::DBI::Record>, which allows record
creations with both object method and class method.

The C<M> function optionally takes a list of key-value pairs after
model names. The keys will be treated as column names, as values are,
of course, column values. These key-value pairs will be the
requirement used to load records. For example, this statement loads a
record of Book with certain isbn:

    $book = M("Book", isbn => "978-0099410676");

Effectively, this is the same as:

    $book => Jifty->app_class(Model => "Book")->new;
    $book->load_by_cols(isbn => "978-0099410676");

If you pass only one numeric value instead of a key-value pair, that
is specially treated as if it's an record id. So instead of saying:

    $book = M("Book", id => 42);

It can be shorten to:

    $book = M(Book => 42);

If the given model name is a collection, instead of meaning a I<blank>
collection object, it means the collection of I<all> records.

    $books = M("BookCollection");

Effectly the same as:

    $books = Jifty->app_class(Model => "BookCollection")->new;
    $books->unlimit;

Practially this is the mostly used scenario, that's why I this
decision to lett it represent a collection of "all" instead of "none".

If you need to set "current_user" to different ones when you construct
a new model object, you can do it like this:

    my $u = Jifty->app_class('CurrentUser')->superuser;
    $book = M("Book", isbn => "978-0099410676", { current_user => $u });

If the last argument to the M() method is a hashref, it is then passed
to the C<new> method of the model class.

=head2 The auto-generated model functions.

Optionally, C<JiftyX::ModelHelpers> generates two functions for each
models your Jifty application. One for accessing records, the other
for accessing collections. For example, if you have a model named
"Book", the generated functions are:

    JiftyX::ModelHelpers::Book
    JiftyX::ModelHelpers::BookCollection

They are imported to your currenct package scope as:

    Book
    BookCollection

The are generated and imported when you say:

    use JiftyX::ModelHelpers;

The record function takes either exact one argument or a hash. When it
is given only one argument, that argument is treated as the value of
"id" field and the record with that id is retured. Such as:

    my $book = Book(42);

This is exactly the same as:

    my $book = Jifty->app_class(Model => 'Book')->new;
    $book->load(42);

In other cases, it'd expect a hash:

    my $book = Book(isbn => "978-0099410676");

This is exactly the same as:

    my $book = Jifty->app_class(Model => 'Book');
    $book->load_by_cols(isbn => "978-0099410676");

Please also read the description of C<load_by_cols> in
L<Jifty::DBI::Record> to know how to use it. Basically the generate
helper functions just delegate all its argument to that method and
returns whatever returned from there.

The returned C<$book> is a L<Jifty::Record> object, so please read
its POD for how to use it.

As for the function of collections, here's the example to get a
collection of all records of books:

    my $books = BookCollection;

And that's identical to:

    my $books = Jifty->app_class(Model => "BookCollection")->new;
    $books->unlimit;

The function for collection can take a hash too, and calls C<limit>
method on the collection several times:

    my $books = BookCollection(
        author => "Neal Stephenson",
        binding => "paperback"
    );

This is the same as:

    my $books = Jifty->app_class(Model => "BookCollection")->new;
    $books->limit(column => "author", value => "Neal Stephenson");
    $books->limit(column => "binding", value => "paperback");

The returned C<$books> is still a L<Jifty::Collection> object, so
please read its POD for how to use it.

For people who works daily in Jifty world, this should make your code
more readible for most of the time.

=head2 Namespace clobbering

One major issue for using this module is that it automaically defines
many functions in its caller, and that might cause naming collision.

To work around this, keep in mind that this module is an L<Exporter>,
and you can pass those functions your want explicitly:

    # Don't want BookCollection function
    use JiftyX::ModelHelpers qw(Book);

Or you can only import the M() function, which is likely
much less problematic:

    use JiftyX::ModelHelpers qw(M);

=head2 Development

The code repository for this project is hosted on

    http://svn.jifty.org/svn/jifty.org/JiftyX-ModelHelpers

If you want to report a bug or an issue, please use this form:

    https://rt.cpan.org/Ticket/Create.html?Queue=JiftyX-ModelHelpers

If you want to disscuss about this module, please join jifty-devel
mailing list.

To join the list, send mail to C<jifty-devel-subscribe@lists.jifty.org>

=head1 AUTHOR

  Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008, 2009 by Kang-min Liu.

This is free software, licensed under:

  The MIT (X11) License

