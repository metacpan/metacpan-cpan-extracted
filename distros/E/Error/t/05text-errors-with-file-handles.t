#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Error qw(:try);

BEGIN
{
    use File::Spec;
    use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");
    use MyDie;
}

package MyError::Foo;

use vars qw(@ISA);

@ISA=(qw(Error));

package main;

my $ok = 1;
eval
{
    try
    {
        MyDie::mydie();
    }
    catch MyError::Foo with
    {
        my $err = shift;
        $ok = 0;
    };
};

my $err = $@;

# TEST
ok($ok, "Not MyError::Foo");

# TEST
ok($err->isa("Error::Simple"), "Testing");

# TEST
is($err->{-line}, 19, "Testing for correct line number");

# TEST
ok(($err->{-file} =~ m{MyDie\.pm$}), "Testing for correct module");

