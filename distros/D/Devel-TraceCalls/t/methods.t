use Test;
use Devel::TraceCalls;
use strict;

{
    package Foo;

    sub new { return bless {}, ref $_[0] || $_[0] }
    sub foo { "Foo::foo" };
    sub bar { "Foo::bar" };

    package Bar;
    use vars qw( @ISA );
    @ISA = qw( Foo );

    sub baz { my $self = shift ; "Bar::baz/" . $self->foo };
    sub bat { my $self = shift ; "Bar::bat/" . $self->bar };
}

my $b1 = Bar->new();
my $b2 = Bar->new();

my $t1;
my $t2;

my @calls1;
my @calls2;

my @tests = (

sub { ok UNIVERSAL::isa $b1, "Bar" },
sub { ok UNIVERSAL::isa $b1, "Foo" },

sub {
    $t1 = Devel::TraceCalls->new( {
        Objects => [$b1],
        LogTo   => \@calls1,
    } );
    ok scalar $t1->_trace_points, 5;
},

sub { ok UNIVERSAL::isa $b1, "Bar" },
sub { ok UNIVERSAL::isa $b1, "Foo" },

sub {
    $t2 = Devel::TraceCalls->new( {
        Objects => [ $b2 ],
        LogTo   => \@calls2,
    } );
    ok scalar $t2->_trace_points, 5;
},


sub { ok UNIVERSAL::isa $b2, "Bar" },
sub { ok UNIVERSAL::isa $b2, "Foo" },

sub {
    ok $b1->bat, "Bar::bat/Foo::bar";
},

sub {
    ok scalar @calls1, 2;
},

sub {
    ok scalar @calls2, 0;  ## We only called $t1's bat, not $t2's.
},

##
## Class methods
##
sub {
    @calls1 = ();
    $t1 = Devel::TraceCalls->new( {
        Class => "Foo",
        LogTo => \@calls1,
    } );
    ok scalar $t1->_trace_points, 3, "tracking Class Foo";
},

sub {
    @calls2 = ();
    $t2 = Devel::TraceCalls->new( {
        Class => "Bar",
        LogTo => \@calls2,
    } );
    ok scalar $t2->_trace_points, 5, "tracking Class Bar";
},

sub {
    ok $b1->bar(), "Foo::bar";
},

sub {
    ok scalar @calls1, 1;
},

sub {
    ok scalar @calls2, 1;
},

sub {
    ok $b1->bat(), "Bar::bat/Foo::bar";
    undef $t1;  ## No specific reason, just cleaning up
    undef $t2;  ## No specific reason, just cleaning up
},

sub {
    ok scalar @calls1, 2;
},

sub {
    ok scalar @calls2, 3;
},

##
## See if the method vs. sub discrimination is all it should be (it'll
## never be perfect).
##
sub {
    @calls1 = ();
    $t1 = Devel::TraceCalls->new( {
        Class => "Foo",
        LogTo => \@calls1,
    } );
    ok scalar $t1->_trace_points, 3, "tracking Class Bar";
},

sub {
    ok Foo::foo(), "Foo::foo";
},

sub {
    ok scalar @calls1, 0;  ## That was detectable *not* a method call
},

);

plan tests => scalar @tests;

$_->() for @tests;
