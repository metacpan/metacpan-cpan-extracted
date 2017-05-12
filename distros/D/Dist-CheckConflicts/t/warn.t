#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib/warn';

{
    require Foo::Conflicts;

    my $warning = '';
    local $SIG{__WARN__} = sub { $warning .= $_[0] };
    my $conflicts = Foo::Conflicts->calculate_conflicts;
    is($warning, '', "we don't see warnings from loaded modules");
}

done_testing;
