#!/usr/bin/perl

# I can't make this go with Test::More because we're hooking the symbol table
use vars qw/@CALLED/;
use Devel::CallTrace;

package DB;
sub Devel::CallTrace::called {
    my @args = ($_[0], $DB::sub, $_[1]);
    push @main::CALLED, \@args;
}
package main;


sub bar {
  baz();
}
sub baz {
1;
}

my $return = bar();

package DB;

eval "sub DB::sub  {&\$DB::sub};";

package main;


unless( scalar @CALLED == 2 ) { print "not "};
print "ok 1 - There were two calls\n";
unless ($return ==1) { print "not "};
print "ok 2\n";

my $first = shift @CALLED;
unless ($first->[0] == '1') { print "not "};
print "ok 3 - Started with a depth of 1 - ".$first->[0]."\n";
unless ($first->[1] eq 'main::bar') { print "not "};
print "ok 4 - bar was called first: ".$first->[1]."\n";

my $second = shift @CALLED;
unless ($second->[0] == '2') { print "not "};
print "ok 5 - Started with a depth of 2 ".$second->[0]."\n";
unless ($second->[1] eq 'main::baz') { print "not "};
print "ok 6 - baz was called second ".$second->[1]."\n";
print "1..6\n";
1;
