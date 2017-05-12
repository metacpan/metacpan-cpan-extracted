#!/usr/bin/perl

use warnings;
use strict;

my $PERLTESTS = 2;
my $CTESTS = 7;
my $NTESTS = $CTESTS + $PERLTESTS;

print "1..$NTESTS\n";

if (system("t/bin/corpus")) {
    nok();
} else {
    ok();
}

if (files_match('t/bin/corpus.input','t/bin/corpus.output')) {
    ok();
} else {
    nok();
}

unlink "t/bin/corpus.output"          if -f "t/bin/corpus.output";
unlink "t/bin/corpus.output.gz"       if -f "t/bin/corpus.output.gz";
unlink "t/bin/corpus.output.gz.index" if -f "t/bin/corpus.output.gz.index";


sub files_match {
    my ($a, $b) = @_;
    return 0 unless -f $a;
    return 0 unless -f $b;
    open A, $a or return 0;
    open B, $b or return 0;
    while (<A>) {
        return 0 unless $_ == <B>;
    }
    close A;
    close B;
    return 1;
}


sub nok { print "n",ok() }
sub  ok { print "ok ",++$CTESTS,"\n" }

