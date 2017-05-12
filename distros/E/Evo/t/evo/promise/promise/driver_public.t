package main;
use Evo '-Promise::Util *';
use Test::More;
use Evo::Internal::Exception;

{

  package MyTestPromise;
  use Evo -Class;
  with 'Evo::Promise::Role';

  sub postpone ($self, $code) {
  }
}
sub p { MyTestPromise->new(@_) }

# then
THEN_HANDLERS: {
  my $root = p();
  my $ch1 = $root->then(sub {'FH'}, 'BAD');
  is $ch1->d_fh->(), 'FH';
  ok !$ch1->d_rh;

  my $ch2 = $root->then('BAD', sub {'RH'});
  is $ch2->d_rh->(), 'RH';
  ok !$ch2->d_fh;

  is_deeply $root->d_children, [$ch1, $ch2];
}

THEN_TRAVERSE: {
  my $root = p()->d_fulfill('V');
  my $ch   = $root->then()->then();
  my $ch2  = $root->then(sub { fail 'should be async' });

  ok is_fulfilled_with('V', $ch);
  ok !$ch2->d_settled;
}


#VALUE: {
#  like exception { p()->value }, qr/isn't fulfilled/;
#  like exception { p()->d_reject('R')->value }, qr/isn't fulfilled/;
#
#  my $p = p();
#  $p->d_fulfill('V');
#  is $p->value, 'V';
#}
#
#REASON: {
#  like exception { p()->reason }, qr/isn't rejected/;
#  like exception { p()->d_fulfill('R')->reason }, qr/isn't rejected/;
#
#  my $p = p();
#  $p->d_reject('R');
#  is $p->reason, 'R';
#}

CATCH: {
  my @got;
  no warnings 'redefine', 'once';
  local *MyTestPromise::then = sub { @got = @_ };
  my $root = p();
  my $p    = $root->catch('REJ');
  is_deeply \@got, [$root, undef, 'REJ'];
}

SPREAD: {
  my $p = p();
  my %GOT;
  my $ch = $p->spread(sub(%opts) { %GOT = %opts });
  $ch->d_fh->([one => 1, two => 2]);
  is_deeply \%GOT, {one => 1, two => 2};
}

done_testing;
