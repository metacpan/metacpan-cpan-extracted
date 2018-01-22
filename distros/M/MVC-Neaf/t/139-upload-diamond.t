#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(weaken);

use MVC::Neaf::Upload;

TODO: {

    local $TODO = "Diamond op may not work on perl < 5.10, but it's non-essential"
        if $] < 5.010;

    my $up = MVC::Neaf::Upload->new( id => "data", handle => \*DATA );

    is <$up>, "Foo\n", "Diamond op works"
        or diag "Read failed: $!";
    is <$up>, "Bared\n", "Diamond op works again"
        or diag "Read failed: $!";
};

note "TESTING LEAK";
# Because we use inside-out objects, must also test for leaks

{
    package Vanish;
    sub new {
        my ($class, $str) = @_;
        bless \$str, $class;
    };
    sub str {
        return ${ $_[0] };
    };
};

my $leaky = Vanish->new("fname");
my $weak  = [$leaky];
weaken $weak->[0];

my $newup = MVC::Neaf::Upload->new(
    id => "leak", filename => $leaky, handle => \*DATA );

undef $leaky;
is ref $weak->[0], "Vanish", "Leaky ref still present";
is $newup->filename->str, "fname", "Leaky ref in upload obj";
undef $newup;
ok !$weak->[0], "Leaky ref disappeared";

done_testing;

__DATA__
Foo
Bared
Bazzz
