use Test::More;
use File::Spec;

BEGIN {
    my $ret = do File::Spec->catfile("t", "copy.pl");
    if ($ret) {
        plan tests => 22;
    } else {
        plan skip_all;
    }
}
    
use lib qw(../blib/arch ../blib/lib);
use MP3::Mplib;
ok(1);

my $mp3 = MP3::Mplib->new(File::Spec->catfile("t", "test.mp3"));
my $tag = $mp3->get_v1tag;

# test id3v1 header
ok($tag->{TITLE}   eq 'test title',
    "id3v1: title");
ok($tag->{ARTIST}  eq 'test artist',
    "id3v1: artist");
ok($tag->{ALBUM}   eq 'test album', 
    "id3v1: album");
ok($tag->{YEAR}    ==  2525,
    "id3v1: year");
ok($tag->{GENRE}   eq 'Vocal',
    "id3v1: genre");
ok($tag->{COMMENT} eq 'from Games::AIBots', 
    "id3v1: comment");

# test id3v2 header
$tag = $mp3->get_v2tag;
ok($tag->{TRCK} == 0, 
    "id3v2: TRCK");
ok($tag->{TCOP} eq 'Copyright 2001, 2002 by Autrijus Tang <autrijus@autrijus.org>', 
    "id3v2: TCOP");
ok($tag->{TYER} == 2525, 
    "id3v2: TYER");
ok($tag->{TPE1} eq "test artist", 
    "id3v2: TPE1");
ok($tag->{WXXX}->{url} eq "http://search.cpan.org/author/AUTRIJUS/Games-AIBots-0.03/lib/Games/AIBot.pm", 
    "id3v2: WXXX->url");
ok($tag->{TALB} eq "test album", 
    "id3v2: TALB");
ok($tag->{TENC} eq "winlame", 
    "id3v2: TENC");

ok(defined $tag->{COMM},
    "id3v2: COMM defined");
ok($tag->{COMM}->{text}  eq "from Games::AIBots",   
    "id3v2: COMM->text");
ok($tag->{COMM}->{lang}  eq "", 
    "id3v2: COMM->lang");
ok($tag->{COMM}->{short} eq "", 
    "id3v2: COMM->short");

ok($tag->{TOPE} eq "likewise",    
    "id3v2: TOPE");
ok($tag->{TCOM} eq "no idea",     
    "id3v2: TCOM");
ok($tag->{TCON} eq "(28)Vocal",   
    "id3v2: TCON");
ok($tag->{TIT2} eq "test title",  
    "id3v2: TIT2");

