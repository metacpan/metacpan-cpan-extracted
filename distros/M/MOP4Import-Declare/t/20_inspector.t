#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }

use File::Basename;
use File::Spec;

use Test::More;
use Test::Output;
use Capture::Tiny qw(capture_stdout);
use JSON::MaybeXS;

use_ok("MOP4Import::Util::Inspector");

my $testDir = "$FindBin::Bin/examples";

{
  my $modulinoFn = $INC{"MOP4Import/Util/Inspector.pm"};
  ok -x $modulinoFn, "Inspector.pm is executable";
  stdout_is sub {
    system $^X ($^X, $modulinoFn, "--lib=$testDir", list_commands_of => "t_Case1")
  }, "foo\nhelp\n", "Inspector.pm as a modulino";

  is_deeply decode_json(capture_stdout {
    system $^X ($^X, $modulinoFn, "--lib=$testDir"
                , qw(info_code_attributes_of t_Case2 foo))
  }), +{Bar => "yy", Foo => "xx"}, "Custom code attributes";
}

{
  my $inspector = MOP4Import::Util::Inspector->new(lib => $testDir);

  {
    local @INC = ($FindBin::Bin, @INC);
    is $inspector->require_module("t_Case1"), "t_Case1"
      , "require_module ok";
  }

  is_deeply [$inspector->list_commands_of("t_Case1")]
    , [qw(foo help)], "list_commands_of";

  is_deeply [$inspector->list_options_of("t_Case1")]
    , [qw(
      help
      quiet
      scalar
      output
      flatten
      undef-as
      no-exit-code
      binary
      foo
      bar
    )], "list_options_of";

  is_deeply $inspector->info_code_attributes_of(t_Case1 => "cmd_foo")
    , +{Doc => q(this is foo command)}
    , "info_code_attributes_of(t_Case1 => cmd_foo)";

  is_deeply $inspector->info_code_attributes_of(t_Case1 => "onconfigure_bar")
    , +{Doc => q(bar option), ZshCompleter => q(:filename:_files)}
    , "info_code_attributes_of(t_Case1 => onconfigure_bar)";
}

{
  stderr_like sub {
    system $^X ($^X, "$testDir/t_Case1.pm")
  }, qr{\A\QUsage: t_Case1.pm [--opt=value].. <Command> ARGS...

Commands
  foo        this is foo command
  help        


Options from t_Case1:
  --foo           
  --bar           bar option
}, "output of cmd_help";
}
done_testing;
