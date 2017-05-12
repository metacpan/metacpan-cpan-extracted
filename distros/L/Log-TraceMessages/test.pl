# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
# 
# In case you're wondering, the curly braces round some variable names
# are to stop interpretation by RCS :-(.
# 

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $VERSION = '1.4';
BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use Log::TraceMessages qw(t d trace dmp);
$loaded = 1;
print 'not ' if ${Log::TraceMessages::VERSION} ne $VERSION;
print "ok 1\n";

######################### End of black magic.

use strict;
use POSIX qw(tmpnam);
my $test_str = 'test < > &';
my $debug = 0;
my $out;

# Test 2 - t() with $On == 1
${Log::TraceMessages::On} = 1;
${Log::TraceMessages::CGI} = 0;
$out = grab_output("t('$test_str')");
print 'not ' if $out->[0] ne '' or $out->[1] ne "$test_str\n";
print "ok 2\n";

# Test 3 - t() with $On == 0
${Log::TraceMessages::On} = 0;
$out = grab_output("t('$test_str')");
print 'not ' if $out->[0] ne '' or $out->[1] ne '';
print "ok 3\n";

# Test 4 - t() with $CGI == 1
${Log::TraceMessages::On} = 1;
${Log::TraceMessages::CGI} = 1;
$out = grab_output("t('$test_str')");
print 'not ' if $out->[0] ne "\n<pre>test &lt; &gt; &amp;</pre>\n"
             or $out->[1] ne '';
print "ok 4\n";

# Test 5 - t() with $CGI == 0 after setting a logfile
${Log::TraceMessages::On} = 1;
${Log::TraceMessages::CGI} = 0;
my $tmp = tmpnam();
${Log::TraceMessages::Logfile} = $tmp;
$out = grab_output("t('$test_str')");
${Log::TraceMessages::Logfile} = undef;
my $contents = read_file($tmp);
print "contents of $tmp: $contents\n" if $debug;
print 'not ' if $out->[0] ne '' or $out->[1] ne ''
             or $contents ne "$test_str\n";
print "ok 5\n";
# On Windows the file must be closed before unlinking, and that
# doesn't happen until the next t().
#
grab_output("t('')");
unlink $tmp or die "cannot unlink $tmp: $!";

# Test 6 - t() with $CGI == 1 after setting a different logfile
${Log::TraceMessages::On} = 1;
${Log::TraceMessages::CGI} = 1;
my $tmp = tmpnam();
${Log::TraceMessages::Logfile} = $tmp;
$out = grab_output("t('$test_str')");
${Log::TraceMessages::Logfile} = undef;
my $contents = read_file($tmp);
print "contents of $tmp: $contents\n" if $debug;
print 'not ' if $out->[0] ne '' or $out->[1] ne ''
             or $contents ne "\n<pre>test &lt; &gt; &amp;</pre>\n";
print "ok 6\n";
grab_output("t('')"); # Windows - see above
unlink $tmp or die "cannot unlink $tmp: $!";

# Test 7 - quick check that trace() works (no logfile now)
${Log::TraceMessages::On} = 1;
${Log::TraceMessages::CGI} = 0;
$out = grab_output("trace('$test_str')");
print 'not ' if $out->[0] ne '' or $out->[1] ne "$test_str\n";
print "ok 7\n";

# Test 8 - d().  But this is not a full test suite for Data::Dumper.
${Log::TraceMessages::On} = 1;
my $a; eval '$a = ' . d($test_str);
print 'not ' if $a ne $test_str;
print "ok 8\n";

# Test 9 - check that d() does nothing when trace is off
${Log::TraceMessages::On} = 0;
print 'not ' if d($test_str) ne '';
print "ok 9\n";

# Test 10 - quick check that dmp() works
${Log::TraceMessages::On} = 1;
my $a; eval '$a = ' . dmp($test_str);
print 'not ' if $a ne $test_str;
print "ok 10\n";

# Test 11 - check_argv()
${Log::TraceMessages::On} = 0;
my $num_args = @ARGV;
@ARGV = (@ARGV, '--trace');
Log::TraceMessages::check_argv();
print 'not ' if @ARGV != $num_args or not ${Log::TraceMessages::On};
print "ok 11\n";


# grab_output()
# 
# Eval some code and return what was printed to stdout and stderr.
# 
# Parameters: string of code to eval
# 
# Returns: listref of [ stdout text, stderr text ]
# 
sub grab_output($) {
    die 'usage: grab_stderr(string to eval)' if @_ != 1;
    my $code = shift;
    require POSIX;
    my $tmp_o = POSIX::tmpnam(); my $tmp_e = POSIX::tmpnam();
    local *OLDOUT, *OLDERR;

    print "running code: $code\n" if $debug;
    
    # Changing $SIG{__DIE__} seems to cause problems elsewhere, even
    # if you set it back again or undefine it afterwards.  So we use
    # this as a replacement for die().
    # 
    sub dy($) { print "$_[0]\n"; print STDERR "$_[0]\n"; exit(1) }

    open(OLDOUT, ">&STDOUT") or dy "can't dup stdout: $!";
    open(OLDERR, ">&STDERR") or dy "can't dup stderr: $!";
    open(STDOUT, ">$tmp_o")  or dy "can't open stdout to $tmp_o: $!";
    open(STDERR, ">$tmp_e")  or dy "can't open stderr to $tmp_e: $!";
    eval $code;
    close(STDOUT)            or dy "cannot close stdout opened to $tmp_o: $!";
    close(STDERR)            or dy "will anyone ever see this message?  $!";
    open(STDOUT, ">&OLDOUT") or dy "can't dup stdout back again: $!";
    open(STDERR, ">&OLDERR") or dy "can't dup stderr back again: $!";

    dy $@ if $@;

    local $/ = undef;
    open (TMP_O, $tmp_o) or dy "cannot open $tmp_o: $!";
    open (TMP_E, $tmp_e) or dy "cannot open $tmp_e: $!";
    my $o = <TMP_O>; my $e = <TMP_E>;
    close TMP_O   or dy "cannot close filehandle opened to $tmp_o: $!";
    close TMP_E   or dy "cannot close filehandle opened to $tmp_e: $!";
    unlink $tmp_o or dy "cannot unlink $tmp_o: $!";
    unlink $tmp_e or dy "cannot unlink $tmp_e: $!";

    if ($debug) {
	print "stdout: $o\n";
	print "stderr: $e\n";
    }

    return [ $o, $e ];
}


# read_file()
# 
# Read a file's contents and return them as a string.
# 
sub read_file($) {
    die 'usage: read_file(filename)' if @_ != 1;
    my $f = shift;
    my $fh = new FileHandle($f); die "cannot open $f: $!" if not $fh;
    local $/ = undef;
    my $r = <$fh>;
    close $fh or die "cannot close filehandle opened to $f: $!";
    return $r;
}
