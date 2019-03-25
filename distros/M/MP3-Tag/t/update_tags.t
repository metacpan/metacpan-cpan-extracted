#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; $ENV{MP3TAG_SKIP_LOCAL} = 1}
END {print "MP3::Tag not loaded :(\n" unless $loaded;}
use MP3::Tag;
$loaded = 1;
$count = 0;
ok(1,"MP3::Tag initialized");

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

{local *F; open F, '>test14.MP3' or warn; print F 'empty'}

$mp3 = MP3::Tag->new("test14.MP3");
ok($mp3, "Got tag");
ok($mp3->update_tags({'title' => 'foobar'}), 'update_tags() called');
ok($mp3 = MP3::Tag->new("test14.MP3"), "Regot tag");
my $t = $mp3->title;
print "# t=<$t>\n";
ok($mp3->title eq 'foobar', 'Tag correctly written');

{local *F; open F, '>test15.mp7' or warn; print F 'empty'}
$mp3 = MP3::Tag->new("test15.mp7");
ok($mp3, "Got tag from empty .mp7");
ok(! eval {$mp3->update_tags({'title' => 'foobar'})}, 'update_tags() failing');
ok(scalar($@ =~ /`is_writable'/), 'is_writable triggering failure');

my @failed;

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
