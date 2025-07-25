# This file was autogenerated.

=head1 NAME

t/unit/Hydrogen/Topic/ArrayRef.t - unit tests for Hydrogen::Topic::ArrayRef

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022-2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

use 5.008001;
use strict;
use warnings;
use Test2::V0 -target => "Hydrogen::Topic::ArrayRef";

isa_ok( 'Hydrogen::Topic::ArrayRef', 'Exporter::Tiny' );

my %EXPORTS = map +( $_ => 1 ), @Hydrogen::Topic::ArrayRef::EXPORT_OK;

subtest 'accessor' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::accessor), 'function exists';
    ok $EXPORTS{'accessor'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        Hydrogen::Topic::ArrayRef::accessor( 1, 'quux' );
        is( $_, [ 'foo', 'quux', 'baz' ], q{$_ deep match} );
        is( Hydrogen::Topic::ArrayRef::accessor( 2 ), 'baz', q{Hydrogen::Topic::ArrayRef::accessor( 2 ) is 'baz'} );
    };
    is $exception, undef, 'no exception thrown running accessor example';
};

subtest 'all' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::all), 'function exists';
    ok $EXPORTS{'all'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar' ];
        my @list = Hydrogen::Topic::ArrayRef::all();
        is( \@list, [ 'foo', 'bar' ], q{\@list deep match} );
    };
    is $exception, undef, 'no exception thrown running all example';
};

subtest 'all_true' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::all_true), 'function exists';
    ok $EXPORTS{'all_true'}, 'function is importable';
};

subtest 'any' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::any), 'function exists';
    ok $EXPORTS{'any'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        my $truth  = Hydrogen::Topic::ArrayRef::any( sub { /a/ } );
        ok( $truth, q{$truth is true} );
    };
    is $exception, undef, 'no exception thrown running any example';
};

subtest 'apply' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::apply), 'function exists';
    ok $EXPORTS{'apply'}, 'function is importable';
};

subtest 'clear' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::clear), 'function exists';
    ok $EXPORTS{'clear'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo' ];
        Hydrogen::Topic::ArrayRef::clear();
        is( $_, [], q{$_ deep match} );
    };
    is $exception, undef, 'no exception thrown running clear example';
};

subtest 'count' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::count), 'function exists';
    ok $EXPORTS{'count'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar' ];
        is( Hydrogen::Topic::ArrayRef::count(), 2, q{Hydrogen::Topic::ArrayRef::count() is 2} );
    };
    is $exception, undef, 'no exception thrown running count example';
};

subtest 'delete' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::delete), 'function exists';
    ok $EXPORTS{'delete'}, 'function is importable';
};

subtest 'elements' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::elements), 'function exists';
    ok $EXPORTS{'elements'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar' ];
        my @list = Hydrogen::Topic::ArrayRef::elements();
        is( \@list, [ 'foo', 'bar' ], q{\@list deep match} );
    };
    is $exception, undef, 'no exception thrown running elements example';
};

subtest 'first' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::first), 'function exists';
    ok $EXPORTS{'first'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        my $found  = Hydrogen::Topic::ArrayRef::first( sub { /a/ } );
        is( $found, 'bar', q{$found is 'bar'} );
    };
    is $exception, undef, 'no exception thrown running first example';
};

subtest 'first_index' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::first_index), 'function exists';
    ok $EXPORTS{'first_index'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        my $found  = Hydrogen::Topic::ArrayRef::first_index( sub { /z$/ } );
        is( $found, 2, q{$found is 2} );
    };
    is $exception, undef, 'no exception thrown running first_index example';
};

subtest 'flatten' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::flatten), 'function exists';
    ok $EXPORTS{'flatten'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar' ];
        my @list = Hydrogen::Topic::ArrayRef::flatten();
        is( \@list, [ 'foo', 'bar' ], q{\@list deep match} );
    };
    is $exception, undef, 'no exception thrown running flatten example';
};

subtest 'flatten_deep' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::flatten_deep), 'function exists';
    ok $EXPORTS{'flatten_deep'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', [ 'bar', [ 'baz' ] ] ];
        is( [ Hydrogen::Topic::ArrayRef::flatten_deep() ], [ 'foo', 'bar', 'baz' ], q{[ Hydrogen::Topic::ArrayRef::flatten_deep() ] deep match} );
      
        $_ = [ 'foo', [ 'bar', [ 'baz' ] ] ];
        is( [ Hydrogen::Topic::ArrayRef::flatten_deep(1) ], [ 'foo', 'bar', [ 'baz' ] ], q{[ Hydrogen::Topic::ArrayRef::flatten_deep(1) ] deep match} );
    };
    is $exception, undef, 'no exception thrown running flatten_deep example';
};

subtest 'for_each' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::for_each), 'function exists';
    ok $EXPORTS{'for_each'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        Hydrogen::Topic::ArrayRef::for_each( sub { note "Item $_[1] is $_[0]." } );
    };
    is $exception, undef, 'no exception thrown running for_each example';
};

subtest 'for_each_pair' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::for_each_pair), 'function exists';
    ok $EXPORTS{'for_each_pair'}, 'function is importable';
};

subtest 'get' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::get), 'function exists';
    ok $EXPORTS{'get'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        is( Hydrogen::Topic::ArrayRef::get(  0 ), 'foo', q{Hydrogen::Topic::ArrayRef::get(  0 ) is 'foo'} );
        is( Hydrogen::Topic::ArrayRef::get(  1 ), 'bar', q{Hydrogen::Topic::ArrayRef::get(  1 ) is 'bar'} );
        is( Hydrogen::Topic::ArrayRef::get( -1 ), 'baz', q{Hydrogen::Topic::ArrayRef::get( -1 ) is 'baz'} );
    };
    is $exception, undef, 'no exception thrown running get example';
};

subtest 'grep' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::grep), 'function exists';
    ok $EXPORTS{'grep'}, 'function is importable';
};

subtest 'head' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::head), 'function exists';
    ok $EXPORTS{'head'}, 'function is importable';
};

subtest 'indexed' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::indexed), 'function exists';
    ok $EXPORTS{'indexed'}, 'function is importable';
};

subtest 'insert' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::insert), 'function exists';
    ok $EXPORTS{'insert'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        Hydrogen::Topic::ArrayRef::insert( 1, 'quux' );
        is( $_, [ 'foo', 'quux', 'bar', 'baz' ], q{$_ deep match} );
    };
    is $exception, undef, 'no exception thrown running insert example';
};

subtest 'is_empty' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::is_empty), 'function exists';
    ok $EXPORTS{'is_empty'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar' ];
        ok( !(Hydrogen::Topic::ArrayRef::is_empty()), q{Hydrogen::Topic::ArrayRef::is_empty() is false} );
        $_ = [] ;
        ok( Hydrogen::Topic::ArrayRef::is_empty(), q{Hydrogen::Topic::ArrayRef::is_empty() is true} );
    };
    is $exception, undef, 'no exception thrown running is_empty example';
};

subtest 'join' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::join), 'function exists';
    ok $EXPORTS{'join'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        is( Hydrogen::Topic::ArrayRef::join(), 'foo,bar,baz', q{Hydrogen::Topic::ArrayRef::join() is 'foo,bar,baz'} );
        is( Hydrogen::Topic::ArrayRef::join( '|' ), 'foo|bar|baz', q{Hydrogen::Topic::ArrayRef::join( '|' ) is 'foo|bar|baz'} );
    };
    is $exception, undef, 'no exception thrown running join example';
};

subtest 'map' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::map), 'function exists';
    ok $EXPORTS{'map'}, 'function is importable';
};

subtest 'max' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::max), 'function exists';
    ok $EXPORTS{'max'}, 'function is importable';
};

subtest 'maxstr' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::maxstr), 'function exists';
    ok $EXPORTS{'maxstr'}, 'function is importable';
};

subtest 'min' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::min), 'function exists';
    ok $EXPORTS{'min'}, 'function is importable';
};

subtest 'minstr' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::minstr), 'function exists';
    ok $EXPORTS{'minstr'}, 'function is importable';
};

subtest 'natatime' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::natatime), 'function exists';
    ok $EXPORTS{'natatime'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        my $iter   = Hydrogen::Topic::ArrayRef::natatime( 2 );
        is( [ $iter->() ], [ 'foo', 'bar' ], q{[ $iter->() ] deep match} );
        is( [ $iter->() ], [ 'baz' ], q{[ $iter->() ] deep match} );
    };
    is $exception, undef, 'no exception thrown running natatime example';
};

subtest 'not_all_true' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::not_all_true), 'function exists';
    ok $EXPORTS{'not_all_true'}, 'function is importable';
};

subtest 'pairfirst' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::pairfirst), 'function exists';
    ok $EXPORTS{'pairfirst'}, 'function is importable';
};

subtest 'pairgrep' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::pairgrep), 'function exists';
    ok $EXPORTS{'pairgrep'}, 'function is importable';
};

subtest 'pairkeys' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::pairkeys), 'function exists';
    ok $EXPORTS{'pairkeys'}, 'function is importable';
};

subtest 'pairmap' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::pairmap), 'function exists';
    ok $EXPORTS{'pairmap'}, 'function is importable';
};

subtest 'pairs' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::pairs), 'function exists';
    ok $EXPORTS{'pairs'}, 'function is importable';
};

subtest 'pairvalues' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::pairvalues), 'function exists';
    ok $EXPORTS{'pairvalues'}, 'function is importable';
};

subtest 'pick_random' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::pick_random), 'function exists';
    ok $EXPORTS{'pick_random'}, 'function is importable';
};

subtest 'pop' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::pop), 'function exists';
    ok $EXPORTS{'pop'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        is( Hydrogen::Topic::ArrayRef::pop(), 'baz', q{Hydrogen::Topic::ArrayRef::pop() is 'baz'} );
        is( Hydrogen::Topic::ArrayRef::pop(), 'bar', q{Hydrogen::Topic::ArrayRef::pop() is 'bar'} );
        is( $_, [ 'foo' ], q{$_ deep match} );
    };
    is $exception, undef, 'no exception thrown running pop example';
};

subtest 'print' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::print), 'function exists';
    ok $EXPORTS{'print'}, 'function is importable';
};

subtest 'product' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::product), 'function exists';
    ok $EXPORTS{'product'}, 'function is importable';
};

subtest 'push' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::push), 'function exists';
    ok $EXPORTS{'push'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo' ];
        Hydrogen::Topic::ArrayRef::push( 'bar', 'baz' );
        is( $_, [ 'foo', 'bar', 'baz' ], q{$_ deep match} );
    };
    is $exception, undef, 'no exception thrown running push example';
};

subtest 'reduce' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::reduce), 'function exists';
    ok $EXPORTS{'reduce'}, 'function is importable';
};

subtest 'reductions' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::reductions), 'function exists';
    ok $EXPORTS{'reductions'}, 'function is importable';
};

subtest 'reset' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::reset), 'function exists';
    ok $EXPORTS{'reset'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        Hydrogen::Topic::ArrayRef::reset();
        is( $_, [], q{$_ deep match} );
    };
    is $exception, undef, 'no exception thrown running reset example';
};

subtest 'reverse' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::reverse), 'function exists';
    ok $EXPORTS{'reverse'}, 'function is importable';
};

subtest 'sample' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::sample), 'function exists';
    ok $EXPORTS{'sample'}, 'function is importable';
};

subtest 'set' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::set), 'function exists';
    ok $EXPORTS{'set'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        Hydrogen::Topic::ArrayRef::set( 1, 'quux' );
        is( $_, [ 'foo', 'quux', 'baz' ], q{$_ deep match} );
    };
    is $exception, undef, 'no exception thrown running set example';
};

subtest 'shallow_clone' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::shallow_clone), 'function exists';
    ok $EXPORTS{'shallow_clone'}, 'function is importable';
};

subtest 'shift' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::shift), 'function exists';
    ok $EXPORTS{'shift'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo', 'bar', 'baz' ];
        is( Hydrogen::Topic::ArrayRef::shift(), 'foo', q{Hydrogen::Topic::ArrayRef::shift() is 'foo'} );
        is( Hydrogen::Topic::ArrayRef::shift(), 'bar', q{Hydrogen::Topic::ArrayRef::shift() is 'bar'} );
        is( $_, [ 'baz' ], q{$_ deep match} );
    };
    is $exception, undef, 'no exception thrown running shift example';
};

subtest 'shuffle' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::shuffle), 'function exists';
    ok $EXPORTS{'shuffle'}, 'function is importable';
};

subtest 'shuffle_in_place' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::shuffle_in_place), 'function exists';
    ok $EXPORTS{'shuffle_in_place'}, 'function is importable';
};

subtest 'sort' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::sort), 'function exists';
    ok $EXPORTS{'sort'}, 'function is importable';
};

subtest 'sort_in_place' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::sort_in_place), 'function exists';
    ok $EXPORTS{'sort_in_place'}, 'function is importable';
};

subtest 'splice' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::splice), 'function exists';
    ok $EXPORTS{'splice'}, 'function is importable';
};

subtest 'sum' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::sum), 'function exists';
    ok $EXPORTS{'sum'}, 'function is importable';
};

subtest 'tail' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::tail), 'function exists';
    ok $EXPORTS{'tail'}, 'function is importable';
};

subtest 'uniq' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::uniq), 'function exists';
    ok $EXPORTS{'uniq'}, 'function is importable';
};

subtest 'uniq_in_place' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::uniq_in_place), 'function exists';
    ok $EXPORTS{'uniq_in_place'}, 'function is importable';
};

subtest 'uniqnum' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::uniqnum), 'function exists';
    ok $EXPORTS{'uniqnum'}, 'function is importable';
};

subtest 'uniqnum_in_place' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::uniqnum_in_place), 'function exists';
    ok $EXPORTS{'uniqnum_in_place'}, 'function is importable';
};

subtest 'uniqstr' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::uniqstr), 'function exists';
    ok $EXPORTS{'uniqstr'}, 'function is importable';
};

subtest 'uniqstr_in_place' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::uniqstr_in_place), 'function exists';
    ok $EXPORTS{'uniqstr_in_place'}, 'function is importable';
};

subtest 'unshift' => sub {
    ok exists(&Hydrogen::Topic::ArrayRef::unshift), 'function exists';
    ok $EXPORTS{'unshift'}, 'function is importable';
    my $exception = dies {
        local $_;
        $_ = [ 'foo' ];
        Hydrogen::Topic::ArrayRef::unshift( 'bar', 'baz' );
        is( $_, [ 'bar', 'baz', 'foo' ], q{$_ deep match} );
    };
    is $exception, undef, 'no exception thrown running unshift example';
};

done_testing; # :)
