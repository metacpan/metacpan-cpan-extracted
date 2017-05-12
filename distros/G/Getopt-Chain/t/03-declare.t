#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

package t::App;

use Getopt::Chain::Declare;

start [qw/ a1 b2:s /];

rewrite qr/^\?(.*)/ => sub { "help ".($1||'') };

rewrite [ ['about', 'copying'] ] => sub { "help $1" };

on apple => [qw/ c3 /], sub {
    my $context = shift;

    $context->option( apple => 1 );
};

on help => undef, sub {
    my $context = shift;

    $context->option( help => 1 );
};

#on 'help xyzzy' => undef, sub {
#    my $context = shift;

#    $context->option( help_xyzzy => 1 );
#};

under help => sub {
    on [ [ qw/a b c/ ] ] => undef, sub {
        my $context = shift;

        $context->option( help_a_b_c => 1 );
    };

    on 'xyzzy' => undef, sub {
        my $context = shift;

        $context->option( help_xyzzy => 1 );
    };

    on 'about' => undef, sub {
        my $context = shift;

        $context->option( help_about => 1 );
    };

    on 'copying' => undef, sub {
        my $context = shift;

        $context->option( help_copying => 1 );
    };

    on qr/^(\S+)$/ => undef, sub {
       my $context = shift;
       my $topic = $1;

        $context->option( no_help => $1 );
    };
};

no Getopt::Chain::Declare;

package main;

my @arguments = qw/--a1 apple --c3/;
my ($options);

my $app = t::App->new;

ok( $app );

$options = $app->run( [ @arguments ] );

ok( $options->{a1} );
ok( $options->{c3} );
ok( $options->{apple} );

$options = $app->run( [qw/ help /] );

ok( $options->{help} );

$options = $app->run( [qw/ ? /] );

ok( $options->{help} );

$options = $app->run( [qw/ help xyzzy /] );

ok( ! $options->{help} );
ok( $options->{help_xyzzy} );

$options = $app->run( [qw/ about /] );

ok( ! $options->{help} );
ok( $options->{help_about} );

$options = $app->run( [qw/ copying /] );

ok( ! $options->{help} );
ok( $options->{help_copying} );

$options = $app->run( [qw/ help a /] );

ok( ! $options->{help} );
ok( $options->{help_a_b_c} );

$options = $app->run( [qw/ help c /] );

ok( ! $options->{help} );
ok( $options->{help_a_b_c} );

$options = $app->run( [qw/ help d /] );

is( $options->{no_help}, 'd' );
