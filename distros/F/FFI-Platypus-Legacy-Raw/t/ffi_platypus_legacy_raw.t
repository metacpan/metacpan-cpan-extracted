use Test2::V0 -no_srand => 1;
use Test2::Tools::FFI;
use FFI::Platypus::Legacy::Raw;

my($shared) = ffi->test->lib;

subtest 'argless' => sub {

  my $argless = FFI::Platypus::Legacy::Raw->new($shared, 'argless', FFI::Platypus::Legacy::Raw::void);
  $argless->attach;

  argless();

  ok 1, 'survived the call (same name)';

  $argless->attach('argless1');

  argless1();

  ok 1, 'survived the call (different name)';

};

subtest 'simple-args' => sub {

  my $take_misc_ints = FFI::Platypus::Legacy::Raw->new(
    $shared, 'take_misc_ints',
    FFI::Platypus::Legacy::Raw::void, FFI::Platypus::Legacy::Raw::int, FFI::Platypus::Legacy::Raw::short, FFI::Platypus::Legacy::Raw::char
  );

  $take_misc_ints->attach;

  take_misc_ints(101, 102, 103);
};

subtest 'platypus types' => sub {

  my $malloc = FFI::Platypus::Legacy::Raw->new(
    undef, 'malloc',
    'opaque', 'size_t',
  );

  my $free = FFI::Platypus::Legacy::Raw->new(
    undef, 'free',
    'void', 'opaque',
  );

  my $ptr = $malloc->call(400);
  like $ptr, qr/^[0-9]+/, 'malloc';
  note "ptr = $ptr";

  $free->call($ptr);
  ok 'free';

};

subtest 'platypus interface' => sub {

  isa_ok(FFI::Platypus::Legacy::Raw->platypus('libfoo.so'), 'FFI::Platypus');

  eval {
    FFI::Platypus::Legacy::Raw->platypus(undef);
  };

  like $@, qr/cannot get platypus instance for undef lib/;

};

done_testing;
