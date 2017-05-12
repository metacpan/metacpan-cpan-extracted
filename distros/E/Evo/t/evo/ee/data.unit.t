package main;
use Evo 'Test::More; Evo::Internal::Exception';

{

  package My::Class;
  use Evo -Class;
  with 'Evo::Ee';
  sub ee_events {qw(e1 e2)}
}


EE_CHECK: {
  my $obj = My::Class->new();
  like exception { $obj->ee_check('bad'); }, qr/Not recognized event "bad"/;
  is $obj->ee_check('e1'), $obj;
}

EXCEPTIONS: {
  my $obj = My::Class->new();
  like exception {
    $obj->on('bad', sub { });
  }, qr/Not recognized event "bad"/;
  like exception {
    $obj->ee_add('bad', sub { });
  }, qr/Not recognized event "bad"/;
  like exception { $obj->ee_remove([]); }, qr/isn't a listener/;
  like exception { $obj->ee_remove_current(); }, qr/not in the.+$0/i;
}

my ($F1, $F2, $F3) = (sub {1}, sub {2}, sub {3});

ON: {
  my $obj = My::Class->new();
  is_deeply $obj->on(e1 => $F1)->on(e1 => $F1)->on(e2 => $F2)->ee_data->{q},
    [[e1 => $F1], [e1 => $F1], [e2 => $F2]];
}

ADD_REMOVE: {
  my $obj  = My::Class->new();
  my $e1_1 = $obj->ee_add(e1 => $F1);
  my $e1_2 = $obj->ee_add(e1 => $F1);
  my $e2   = $obj->ee_add(e2 => $F2);
  is_deeply $obj->ee_data->{q}, [$e1_1, $e1_2, $e2];
  is_deeply [$obj->ee_listeners('e1')], [$e1_1, $e1_2];
  is_deeply [$obj->ee_listeners('e2')], [$e2];
}


EMIT: {
  my $obj = My::Class->new();
  my @got = @_;
  is $obj->on(e1 => sub { @got = @_ })->emit(e1 => 1, 2), $obj;
  is_deeply \@got, [$obj, 1, 2];
}


CURRENT: {
  my $called;
  my $obj = My::Class->new()->on(e1 => sub($o) { $called++; $o->ee_remove_current });

  $obj->emit('e1') for 1 .. 2;
  is $called, 1;
}

done_testing;
