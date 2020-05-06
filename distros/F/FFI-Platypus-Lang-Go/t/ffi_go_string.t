use Test2::V0 -no_srand => 1;
use FFI::Go::String;

subtest 'basic' => sub {

  my $str = FFI::Go::String->new("foo");
  is(
    $str,
    object {
      call _p => match qr/^-?[0-9]+$/;
      call _n => 3;
      call to_string => "foo";
    },
  );
  is "$str", "foo";

};

subtest 'with null' => sub {

  my $str = FFI::Go::String->new("foo\0bar");
  is(
    $str,
    object {
      call _p => match qr/^-?[0-9]+$/;
      call _n => 7;
      call to_string => "foo\0bar";
    },
  );
  is "$str", "foo\0bar";

};

done_testing;
