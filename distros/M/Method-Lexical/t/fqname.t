#!/usr/bin/env perl

use strict;
use warnings;

{
    package MyTest::Parent;

    sub private { 'parent!' } # ordinary public method

    package MyTest::Mother;
    package MyTest::Father;
    package MyTest::Child;

    use Test::More tests => 54;

    use Method::Lexical {
         private                  => sub { 'child!'  },
        'MyTest::Mother::private' => sub { 'mother!' },
        'MyTest::Father::private' => sub { 'father!' },
    };

    our @ISA;

    my $self = bless {};
    my $fqname;

    $fqname = 'private';
    is(__PACKAGE__->private, 'child!', '__PACKAGE__->private');
    is(__PACKAGE__->$fqname, 'child!', '__PACKAGE__->$fqname');
    is($self->private, 'child!', '$self->private');
    is($self->$fqname, 'child!', '$self->$fqname');

    $fqname = 'MyTest::Child::private';
    is(__PACKAGE__->MyTest::Child::private, 'child!', '__PACKAGE__->MyTest::Child::private');
    is(__PACKAGE__->$fqname, 'child!', '__PACKAGE__->$fqname');
    is($self->MyTest::Child::private, 'child!', '$self->MyTest::Child::private');
    is($self->$fqname, 'child!', '$self->$fqname');

    $fqname = "MyTest::Child'private";
    is(__PACKAGE__->$fqname, 'child!', '__PACKAGE__->$fqname');
    is($self->$fqname, 'child!', '$self->$fqname');

    $fqname = "MyTest'Child::private";
    is(__PACKAGE__->$fqname, 'child!', '__PACKAGE__->$fqname');
    is($self->$fqname, 'child!', '$self->$fqname');

    $fqname = "MyTest'Child'private";
    is(__PACKAGE__->$fqname, 'child!', '__PACKAGE__->$fqname');
    is($self->$fqname, 'child!', '$self->$fqname');

    @ISA = qw(MyTest::Mother);

    $fqname = 'SUPER::private';
    is(__PACKAGE__->SUPER::private, 'mother!', '__PACKAGE__->SUPER::private < MyTest::Mother');
    is(__PACKAGE__->$fqname, 'mother!', '__PACKAGE__->$fqname < MyTest::Mother');
    is($self->SUPER::private, 'mother!', '$self->SUPER::private < MyTest::Mother');
    is($self->$fqname, 'mother!', '$self->$fqname < MyTest::Mother');

    $fqname = "SUPER'private";
    is(__PACKAGE__->$fqname, 'mother!', '__PACKAGE__->$fqname < MyTest::Mother');
    is($self->$fqname, 'mother!', '$self->$fqname < MyTest::Mother');

    $fqname = 'MyTest::Child::SUPER::private';
    is(__PACKAGE__->MyTest::Child::SUPER::private, 'mother!', '__PACKAGE__->MyTest::Child::SUPER::private < MyTest::Mother');
    is(__PACKAGE__->$fqname, 'mother!', '__PACKAGE__->$fqname < MyTest::Mother');
    is($self->MyTest::Child::SUPER::private, 'mother!', '$self->MyTest::Child::SUPER::private < MyTest::Mother');
    is($self->$fqname, 'mother!', '$self->$fqname < MyTest::Mother');

    $fqname = "MyTest::Child::SUPER'private";
    is(__PACKAGE__->$fqname, 'mother!', '__PACKAGE__->$fqname < MyTest::Mother');
    is($self->$fqname, 'mother!', '$self->$fqname < MyTest::Mother');

    $fqname = "MyTest::Child'SUPER::private";
    is(__PACKAGE__->$fqname, 'mother!', '__PACKAGE__->$fqname < MyTest::Mother');
    is($self->$fqname, 'mother!', '$self->$fqname < MyTest::Mother');

    $fqname = "MyTest::Child'SUPER'private";
    is(__PACKAGE__->$fqname, 'mother!', '__PACKAGE__->$fqname < MyTest::Mother');
    is($self->$fqname, 'mother!', '$self->$fqname < MyTest::Mother');

    $fqname = "MyTest'Child::SUPER::private";
    is(__PACKAGE__->$fqname, 'mother!', '__PACKAGE__->$fqname < MyTest::Mother');
    is($self->$fqname, 'mother!', '$self->$fqname < MyTest::Mother');

    $fqname = "MyTest'Child::SUPER'private";
    is(__PACKAGE__->$fqname, 'mother!', '__PACKAGE__->$fqname < MyTest::Mother');
    is($self->$fqname, 'mother!', '$self->$fqname < MyTest::Mother');

    $fqname = "MyTest'Child'SUPER::private";
    is(__PACKAGE__->$fqname, 'mother!', '__PACKAGE__->$fqname < MyTest::Mother');
    is($self->$fqname, 'mother!', '$self->$fqname < MyTest::Mother');

    $fqname = "MyTest'Child'SUPER'private";
    is(__PACKAGE__->$fqname, 'mother!', '__PACKAGE__->$fqname < MyTest::Mother');
    is($self->$fqname, 'mother!', '$self->$fqname < MyTest::Mother');

    @ISA = qw(MyTest::Father);

    $fqname = 'SUPER::private';
    is(__PACKAGE__->SUPER::private, 'father!', '__PACKAGE__->SUPER::private < MyTest::Father');
    is(__PACKAGE__->$fqname, 'father!', '__PACKAGE__->$fqname < MyTest::Father');
    is($self->SUPER::private, 'father!', '$self->SUPER::private < MyTest::Father');
    is($self->$fqname, 'father!', '$self->$fqname < MyTest::Father');

    $fqname = 'MyTest::Child::SUPER::private';
    is(__PACKAGE__->MyTest::Child::SUPER::private, 'father!', '__PACKAGE__->MyTest::Child::SUPER::private < MyTest::Father');
    is(__PACKAGE__->$fqname, 'father!', '__PACKAGE__->$fqname < MyTest::Father');
    is($self->MyTest::Child::SUPER::private, 'father!', '$self->MyTest::Child::SUPER::private < MyTest::Father');
    is($self->$fqname, 'father!', '$self->$fqname < MyTest::Father');

    @ISA = qw(MyTest::Parent);

    $fqname = 'SUPER::private';
    is(__PACKAGE__->SUPER::private, 'parent!', '__PACKAGE__->SUPER::private < MyTest::Parent');
    is(__PACKAGE__->$fqname, 'parent!', '__PACKAGE__->$fqname < MyTest::Parent');
    is($self->SUPER::private, 'parent!', '$self->SUPER::private < MyTest::Parent');
    is($self->$fqname, 'parent!', '$self->$fqname < MyTest::Parent');

    $fqname = 'MyTest::Child::SUPER::private';
    is(__PACKAGE__->MyTest::Child::SUPER::private, 'parent!', '__PACKAGE__->MyTest::Child::SUPER::private < MyTest::Parent');
    is(__PACKAGE__->$fqname, 'parent!', '__PACKAGE__->$fqname < MyTest::Parent');
    is($self->MyTest::Child::SUPER::private, 'parent!', '$self->MyTest::Child::SUPER::private < MyTest::Parent');
    is($self->$fqname, 'parent!', '$self->$fqname < MyTest::Parent');
}
