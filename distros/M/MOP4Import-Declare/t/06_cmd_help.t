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
use Test::Differences;
use Capture::Tiny qw(capture_stderr);

my $testDir = "$FindBin::Bin/examples";

use_ok("MOP4Import::Util::Inspector");

my $inspectorFn = $INC{"MOP4Import/Util/Inspector.pm"};
my $distLib = dirname(dirname(dirname(File::Spec->rel2abs($inspectorFn))));

my @run = ($^X, "-I$distLib");

{
  eq_or_diff(scalar(capture_stderr {
    system $^X (@run, "-I$testDir", "$testDir/t_Bar.pm")
  }), <<'END', "cmd_help");
Usage: t_Bar.pm [--opt=value].. <Command> ARGS...

Commands
  help        


Options from t_Bar:
  --foo           

Options from MOP4Import::Base::CLI_JSON:
  --help          show this help message
  --quiet         to be (somewhat) quiet
  --scalar        evaluate methods in scalar context
  --output        choose output serializer (ndjson/json/tsv/dump)
  --flatten       
  --undef-as      serialize undef as this value. used in tsv output
  --no-exit-code  exit with 0(EXIT_SUCCESS) even when result was falsy/empty
  --binary        keep STDIN/OUT/ERR binary friendly
END
}

{
  my $clijsonFn = $INC{"MOP4Import/Base/CLI_JSON.pm"};
  my $distLib = dirname(dirname(dirname(File::Spec->rel2abs($clijsonFn))));

  eq_or_diff(scalar(capture_stderr {
    system $^X (@run, $clijsonFn, "unknown_method")
  }), <<'END', "cmd_help unknown_method");
Error: No such subcommand 'unknown_method'

Usage: CLI_JSON.pm [--opt=value].. <Command> ARGS...

Commands
  help        


Options from MOP4Import::Base::CLI_JSON:
  --help          show this help message
  --quiet         to be (somewhat) quiet
  --scalar        evaluate methods in scalar context
  --output        choose output serializer (ndjson/json/tsv/dump)
  --flatten       
  --undef-as      serialize undef as this value. used in tsv output
  --no-exit-code  exit with 0(EXIT_SUCCESS) even when result was falsy/empty
  --binary        keep STDIN/OUT/ERR binary friendly
END
}


done_testing();
