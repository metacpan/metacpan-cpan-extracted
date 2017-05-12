use Test::More 'no_plan';

BEGIN { use_ok('ExportTo') };

{
  package HOGE;

  sub function1{
    return 1;
  }

  sub function2{
    return 2;
  }

  sub function3{
    return 3;
  }
  sub function4{
    return 'o';
  }

  use ExportTo (HOGE2 => [qw/function1 function2/], HOGE3 => [qw/function3/]);
  use ExportTo (HOGE => [qw/Test::More::is/]);
  use ExportTo (HOGE4 => {func1 => 'function1', func2 => \&function2});
  is(HOGE2::function1(), 1);
  is(HOGE2::function2(), 2);
  is(HOGE3::function3(), 3);
  is(HOGE4::func1(), 1);
  is(HOGE4::func2(), 2);
}

{
  package HOGEHOGE;
  use ExportTo;
  sub function1{
    return -1;
  }

  sub function2{
    return -2;
  }

  sub function3{
    return -3;
  }

  export_to('+HOGE' => [qw/function1 function2/], HOGE3 => [qw/+function3/]);
  export_to(HOGEHOGE => [qw/Test::More::is/]);
  export_to('+HOGE' => {func1 => 'function1', func2 => \&function2}, HOGE3 => { func3 => '+function3'});
  export_to('HOGE' => {'function4' => sub { 'n'} });

  is(HOGE::function1(), -1);
  is(HOGE::function2(), -2);
  is(HOGE3::function3(), -3);
  is(HOGE::func1(), -1);
  is(HOGE::func2(), -2);
  is(HOGE3::func3(), -3);
  is(HOGE::function4(), 'o');
}

