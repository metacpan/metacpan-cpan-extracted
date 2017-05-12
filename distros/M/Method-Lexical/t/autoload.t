#!/usr/bin/env perl

use strict;
use warnings;

my $main = bless {};

{
    package Method::Lexical::Test;

    use Test::More tests => 25;
    use Data::Dumper;
    our $AUTOLOAD;

    use Method::Lexical {
         AUTOLOAD             => sub { [ 1, $AUTOLOAD, @_ ] },
        'main::AUTOLOAD'      => sub { [ 2, $AUTOLOAD, @_ ] },
        'UNIVERSAL::AUTOLOAD' => sub { [ 3, $AUTOLOAD, @_ ] },
    };

    my $self = bless {};
    my $dumper = Data::Dumper->new([ 1 ]);
    my $foo = 'foo';

    isa_ok($dumper, 'Data::Dumper', 'Data::Dumper::new not clobbered by UNIVERSAL::AUTOLOAD');

    is_deeply(__PACKAGE__->foo(), [ 1, 'Method::Lexical::Test::foo', __PACKAGE__ ]);
    is_deeply($self->foo(), [ 1, 'Method::Lexical::Test::foo', $self ]);
    is_deeply(__PACKAGE__->foo(42), [ 1, 'Method::Lexical::Test::foo', __PACKAGE__, 42 ]);
    is_deeply($self->foo(42), [ 1, 'Method::Lexical::Test::foo', $self, 42 ]);

    is_deeply(__PACKAGE__->$foo(), [ 1, 'Method::Lexical::Test::foo', __PACKAGE__ ]);
    is_deeply($self->$foo(), [ 1, 'Method::Lexical::Test::foo', $self ]);
    is_deeply(__PACKAGE__->$foo(42), [ 1, 'Method::Lexical::Test::foo', __PACKAGE__, 42 ]);
    is_deeply($self->$foo(42), [ 1, 'Method::Lexical::Test::foo', $self, 42 ]);

    is_deeply(main->foo(), [ 2, 'main::foo', 'main' ]);
    is_deeply($main->foo(), [ 2, 'main::foo', $main ]);
    is_deeply(main->foo(42), [ 2, 'main::foo', 'main', 42 ]);
    is_deeply($main->foo(42), [ 2, 'main::foo', $main, 42 ]);

    is_deeply(main->$foo(), [ 2, 'main::foo', 'main' ]);
    is_deeply($main->$foo(), [ 2, 'main::foo', $main ]);
    is_deeply(main->$foo(42), [ 2, 'main::foo', 'main', 42 ]);
    is_deeply($main->$foo(42), [ 2, 'main::foo', $main, 42 ]);

    is_deeply(Data::Dumper->foo(), [ 3, 'Data::Dumper::foo', 'Data::Dumper' ]);
    is_deeply($dumper->foo(), [ 3, 'Data::Dumper::foo', $dumper ]);
    is_deeply(Data::Dumper->foo(42), [ 3, 'Data::Dumper::foo', 'Data::Dumper', 42 ]);
    is_deeply($dumper->foo(42), [ 3, 'Data::Dumper::foo', $dumper, 42 ]);

    is_deeply(Data::Dumper->$foo(), [ 3, 'Data::Dumper::foo', 'Data::Dumper' ]);
    is_deeply($dumper->$foo(), [ 3, 'Data::Dumper::foo', $dumper ]);
    is_deeply(Data::Dumper->$foo(42), [ 3, 'Data::Dumper::foo', 'Data::Dumper', 42 ]);
    is_deeply($dumper->$foo(42), [ 3, 'Data::Dumper::foo', $dumper, 42 ]);
}
