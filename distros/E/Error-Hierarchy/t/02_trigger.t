#!/usr/bin/env perl
use strict;
use warnings;
use Error ':try';
use Test::More tests => 2;
use Capture::Tiny 'capture';
use Error::Hierarchy::Container;
use Error::Hierarchy::Internal::Class;

Error::Hierarchy::Container->add_trigger(before_push => sub {
    my ($self, @values) = @_;
    UNIVERSAL::isa($_, 'Error::Hierarchy') or warn $_ for @values;
});

my ($stdout, $stderr) = capture {
    my $container = Error::Hierarchy::Container->new;
    $container->items_push(
        Error::Hierarchy::Internal::Class->new(
            class_expected => 'Foo',
            class_got      => 'Bar'
        ),
        Error::Simple->new("Annoying: Can't locate Foo/Bar.pm"),
        Error::Hierarchy::Internal::Class->new(
            class_expected => 'Bar',
            class_got      => 'Baz'
        ),
    );
};

is $stdout, '', 'STDOUT is empty';
like $stderr, qr!Annoying: Can't locate Foo/Bar\.pm at .* line \d+\.!, 'STDERR contains warning';
