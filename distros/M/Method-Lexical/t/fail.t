#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 33;

our $GLOB = qr{^Can't locate object method "private" via package "IO::(?:File|Handle)" };
our $NONE1 = qr{^Can't locate object method "NoSuchMethod" via package "main" };
our $NONE2 = qr{^Can't locate object method "Method" via package "No::Such" };
our $SUPER1 = qr{Can't locate object method "SUPER" via package "main" };
our $SUPER2 = qr{Can't locate object method "SUPER" via package "Foo" };
our $UNBLESSED = qr{^Can't call method "private" on unblessed reference };
our $UNDEF = qr{^Can't call method "private" on an undefined value };

our $NONREF = ($] >= 5.017005)
    ? qr{^Can't locate object method "private" via package }
    : qr{^Can't call method "private" without a package or object reference };

{
    use Method::Lexical 'UNIVERSAL::private' => sub { 'private!' };

    my $self = bless {};
    my $private = 'private';
    my $undef = undef;
    my $nonref = 42;
    my $unblessed = [];
    my $stdout = *STDOUT;
    my $name1 = 'NoSuchMethod';
    my $name2 = 'No::Such::Method';
    my $super1 = 'SUPER';
    my $super2 = 'Foo::SUPER';

    is($self->private(), 'private!', 'lexical methods works for blessed reference');

    eval { undef->private() };
    like($@, $UNDEF, 'method call on undefined literal passed through to pp_method_named');

    eval { $undef->private() };
    like($@, $UNDEF, 'method call on undefined variable passed through to pp_method_named');

    eval { undef->$private() };
    like($@, $UNDEF, 'method call on undefined literal passed through to pp_method');

    eval { $undef->$private() };
    like($@, $UNDEF, 'method call on undefined variable passed through to pp_method');

    eval { 42->private() };
    like($@, $NONREF, 'method call on a non-reference literal passed through to pp_method_named');

    eval { $nonref->private() };
    like($@, $NONREF, 'method call on a non-reference variable passed through to pp_method_named');

    eval { 42->$private() };
    like($@, $NONREF, 'method call on a non-reference literal passed through to pp_method');

    eval { $nonref->$private() };
    like($@, $NONREF, 'method call on a non-reference variable passed through to pp_method');

    eval { []->private() };
    like($@, $UNBLESSED, 'method call on unblessed reference literal passed through to pp_method_named');

    eval { $unblessed->private() };
    like($@, $UNBLESSED, 'method call on unblessed reference variable passed through to pp_method_named');

    eval { []->$private() };
    like($@, $UNBLESSED, 'method call on unblessed reference literal passed through to pp_method');

    eval { $unblessed->$private() };
    like($@, $UNBLESSED, 'method call on unblessed reference variable passed through to pp_method');

    eval { *STDOUT->private() };
    like($@, $GLOB, 'method call on GVIO literal passed through to pp_method_named');

    eval { $stdout->private() };
    like($@, $GLOB, 'method call on GVIO variable passed through to pp_method_named');

    eval { *STDOUT->$private() };
    like($@, $GLOB, 'method call on GVIO literal passed through to pp_method');

    eval { $stdout->$private() };
    like($@, $GLOB, 'method call on GVIO variable passed through to pp_method');

    eval { $self->NoSuchMethod() };
    like($@, $NONE1, '$self->NoSuchMethod passed through to pp_method_named');

    eval { __PACKAGE__->NoSuchMethod() };
    like($@, $NONE1, '__PACKAGE__->NoSuchMethod passed through to pp_method_named');

    eval { $self->$name1() };
    like($@, $NONE1, '$self->$name1 passed through to pp_method');

    eval { __PACKAGE__->$name1() };
    like($@, $NONE1, '__PACKAGE__->$name1 passed through to pp_method');

    eval { $self->No::Such::Method() };
    like($@, $NONE2, '$self->No::Such::Method passed through to pp_method_named');

    eval { __PACKAGE__->No::Such::Method() };
    like($@, $NONE2, '__PACKAGE__->No::Such::Method passed through to pp_method_named');

    eval { $self->$name2() };
    like($@, $NONE2, '$self->$name2 passed through to pp_method');

    eval { __PACKAGE__->$name2() };
    like($@, $NONE2, '__PACKAGE__->$name2 passed through to pp_method');

    eval { $self->SUPER() };
    like($@, $SUPER1, '$self->SUPER passed through to pp_method_named');

    eval { __PACKAGE__->SUPER() };
    like($@, $SUPER1, '__PACKAGE__->SUPER passed through to pp_method_named');

    eval { $self->$super1() };
    like($@, $SUPER1, '$self->$super1 passed through to pp_method');

    eval { __PACKAGE__->$super1() };
    like($@, $SUPER1, '__PACKAGE__->$super1 passed through to pp_method');

    eval { $self->Foo::SUPER() };
    like($@, $SUPER2, '$self->Foo::SUPER passed through to pp_method_named');

    eval { __PACKAGE__->Foo::SUPER() };
    like($@, $SUPER2, '__PACKAGE__->Foo::SUPER passed through to pp_method_named');

    eval { $self->$super2() };
    like($@, $SUPER2, '$self->$super2 passed through to pp_method');

    eval { __PACKAGE__->$super2() };
    like($@, $SUPER2, '__PACKAGE__->$super2 passed through to pp_method');
}
