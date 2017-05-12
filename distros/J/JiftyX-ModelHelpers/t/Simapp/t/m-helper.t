#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 11;
use JiftyX::ModelHelpers qw(M);
use Simapp::Model::Book;

{
    my $b = M("Book");
    is( ref($b), "Simapp::Model::Book" );
}

my $good_book_id;
{
    my $b1 = Jifty->app_class(Model => "Book")->new;
    $good_book_id = $b1->create( name => "Good Book A");

    my $b2 = M("Book", name => "Good Book A");
    is( $b2->id, $b1->id );
}

{
    my $b = M("Book", id => $good_book_id);
    is( $b->name, "Good Book A" );
}

{
    my $b = M("BookCollection");
    is( ref($b), "Simapp::Model::BookCollection" );
    is($b->count, 1, "There is one book in the collections so far.");
}

{
    my $b = M("BookCollection", name => "Good Book A");
    is( ref($b), "Simapp::Model::BookCollection" );
    is( $b->count, 1 );
}

{
    my $system_user = Simapp::CurrentUser->superuser;

    my $b = M("Book", { current_user => $system_user });
    my ($id) = $b->create(name => "Book Created by System User");

    ok( $b->current_user->is_superuser );

    ok($id, "Book create returned success");
    ok($b->id, "New Book has valid id set");
    is($b->id, $id, "Create returned the right id");
}
