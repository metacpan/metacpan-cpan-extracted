# Perl versions supported
requires  'perl', '5.014';
conflicts 'perl', '5.020'; # regex bug

# Modules
requires 'AnyEvent',         '7.14';
requires 'Guard',            '1.023';
requires 'Keyword::Declare', '0.001006';
requires 'IPC::Semaphore',   '0';
requires 'IPC::SysV',        '0';

# Testing
on test => sub {
  requires 'Test', '0';
  requires 'Test2::Bundle::Extended', '0';
  requires 'Test::Pod', '0';
};
