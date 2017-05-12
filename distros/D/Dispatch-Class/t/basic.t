#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 17;

use Dispatch::Class qw(class_case dispatch);
use IO::Handle ();

{
    package DummyClass;
    sub new { bless {}, $_[0] }
    sub subclass {
        my $class = shift;
        for my $subclass (@_) {
            no strict 'refs';
            push @{$subclass . '::ISA'}, $class;
        }
    }
}

DummyClass->subclass(qw(Some::Class Other::Class));

my $analyze = class_case(
    'Some::Class'  => 1,
    'Other::Class' => 2,
    'UNIVERSAL'    => "???",
);
is $analyze->(Other::Class->new), 2;
is $analyze->(IO::Handle->new), "???";
is $analyze->(["not an object"]), undef;
is +() = $analyze->(["not an object"]), 0;

DummyClass->subclass(qw(Mammal Tree));
Mammal->subclass(qw(Dog Bunny));
Dog->subclass(qw(Dog::Tiny Barky Setter));
Tree->subclass(qw(Barky));

my @trace;

my $dispatch = dispatch(
    map {
        my $class = $_;
        $_ => sub {
            push @trace, $class;
            return $class, $_[0];
        }
    } qw(
        Tree
        Dog::Tiny
        Dog
        ARRAY
        Mammal
        :str
        HASH
        *
    )
);

my @prep = (
    'Tree' => Tree->new,
    'Mammal' => Mammal->new,
    'Dog' => Dog->new,
    'Mammal' => Bunny->new,
    'Dog::Tiny' => Dog::Tiny->new,
    'Tree' => Barky->new,
    'Dog' => Setter->new,
    'ARRAY' => [1, 2, 3],
    'HASH' => {A => 'b'},
    ':str' => "foo bar",
    ':str' => 5,
    '*' => IO::Handle->new,
);

my @ks;
for (my $i = 0; $i < @prep; $i += 2) {
    my ($k, $v) = @prep[$i, $i + 1];
    my @got = $dispatch->($v);
    is_deeply \@got, [$k, $v];
    push @ks, $k;
}
is_deeply \@trace, \@ks;
