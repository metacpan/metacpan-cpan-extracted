# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl
# 01_Games-AlphaBeta.t'

#########################

package My::Pos;
use base qw(Games::Sequential::Position);

sub init {
    my $self = shift;
    $self->{player} = 1;
    $self->{val}    = 0;
    return $self->SUPER::init(@_);
}

sub apply {
    my ($self, $m) = @_;
    $self->{player} = 3 - $self->{player};
    $self->{val} += $self->{player} == 2 ? $m : -$m;
    return $self;
}

sub endpos {
    my $self = shift;
    return $self->{val} > 30 ? 1 : 0;
}

sub evaluate {
    my $self = shift;
    return $self->{val};
}

sub findmoves {
    return (0, 1, -1, 0);
}

package main;
use Test::More tests => 17;

BEGIN { 
  use_ok(Games::AlphaBeta);
}

my ($p, $g);
ok($p = My::Pos->new,                     "new()");
isa_ok($p, Games::Sequential::Position);

ok($g = Games::AlphaBeta->new($p),        "new(\$pos)");
isa_ok($g, Games::Sequential);
isa_ok($g, Games::AlphaBeta);

can_ok($g, qw/abmove ply/);

ok($g->abmove(4),                         "abmove(4)");
ok($p = $g->peek_pos,                     "peek_pos()");
is($g->peek_move, 1,                      "peek_move()");
is($p->{player}, 2,                       "check player turn");
is($p->{val}, 1,                          "check best value");
                                       
is($g->ply(3), 2,                         "set & read ply");
ok($g->abmove,                            "abmove()");
                                       
is($p->{player}, 2,                       "check player turn");
is($p->{val}, 1,                          "current value");
is($g->peek_move, 1,                      "peek_move()");

