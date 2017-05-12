#!/usr/bin/perl -w

use strict;
use Test::More tests => 34;
use Test::Differences;

use Devel::ebug;
use Devel::ebug::Wx::View::Expressions;

my $called = 0;

{
    package MyEbug;

    sub eval_level {
        ++$called;
        shift->{ebug}->eval_level( @_ );
    }

    our $AUTOLOAD;
    sub AUTOLOAD {
        ( my $method = $AUTOLOAD ) =~ s/.*:://;
        return if $method eq 'DESTROY';
        return shift->{ebug}->$method( @_ );
    }
}

sub _normalize($);
sub _normalize($) {
    my $val = shift;

    if( ref( $val ) eq 'ARRAY' ) {
        return [ map _normalize( $_ ), @$val ];
    } elsif( ref( $val ) eq 'HASH' ) {
        return { map { $_ => _normalize( $val->{$_} ) } keys %$val };
    } elsif( defined $val ) {
        $val =~ s/(ARRAY|HASH)\(0x.*?\)/$1(0xaddr)/;
        return $val;
    } else {
        return '<undef>';
    }
}

my $ebug = Devel::ebug->new;
my $myebug = bless { ebug => $ebug }, 'MyEbug';
$myebug->program( '-e 42' );
$myebug->load;

my $model = Devel::ebug::Wx::View::Expressions::Model->new
                 ( { _expressions => [], _values => [], ebug => $myebug } );

is( $model->get_child_count( '' ), 0 );
is( $called, 0 );

$model->add_expression( 'die "moo\n"' );
$model->add_expression( '[1,2,[3,4,5,{6,7,8,9}]]' );

is( $model->get_child_count( '' ), 2 );
is( $called, 0 );

eq_or_diff( [ $model->expressions ],
            [ { level => 0, expression => 'die "moo\n"', },
              { level => 0, expression => '[1,2,[3,4,5,{6,7,8,9}]]', },
              ] );

eq_or_diff( _normalize [ $model->get_root ],
            _normalize [ '', 'root', undef, undef ] );

is( $model->get_child_count( '0' ), 0 );
is( $called, 1 );
is( $model->get_child_count( '1' ), 3 );
is( $called, 2 );

eq_or_diff( _normalize $model->_values->[0],
            [ 1, "moo\n" ] );

eq_or_diff( _normalize $model->_values->[1],
            [ '0',
              { string => 'ARRAY(0xaddr)',
                type   => 'ARRAY',
                childs => '3',
                } ] );

is( _normalize $model->get_child( '1', 2 ), "2 => ARRAY(0xaddr)" );
is( $called, 3 );
is( _normalize $model->get_child( '1,2', 3 ), "3 => HASH(0xaddr)" );
is( $called, 3 );

eq_or_diff( _normalize $model->_values->[1],
            [ '0',
              { string => 'ARRAY(0xaddr)',
                type   => 'ARRAY',
                keys   =>
                  [ [ '0',
                      { string => '1',
                        type   => '',
                        value  => '1',
                        } ],
                    [ '1',
                      { string => '2',
                        type   => '',
                        value  => '2',
                        } ],
                    [ '2',
                      { string => 'ARRAY(0xaddr)',
                        type   => 'ARRAY',
                        keys   =>
                          [ [ '0',
                              { string => '3',
                                type   => '',
                                value  => '3',
                                } ],
                            [ '1',
                              { string => '4',
                                type   => '',
                                value  => '4',
                                } ],
                            [ '2',
                              { string => '5',
                                type   => '',
                                value  => '5',
                                } ],
                            [ '3',
                              { string => 'HASH(0xaddr)',
                                type   => 'HASH',
                                childs => '2',
                                } ],
                            ],
                        } ],
                    ],
                } ] );

is( $model->get_child( '1,2,3', 0 ), '6 => 7' );

is( $called, 4 );

is( $model->get_child_count( '1,0' ), 0 );
is( $model->get_child_count( '1,1' ), 0 );
is( $model->get_child_count( '1,2' ), 4 );
is( $model->get_child_count( '1,2,0' ), 0 );
is( $model->get_child_count( '1,2,1' ), 0 );
is( $model->get_child_count( '1,2,2' ), 0 );
is( $model->get_child_count( '1,2,3' ), 2 );
is( $model->get_child_count( '1,2,3,0' ), 0 );
is( $model->get_child_count( '1,2,3,1' ), 0 );

is( $called, 4 );

is( $model->get_child( '1,2,3', 0 ), '6 => 7' );
is( $model->get_child( '1,2,3', 1 ), '8 => 9' );

is( $called, 4 );

eq_or_diff( _normalize [ $model->get_child( '', 0 ) ],
            [ 0, 'die "moo\\n" = moo', '<undef>',
              { expression => 'die "moo\\n"', level => 0 } ] );
eq_or_diff( _normalize [ $model->get_child( '', 1 ) ],
            [ 1, '[1,2,[3,4,5,{6,7,8,9}]] = ARRAY(0xaddr)', '<undef>',
              { expression => '[1,2,[3,4,5,{6,7,8,9}]]', level => 4 } ] );
