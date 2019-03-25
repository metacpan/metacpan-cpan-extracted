#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..20\n"; $ENV{MP3TAG_SKIP_LOCAL} = 1}
END {print "MP3::Tag not loaded :(\n" unless $loaded;}
use MP3::Tag;
$loaded = 1;
$count = 0;
ok(1,"MP3::Tag initialized");

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

{local *F; open F, '>test12.mp3' or warn; print F 'empty'}

$mp3 = MP3::Tag->new("test12.mp3");

ok($res = $mp3->parse('%t - %l', 'abc - def - xyz'), "Parsed greedily");
ok($res->{title} eq 'abc - def', "Parsed before correct");
ok($res->{album} eq 'xyz', "Parsed after correct");

ok($mp3->config(parse_minmatch => 1), 'Set parse_minmatch');

ok($res = $mp3->parse('%t - %l', 'abc - def - xyz'), "Parsed nongreedily");
ok($res->{title} eq 'abc', "Parsed before correct");
ok($res->{album} eq 'def - xyz', "Parsed after correct");


ok($res = $mp3->parse('%{COMM(rus,EN,#1,)[foo]}', 'abc - def - xyz'), "Parsed COMM(rus,EN,#1,)[foo]");
ok($res->{'COMM(rus,EN,#1,)[foo]'} eq 'abc - def - xyz', "Parsed after correct");

{local *F; open F, '>t12.mp3' or warn; print F 'empty'}

$mp3 = MP3::Tag->new("t12.mp3");
ok($mp3, "Got tag");
ok(scalar ($mp3->config('parse_data',['bOD', "foo\n", '%B%B/%B%B.xxx']), 1),
   "config parsedata");

ok(!-e 't12t12', 'temporary directory not there');
ok(!-e 't12t12/t12t12.xxx', 'temporary output file not there');

unlink 't12t12/t12t12.xxx';
rmdir 't12t12';

ok(scalar ($mp3->title, 1), "Run the parser");
ok(-d 't12t12', 'Output directory created');
ok(-e 't12t12/t12t12.xxx', 'Output file created');
ok(4 == -s 't12t12/t12t12.xxx', 'Output file of correct size');

ok(unlink('t12t12/t12t12.xxx'), 'Remove output file');
ok(rmdir('t12t12'), 'Remove output directory');

my @failed;
#@failed ? die "Tests @failed failed.\n" : print "All tests successful.\n";

sub ok_test {
  my ($result, $test) = @_;
  printf ("Test %2d %s %s", ++$count, $test, '.' x (45-length($test)));
  (push @failed, $count), print " not" unless $result;
  print " ok\n";
}
sub ok {
  my ($result, $test) = @_;
  (push @failed, $count), print "not " unless $result;
  printf "ok %d # %s\n", ++$count, $test;
}
