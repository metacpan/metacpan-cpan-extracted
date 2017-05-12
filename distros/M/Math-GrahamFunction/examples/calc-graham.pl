#!/usr/bin/perl

use strict;
use warnings;

use Math::GrahamFunction;

my $n = shift;

if (!defined($n))
{
    die "You must specify an argument.";
}
if ($n !~ /^\d+$/)
{
    die "Argument is not numeric.";
}

my $obj = Math::GrahamFunction->new({n => $n});

my $values = $obj->solve();
print map { "$_\n" } @{$values->{factors}};
