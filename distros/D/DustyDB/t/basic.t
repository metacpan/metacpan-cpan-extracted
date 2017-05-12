use strict;
use warnings;

=head1 NAME

basic.t - quick and dirty general test of things

=cut

use Test::More tests => 40;
use Test::Moose;
use_ok('DustyDB');

# Declare a model
package Author;
use DustyDB::Object;

has key name => ( is => 'rw', isa => 'Str' );

# Declare another model
package Book;
use DustyDB::Object;

has key title => ( is => 'rw', isa => 'Str' );
has author    => ( is => 'rw', isa => 'Author' );

# Get down to business
package main;

# Create/connect to the database
my $db = DustyDB->new( path => 't/basic.db' );
ok($db, 'Loaded the database object');
isa_ok($db, 'DustyDB');

# Are the meta-classes the right kind of things?
does_ok(Author->meta, 'DustyDB::Meta::Class');
does_ok(Book->meta, 'DustyDB::Meta::Class');

# Are the attributes teh right kind of things?
does_ok(Author->meta->get_attribute_map->{name}, 'DustyDB::Meta::Attribute');
does_ok(Author->meta->get_attribute_map->{name}, 'DustyDB::Key');
does_ok(Book->meta->get_attribute_map->{title}, 'DustyDB::Meta::Attribute');
does_ok(Book->meta->get_attribute_map->{title}, 'DustyDB::Key');
does_ok(Book->meta->get_attribute_map->{author}, 'DustyDB::Meta::Attribute');

# Get the model classes used to work with records
my $author = $db->model('Author');
ok($author, 'Loaded the author model object');
isa_ok($author, 'DustyDB::Model');

my $book   = $db->model('Book');
ok($book, 'Loaded the book model object');
isa_ok($book, 'DustyDB::Model');

{
    # Create a couple records
    my $the_damian = $author->construct( name => 'Damian Conway' );
    ok($the_damian, 'Created an author');
    isa_ok($the_damian, 'Author');
    does_ok($the_damian, 'DustyDB::Record');
    is($the_damian->name, 'Damian Conway', 'name is correct');

    my $pbp        = $book->construct( 
        title  => 'Perl Best Practices', 
        author => $the_damian,
    );
    ok($pbp, 'Create a book');
    isa_ok($pbp, 'Book');
    does_ok($pbp, 'DustyDB::Record');
    is($pbp->title, 'Perl Best Practices', 'title is correct');
    ok($pbp->author, 'author is set');
    is($pbp->author->name, 'Damian Conway', 'author is correct');

    # Save them to the database
    $the_damian->save;
    pass('we did not die saving the author');

    $pbp->save;
    pass('we did not die saving the book');
}

{
    # Load some records
    my $the_damian = $author->load( 'Damian Conway' );
    ok($the_damian, 'we loaded an author');
    isa_ok($the_damian, 'Author');
    does_ok($the_damian, 'DustyDB::Record');
    is($the_damian->name, 'Damian Conway', 'author name is correct');

    my $pbp        = $book->load( 'Perl Best Practices' );
    ok($pbp, 'we loaded a book');
    isa_ok($pbp, 'Book');
    does_ok($pbp, 'DustyDB::Record');
    is($pbp->title, 'Perl Best Practices', 'title is correct');
    ok($pbp->author, 'author is set');
    is($pbp->author->name, 'Damian Conway', 'author is correct');

    # Delete them
    $the_damian->delete;
    pass('we did not die deleting the author');

    $pbp->delete;
    pass('we did not die deleting the book');
}

{
    # Try to load again, should fail
    my $the_damian = $author->load( 'Damian Conway' );
    is($the_damian, undef, 'no author found');

    my $pbp = $book->load( 'Perl Best Practicies' );
    is($pbp, undef, 'no book found');
}

unlink 't/basic.db';
