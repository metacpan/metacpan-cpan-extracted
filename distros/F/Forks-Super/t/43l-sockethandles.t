use Forks::Super qw(:test overload);
use Forks::Super::Util qw(is_socket is_pipe);
use Test::More tests => 7;
use utf8;
use strict;
use warnings;

############### utf8 layer ###################

my $unicode_phrase = "A string with wide characters: Tiếng Viẹt ...\n";
my $layer = ':utf8';
if ($] < 5.008) {
    $unicode_phrase = "A string with a newline\n";
    $layer = ':crlf';
    SKIP: {
        skip "layers not available for $]", 7;
    }
    exit;
}

my $pid = fork {
    child_fh => "out,err,socket,block,$layer",
    sub => sub {
	print STDERR "foo\n";
	print STDOUT $unicode_phrase;
	print STDOUT "baz\n";
    }
};

ok(isValidPid($pid), "$pid is valid pid");
ok(is_socket($pid->{child_stdout}) && !is_pipe($pid->{child_stdout}), 
     "ipc with filehandles");
sleep 1;
my $err = Forks::Super::read_stderr($pid);
ok($err =~ /^foo/, "read stderr")
    or diag("expected 'foo', got $err");

my $out = <$pid>;
if ($] < 5.008) {
    # read with :crlf layer doesn't work the same in 5.6
    $unicode_phrase =~ s/\n/\r\n/g;
}
s/\r/\\r/g,s/\n/\\n/g for $out,$unicode_phrase;
ok($out eq $unicode_phrase, "read stdout")
    or diag("output was: $out\nexpected  : $unicode_phrase\n");

$out = Forks::Super::read_stdout($pid);
ok($out =~ /^baz/, "successful blocking read on stdout");

#### no more input on STDOUT or STDERR

{
    no warnings 'utf8';
    my @err = Forks::Super::read_stderr($pid);
    ok(@err==0,
       "blocking read on empty stderr returns empty")
	or diag("expected nothing, got @err");
}

$out = Forks::Super::read_stdout($pid, "block" => 0);
ok(!defined($out) || $out eq "",                         ### 13 ###
   "non-blocking read on empty stdout returns empty");




# skip :gzip layer tests. in general, :gzip layer can't be used
# with a sockethandle, which can be both written to and read from
