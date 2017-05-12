# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..26\n"; }
END {print "not ok 1\n" unless $loaded;}
use Devel::Messenger qw{note};
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# test print
local *note = note { output => 'print' };
note "ok 2\n";

no warnings 'redefine'; # test warn
local *note = note { output => 'warn' };
{
    my $message = '';
    my $text = "This is a line\n";
    local $SIG{__WARN__} = sub { $message = $_[0] };
    note $text;
    print (($text eq $message ? '' : 'not ') . "ok 3\n");
}

# test filename
my $file = 'debug.txt'; unlink $file; # may fail
local *note = note { output => $file };
my @data = <DATA>;
note @data;

if (open FILE, $file) {
    my @wrote = <FILE>;
    close FILE;
    print ((@data == @wrote ? '' : 'not ') . "ok 4\n");
    my $ok = 0;
    foreach my $c (0..(scalar(@data)-1)) {
        $ok++ if ($data[$c] eq $wrote[$c]);
    }
    print (($ok == @data ? '' : 'not ') . "ok 5\n");
} else {
    print "not ok 4 # unable to read file: $!\n";
    print "not ok 5 # unable to read file: $!\n";
}

# test filehandle
if (open FILE, ">$file") {
    local *note = note { output => \*FILE };
    note @data;
    close FILE;
    if (open FILE, $file) {
        my @wrote = <FILE>;
        close FILE;
        print ((@data == @wrote ? '' : 'not ') . "ok 6\n");
        my $ok = 0;
        foreach my $c (0..scalar(@data)-1) {
            $ok++ if ($data[$c] eq $wrote[$c]);
        }
        print (($ok == @data ? '' : 'not ') . "ok 7\n");
    } else {
        print "not ok 6 # unable to read file: $!\n";
        print "not ok 7 # unable to read file: $!\n";
    }
} else {
    print "not ok 6 # unable to write file: $!\n";
    print "not ok 7 # unable to wrtie file: $!\n";
}

# test return
local *note = note { output => 'return' };
print (('normal text' eq note('normal text') ? '' : 'not ') . "ok 8\n");

# test wrap
local *note = note { wrap => ['<!--', "-->\n"] };
print (("<!--html-->\n" eq note('html') ? '' : 'not ') . "ok 9\n");
print (("<!--html-->\n" eq note("html\n") ? '' : 'not ') . "ok 10\n");

local *note = note { wrap => ['<text>', '</text>'] };
print (('<text>xml</text>' eq note('xml') ? '' : 'not ') . "ok 11\n");
print (("<text>xml\n</text>" eq note("xml\n") ? '' : 'not ') . "ok 12\n");

local *note = note { wrap => '###' };
print (('###alert###' eq note('alert') ? '' : 'not ') . "ok 13\n");

# test prefix
local *note = note { wrap => '', pkgname => 1 };
print (('t/note.t: my note' eq note('my note') ? '' : 'not ') . "ok 14\n");

local *note = note { linenumber => 1 };
print (('t/note.t (99): my note' eq note('my note') ? '' : 'not ') . "ok 15\n");

local *note = note { pkgname => 0 };
print (('(102): my note' eq note('my note') ? '' : 'not ') . "ok 16\n");
print (('my note' eq note('continue', 'my note') ? '' : 'not ') . "ok 17\n");

local *note = note { linenumber => 0 };
print (('' eq note(\2, 'note 2') ? '' : 'not ') . "ok 18\n");

local *note = note { level => 0 };
print (('note 2' eq note(\2, 'note 2') ? '' : 'not ') . "ok 19\n");

local *note = note { level => 2 };
print (('note 2' eq note(\2, 'note 2') ? '' : 'not ') . "ok 20\n");

# test trap
local *note = note { output => 'trap', level => 1 };
print (('' eq note("ok 23\n") ? '' : 'not ') . "ok 21\n");
print (('' eq note("ok 24\n") ? '' : 'not ') . "ok 22\n");

local *note = note { output => 'print' };
# should automatically print for test 23 and 24

# test trap on wrapped notes
local *note = note { output => 'trap', wrap => ["<tag>", "</tag>\n"] };
print (('' eq note('wrapped text') ? '' : 'not ') . "ok 25\n");
{
    my $message = '';
    local $SIG{__WARN__} = sub { $message = $_[0] };
    local *note = note { output => 'warn' };
    print (("<tag>wrapped text</tag>\n" eq $message ? '' : 'not ') . "ok 26\n");
}

__DATA__
This is to see if I can write to a file.

