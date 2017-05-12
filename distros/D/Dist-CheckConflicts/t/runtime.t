#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib/runtime';

use Module::Runtime 'require_module';

sub warnings_ok {
    my ($class, @conflicts) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    @conflicts = sort map { "Conflict detected for $_->[0]:\n  $_->[1] is version $_->[2], but must be greater than version $_->[3]\n" } @conflicts;

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        require_module($class);
    }
    @warnings = sort @warnings;

    is_deeply(\@warnings, \@conflicts, "correct runtime warnings for $class");
}

warnings_ok(
    'Foo',
    ['Foo::Conflicts', 'Foo::Foo', '0.01', '0.01'],
    ['Foo::Conflicts', 'Foo::Bar', '0.01', '0.01'],
);
warnings_ok(
    'Bar',
    ['Bar::Conflicts', 'Bar::Baz::Bad',  '0.01', '0.01'],
    ['Bar::Conflicts', 'Bar::Foo::Bad',  '0.01', '0.01'],
    ['Bar::Conflicts', 'Bar::Foo',       '0.01', '0.01'],
    ['Bar::Conflicts', 'Bar::Bar::Bad',  '0.01', '0.01'],
    ['Bar::Conflicts', 'Bar::Bar',       '0.01', '0.01'],
    ['Bar::Conflicts', 'Bar::Quux::Bad', '0.01', '0.01'],
);

is(Bar::Foo->contents, "__DATA__ for Bar::Foo\n", "__DATA__ sections intact");
is(Bar::Bar->contents, "__DATA__ for Bar::Bar\n", "__DATA__ sections intact");
is(Bar::Baz->contents, "__DATA__ for Bar::Baz\n", "__DATA__ sections intact");
is(Bar::Quux->contents, "__DATA__ for Bar::Quux\n", "__DATA__ sections intact");

is(scalar(grep { ref($_) eq 'ARRAY' && @$_ > 1 && ref($_->[1]) eq 'HASH' }
               @INC),
   1,
   "only installed one \@INC hook");

done_testing;
