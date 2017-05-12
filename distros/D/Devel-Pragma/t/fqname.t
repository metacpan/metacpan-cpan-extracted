#!/usr/bin/env perl

use strict;
use warnings;

use vars qw(@RESULTS);

use Test::More tests => 1;

package MyPragma;

use Devel::Pragma qw(fqname);

sub import {
    my ($class, @names) = @_;

    for my $name (@names) {
        my $fqname = fqname($name);
        push @::RESULTS, $fqname;
    }
}

package MySubPragma;

BEGIN { our @ISA = qw(MyPragma) }

sub import {
    shift->SUPER::import(@_);
}

package main;

BEGIN { MyPragma->import(qw(foo Foo::Bar::baz Foo'Bar'baz Foo'Bar::baz)) }

{
    package Some::Other::Package;

    BEGIN { MySubPragma->import(qw(quux)) }

    ::is_deeply(
        \@::RESULTS,
        [ qw(main::foo Foo::Bar::baz Foo::Bar::baz Foo::Bar::baz Some::Other::Package::quux) ],
        'fqname'
    );
}
