use strict;
#use warnings; # we need to check with default warnings
use Test::More;

use Devel::CompileLevel qw(compile_level compile_caller);

sub foo {
  compile_level;
}

sub bar {
  foo;
}

sub welp {
  compile_caller;
}

sub baz {
  welp;
}

eval q{
  BEGIN {
    is compile_level, 0,  'compile_level is 0 in BEGIN';
    is foo, 1,            'compile_level is 1 in sub call from BEGIN';
    is bar, 2,            'compile_level is 2 in two sub calls from BEGIN';
  }
  is compile_level, undef,  'compile_level is undef when not compiling';
  is foo, undef,            '... not compiling->sub: level is undef';
  is bar, undef,            'not compiling->sub->sub: level is undef';
  1;
} or die "$@";

my %check;
my @check;
BEGIN {
  @check = qw(package file line);
  %check = (
    package => 'Fun::Grizzler',
    file    => 'fun-grizzler..pl',
    line    => '219',
  );
}
BEGIN {
  package New::Willenium;
  $INC{'New/Willenium.pm'} = 1;

  sub import {
    ::is_deeply
      [ (::compile_caller) ],
      [ caller(::compile_level - 1) ],
      'compile_caller matches manual caller check';

    ::is_deeply
      [ (::compile_caller)[0..$#check] ],
      [ @check{@check} ],
      'compile_caller gives correct info';
    ::is
      scalar ::compile_caller,
      $check{package},
      'compile_caller in scalar context gives package';

    ::is_deeply
      [ (::welp)[0..$#check] ],
      [ @check{@check} ],
      'compile_caller gives correct info through two extra sub calls';
    ::is_deeply
      [ (::baz)[0..$#check] ],
      [ @check{@check} ],
      'compile_caller gives correct info through extra sub call';

    {
      @DB::args = ('guff');
      () = ::compile_caller;
      ::is_deeply [@DB::args], ['guff'],
        '@DB::args not populated when called from non-DB package';

      package DB;
      () = ::compile_caller;
      ::is_deeply [@DB::args], ['New::Willenium', 'garf' ],
        '@DB::args populated when called from DB package';
    }
  }
}

eval qq{
  package $check{package};
#line $check{line} "$check{file}"
  use New::Willenium 'garf';
  1;
} or die "$@";


is_deeply [::compile_caller], [],
  'compile_caller is empty when not compiling';

done_testing;
