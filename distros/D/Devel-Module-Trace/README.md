# Perl Module - Devel::Module::Trace

Devel::Module::Trace is a perl module which prints a table of all used and
required module with its origin and elapsed time. This helps tear down slow
modules and helps optimizing module usage in general.

This module uses the Time::Hires module for timing and the POSIX module for
the final output which may slightly interfer your results.

## Usage

```
  perl -d:Module::Trace[=<option1>,<option2>,...] -M<module> -e exit
```

## Options

Options are supplied as command line options to the module itself. Multiple options can be separated by comma.

```
  perl -d:Module::Trace=<option1>,<option2>,... -M<module> -e exit
```

### print

Make the module print the results at exit.

```
  perl -d:Module::Trace=print -MBenchmark -e exit
```

### save

Make the module save the results at exit.

```
  perl -d:Module::Trace="save=/tmp/results.txt" -MBenchmark -e exit
`
### filter

Output filter are defined by the filter option. Multiple filter can be used as comma separated list.
The generic `perl` filter hides requires like `use 5.008`.

```
  %> perl -d:Module::Trace="print,filter=strict.pm,filter=warnings.pm,filter=perl" -MBenchmark -e exit
```

## Output

### Ascii Result

The result is printed to STDERR on exit if using the `print` option. You can get
the raw results at any time with the `Devel::Module::Trace::raw_result` function
and force print the results table any time by the `Devel::Module::Trace::print_pretty`
function.

```
  %> perl -d:Module::Trace="print,filter=strict.pm,filter=warnings.pm,filter=perl" -MBenchmark -e exit
   -------------------------------------------------------------------------------------------------------
  | 13:41:07.37458 |  Benchmark.pm        | 0.013697 | -e:0                                               |
  | 13:41:07.37576 |      Carp.pm         | 0.006555 | /usr/share/perl/5.18/Benchmark.pm:432              |
  | 13:41:07.38211 |          Exporter.pm | 0.000142 | /home/sven/perl5/lib/perl5/Carp.pm:35              |
  | 13:41:07.38245 |      Exporter.pm     | 0.000136 | /usr/share/perl/5.18/Benchmark.pm:433              |
  | 13:41:07.38289 |      Time/HiRes.pm   | 0.000138 | (eval 34)[/usr/share/perl/5.18/Benchmark.pm:454]:2 |
   -------------------------------------------------------------------------------------------------------
```

### HTML Result

There is a small script `script/devel_module_trace_result_server`
available to display the result in a webbrowser from a previous saved result
file.

```
  %> perl -d:Module::Trace=save=results.dat -MBenchmark -e exit
  %> perl ./script/devel_module_trace_result_server results.dat
  [Thu Apr 30 14:49:02 2015] [info] Listening at "http://*:3000".
  Server available at http://127.0.0.1:3000.
```

You can then view the result with a browser.

## Example

To get module trace information for the Benchmark module use this oneliner:

```
  perl -d:Module::Trace=print -MBenchmark -e exit
```

