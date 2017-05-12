use Test::More tests => 4;

use Devel::PrettyTrace;
$Devel::PrettyTrace::Opts{colored} = 0;

sub z{
	bt;
}

sub f{
    package Z;
    sub {
        main::z(1,2, "t")
    }->()
}

my $z = sub {f()};

is($z->(), '  main::z(
    [0] 1,
    [1] 2,
    [2] "t"
  ) called at t/03_traces.t line 13
  Z::__ANON__() called at t/03_traces.t line 14
  main::f() called at t/03_traces.t line 17
  main::__ANON__() called at t/03_traces.t line 19
');

{
	local $Devel::PrettyTrace::Deeplimit = 2;
	
	is($z->(), '  main::z(
    [0] 1,
    [1] 2,
    [2] "t"
  ) called at t/03_traces.t line 13
  Z::__ANON__() called at t/03_traces.t line 14
');
}

{
    local $Devel::PrettyTrace::Skiplevels = 1;

	is($z->(), '  Z::__ANON__() called at t/03_traces.t line 14
  main::f() called at t/03_traces.t line 17
  main::__ANON__() called at t/03_traces.t line 44
');
}

{
    $Devel::PrettyTrace::IgnorePkg{Z}++;

	is($z->(), '  main::z(
    [0] 1,
    [1] 2,
    [2] "t"
  ) called at t/03_traces.t line 13
  main::f() called at t/03_traces.t line 17
  main::__ANON__() called at t/03_traces.t line 53
');
}
