#!perl

use Test::More;

use Devel::Cover::Report::Clover::Class;

my @test = (
    sub {
        my $t = "name - comes out as passed";
        my $c = Devel::Cover::Report::Clover::Class->new( { name => 'a' } );
        is( $c->name, 'a', $t );
    },
    sub {
        my $t = "full_name - ( '', Class ) -> Class";
        my $c = Devel::Cover::Report::Clover::Class->new( { name => 'Class', package => '' } );

        is( $c->full_name, 'Class', $t );
    },
    sub {
        my $t = "full_name - ( undef, Class ) -> Class";
        my $c = Devel::Cover::Report::Clover::Class->new( { name => 'Class', package => undef } );

        is( $c->full_name, 'Class', $t );
    },
    sub {
        my $t = "full_name - ( My, Class ) -> My::Class";
        my $c = Devel::Cover::Report::Clover::Class->new( { name => 'Class', package => 'My' } );

        is( $c->full_name, 'My::Class', $t );
    },
);

plan tests => scalar @test;

$_->() foreach @test;
