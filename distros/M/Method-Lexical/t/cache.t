#!/usr/bin/env perl

use strict;
use warnings;

# this verifies that method caching doesn't break anything, but the caching behaviour
# can better be verified by looking at the output of this test with e.g.
#
#     METHOD_LEXICAL_DEBUG=1 prove -vb t/cache.t

{
    package MyTest::Parent;

    sub private { 'parent!' } # ordinary public method

    package MyTest::Mother;
    package MyTest::Father;
    package MyTest::Child;

    use Test::More tests => 136;

    use Method::Lexical {
         private                  => sub { 'child!'  },
        'MyTest::Mother::private' => sub { 'mother!' },
        'MyTest::Father::private' => sub { 'father!' },
    };

    our @ISA;

    my $self = bless {};
    my $fqname;

    for my $isa (
        [ [ qw(MyTest::Mother) ], 'mother!' ],
        [ [ qw(MyTest::Mother) ], 'mother!' ], # don't smash the cache the second time through
        [ [ qw(MyTest::Father) ], 'father!' ],
        [ [ qw(MyTest::Parent) ], 'parent!' ]
    ) {
        my $want = 'child!';

        $fqname = 'private';
        is(__PACKAGE__->private, $want, '__PACKAGE__->private ('.__LINE__.')');
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->private, $want, '$self->private ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        @ISA = @{$isa->[0]};
        $want = $isa->[1];

        $fqname = 'SUPER::private';
        is(__PACKAGE__->SUPER::private, $want, '__PACKAGE__->SUPER::private ('.__LINE__.')');
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->SUPER::private, $want, '$self->SUPER::private ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = "SUPER'private";
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = 'SUPER::private';
        is(__PACKAGE__->SUPER::private, $want, '__PACKAGE__->SUPER::private ('.__LINE__.')');
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->SUPER::private, $want, '$self->SUPER::private ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = "SUPER'private";
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = 'MyTest::Child::SUPER::private';
        is(__PACKAGE__->MyTest::Child::SUPER::private, $want, '__PACKAGE__->MyTest::Child::SUPER::private ('.__LINE__.')');
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->MyTest::Child::SUPER::private, $want, '$self->MyTest::Child::SUPER::private ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = "MyTest::Child::SUPER'private";
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = "MyTest::Child'SUPER::private";
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = "MyTest::Child'SUPER'private";
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = "MyTest'Child::SUPER::private";
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = "MyTest'Child::SUPER'private";
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = "MyTest'Child'SUPER::private";
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');

        $fqname = "MyTest'Child'SUPER'private";
        is(__PACKAGE__->$fqname, $want, '__PACKAGE__->$fqname ('.__LINE__.')');
        is($self->$fqname, $want, '$self->$fqname ('.__LINE__.')');
    }
}
