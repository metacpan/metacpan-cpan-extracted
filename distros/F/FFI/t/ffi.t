use strict;
use warnings;
use Test::More;
use Config;
use FFI;
use FFI::CheckLib qw( find_lib_or_die );
use FFI::Library;

subtest 'test some common lib C stuff' => sub {

  my $libc = FFI::Library->new(\$0);

  # Function addresses
  my $atoi = $libc->address("atoi");
  my $strlen = $libc->address("strlen");
  my $pow = $libc->address("pow");

  is FFI::call($atoi,   'cip', "12"),         12, 'atoi(12)';
  is FFI::call($atoi,   'cip', "-97"),       -97, 'atoi(-97)';
  is eight_digits(FFI::call($pow,   'cddd', 2, 0.5)),   eight_digits(2**0.5), 'pow(2,0.5)';
  is FFI::call($strlen, 'cIp', "Perl"),      4, 'strlen("Perl")';

  done_testing;
};

subtest 'test using the Windows API calling conventions' => sub {

  my $lib = FFI::Library->new(find_lib_or_die( lib => "test", libpath => "t/ffi/_build" ));

  # honestly this shit makes my head hurt.
  my $possibly_decorated_name = 'fill_my_string';
  $possibly_decorated_name .= '@8' if $Config{ptrsize} == 4 && $^O =~ /^(MSWin32|cygwin)$/i;

  my $fill_my_string = $lib->function($possibly_decorated_name, 'sIIp');

  my $buffer = ' ' x 20;
  is($fill_my_string->(20, $buffer), 20);
             # 12345678901234567890
  is($buffer, "The quick brown fox\0");

  $buffer = ' ' x 500;
  is($fill_my_string->(500, $buffer), 45);
  $buffer = substr($buffer, 0, 45);
  is($buffer, "The quick brown fox jumps over the lazy dog.\0");

  done_testing;
};

subtest 'test closures' => sub {

  my $lib = FFI::Library->new(find_lib_or_die( lib => "test", libpath => "t/ffi/_build" ));

  sub callback1
  {
    return $_[0] + $_[1];
  }

  my $callback1  = FFI::callback("ciii", \&callback1);
  my $call_adder = $lib->function("call_adder", 'cioii');

  is($call_adder->($callback1->addr, 1,2), 3, 'call_addr->($address,1,2) = 3');

  done_testing;
};

done_testing;

sub eight_digits
{
  my $value = shift;
  $value =~ /^([0-9]*\.[0-9]{8})/
    ? $1
    : die "pattern failed";
}
