#!/usr/bin/perl
package TEST::Devel::Declare::Parser::Fennec;
use strict;
use warnings;
use Test::More;
use Devel::Declare::Interface;


BEGIN {
    use_ok( 'Devel::Declare::Parser::Fennec' );
    enhance(
        'TEST::Devel::Declare::Parser::Fennec',
        'tests',
        'fennec',
    );
}

sub tests {
    use Data::Dumper;
    my $name = shift;
    my $sub = pop;
    if ( @_ && @_ % 2) {
        is( pop( @_ ), "method", 'proper key for method' );
    }
    $sub->(
        bless( { name => $name, @_}, 'TEST::Devel::Declare::Parser::Fennec' )
    );
}

tests simple {
    ok( $self, "Magically got self" );
    $self->isa_ok( 'TEST::Devel::Declare::Parser::Fennec' );
    ok( 1, "In declared tests!" );
}

tests 'complicated name' {
    ok( $self, "Magically got self" );
    $self->isa_ok( 'TEST::Devel::Declare::Parser::Fennec' );
    ok( 1, "Complicated name!" );
}

tests old => sub {
    ok( 1, "old style still works" );
};

tests old_deep => (
    method => sub { ok( 1, "old with depth" )},
);

tests magic {
    ok( $self, "Magically got self" );
    $self->isa_ok( 'TEST::Devel::Declare::Parser::Fennec' );
}

tests add_specs ( a => 'b' ) {
    is( $self->{a}, 'b', "Got params" );
}

tests open_next_line
{
    ok( $self, "Magically got self" );
    ok( 1, "open on next line" );
}

tests errors {
    eval 'tests { 1 }';
    my $msg = $@;
    like(
        $msg,
        qr/You must provide a name to tests\(\) at /,
        "Got error"
    );
}

done_testing;

1;
