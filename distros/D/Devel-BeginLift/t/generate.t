use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "B::Generate required" unless eval { require B::Generate };
    plan skip_all => "B::Utils required" unless eval { require B::Utils };
    plan tests => 2;
}

sub foo {
    B::SVOP->new("const", 0, 42);
}

sub gorch ($) {
    my $meth = ( $_[0]->kids )[-1]->sv->object_2svref;
    $$meth = "other";
    $_[0];
}

use Devel::BeginLift qw(foo gorch);

sub bar { 7 + foo() }
is( bar(), 49, "optree injected" );

sub blah { foo(31) }
is(blah(), 42, "optree injected" );;

sub meth { 3 }

sub other { 42 }

__END__

my $obj = bless {};
sub oink { gorch $obj->meth; }

is( oink(), 42, "modify method call");

my @args = ( 1 .. 3 );
sub ploink { gorch $obj->meth(1, @args); }
is( ploink(), 42, "modify method call with args");

