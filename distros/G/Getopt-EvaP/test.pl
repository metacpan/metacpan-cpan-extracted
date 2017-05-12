#!./perl

use Getopt::EvaP;		# Evaluate Parameters
use subs qw/exit/;

sub exit {} # override builtin to check command line processing errors

@PDT = split /\n/, <<'end-of-PDT';
PDT sample
  verbose, v: switch
  command, c: string = D_SAMPLE_COMMAND, "ps -el"
  scale_factor, sf: real = 1.2340896e-1
  millisecond_update_interval, mui: integer = $required
  ignore_output_file_column_one, iofco: boolean = TRUE
  output, o: file = stdout
  queue, q: key plotter, postscript, text, printer, keyend = printer
  destination, d: application = `hostname`
  tty, t: list of name = ("/dev/console", "/dev/tty0", "/dev/tty1")
PDTEND optional_file_list
end-of-PDT

@MM = split /\n/, <<'end-of-MM';
sample

	A sample program demonstrating typical Evaluate Parameters
	usage.

	Examples:

	  sample
	  sample -usage-help
	  sample -h
	  sample -full-help
          sample -mui 1234
.verbose
        A 'switch' type parameter emulates a typical standalone
        switch. If the switch is specified Evaluate Parameters
        returns a '1'.
.command
        A 'string' type parameter is just a list of characters,
        which must be quoted if it contains whitespace. 
        NOTE:  for this parameter you can also create and
        initialize the environment variable D_SAMPLE_COMMAND to
        override the standard default value for this command
        line parameter.  All types except 'switch' may have a
        default environment variable for easy user customization.
.scale_factor
        A 'real' type parameter must be a real number that may
        contain a leading sign, a decimal point and an exponent.
.millisecond_update_interval
        An 'integer' type parameter must consist of all digits
        with an optional leading sign.  NOTE: this parameter's
        default value is '$required', meaning that
        Evaluate Parameters ensures that this parameter is
        specified and given a valid value.  All types except
        'switch' may have a default value of '$required'.
.ignore_output_file_column_one
        A 'boolean' type parameter may be TRUE/YES/ON/1 or
        FALSE/NO/OFF/0, either upper or lower case.  If TRUE,
        Evaluate Parameters returns a value of '1', else '0'.
.output
        A 'file' type parameter expects a filename.  For Unix
        $HOME and ~ are expanded.  For evap/Perl 'stdin' and
	'stdout' are converted to '-' and '>-' so they can be
	used in a Perl 'open' function.
.queue
        A 'key' type parameter enumerates valid values.  Only the
        specified keywords can be entered on the command line.
.destination
	An 'application' type parameter is not type-checked in
	any - the treatment of this type of parameter is
	application specific.  NOTE:  this parameter' default
	value is enclosed in grave accents (or "backticks").
	Evaluate Parameters executes the command and uses it's
	standard output as the default value for the parameter.
.tty
	A 'name' type parameter is similar to a string except
	that embedded white-space is not allowed.  NOTE: this
	parameter is also a LIST, meaning that it can be
	specified multiple times and that each value is pushed
        onto a Perl LIST variable.  In general you should quote
        all list elements.  All types except 'switch' may be
	'list of'.
end-of-MM

push @ARGV, qw/-mui 123/;     # fake a command line
EvaP \@PDT, \@MM, \%OPT;      # evaluate parameters


select(STDERR); $| = 1;     # make unbuffered
select(STDOUT); $| = 1;     # make unbuffered
print "1..23\n";

# Exercise PDT defaults.

print $0 eq $OPT{help} ? "ok1\n" : "not ok1\n";
print !defined($OPT{verbose}) ? "ok2\n" : "not ok2\n";
print $OPT{command} eq 'ps -el' ? "ok3\n" : "not ok3\n";
print $OPT{scale_factor} ==  1.2340896e-1 ? "ok4\n" : "not ok4\n";
print $OPT{millisecond_update_interval} == 123 ? "ok5\n" : "not ok5\n";
print $OPT{ignore_output_file_column_one} ? "ok6\n" : "not ok6\n";
print $OPT{output} eq '>-' ? "ok7\n" : "not ok7";
print $OPT{queue} eq 'printer' ? "ok8\n" : "not ok8\n";
my $hn = `hostname`; chomp $hn;
print $OPT{destination} eq $hn ? "ok9\n" : "not ok9\n";
print join(",", @{$OPT{tty}}) eq "/dev/console,/dev/tty0,/dev/tty1" ?
    "ok10\n" : "not ok10\n";
print $#ARGV == -1 ? "ok11\n" : "not ok11\n";

# Exercise command line overrides.  Pretend we're embedding to allow
# successive calls to EvaP.

$Getopt::EvaP::evap_embed = 1;
@ARGV = qw/-v -c Frog -sf -2.5 -mui 123 -iofco 0 -o toad.lst -q plotter
    -destination Pandora.CC.Lehigh.EDU -tty tty1 -tty com2 -tty ptty0 a b c/;
EvaP \@PDT, \@MM;      # evaluate parameters

print defined($Options{verbose}) ? "ok12\n" : "not ok12\n";
print $Options{command} eq 'Frog' ? "ok13\n" : "not ok13\n";
print $Options{scale_factor} ==  -2.5 ? "ok14\n" : "not ok14\n";
print $opt_millisecond_update_interval == 123 ? "ok15\n" : "not ok15\n";
print not $options{ignore_output_file_column_one} ? "ok16\n" : 	"not ok16\n";
print $options{output} eq 'toad.lst' ? "ok17\n" : "not ok17";
print $opt_queue eq 'plotter' ? "ok18\n" : "not ok18\n";
print $opt_destination eq 'Pandora.CC.Lehigh.EDU' ? "ok19\n" : 	"not ok19\n";
print join(",", @opt_tty) eq "tty1,com2,ptty0" ? "ok20\n" : "not ok20\n";
print $#ARGV == 2 ? "ok21\n" : "not ok21\n";

# Exercise type checking and help stuff.
 
open(OLDOUT, ">&STDOUT") or die $!;
open(OLDERR, ">&STDERR") or die $!;
open(STDERR, '>test.err') or die $!;
open(STDOUT, '>test.out') or die $!;
@ARGV = qw/-sf not-a-float -mui 1bc -iofco 2 -q no-queue -unknown -comm/;
EvaP \@PDT, \@MM;      # evaluate parameters
@ARGV = (qw/-sf 1 -usage-help/);
EvaP \@PDT, \@MM;      # evaluate parameters
@ARGV = (qw/-sf 1 -help/);
EvaP \@PDT, \@MM;      # evaluate parameters
@ARGV = (qw/-sf 1 -full-help/);
EvaP \@PDT, \@MM;      # evaluate parameters
close STDERR;
close STDOUT;

open(STDOUT, ">&OLDOUT");
open(STDERR, ">&OLDERR");

@test = ();
@good = ();
open(T, 'test.err') or die $!;
open(G, 'test.err.good') or die $!;
@test = <T>;
@good = <G>;
close T;
close G;
print @test eq @good ? "ok22\n" : "not ok 22\n";

@test = ();
@good = ();
open(T, 'test.out') or die $!;
open(G, 'test.out.good') or die $!;
@test = <T>;
@good = <G>;
close T;
close G;
print @test eq @good ? "ok23\n" : "not ok 23\n";
__END__
use Getopt::EvaP;		# Evaluate Parameters
use subs qw/exit/;

sub exit {} # override builtin to check command line processing errors

@PDT = split /\n/, <<'end-of-PDT';
PDT sample
  set, s: list of 2 real = (123,456)
  tet, t:  1 strings = ("555", "777")
PDTEND optional_file_list
end-of-PDT

@MM = split /\n/, <<'end-of-MM';
sample

	A sample program demonstrating typical Evaluate Parameters
	usage.
end-of-MM

@ARGV=(qw/-h -s 1 2 3/);
EvaP \@PDT, \@MM;

print "set=", join(',', @opt_set), "!\n";
__END__
