# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use Festival::Client::Async qw(parse_lisp);
use IO::Select;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

unlink 'hello.tmp.raw';
open TMP, ">hello.tmp.raw"
    or die "can't open hello.tmp.raw: $!";
my $c = Festival::Client::Async->new;
unless (defined $c) {
    print "No Festival server running, skipping tests\n";
    exit;
}
print "ok 2\n";

# Test error handling (Parameter.set needs an extra argument)
my $r = $c->server_eval_sync(q/(Parameter.set 'Wavefiletype)/);
if ($r) {
    print "not ok 3\n";
} else {
    print "ok 3\n";
}

# Our testsuite won't work with anything but kal_diphone
unless ($c->server_eval_sync(q/(voice_kal_diphone)/)) {
    print "voice_kal_diphone not available, skipping tests\n";
    exit;
}

$r = $c->server_eval_sync(q/(Parameter.set 'Wavefiletype 'raw)/,
			  { LP => sub { print "ok 4\n" if shift } });
if ($r) {
    print "ok 5\n";
} else {
    print "not ok 5\n";
}

# Test the blocking interface
$r = $c->server_eval_sync(<<EOL, { WV => sub { print TMP shift } });
(let ((utt (Utterance Text "Hello, World.")))
  (utt.synth utt)
  (utt.wave.resample utt 16000)
  (utt.send.wave.client utt))
EOL

if ($r) {
    print "ok 6\n";
} else {
    print "not ok 6\n";
}

close TMP;
if (system('cmp', 'hello.raw', 'hello.tmp.raw') == 0) {
    print "ok 7\n";
} else {
    print "not ok 7\n";
}

# Now test the non-blocking interface
open TMP, ">hello.tmp.raw"
    or die "can't open hello.tmp.raw: $!";
my $s = IO::Select->new($c->fh);
$c->server_eval(<<EOL);
(let ((utt (Utterance Text "Hello, World.")))
  (utt.synth utt)
  (utt.wave.resample utt 16000)
  (utt.send.wave.client utt))
EOL

$c->server_eval('(+ 2 2)');
$c->server_eval(q((mapcar (lambda (x) (/ x 5)) '(5 10 15 23))));
$c->server_eval(q/'(")\"()()())("(foo))/);

EVENT:
while (1) {
    if ($s->can_write) {
	if ($c->write_pending) {
	    $c->write_more;
	}
    }

    if ($s->can_read) {
	$c->read_more;
	if ($c->wave_pending) {
	    while (defined(my $w = $c->dequeue_wave)) {
		print TMP $w;
	    }
	}
	if ($c->lisp_pending) {
	    while (defined(my $l = $c->dequeue_lisp)) {
		$l = parse_lisp($l);
		print "ok 8\n" if $l =~ /#<Utterance/;
		print "ok 9\n" if $l == 4;
		print "ok 10\n" if ref($l) and @$l == 4;
		print "ok 11\n" if ref($l) and $l->[0] eq '")\"()()())("';
	    }
	}
	if ($c->ok_pending) {
	    while (defined(my $o = $c->dequeue_ok)) {
		# print "ok 9\n";
	    }
	    last EVENT;
	}
	if ($c->error_pending) {
	    while (defined(my $e = $c->dequeue_error)) {
		print $e, "\n";
	    }
	}
    }
}

close TMP;
if (system('cmp', 'hello.raw', 'hello.tmp.raw') == 0) {
    print "ok 12\n";
} else {
    print "not ok 12\n";
}
unlink 'hello.tmp.raw';
