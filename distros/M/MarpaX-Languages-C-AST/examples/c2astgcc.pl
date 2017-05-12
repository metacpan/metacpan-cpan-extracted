#!env perl
use strict;
use warnings FATAL => 'all';
use diagnostics;
use Getopt::Long;
use POSIX qw/EXIT_FAILURE EXIT_SUCCESS/;
use File::Spec;
use File::Basename;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;

autoflush STDOUT 1;

# ABSTRACT: Do C source analysis before calling the compiler. This wrapper is designed for gcc only, and is best used in workflows using the ${CC} environment variable.

# VERSION

# PODNAME: c2astgcc.pl

=head1 DESCRIPTION

This script will call c2ast before calling the real compiler, and is targetted for gcc. You should set the environment variable ${CC} and then do 'make'.

=cut

# ----
# Init
# ----
my $loglevel = 'INFO';
my $defaultLog4perlConf = <<DEFAULT_LOG4PERL_CONF;
log4perl.rootLogger              = $loglevel, Screen
log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr  = 1
log4perl.appender.Screen.layout  = PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
DEFAULT_LOG4PERL_CONF
Log::Log4perl::init(\$defaultLog4perlConf);
Log::Any::Adapter->set('Log4perl');

my @ORIG_ARGV = @ARGV;

#
# We want to remove any -o option and catch all .c
#
my $help = 0;
my @o = '';
my $c = '';
#
# This should be in the same directory than where we leave
#
my $c2astPath = File::Spec->catfile(dirname($0), 'c2ast.pl');
my $c2astOpt = '--check reservedNames --progress --logstderr';
my $cc = 'cc';

$log->debugf('Original list of arguments: %s', "@ARGV");
Getopt::Long::Configure("pass_through");
GetOptions ('help!' => \$help,
            'o=s' => \@o,
            'c!' => \$c,
	    'loglevel=s' => \$loglevel,
	    'c2astOpt=s' => \$c2astOpt,
	    'c2astPath=s' => \$c2astPath,
	    'cc=s' => \$cc);
if ($help || ! @ARGV) {
  usage($help ? EXIT_SUCCESS : EXIT_FAILURE)
}

# ----------------------------
# For every .c file call c2ast
# ----------------------------
my @argv = ();
my @c = ();
foreach (@ARGV) {
    if (/\.c*/i) {
	push(@c, $_);
    } else {
	push(@argv, $_);
    }
}
foreach (@c) {
    my @cmd = ($^X, $c2astPath, split(' ', $c2astOpt), @argv, $_);
    $log->infof('%s', "@cmd");
    system(@cmd);
}
#
# Finally call the compiler
#
my @cmd = ($cc);
push(@cmd, @ORIG_ARGV);
$log->infof('%s', "@cmd");
system(@cmd);
my $rc = $? >> 8;
$log->debugf('Exit code: %d', $rc);
exit($? >> 8);

# --------------------------------------------------------------------------------------
sub usage {
    my $rc = shift;

    print <<USAGE;
Usage: $^X $0 options

where options can be:

--help                  This help

--o <outputfile>        This is a fake option from c2astgcc point of view, that exist in this wrapper only to catch the -o option and remove it.

--c <outputfile>        This is a fake option from c2astgcc point of view, that exist in this wrapper only to catch the -c option and remove it.

--cc <outputfile>       Compiler. Default is "$cc".

--c2astPath <path>      c2ast.pl path. Default is "$c2astPath".

--c2astOpt <options>    c2ast.pl specific options. Please say c2ast.pl --help to see all c2ast.pl options.
                        All c2ast arguments should go into the single string following --c2ast on the command-line.
                        Default is: "$c2astOpt".

--loglevel <level>      A level that has to be meaningful for Log::Log4perl, typically WARN, INFO, ERROR, etc.
                        Default is INFO. Logging will go through STDERR because quite a lot of make framework
                        redirect standard output and parses it.
Example:
* Extract perl tarball and go into the extracted perl distribution
./Configure -des -Dusedevel
* In Makefile, replace CC=cc by CC=c2astgcc.pl
make
USAGE

    exit($rc);
}
