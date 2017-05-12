#!/usr/bin/perl

use strict;
use warnings;
use File::Temp;
use File::Path;
use File::Spec;
use File::Find::Parallel;
use Test::More;
use Data::Dumper;

my @schedule;

BEGIN {
    @schedule = (
        {
            name   => 'One directory',
            create => [
                {
                    dirs  => [ 'a',    'b/c',  'd' ],
                    files => [ 'a/f1', 'b/f2', 'b/c/f3', 'd/f4' ]
                }
            ],
            check => {
                all_iterator => [
                    '.',    'a',      'b', 'b/c', 'd', 'a/f1',
                    'b/f2', 'b/c/f3', 'd/f4'
                ],
                any_iterator => [
                    '.',    'a',      'b', 'b/c', 'd', 'a/f1',
                    'b/f2', 'b/c/f3', 'd/f4'
                ],
            },
        },
        {
            name   => 'Two directories',
            create => [
                {
                    dirs => [ 'a', 'b/c', 'd', 'e' ],
                    files =>
                      [ 'a/f1', 'b/f2', 'b/f5', 'b/c/f3', 'd/f4', 'e/f6' ]
                },
                {
                    dirs => [ 'a', 'b/c', 'd', 'f' ],
                    files =>
                      [ 'a/f1', 'b/f2', 'b/f6', 'b/c/f3', 'd/f4', 'f/f5' ]
                },
            ],
            check => {
                all_iterator => [
                    '.',    'a',      'b', 'b/c', 'd', 'a/f1',
                    'b/f2', 'b/c/f3', 'd/f4'
                ],
                any_iterator => [
                    '.',    'a',    'b',    'b/c',    'd',    'a/f1',
                    'b/f2', 'b/f5', 'b/f6', 'b/c/f3', 'd/f4', 'e',
                    'e/f6', 'f',    'f/f5'
                ],
            },
        },
        {
            name   => 'Three directories',
            create => [
                {
                    dirs => [ 'a', 'b/c', 'd', 'e' ],
                    files =>
                      [ 'a/f1', 'b/f2', 'b/f5', 'b/c/f3', 'd/f4', 'e/f6' ]
                },
                {
                    dirs => [ 'a', 'b/c', 'd', 'f' ],
                    files =>
                      [ 'a/f1', 'b/f2', 'b/f6', 'b/c/f3', 'd/f4', 'f/f5' ]
                },
                {
                    dirs => [ 'a', 'b/c', 'd', 'g' ],
                    files =>
                      [ 'a/f1', 'b/f2', 'b/f5', 'b/c/f3', 'd/f4', 'g/f6' ]
                },
            ],
            check => {
                all_iterator => [
                    '.',    'a',      'b', 'b/c', 'd', 'a/f1',
                    'b/f2', 'b/c/f3', 'd/f4'
                ],
                any_iterator => [
                    '.',    'a',    'b',    'b/c',    'd',    'a/f1',
                    'b/f2', 'b/f5', 'b/f6', 'b/c/f3', 'd/f4', 'e',
                    'e/f6', 'f',    'f/f5', 'g',      'g/f6'
                ],
            },
        },
    );

    plan tests => 4 * @schedule;
}

for my $test ( @schedule ) {
    my $name = $test->{name};
    my @temp = ();

    ok my $ffp = File::Find::Parallel->new, "$name: object created OK";
    isa_ok $ffp, 'File::Find::Parallel';

    # Setup
    for my $create ( @{ $test->{create} } ) {
        my $td = File::Temp->newdir();
        push @temp, $td;    # stop it going out of scope
        my $root = $td->dirname;
        $ffp->add_dirs( $root );

        # Make directories
        if ( $create->{dirs} ) {
            for my $dir ( @{ $create->{dirs} } ) {
                mkpath( File::Spec->catdir( $root, split /\//, $dir ) )
                  or die "Can't create $dir below $root ($!)";
            }
        }

        # Make files
        if ( $create->{files} ) {
            for my $file ( @{ $create->{files} } ) {
                my $fn = File::Spec->catfile( $root, split /\//, $file );
                open my $fh, '>', $fn
                  or die "Can't create $file below $root ($!)";
                print $fh 'empty';
                close $fh;
            }
        }
    }

    while ( my ( $method, $expect ) = each %{ $test->{check} } ) {
        my @want = sort map { File::Spec->catdir( split /\//, $_ ) } @$expect;
        my $iter = $ffp->$method;
        my @got  = ();

        # Drain iter
        while ( my $obj = $iter->() ) {
            push @got, $obj;
        }
        @got = sort @got;
        unless ( is_deeply \@got, \@want, "$name: results match for $method" ) {
            diag( Data::Dumper->Dump( [ \@got ],  ['$got'] ) );
            diag( Data::Dumper->Dump( [ \@want ], ['$want'] ) );
        }
    }
}
