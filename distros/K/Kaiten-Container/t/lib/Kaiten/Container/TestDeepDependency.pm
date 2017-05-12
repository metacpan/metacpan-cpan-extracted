package Kaiten::Container::TestDeepDependency;

use v5.10;
use warnings;

# just cleanup tests, DONT, LISTEN TO ME, D-O-N-T put this to you code ever!!!
no warnings qw(recursion);

use base qw(Test::Class);
use Test::More;
use Test::Warn;

# for Sponge test
use DBI;

#======== DEVELOP THINGS ===========>
# develop mode
#use Smart::Comments;
#use Data::Printer;

#======== DEVELOP THINGS ===========<

use lib::abs qw(../../../../lib);


use Kaiten::Container;

my $deep_dependency_linear = {
    foo => {
             handler  => sub        { return 'FooSQL there!' },
             probe    => sub        { return 1 },
             settings => { reusable => 1 }
           },
    bar => {
        handler => sub {
            my $c = shift;

            my $foo = $c->get_by_name('foo');
            return $foo;
        },
        probe    => sub        { return 1 },
        settings => { reusable => 1 }
           },
    baz => {
        handler => sub {
            my $c = shift;

            my $bar = $c->get_by_name('bar');
            return $bar;
        },
        probe => sub { return 1 },
           },

};

my $deep_dependency_circular = {
    creble => {
        handler => sub {
            my $c = shift;

            my $crable = $c->get_by_name('crable');
            return $crable;
        },
        probe    => sub        { return 1 },
        settings => { reusable => 1 }
              },
    crable => {
        handler => sub {
            my $c = shift;

            my $boom = $c->get_by_name('boom');
            return $boom;
        },
        probe    => sub        { return 1 },
        settings => { reusable => 1 }
              },
    boom => {
        handler => sub {
            my $c = shift;

            my $creble = $c->get_by_name('creble');
            return $creble;
        },
        probe => sub { return 1 },
            },
    non_magical => {
        handler => sub {
            my $c = shift;

            return 'Yapp, this one worked well!';
        },
        probe    => sub        { return 1 },
        settings => { reusable => 1 }
                   },
};

# setup methods are run before every test method.
sub make_fixture : Test(setup) {
    my $self = shift;

    # its because we are have global vars, all go wrong if we not de-referenced it first. yap!
    my %init_deep_dependency_linear   = %$deep_dependency_linear;
    my %init_deep_dependency_circular = %$deep_dependency_circular;

    $self->{linear}   = Kaiten::Container->new( init => \%init_deep_dependency_linear, DEBUG => 1 );
    $self->{circular} = Kaiten::Container->new( init => \%init_deep_dependency_circular, DEBUG => 1 );

}

sub check_deep_dependency_linear : Test(2) {
    my $self = shift;

    my $container = $self->{linear};
    is( $container->get_by_name('bar'), $deep_dependency_linear->{foo}{handler}->(), "short linear deep dependency worked" );
    is( $container->get_by_name('baz'), $deep_dependency_linear->{foo}{handler}->(), "long linear deep dependency worked" );

}

sub check_circular_non_expoldable_if_frozen : Test(1) {
    my $self = shift;

    my $object = $self->{circular};
    isa_ok( $object, "Kaiten::Container" );
}

sub check_circular_exploide_on_thaw_out : Test(1) {
    my $self = shift;

    my $container = $self->{circular};
    ok( !eval { $container->get_by_name('creble') }, 'circular deep denendency deny check' );

    say $@;
}

sub check_one_non_circular_in_circular : Test(1) {
    my $self = shift;

    my $container = $self->{circular};
    is( $container->get_by_name('non_magical'), $deep_dependency_circular->{non_magical}{handler}->(), "normal handler in circalar environment worked" );

}

sub check_test_method_on_linear : Test(3) {
    my $self = shift;

    my $container = $self->{linear};
    ok( $container->test('foo'), 'test method for one flat handler worked' );
    ok( $container->test( 'baz', 'bar' ), 'test method for two deep depended handler worked' );
    ok( $container->test, 'test method for default handler worked' );
}

sub check_test_method_on_circular : Test(2) {
    my $self = shift;

    my $container = $self->{circular};

    ok( !eval { $container->test('creble') }, 'test method for one circular handler worked' );
    ok( !eval { $container->test },           'test method for default circular handler worked' );

}

1;
