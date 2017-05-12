#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..139\n"; $ENV{MP3TAG_SKIP_LOCAL} = 1}
END {print "MP3::Tag not loaded :(\n" unless $loaded;}
use MP3::Tag;
$loaded = 1;
$count = 0;
ok(1,"MP3::Tag initialized");

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

#test - getting the tags
$mp3 = MP3::Tag->new("test.mp3");
$mp3->get_tags;

$v1 = $mp3->{ID3v1};
ok($v1,"Detecting ID3v1");

$v2 = $mp3->{ID3v2};
ok($v2,"Detecting ID3v2");

#test - reading ID3v1
ok(($v1 && ($v1->song eq "Song") && ($v1->track == 10)),"Reading ID3v1");

ok(($mp3->title eq "Only a test with a ID3v1 and ID3v2 tag") && ($mp3->track == 10),"Reading ID3v1/2 via Tag");
ok($mp3->comment eq "test", "Reading ID3v1 comment via Tag");
ok($mp3->year eq 2000, "Reading ID3v1 year via Tag");
ok($mp3->genre eq 'Ska', "Reading ID3v1 genre via Tag");

#test - reading ID3v2
ok($v2 && $v2->get_frame("COMM")->{Description} eq "Test!","Reading ID3v2");

{local *F; open F, '>test2.mp3' or warn; print F 'empty'}

$mp3 = MP3::Tag->new("test2.mp3");
$mp3->new_tag("ID3v1");
$v1 = $mp3->{ID3v1};
$mp3->new_tag("ID3v2");
$v2 = $mp3->{ID3v2};

#test - creating/changing/writing ID3v1
ok($v1 && join("",$v1->all("New","a","a",2000,"c",10,"Ska")), "Creating new ID3v1");
ok($v1 && $v1->write_tag,"Writing ID3v1");
ok($v1 && $v1->artist("Artist"), "Changing ID3v1");
ok($v1 && $v1->write_tag,"Writing ID3v1");

#test - creating/changing/writing ID3v2
ok($v2 && $v2->add_frame("TLAN","ENG"),"Creating new ID3v2");
ok($v2 && $v2->write_tag,"Writing ID3v2");
ok($v2 && $v2->add_frame("TLAN","GER"),"Changing ID3v2");
ok($v2 && $v2->year('1848-9,1864-1872'),"Writing ID3v2 complex timestamp");
ok($v2 && $v2->write_tag,"Writing ID3v2");

$mp3=$v1=$v2=undef;			# Close the file...

ok(((stat("test2.mp3"))[7] % 512) == 0," ID3v2 rounding size");

$mp3 = MP3::Tag->new("test2.mp3");
$mp3->get_tags;
$v1 = $mp3->{ID3v1};
$v2 = $mp3->{ID3v2};

#test 10 - reading new ID3v1
ok($v1 && $v1->song eq "New" && $v1->artist eq "Artist","Checking new ID3v1");
ok($v1 && $v1->title eq "New","Checking new ID3v1");
ok($v1 && $mp3->autoinfo->{title} eq "New","Checking new ID3v1");



#test 11 - reading new ID3v2
ok($v2 && $v2->get_frame("TLAN") eq "ENG" && $v2->get_frame("TLAN01") eq "GER","Checking new ID3v2");

#test 16 - reading new ID3v2
ok($v2 && (@f = $v2->get_frame("TLAN"))  && @f == 3 && "@f[0,2]" eq "ENG GER", "Checking multi-frame ID3v2");
ok($v2 && (@f = $v2->get_frames("TLAN")) && @f == 3 && "@f[1,2]" eq "ENG GER", "Checking multi-frame ID3v2");

#test 18 - comment
ok($v2 && !defined $v2->comment(), "Checking no comment");

# year
ok($v2 && (@f = $v2->get_frames("TDRC", 'intact')) && @f == 2 && $f[-1] eq "1848-09\0001864/1872", "Checking timestamp(s) in ID3v2");
ok($v2 && ($y = $v2->year) && $y eq "1848-09,1864--1872", "Checking ID3v2 year");

ok($v2 && $v2->add_frame("COMM", "ENG", '', 'Testing...'), "Changing ID3v2 ''-comment");
ok($v2 && $v2->write_tag,"Writing ID3v2");

$mp3 = MP3::Tag->new("test2.mp3");
$mp3->get_tags;
$v2 = $mp3->{ID3v2};
ok($v2 && $v2->comment() eq 'Testing...', "Checking any-language comment");

ok($v2 && $v2->comment('Another test...', '', "ENG"), "Setting ID3v2-comment");
ok($v2 && $v2->write_tag,"Writing ID3v2");

$mp3 = MP3::Tag->new("test2.mp3");
$mp3->get_tags;
$v1 = $mp3->{ID3v1};
$v2 = $mp3->{ID3v2};

ok($v2 && $v2->comment() eq 'Another test...', "Checking any-language comment");
ok($v2 && !defined $v2->_comment('GER'), "Checking no GER comment");
ok($v2 && $v2->_comment('ENG') eq 'Another test...', "Checking ENG comment");
ok($v2 && $mp3->comment() eq 'Another test...', "Checking ID3 comment");

my $s = $mp3->interpolate('%%02t_Title: `%012.12t\'; %{TLAN} %{TLAN01: have %{TLAN01}} %{!TLAN02:, do not have TLAN02}');	#'
print "# `$s'\n";
#	        %02t_Title: `000000000New'; ENG  have ENG , do not have TLAN02
ok($s && $s eq "%02t_Title: `000000000New'; ENG  have GER , do not have TLAN02", "Checking ID3 interpolation");
$s = $mp3->interpolate('%%02{t(ID3v1)}_Title: `%012.12{t(ID3v1)}\'; %{TLAN} %{TLAN01: have %{TLAN01}} %{!TLAN02:, do not have TLAN02}');	#'
print "# `$s'\n";
ok($s && $s eq "%02{t(ID3v1)}_Title: `000000000New'; ENG  have GER , do not have TLAN02", "Checking handler ID3v1 interpolation");
$s = $mp3->interpolate('%%02{t(ID3v2)}_Title: `%012.12{t(ID3v2)}\'; %{TLAN} %{TLAN01: have %{TLAN01}} %{!TLAN02:, do not have TLAN02}');	#'
print "# `$s'\n";
ok($s && $s eq "%02{t(ID3v2)}_Title: `000000000000'; ENG  have GER , do not have TLAN02", "Checking handler ID3v2 interpolation");
#back to original tag
open (FH, ">test2.mp3") or warn;
binmode FH;
print FH "empty";
close FH or warn;

# Check the .inf parsing
open FH, ">test2.inf" or warn;
print FH <<EOP;
#created by test script
#
CDINDEX_DISCID=	'nFif1ufKKowDai0uJk8E7b_B1cw-'
CDDB_DISCID=	0xe60ca011
MCN=		
ISRC=		               
#
Albumperformer=	'Some Choir'
Performer=	'Bach (2110)'
Albumtitle=	'Liturgy of St. John; Op 31'
Tracktitle=	'It Is Truly Meet'
Tracknumber=	11
Trackstart=	174717
# track length in sectors (1/75 seconds each), rest samples
Tracklength=	10533, 0
Pre-emphasis=	no
Channels=	2
Copy_permitted=	once (copyright protected)
Endianess=	little
# index list
Index=		0
Year=		1988
Trackcomment=	'Chiribim conducts Some Choir; recorded in Mariann'
EOP
close FH or warn;

$mp3 = MP3::Tag->new("./test2.mp3");
$mp3->get_tags;
my $inf = $mp3->{Inf};
#my @a = %$mp3;
#warn "@a";

ok($inf, ".inf file parsed");
ok($inf && $mp3->autoinfo->{title} eq 'It Is Truly Meet', "Checking .inf title");
ok($inf && $mp3->autoinfo->{artist} eq 'Bach (2110)', "Checking .inf artist");
ok($inf && $mp3->autoinfo->{track} eq 11, "Checking .inf track");
ok($inf && $mp3->autoinfo->{album} eq 'Liturgy of St. John; Op 31', "Checking .inf album");
ok($inf && $mp3->autoinfo->{year} eq 1988, "Checking .inf year");
ok($inf && $mp3->autoinfo->{comment} eq 'Chiribim conducts Some Choir; recorded in Mariann', "Checking .inf comment");

ok($inf && $mp3->autoinfo('from')->{comment}[0] eq 'Chiribim conducts Some Choir; recorded in Mariann', "Checking .inf comment+source");
ok($inf && $mp3->autoinfo('from')->{comment}[1] eq 'Inf', "Checking .inf comment source");

use File::Spec;
require File::Basename;
my $i =  $mp3->interpolate('file=%(_)-12f, File=%F, %%comment="%c", dir="%{d0}"');
# Skip a good test on 5.005
my $checkname = (File::Spec->can('rel2abs') ? 'test2.mp3' : './test2.mp3');
my $ii = 'file=test2.mp3___, File=' . MP3::Tag->rel2abs($checkname)
	. ', %comment="Chiribim conducts Some Choir; recorded in Mariann"'
	. ', dir="' . scalar(File::Basename::fileparse(File::Basename::dirname(MP3::Tag->rel2abs('test2.mp3')),"")) . '"';
#warn "$i\n$ii\n";
ok($inf && $i eq $ii, "Checking interpolation: `$i' eq `$ii'");

ok($mp3->filename_nodir eq "test2.mp3", "Checking filename method:");
ok($mp3 && $mp3->interpolate("%A.%e") eq $mp3->interpolate("%F"), "interpolate %A");

# Check CDDB_File...
ok(MP3::Tag->config('cddb_files', qw(cddb.tm1 cddb.tm cddb.tm2)), "Configuring list of cddb_files");

open NH, '>audio07.mp3' or warn;
close NH;
$mp3 = MP3::Tag->new("./audio07.mp3");
ok($mp3 && $mp3->title eq 'Makrokosmos III - I. Nocturnal Sounds (The Awakening)', "Title via CDDB_File");
ok($mp3 && $mp3->artist eq 'Crumb Piece', "Artist via CDDB_File");
ok($mp3 && $mp3->album eq 'Ancient Voices', "Album via CDDB_File");
ok($mp3 && $mp3->year eq '1234', "Year via CDDB_File");
ok($mp3 && $mp3->comment eq 'comment7; Fake entry', "Comment via CDDB_File");
# print STDERR "# Genre=", $mp3->genre, "\n";
ok($mp3 && $mp3->genre eq 'Vocal', "Genre via CDDB_File");
ok($mp3 && $mp3->track eq '7', "Track no with CDDB_File");
ok($mp3 && (not defined $mp3->artist_collection), "artist_collection");

open NH, '>audio08.mp3' or warn;
close NH;
$mp3 = MP3::Tag->new("./audio08.mp3");
ok($mp3 && $mp3->year eq '2001-10-23--30,2002-02-28', "Year via CDDB_File");
ok($mp3 && $mp3->comment_collection eq 'Fake entry', "comment_collection");
# print STDERR "# cT=", $mp3->comment_track, "\n";
ok($mp3 && $mp3->comment_track eq 'comment8; Recorded on 2001-10-23--30,2002-02-28', "comment_track");
ok($mp3 && $mp3->artist_collection eq 'Crumb Piece', "artist_collection");
ok($mp3 && $mp3->artist eq 'Piece of Crumb', "artist");
ok($mp3 && $mp3->interpolate('%{aC}') eq 'Crumb Piece', "artist_collection via %{aC}");

ok(MP3::Tag->config('comment_remove_date', 1), "Configuring comment_remove_date");
$mp3 = MP3::Tag->new("./audio08.mp3");
# print STDERR "# cT=", $mp3->comment_track, "\n";
ok($mp3 && $mp3->comment_track eq 'comment8', "comment_track with removal");

ok(MP3::Tag->config('cddb_files', qw(cddb.tmp1 cddb.tmp cddb.tmp2)), "Configuring2 list of cddb_files");

open NH, '>audio07.mp3' or warn;
close NH;
$mp3 = MP3::Tag->new("./audio07.mp3");
ok($mp3 && $mp3->title eq 'Makrokosmos III - I. Nocturnal Sounds (The Awakening)', "Title via CDDB_File");
ok($mp3 && $mp3->artist eq 'Crumb Piece', "Artist via CDDB_File");
ok($mp3 && $mp3->album eq 'Ancient Voices', "Album via CDDB_File");
ok($mp3 && $mp3->year eq '1234', "Year via CDDB_File");
ok($mp3 && $mp3->comment eq 'comment7; Fake entry', "Comment via CDDB_File");
ok($mp3 && $mp3->genre eq 'A special genre', "Genre via CDDB_File");
ok($mp3 && $mp3->track eq '7', "Track no with CDDB_File");


open NH, '>audio_07.mp3' or warn;
close NH;
$mp3 = MP3::Tag->new("./audio_07.mp3");
$mp3->config(parse_data => ['m', 'no comment', '%c']);
ok($mp3 && $mp3->title eq 'Makrokosmos III - I. Nocturnal Sounds (The Awakening)', "Title via CDDB_File with force");
ok($mp3 && $mp3->comment eq 'no comment', "Forced comment");

$mp3 = MP3::Tag->new("./audio_07.mp3");
$mp3->config(parse_data => ['im', '<%c>', '%t']);
ok($mp3 && $mp3->artist eq 'Crumb Piece', "Artist via CDDB_File with force/interpolate");
ok($mp3 && $mp3->title eq '<comment7; Fake entry>', "Force/interpolated title");

$mp3 = MP3::Tag->new("./audio_07.mp3");
$mp3->config(parse_data => ['im', '[%t]' => '%t'], ['im', '<%t>' => '%c']);
ok($mp3 && $mp3->comment eq '<[Makrokosmos III - I. Nocturnal Sounds (The Awakening)]>', "Force/interpolated recursive comment");
ok($mp3 && $mp3->title eq '[Makrokosmos III - I. Nocturnal Sounds (The Awakening)]', "Force/interpolated recursive title");

$mp3 = MP3::Tag->new("audio_07.mp3");
$mp3->config(parse_data => ['im', '%f', '%c_%n.mp3'], ['mz', '' => '%g']);
ok($mp3 && $mp3->comment eq 'audio', "comment via parse");
ok($mp3 && $mp3->track eq '7', "track via parse");
ok($mp3 && $mp3->comment eq 'audio', "comment via cached parse");
ok($mp3 && $mp3->title eq 'Makrokosmos III - I. Nocturnal Sounds (The Awakening)', "title with parse");

$s = $mp3->interpolate("%03n_%{!g: Have only comment=<%c>}<%g>%c");
ok($mp3 && $s eq '007_ Have only comment=<audio><>audio', "conditional interpolation");

$mp3 = MP3::Tag->new("./audio_07.mp3");
$mp3->config(parse_data => ['iRm', 'my/dir/%f', '/%c/%c%E']);
ok($mp3 && $mp3->comment eq 'dir; audio_07', "multi-%c via parse/interpolate");

$mp3 = MP3::Tag->new("./audio_07.mp3");
$mp3->config(parse_data => ['iRm', 'my/dir/%f', '/%c/%c%=E']);
ok($mp3 && $mp3->comment eq 'dir; audio_07', "multi-%c and %=E via parse/interpolate");

$mp3 = MP3::Tag->new("./audio_07.mp3");
$mp3->config(parse_data => ['im', 'my/dir/%f', '%t/%c/%c.%e']);
$i = $mp3->comment;
#warn "<$i>\n";
ok($mp3 && $i eq 'dir; audio_07', "multi-%c and %e via parse/interpolate");

$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre_set('foobar / baz'), "set genre to something complicated to trigger v2");
ok($mp3 && $mp3->update_tags({genre => '(18)'}), "set genre to (18)");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq 'Techno', "get genre");
ok($mp3 && $mp3->{ID3v1}->genre() eq 'Techno', "get v1 genre");
ok($mp3 && $mp3->{ID3v2}, "v2 was set");

$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->update_tags({genre => 18}), "set genre to 18");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq 'Techno', "get genre");
ok($mp3 && $mp3->{ID3v1}->genre() eq 'Techno', "get v1 genre");

$mp3 = MP3::Tag->new("./audio_07.mp3");	# max=147 SynthPop
ok($mp3 && $mp3->update_tags({genre => '(147)'}), "set genre to (147)");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq 'SynthPop', "get genre");
ok($mp3 && $mp3->{ID3v1}->genre() eq 'SynthPop', "get v1 genre");

$mp3 = MP3::Tag->new("./audio_07.mp3");	# max=147 SynthPop
ok($mp3 && $mp3->update_tags({genre => '147'}), "set genre to 147");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq 'SynthPop', "get genre");
ok($mp3 && $mp3->{ID3v1}->genre() eq 'SynthPop', "get v1 genre");

$mp3 = MP3::Tag->new("./audio_07.mp3");	# max=149 SynthPop
ok($mp3 && $mp3->update_tags({genre => '(149)'}), "set genre to (149)");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq '(149)', "get genre");
my $g = $mp3->{ID3v1}->genre();
print "# g=<$g>\n";
ok($mp3 && $g eq '', "get v1 genre");

$mp3 = MP3::Tag->new("./audio_07.mp3");	# max=149 SynthPop
ok($mp3 && $mp3->update_tags({genre => '149'}), "set genre to 149");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq '(149)', "get genre");
$g = $mp3->{ID3v1}->genre();
print "# g=<$g>\n";
ok($mp3 && $g eq '', "get v1 genre");

open NH, '>audio_07.mp3' or warn;
close NH;

$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3->interpolate("%{ID3v1:have v1}/%{!ID3v1:no v1}; %{ID3v2:have v2}/%{!ID3v2:no v2}") eq '/no v1; /no v2', 'conditional interpolate');
ok($mp3 && $mp3->update_tags({genre => '(18)'}), "set genre to (18)");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq 'Techno', "get genre");
ok($mp3 && $mp3->{ID3v1}->genre() eq 'Techno', "get v1 genre");
ok($mp3->interpolate("%{ID3v1:have v1}/%{!ID3v1:no v1}; %{ID3v2:have v2}/%{!ID3v2:no v2}") eq 'have v1/; /no v2', 'conditional interpolate');

$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->update_tags({genre => 18}), "set genre to 18");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq 'Techno', "get genre");
ok($mp3 && $mp3->{ID3v1}->genre() eq 'Techno', "get v1 genre");

$mp3 = MP3::Tag->new("./audio_07.mp3");	# max=147 SynthPop
ok($mp3 && $mp3->update_tags({genre => '(147)'}), "set genre to (147)");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq 'SynthPop', "get genre");
ok($mp3 && $mp3->{ID3v1}->genre() eq 'SynthPop', "get v1 genre");

$mp3 = MP3::Tag->new("./audio_07.mp3");	# max=147 SynthPop
ok($mp3 && $mp3->update_tags({genre => '147'}), "set genre to 147");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq 'SynthPop', "get genre");
ok($mp3 && $mp3->{ID3v1}->genre() eq 'SynthPop', "get v1 genre");
ok($mp3 && !$mp3->{ID3v2}, "no v2 was set");

$mp3 = MP3::Tag->new("./audio_07.mp3");	# max=147 SynthPop
ok($mp3 && $mp3->update_tags({genre => '(149)'}), "set genre to (149)");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq '(149)', "get genre");
$g = $mp3->{ID3v1}->genre();
print "# g=<$g>\n";
ok($mp3 && $g eq '', "get v1 genre");

$mp3 = MP3::Tag->new("./audio_07.mp3");	# max=147 SynthPop
ok($mp3 && $mp3->update_tags({genre => '149', track => '2/4'}), "set genre to 149, track");
$mp3 = MP3::Tag->new("./audio_07.mp3");
ok($mp3 && $mp3->genre() eq '(149)', "get genre");
$g = $mp3->{ID3v1}->genre();
print "# g=<$g>\n";
ok($mp3 && $g eq '', "get v1 genre");
ok($mp3 && $mp3->track() eq '2/4', "get track");
ok($mp3 && $mp3->{ID3v1}->track() eq '2', "get v1 track");
ok(0 == ((-s "./audio_07.mp3") % 512), "padding to sector");
ok($mp3->interpolate("%{ID3v1:have v1}/%{!ID3v1:no v1}; %{ID3v2:have v2}/%{!ID3v2:no v2}") eq 'have v1/; have v2/', 'conditional interpolate');

open NH, '>audio_07.mp3' or warn;
close NH;
$mp3 = MP3::Tag->new("./audio_07.mp3");	# max=147 SynthPop
ok($mp3 && ($mp3->genre_set(113) or 1), 'set genre');
ok($mp3 && $mp3->{ID3v1} && $mp3->{ID3v1}->genre() eq 'Tango', 'get v1 genre');
ok($mp3 && $mp3->genre() eq 'Tango', 'get genre');

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
