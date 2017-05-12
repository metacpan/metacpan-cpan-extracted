#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep qw(cmp_details deep_diag bag);
use Data::Dump qw(pp);
use Test::Exception;
use Elastic::Model::SearchBuilder;

use lib 't/lib';
our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok $model->namespace('myapp')->index->create, 'Created index';
isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain';

isa_ok
    my $user = $domain->new_doc( user => { id => 1, name => 'X' } ),
    'MyApp::User',
    'User';

isa_ok
    my $uid = $user->uid,
    'Elastic::Model::UID',
    'UID';

my @objs = ( $user, $uid );

my $a = Elastic::Model::SearchBuilder->new;

test_filters(
    'HASHREF - key',
    'Object',
    { 'user' => $user },
    {   and => [
            { term => { 'user.uid.index' => 'myapp' } },
            { term => { 'user.uid.type'  => 'user' } },
            { term => { 'user.uid.id'    => 1 } },
        ]
    },

    'UID',
    { 'user' => $uid },
    {   and => [
            { term => { 'user.uid.index' => 'myapp' } },
            { term => { 'user.uid.type'  => 'user' } },
            { term => { 'user.uid.id'    => 1 } },
        ]
    },

);

test_filters(
    '= op', 'Object',
    { 'user' => { '=' => $user } },
    {   and => [
            { term => { 'user.uid.index' => 'myapp' } },
            { term => { 'user.uid.type'  => 'user' } },
            { term => { 'user.uid.id'    => 1 } },
        ]
    },

    'UID',
    { 'user' => { '=' => $uid } },
    {   and => [
            { term => { 'user.uid.index' => 'myapp' } },
            { term => { 'user.uid.type'  => 'user' } },
            { term => { 'user.uid.id'    => 1 } },
        ]
    },

);

test_filters(
    '!= op', 'Object',
    { 'user' => { '!=' => $user } },
    {   not => {
            filter => {
                and => [
                    { term => { 'user.uid.index' => 'myapp' } },
                    { term => { 'user.uid.type'  => 'user' } },
                    { term => { 'user.uid.id'    => 1 } },
                ]
            }
        }
    },
    'UID',
    { 'user' => { '!=' => $uid } },
    {   not => {
            filter => {
                and => [
                    { term => { 'user.uid.index' => 'myapp' } },
                    { term => { 'user.uid.type'  => 'user' } },
                    { term => { 'user.uid.id'    => 1 } },
                ]
            }
        }
    },
);

test_filters(
    'ARRAYREF',
    'Objects',
    { 'user' => \@objs },
    {   or => [ {
                and => [
                    { term => { 'user.uid.index' => 'myapp' } },
                    { term => { 'user.uid.type'  => 'user' } },
                    { term => { 'user.uid.id'    => 1 } },
                ]
            },
            {   and => [
                    { term => { 'user.uid.index' => 'myapp' } },
                    { term => { 'user.uid.type'  => 'user' } },
                    { term => { 'user.uid.id'    => 1 } },
                ]
            },
        ]
    },

    '= Objects',
    { 'user' => { '=' => \@objs } },
    {   or => [ {
                and => [
                    { term => { 'user.uid.index' => 'myapp' } },
                    { term => { 'user.uid.type'  => 'user' } },
                    { term => { 'user.uid.id'    => 1 } },
                ]
            },
            {   and => [
                    { term => { 'user.uid.index' => 'myapp' } },
                    { term => { 'user.uid.type'  => 'user' } },
                    { term => { 'user.uid.id'    => 1 } },
                ]
            },
        ]
    },
    '!= Objects',
    { 'user' => { '!=' => \@objs } },
    {   not => {
            filter => {
                or => [ {
                        and => [
                            { term => { 'user.uid.index' => 'myapp' } },
                            { term => { 'user.uid.type'  => 'user' } },
                            { term => { 'user.uid.id'    => 1 } },
                        ]
                    },
                    {   and => [
                            { term => { 'user.uid.index' => 'myapp' } },
                            { term => { 'user.uid.type'  => 'user' } },
                            { term => { 'user.uid.id'    => 1 } },
                        ]
                    },
                ]
            }
        }
    }

);

done_testing();

#===================================
sub test_filters {
#===================================
    note "\n" . shift();
    while (@_) {
        my $name = shift;
        my $in   = shift;
        my $out  = shift;
        if ( ref $out eq 'Regexp' ) {
            throws_ok { $a->filter($in) } $out, $name;
            next;
        }

        my $got = $a->filter($in);
        my $expect = { filter => $out };
        my ( $ok, $stack ) = cmp_details( $got, $expect );

        if ($ok) {
            pass $name;
            next;
        }

        fail($name);

        note("Got:");
        note( pp($got) );
        note("Expected:");
        note( pp($expect) );

        diag( deep_diag($stack) );

    }
}
