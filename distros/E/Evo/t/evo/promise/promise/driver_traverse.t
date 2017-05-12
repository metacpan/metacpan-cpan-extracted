package main;
use Evo '-Promise::Util *';
use Test::More;

{

  package My::P;
  use Evo '-Class *';
  with '-Promise::Role';
  has $_, optional for qw(n x_res x_rej);

  sub postpone ($me, $sub) {
    $sub->();
  }
}


sub p { My::P->new(@_) }

ORDER: {
  no warnings qw(once redefine);

  my @log;
  my $root = p->d_fulfill('V');
  my $prev = *My::P::d_fulfill{CODE};
  local *My::P::d_fulfill = sub { push @log, $_[0]->n; $prev->(@_) };

  push $root->d_children->@*, my $ch1 = p(n => 1);
  push $root->d_children->@*, my $ch2 = p(n => 2);
  push $ch1->d_children->@*, p(n => '1_1');
  push $ch1->d_children->@*, my $ch1_2 = p(n => '1_2');
  push $ch2->d_children->@*,   p(n => '2_1');
  push $ch1_2->d_children->@*, p(n => '1_2_1');

  $root->d_traverse();

  is_deeply \@log, [qw(1 2 1_1 1_2 2_1 1_2_1)];
  ok !$root->d_children->@*;
  ok !$ch1->d_children->@*;
}


FULFILL: {

  my $p = p->d_fulfill('V');
  $p->{d_children} = [my $p1 = p(), my $p2 = p()];
  $p->d_traverse;
  ok is_fulfilled_with('V', $p1);
  ok is_fulfilled_with('V', $p2);
}

REJECT: {
  my $p = p->d_reject('R');
  $p->{d_children} = [my $p1 = p(), my $p2 = p()];
  $p->d_traverse;
  ok is_rejected_with('R', $p1);
  ok is_rejected_with('R', $p2);
}


# --- handlers
no warnings 'redefine', 'once';
local *My::P::d_resolve_continue = sub ($self, $x) {
  $self->x_res($x);
};
local *My::P::d_reject_continue = sub ($self, $x) {
  $self->x_rej($x);
};

CLEAR_FHS: {
  my $root = p->d_fulfill('V');
  $root->{d_children} = [my $ch = p(d_fh => sub { }, d_rh => sub { })];
  $root->d_traverse();
  ok !$ch->d_fh;
  ok !$ch->d_rh;
}

CALL_FH: {
  my $root = p->d_fulfill('V');
  my $called;
  $root->{d_children} = [my $ch = p(d_fh => sub { $called++; 'X' })];
  $root->d_traverse();
  is $called, 1;
  is $ch->x_res, 'X';
}

CALL_RH: {
  my $root = p->d_reject('R');
  my $called;
  $root->{d_children} = [my $ch = p(d_rh => sub { $called++; 'X' })];
  $root->d_traverse();
  is $called, 1;
  is $ch->x_res, 'X';
}

CALL_FH_AND_DIE: {
  my $root = p->d_fulfill('V');
  $root->{d_children} = [my $ch = p(d_fh => sub { die "Foo\n" })];
  $root->d_traverse;
  is $ch->x_rej, "Foo\n";
}

CALL_RH_AND_DIE: {
  my $root = p->d_reject('R');
  $root->{d_children} = [my $ch = p(d_rh => sub { die "Foo\n" })];
  $root->d_traverse;
  is $ch->x_rej, "Foo\n";
}


done_testing;
