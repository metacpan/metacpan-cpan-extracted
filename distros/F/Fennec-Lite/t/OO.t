#!/usr/bin/perl
use strict;
use warnings;

# Use plan instead of done testing so we pass on old versions
use Fennec::Lite ();
use Test::More tests => 10;

my $fennec = Fennec::Lite->new( test_class => __PACKAGE__ );

$fennec->add_tests( good => sub {
    ok( 1, "A good test" );
});

$fennec->add_tests( "run as method" => sub {
    isa_ok( $_[0], __PACKAGE__ );
});

$fennec->add_tests( "todo group" => (
    todo => "This will fail",
    code => sub { ok( 0, "false value" )},
));

$fennec->add_tests( "skip group" => (
    skip => "This will fail badly",
    sub => sub { die "oops" },
));

$fennec->add_tests( "continue if group dies" => (
    method => sub { die "Safe to ignore this" },
    should_fail => 1,
));

$fennec->add_tests( "constructor args" => sub {
    my $self = shift;
    is( $self->{ proto }, "indeed!", "Created with proper proto" );
});

$fennec->run_tests( proto => "indeed!" );

my $run = 0;
{
    no warnings 'once';
    *new = sub {
        my $class = shift;
        $run++;
        my %proto = @_;
        $proto{ constructed } = 1;
        return bless( \%proto, $class );
    };
}

Fennec::Lite::fennec_accessors( qw/ proto constructed /);

$fennec->add_tests( "with constructor" => sub {
    my $self = shift;
    $self->isa_ok( __PACKAGE__ );
    is( $self->proto, "Yes, again", "Built correctly" );
    ok( $self->constructed, "Built with new()" );
    is( $run, 1, "Ran once, and only once" );
});

$fennec->run_tests( proto => "Yes, again" );

my $ran = undef;

$fennec->add_tests( "item_blah" => sub {
    $ran++
});

$fennec->add_tests( "item_by_name" => sub {
    $ran = "correct";
});

$fennec->add_tests( "item_extra" => sub {
    $ran++
});

{
    local $ENV{FENNEC_ITEM} = "item_by_name";
    $fennec->run_tests();
    is( $ran, "correct", "Only ran 1" );
}
