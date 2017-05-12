# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SpamCannibal::WebService qw(
	load
	html_cat
	make_jsPOP_win
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 027;
foreach my $dir (qw(tmp)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;	# remove files of this name as well
}

sub ok {
  print "ok $test\n";
  ++$test;
}

mkdir './tmp',0755;

my $file = {
	test1	=> './tmp/test1.txt',
	test2	=> './tmp/test2.txt',
};

my $test1txt = q|test1 file
text is here
|;

my $test2txt = q|the quick brown fox jumped over the lazy dog
1234567890
|;

open(F,'>'. $file->{test1}) or die "could not open test file\n";
print F $test1txt;
close F;

## test 2	load file text
my $filetxt = load($file->{test1});
print "bad file text comparison\nnot "
	unless $filetxt eq $test1txt;
&ok;

## test 3	cat strings, load cache
my $string = 'sometext ';
my $htmltst = $string;
my %cache;

print "html_cat returned false\nnot "
	unless html_cat(\$htmltst,'test1',$file,\%cache);
&ok;

## test 4	check that results are defined
print "cache undefined\nnot "
	unless exists $cache{test1};
&ok;

## test 5	check that results are correct
print "cache value mismatch\nnot "
	unless $cache{test1} eq $test1txt;
&ok;

###########################
## test 6	check jsPOP javascript generator
my $expected = q|
<script language=javascript1.1>
var testname;
function popwin(color) {
  if (!color)
    color = '#ffffcc';
  testname = window.open ( "","testname",
"toolbar=no,menubar=no,location=no,scrollbars=yes,status=yes,resizable=yes," +
  "width=555,height=444");
  testname.document.open();
  testname.document.writeln('<html><body bgcolor="' + color + '"></body></html>');
  testname.document.close();
  testname.focus();
  return false;
}
</script>
|;
my $jshtml = make_jsPOP_win('testname',555,444);
print ":got: $jshtml\nexp: $expected\nnot "
	unless $jshtml eq $expected;
&ok;
