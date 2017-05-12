package HOGEHOGE;

sub function1{
  return -1;
}

sub function2{
  return -2;
}

sub function3{
  return -3;
}

use ExportTo (HOGE => [qw/+function1 +function2/]);

1;
