#!/usr/bin/perl
use strict;
use warnings;

# Use plan instead of done testing so we pass on old versions
use Fennec::Lite plan => 2;

my $ran;

tests "item_blah" => sub {
    $ran++
};

tests "item_by_line" => sub {
    $ran = "correct";
};

tests "item_extra" => sub {
    $ran++
};

{
    local $ENV{FENNEC_ITEM} = 15;
    run_tests();
    is( $ran, "correct", "Only ran 1" );
}

$ran = undef;
my $fennec = Fennec::Lite->new( test_class => __PACKAGE__ );

$fennec->add_tests( "item_blah" => sub {
    $ran++
});

$fennec->add_tests( "item_by_line" => sub {
    $ran = "correct";
});

$fennec->add_tests( "item_extra" => sub {
    $ran++
});

{
    local $ENV{FENNEC_ITEM} = 36;
    $fennec->run_tests();
    is( $ran, "correct", "Only ran 1" );
}
