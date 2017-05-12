#!/usr/bin/perl

use Test::More tests => 2;

use strict;
use warnings;

use Language::Prolog::Types qw(:short);
use Language::Prolog::Types::overload;
use Language::Prolog::Sugar functors => [qw(perl5_eval perl5_method)],
                            vars => [qw(X O)];
use Language::Prolog::Yaswi qw(:query);

$Language::Prolog::Yaswi::swi_converter->pass_as_opaque('Foo');

my $query = swi_parse q|perl5_method('Foo', new, [], [O]), perl5_method(O, foo, [], [X])|;
my ($x) = swi_find_one($query, X);
is ($x, Foo->foo, "method called");

my $bad_query = swi_parse q|perl5_method('Foo', new, [], [O]), perl5_method(O, bad, [], [X])|;
($x) = swi_find_one($bad_query, X);
is ($x, undef, "bad method called");

package Foo;

sub new {
    my $class = shift;
    my $self = bless { foo => 'bar' }, $class;
}

sub foo { 'method foo called' }
