use Test2::V0 -no_srand => 1;
use Test2::Tools::FFI;
use lib 't/lib';
use FFI::Raw;

my($shared) = ffi->test->lib;

subtest 'basic' => sub {

  my $greeting = "Hello\0World";

  my $buf = FFI::Raw::MemPtr->new_from_buf($greeting, length $greeting);

  my $got = $buf->to_perl_str;

  is $got, "Hello", "Without arguments, to_perl_str uses strlen() to determine the length";

  $got = $buf->to_perl_str(length $greeting);

  is $got, $greeting, "A length to to_perl_str() is honoured, and binary data is retrieved correctly";

  $got = $buf->to_perl_str(0);

  is $got, '', "A length of 0 to_perl_str() is handled correctly, returning an empty string";
};

subtest 'new' => sub {

  my $bar = FFI::Raw::MemPtr->new(20);
  isa_ok $bar, 'FFI::Raw::MemPtr';
  isa_ok $bar, 'FFI::Raw::Ptr';

};

subtest 'pointers' => sub {
  my $get_test_ptr_size = FFI::Raw->new(
    $shared, 'get_test_ptr_size', FFI::Raw::int
  );

  my $ptr1 = FFI::Raw::memptr($get_test_ptr_size->call);

  my $take_one_pointer = FFI::Raw->new(
    $shared, 'take_one_pointer',
    FFI::Raw::void, FFI::Raw::ptr
  );

  $take_one_pointer->call($ptr1);

  my $return_pointer = FFI::Raw->new($shared, 'return_pointer', FFI::Raw::ptr);
  my $ptr2 = $return_pointer->call;

  my $return_str_from_ptr = FFI::Raw->new(
    $shared, 'return_str_from_ptr',
    FFI::Raw::str, FFI::Raw::ptr
  );

  my $return_int_from_ptr = FFI::Raw->new(
    $shared, 'return_int_from_ptr',
    FFI::Raw::int, FFI::Raw::ptr
  );

  my $return_str_from_ptr_by_ref = FFI::Raw->new(
    $shared, 'return_str_from_ptr_by_ref',
    FFI::Raw::str, FFI::Raw::ptr
  );

  my $return_int_from_ptr_by_ref = FFI::Raw->new(
    $shared, 'return_int_from_ptr_by_ref',
    FFI::Raw::int, FFI::Raw::ptr
  );

  my $test_str = 'some string';
  my $test_int = 42;

  my $ptrptr1 = FFI::Raw::MemPtr->new_from_ptr($ptr1);
  my $ptrptr2 = FFI::Raw::MemPtr->new_from_ptr($ptr2);

  is $return_str_from_ptr->call($ptr1), $test_str;
  is $return_str_from_ptr->($ptr1), $test_str;

  is $return_int_from_ptr->call($ptr1), $test_int;
  is $return_int_from_ptr->($ptr1), $test_int;

  is $return_str_from_ptr_by_ref->call($ptrptr1), $test_str;
  is $return_str_from_ptr_by_ref->($ptrptr1), $test_str;

  is $return_int_from_ptr_by_ref->call($ptrptr1), $test_int;
  is $return_int_from_ptr_by_ref->($ptrptr1), $test_int;

  is $return_str_from_ptr->call($ptr2), $test_str;
  is $return_str_from_ptr->($ptr2), $test_str;

  is $return_int_from_ptr->call($ptr2), $test_int;
  is $return_int_from_ptr->($ptr2), $test_int;

  is $return_str_from_ptr_by_ref->call($ptrptr2), $test_str;
  is $return_str_from_ptr_by_ref->($ptrptr2), $test_str;

  is $return_int_from_ptr_by_ref->call($ptrptr2), $test_int;
  is $return_int_from_ptr_by_ref->($ptrptr2), $test_int;

  my $return_null = FFI::Raw->new($shared, 'return_null', FFI::Raw::ptr);
  is $return_null->call, undef;

};

subtest 'struct' => sub {

  my $int_arg = 42;
  my $str_arg = "hello";

  my $packed = pack('ix![p]p', 42, $str_arg);

  my $arg = FFI::Raw::MemPtr->new_from_buf($packed, length $packed);

  my $take_one_struct = FFI::Raw->new(
    $shared, 'take_one_struct',
    FFI::Raw::void, FFI::Raw::ptr
  );

  $take_one_struct->call($arg);

  ok(1, "survived the call");

  $arg = FFI::Raw::MemPtr->new(length $packed);

  my $return_one_struct = FFI::Raw->new(
    $shared, 'return_one_struct',
    FFI::Raw::void, FFI::Raw::ptr
  );

  $return_one_struct->call($arg);

  ok(1, "survived the call");

  my ($int, $str) = unpack('ix![p]p', $arg->to_perl_str(length $packed));

  is($int, 42, "got 42");
  is($str, "hello", "got hello");
};

done_testing;
