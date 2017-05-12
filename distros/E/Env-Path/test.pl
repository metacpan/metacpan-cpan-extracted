# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

my $final = 0;

# Automatically generates an ok/nok msg, incrementing the test number.
BEGIN {
    my($next, @msgs);
    sub printok {
	push @msgs, ($_[0] ? '' : 'not ') . "ok @{[++$next]}\n";
	return !$_[0];
    }
    END {
	if ($loaded) {
	    print "\n1..", scalar @msgs, "\n", @msgs;
	} else {
	    print "not ok 1\n";
	}
    }
}

use Env::Path;
$loaded = 1;
$final += printok(1);

my $p1 = Env::Path->XXXPATH(qw(aaa bbb ccc));
printok($p1->Name eq 'XXXPATH' && !@XXXPATH::ISA);

my $p2 = Env::Path->new('YYYPATH', qw(aaa bbb ccc xxx yyy zzz c123));
$p2->Replace('^c.*', qw(/CC /XX));
printok($p2->Name eq 'YYYPATH');

$p1->Append($p2->List);
$p1->Uniqify;
$p1->DeleteNonexistent;
printok($p1->List eq 0);

Env::Path->PATH;
PATH->Uniqify;
PATH->DeleteNonexistent;
printok(@PATH::ISA);

Env::Path->ZZZPATH(PATH->List);
ZZZPATH->Append('/nosuchdir');
ZZZPATH->Assign(ZZZPATH->List, $ENV{ZZZPATH});
printok(PATH->List eq (ZZZPATH->List - 2)/2);
ZZZPATH->Uniqify;
printok(PATH->List eq ZZZPATH->List - 1);
ZZZPATH->DeleteNonexistent;
printok(PATH->List eq ZZZPATH->List);
