# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl
# Games-Sequential.t'

#########################

package My::Pos;
use base Games::Sequential::Position;

sub init {
    my $self = shift;
    my %config = (
        sum => 1
    );

    @$self{keys %config} = values %config;

    return $self->SUPER::init(@_);
}

sub apply {
    my ($self, $m) = @_;
    return $self->{sum} += $m;
}


package main;
use Test::More tests => 19;

BEGIN { 
  use_ok(Games::Sequential);
};

my ($p, $g);

ok($p = My::Pos->new,               "new()");
isa_ok($p, Games::Sequential::Position);
can_ok($p, qw/copy apply new/);

ok($g = Games::Sequential->new($p), "new(1)");
isa_ok($g, Games::Sequential);
can_ok($g, qw/new move undo peek_pos peek_move debug/);

is($g->peek_pos, $p,                "peek_pos()");
is($g->peek_move, undef,            "peek_move()");

is($g->debug(1), 0,                 "debug(1)");
is($g->debug(0), 1,                 "debug(0)");
is($g->debug, 0,                    "debug()");
                       
is($g->move(1)->{sum}, 2,           "move(1)");
is($g->move(2)->{sum}, 4,           "move(2)");
                       
is($g->peek_pos->{sum}, 4,          "peek_pos()");
is($g->peek_move, 2,                "peek_move()");
                       
is($g->move(1)->{sum}, 5,           "move(1)");
is($g->move(1)->{sum}, 6,           "move(1)");
is($g->undo->{sum}, 5,              "undo()");

