use Test::More;

use Devel::PrettyTrace;
$Devel::PrettyTrace::Opts{colored} = 0;
$Devel::PrettyTrace::Opts{show_readonly} = 0;

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
  ) called at t/03_traces.t line 14
  Z::__ANON__() called at t/03_traces.t line 15
  main::f() called at t/03_traces.t line 18
  main::__ANON__() called at t/03_traces.t line 20
');

{
	local $Devel::PrettyTrace::Deeplimit = 2;
	
	is($z->(), '  main::z(
    [0] 1,
    [1] 2,
    [2] "t"
  ) called at t/03_traces.t line 14
  Z::__ANON__() called at t/03_traces.t line 15
');
}

{
    local $Devel::PrettyTrace::Skiplevels = 1;

	is($z->(), '  Z::__ANON__() called at t/03_traces.t line 15
  main::f() called at t/03_traces.t line 18
  main::__ANON__() called at t/03_traces.t line 45
');
}

{
    $Devel::PrettyTrace::IgnorePkg{Z}++;

	is($z->(), '  main::z(
    [0] 1,
    [1] 2,
    [2] "t"
  ) called at t/03_traces.t line 14
  main::f() called at t/03_traces.t line 18
  main::__ANON__() called at t/03_traces.t line 54
');
}
done_testing;
