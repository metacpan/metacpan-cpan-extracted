#!/usr/bin/perl
use strict;
use warnings;

# Use plan instead of done testing so we pass on old versions
use Fennec::Lite
    plan => 16,
    testing => 'Fennec::Lite',
    alias => [
        'Fennec::Lite'
    ],
    alias_to => {
        Fennec => 'Fennec::Lite',
    };

tests import => sub {
    my $self = shift;
    $self->can_ok( qw/CLASS Lite Fennec fennec / );
    is( $CLASS,   'Fennec::Lite', "Imported \$CLASS" );
    is( CLASS(),  'Fennec::Lite', "Imported CLASS()" );
    is( Lite(),   'Fennec::Lite', "Aliased Lite()"   );
    is( Fennec(), 'Fennec::Lite', "Aliased Fennec()" );
    isa_ok( fennec(), 'Fennec::Lite'                 );
};

tests good => sub {
    ok( 1, "A good test" );
};

tests "run as method" => sub {
    isa_ok( $_[0], __PACKAGE__ );
};

tests "todo group" => (
    todo => "This will fail",
    code => sub { ok( 0, "false value" )},
);

tests "skip group" => (
    skip => "This will fail badly",
    sub => sub { die "oops" },
);

tests "continue if group dies" => (
    method => sub { die "Safe to ignore this" },
    should_fail => 1,
);

tests "constructor args" => sub {
    my $self = shift;
    is( $self->{ proto }, "indeed!", "Created with proper proto" );
};

run_tests( proto => "indeed!" );

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

fennec_accessors qw/proto constructed/;

tests "with constructor" => sub {
    my $self = shift;
    $self->isa_ok( __PACKAGE__ );
    is( $self->proto, "Yes, again", "Built correctly" );
    ok( $self->constructed, "Built with new()" );
    is( $run, 1, "Ran once, and only once" );
};

run_tests( proto => "Yes, again" );

my $ran = undef;

tests "item_blah" => sub {
    $ran++
};

tests "item_by_name" => sub {
    $ran = "correct";
};

tests "item_extra" => sub {
    $ran++
};

{
    local $ENV{FENNEC_ITEM} = "item_by_name";
    run_tests();
    is( $ran, "correct", "Only ran 1" );
}
