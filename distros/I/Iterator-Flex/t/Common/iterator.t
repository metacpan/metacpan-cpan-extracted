#! perl

use strict;
use warnings;

use Test2::V0;

use Scalar::Util 'refaddr';
use Ref::Util 'is_ref';
use Iterator::Flex::Common 'iterator';

sub use_object {
    sub { $_[0]->next }
}
sub use_coderef {
    sub { $_[0]->() }
}

sub test {
    my ( $mknext ) = @_;
    my $ctx = context();

    subtest 'default' => sub {

        my $len = my @data = ( 1 .. 10 );
        my @got;
        my $iterator = iterator { shift @data };
        my $next     = $mknext->( $iterator );
        while ( @got <= $len and my $data = $next->( $iterator ) ) {
            push @got, $data;
        }

        ok( $iterator->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 10 ], "got data" );

    };


    for my $sentinel (
        [ undef  => sub { !defined $_[0] }, undef ],
        [ number => sub { $_[0] == $_[1] }, -22 ],
        [ string => sub { $_[0] eq $_[1] }, 'last' ],
        [
            reference => sub { is_ref( $_[0] ) && refaddr( $_[0] ) == refaddr( $_[1] ) },
            \1
        ],
      )
    {

        my ( $label, $compare, $value ) = @$sentinel;

        subtest "input exhaustion: sentinel is a $label" => sub {
            my $len = my @data = ( 1 .. 10 );
            my @got;
            my $iterator = iterator { shift( @data ) // $value }
            { input_exhaustion => [ return => $value ] };
            my $next = $mknext->( $iterator );
            while ( @got <= $len ) {
                my $data = $next->( $iterator );
                last if $compare->( $data, $value );
                push @got, $data;
            }
            ok( $iterator->is_exhausted, "exhausted flag" );
            is( \@got, [ 1 .. 10 ], "got data" );
        };

    }

    subtest "input exhaustion: throw" => sub {
        my $len = my @data = ( 1 .. 10 );
        my @got;
        my $iterator = iterator { shift( @data ) // die }
        {
            input_exhaustion => 'throw',
            exhaustion       => 'return',
        };
        my $next = $mknext->( $iterator );
        while ( @got <= $len ) {
            my $data = $next->( $iterator );
            last if !defined $data;
            push @got, $data;
        }
        ok( $iterator->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 10 ], "got data" );
    };


    subtest 'output exhaustion: throw' => sub {
        my $len = my @data = ( 1 .. 10 );
        my @got;
        my $iterator = iterator { shift @data } { exhaustion => 'throw' };
        my $next     = $mknext->( $iterator );

        my $err = dies {
            my $data;
            while ( @got <= $len ) {
                $data = $next->( $iterator );
                push @got, $data;
            }
        };

        isa_ok( $err, 'Iterator::Flex::Failure::Exhausted' );
        ok( $iterator->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 10 ], "got data" );
    };



    subtest 'attr => rewind' => sub {

        my $len = my @data = ( 1 .. 10 );
        my @got;
        my $iterator = iterator { shift @data }
        { rewind => sub { @data = ( 1 .. 10 ) }, };

        my $next = $mknext->( $iterator );
        while ( @got <= $len and my $data = $next->( $iterator ) ) {
            push @got, $data;
        }

        is( \@got, [ 1 .. 10 ], "first run" );

        $iterator->rewind;

        @got = ();
        while ( @got <= $len and my $data = $next->( $iterator ) ) {
            push @got, $data;
        }

        ok( $iterator->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 10 ], "after rewind" );

    };

    $ctx->release;
}

for my $impl ( [ object => \&use_object ], [ coderef => \&use_coderef ], ) {
    my ( $label, $sub ) = @$impl;
    subtest( $label, \&test, $sub );
}


done_testing;
