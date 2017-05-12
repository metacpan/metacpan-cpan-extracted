#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..105\n"; $ENV{MP3TAG_SKIP_LOCAL} = 1}
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
ok($mp3, "Got tag");
ok(scalar $mp3->set_id3v2_frame("COMM", "eng", 'foo', 'Testing...'), "Changing ID3v2 ''-comment");

ok($mp3->{ID3v2}, "ID3v2 tag autocreated");
ok(($mp3->{ID3v2} and $mp3->{ID3v2}->write_tag),"Writing ID3v2");

$mp3 = MP3::Tag->new("test12.mp3");

ok($mp3->interpolate('%{COMM}'),'have COMM frame');
ok(!$mp3->interpolate('%{COMM01}'),'no COMM01 frame');
ok(!$mp3->interpolate('%{COMM02}'),'no COMM02 frame');

ok($mp3->interpolate('%{COMM(RUS,eng)[foo]}') eq 'Testing...', "Got tag via %{COMM(RUS,eng)[foo]}");
ok($mp3->interpolate('%{COMM(rus,ENG)[foo]}') eq 'Testing...', "Got tag via %{COMM(rus,ENG)[foo]}");
ok($mp3->interpolate('%{COMM(rus,EN,#0)[foo]}') eq 'Testing...', "Got tag via %{COMM(rus,EN,#0)[foo]}");
ok($mp3->interpolate('%{COMM(rus,EN,#1,)[foo]}') eq 'Testing...', "Got tag via %{COMM(rus,EN,#1,)[foo]}");
ok($mp3->interpolate('%{COMM[foo]}') eq 'Testing...', "Got tag via %{COMM[foo]}");
ok($mp3->interpolate('%{COMM(rus,EN,#1)[foo]}') eq '', "No tag via %{COMM(rus,EN,#1)[foo]}");
#my $r = $mp3->interpolate('%{!COMM(rus,EN,#1)[foo]:<%\{COMM(rus,EN,#1,)[foo]\}>}');
#warn "'$r'\n";
ok($mp3->interpolate('%{!COMM(rus,EN,#1)[foo]:<%{COMM(rus,EN,#1,)[foo]}>}')
   eq '<Testing...>', "Conditional via %{COMM(rus,EN,#1)[foo]}");

ok($mp3->interpolate('%{COMM(rus,EN,#1)[foo]||<%{COMM(rus,EN,#1,)[foo]}>}')
   eq '<Testing...>', "Alternative via %{COMM(rus,EN,#1)[foo]}");

ok($mp3->interpolate('%{COMM(rus,EN,#1,)[foo]||<%{COMM(rus,EN,#1,)[foo]}>}')
   eq 'Testing...', "Alternative via %{COMM(rus,EN,#1,)[foo]}");

ok($mp3->interpolate('%{COMM(rus,EN,#1)[foo]|COMM(rus,EN,#1,)[foo]}')
   eq 'Testing...', "Alternative via %{COMM(rus,EN,#1)[foo]}");
ok($mp3->interpolate('%{COMM(rus,EN,#1,)[foo]|COMM02}')
   eq 'Testing...', "Alternative via %{COMM(rus,EN,#1,)[foo]}");
ok($mp3->interpolate('%{COMM(rus,EN,#1)[foo]|f}')
   eq 'test12.mp3', "Alternative via %{COMM(rus,EN,#1)[foo]}");

ok($mp3->interpolate('%{COMM01||<%{COMM(rus,EN,#1,)[foo]}>}')
   eq '<Testing...>', "Alternative via %{COMM01}");

ok($mp3->set_id3v2_frame('TLEN', 123456), 'Set TLEN frame');

ok($mp3->interpolate('%{TLEN||<%{COMM(rus,EN,#1,)[foo]}>}')
   eq '123456', "Alternative via %{TLEN}");

ok($mp3->interpolate('%{COMM01|COMM(rus,EN,#1,)[foo]}')
   eq 'Testing...', "Alternative via %{COMM01}");
ok($mp3->interpolate('%{TLEN|COMM(rus,EN,#1,)[foo]}')
   eq '123456', "Alternative via %{TLEN}");
ok($mp3->interpolate('%{COMM01|f}')
   eq 'test12.mp3', "Alternative via %{TLEN}");

ok($mp3->interpolate('%{y||<%{COMM(rus,EN,#1,)[foo]}>}')
   eq '<Testing...>', "Alternative via %{y}");

print "# res=`", $mp3->interpolate('%{f||<%{COMM(rus,EN,#1,)[foo]}>}'), "'\n";
ok($mp3->interpolate('%{f||<%{COMM(rus,EN,#1,)[foo]}>}')
   eq 'test12.mp3', "Alternative via %{f}");

ok($mp3->interpolate('%{y|COMM(rus,EN,#1,)[foo]}')
   eq 'Testing...', "Alternative via %{y}");
ok($mp3->interpolate('%{f|COMM(rus,EN,#1,)[foo]}')
   eq 'test12.mp3', "Alternative via %{f}");
ok($mp3->interpolate('%{y|f}')
   eq 'test12.mp3', "Alternative via %{y}");

ok($res = $mp3->parse('%{U1}%={COMM(rus,EN,#2,)[foo]}%{U2}', '<Testing...>'), "Parsed %={COMM(rus,EN,#1,)[foo]}");
ok($res->{U1} eq '<', "Parsed before %={COMM(rus,EN,#2,)[foo]}");
ok($res->{U2} eq '>', "Parsed after %={COMM(rus,EN,#2,)[foo]}");

ok(scalar $mp3->set_id3v2_frame("COMM", "fra", 'foo', '????'), "Changing ID3v2 ''-comment");

ok($mp3->interpolate('%{COMM(rus,EN,fra)[foo]|COMM(rus,EN,#1,)[foo]}') eq '????', "Alternative via %{COMM(rus,EN,fra)[foo]}");

ok($mp3->interpolate('%{COMM01|COMM(rus,EN,#1,)[foo]}') eq '????', "Alternative via %{COMM01}");

ok($mp3->{ID3v2}->year(1993), 'Set year');
ok($mp3->interpolate('%{y|COMM(rus,EN,#1,)[foo]}') eq '1993', "Alternative via %{y}");


ok($mp3 = MP3::Tag->new("test12.mp3"), 'reget tags');
ok($mp3->config(parse_data => ['m', 'my/dir/', '%{COMM[directory]}']), 'config parse_data');
ok($mp3->title, 'Get the machinery started');
ok($mp3->interpolate('%{COMM(XXX)[directory]}') eq 'my/dir/', 'have it parsed');
ok($mp3->update_tags(), 'update tags');

ok($mp3 = MP3::Tag->new("test12.mp3"), 'reget tags');
ok($mp3->interpolate('%{COMM(XXX)[directory]}') eq 'my/dir/', 'have it stored');

{local *F; open F, '>test12.mp3' or warn; print F 'empty'}

ok($mp3 = MP3::Tag->new("test12.mp3"), 'init ourselves');

ok($mp3->config(parse_data => ['m', 'bar', '%{COMM[ini-fname]}']), 'config parse_data');
ok($mp3->title, "prepare the data");
ok($mp3->interpolate('%{COMM}'), "have COMM");
ok(!$mp3->interpolate('%{COMM01}'), "no COMM01");
ok(!$mp3->interpolate('%{COMM02}'), "no COMM02");

ok($mp3->update_tags, 'update');

ok($mp3 = MP3::Tag->new("test12.mp3"), 'reinit ourselves');

ok($mp3->interpolate('%{COMM}'), "have COMM");
ok(!$mp3->interpolate('%{COMM01}'), "no COMM01");
ok(!$mp3->interpolate('%{COMM02}'), "no COMM02");

ok($mp3->config(parse_data => ['m', 'bar', '%{COMM[ini-fname]}']), 'config parse_data');
ok($mp3->title, "prepare the data");
ok($mp3->interpolate('%{COMM}'), "have COMM");
ok(!$mp3->interpolate('%{COMM01}'), "no COMM01");
ok(!$mp3->interpolate('%{COMM02}'), "no COMM02");

{local *F; open F, '>test12.mp3' or warn; print F 'empty'}

ok($mp3 = MP3::Tag->new("test12.mp3"), 'init ourselves');

ok($mp3->config(parse_data => ['m', 'bar', '%{COMM[a]}'], ['m', 'baz', '%{COMM[b]}'], ['m', 'foo', '%{COMM[c]}']), 'config multiple parse_data to create COMMs');
ok($mp3->title, "prepare the data");
ok($mp3->interpolate('%{COMM}'), "have COMM");
ok($mp3->interpolate('%{COMM01}'), "have COMM01");
ok($mp3->interpolate('%{COMM02}'), "have COMM02");
ok(!$mp3->interpolate('%{COMM03}'), "no COMM03");

my $r = $mp3->interpolate('%{COMM[a]&COMM[aa]&COMM[b]&COMM[c]}');
print "# `$r'\n";
ok($r eq 'bar; baz; foo',
   "parse COMM[a]&COMM[aa]&COMM[b]&COMM[c]");

ok($mp3->update_tags, 'update');

ok($mp3 = MP3::Tag->new("test12.mp3"), 'reinit ourselves');

ok($mp3->config(parse_data => ['mz', '', '%{COMM[c]}'], ['mz', '', '%{COMM[b]}'], ['mz', '', '%{COMM[a]}']), 'config multiple parse_data to delete COMMs');
ok($mp3->title, "prepare the data");
ok(!$mp3->interpolate('%{COMM}'), "no COMM");
ok(!$mp3->interpolate('%{COMM01}'), "no COMM01");
ok(!$mp3->interpolate('%{COMM02}'), "no COMM02");
ok(!$mp3->interpolate('%{COMM03}'), "no COMM03");

ok($mp3 = MP3::Tag->new("test12.mp3"), 'reinit ourselves');

ok($mp3->config(parse_data => ['mz', '', '%{COMM[a]}'], ['mz', '', '%{COMM[c]}'], ['mz', '', '%{COMM[b]}']), 'config multiple parse_data to delete COMMs');
ok($mp3->title, "prepare the data");
ok(!$mp3->interpolate('%{COMM}'), "no COMM");
ok(!$mp3->interpolate('%{COMM01}'), "no COMM01");
ok(!$mp3->interpolate('%{COMM02}'), "no COMM02");
ok(!$mp3->interpolate('%{COMM03}'), "no COMM03");

ok($mp3 = MP3::Tag->new("test12.mp3"), 'reinit ourselves');

ok($mp3->config(parse_data => ['mz', '', '%{COMM[b]}'], ['mz', '', '%{COMM[c]}'], ['mz', '', '%{COMM[a]}']), 'config multiple parse_data to delete COMMs');
ok($mp3->title, "prepare the data");
ok(!$mp3->interpolate('%{COMM}'), "no COMM");
ok(!$mp3->interpolate('%{COMM01}'), "no COMM01");
ok(!$mp3->interpolate('%{COMM02}'), "no COMM02");
ok(!$mp3->interpolate('%{COMM03}'), "no COMM03");

ok($mp3 = MP3::Tag->new("test12.mp3"), 'reinit ourselves');

ok($mp3->config(parse_data => ['mz', '', '%{COMM[a]}'], ['mz', '', '%{COMM[b]}'], ['mz', '', '%{COMM[c]}']), 'config multiple parse_data to delete COMMs');
ok($mp3->title, "prepare the data");
ok(!$mp3->interpolate('%{COMM}'), "no COMM");
ok(!$mp3->interpolate('%{COMM01}'), "no COMM01");
ok(!$mp3->interpolate('%{COMM02}'), "no COMM02");
ok(!$mp3->interpolate('%{COMM03}'), "no COMM03");

ok($mp3->update_tags, 'update');

ok($mp3 = MP3::Tag->new("test12.mp3"), 'reinit ourselves');

ok(!$mp3->interpolate('%{COMM}'), "no COMM");
ok(!$mp3->interpolate('%{COMM01}'), "no COMM01");
ok(!$mp3->interpolate('%{COMM02}'), "no COMM02");
ok(!$mp3->interpolate('%{COMM03}'), "no COMM03");



#ok($mp3, "Got tag");

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
