use Test::More;
use File::Spec;

BEGIN { 
    my $ret = do File::Spec->catfile("t", "copy.pl");
    if ($ret) {
        plan tests => 21;
    } else {
        plan skip_all;
    }
}

use MP3::Mplib;

my $v1t = { TITLE   => 'NEWTITLE',
            ALBUM   => 'NEWALBUM',
            YEAR    => 2002,
            ARTIST  => 'NEWARTIST',
            GENRE   => 'Rock',
            COMMENT => 'NEWCOMMENT', };

my $v2t = { TIT2    => 'NEWTIT2',
            COMM    => { text  => 'NEWCOMM-text',
                         short => 'NEWCOMM-short',
                         lang  => 'ENG', },
            WXXX    => { description => 'NEWWXX-description',
                         url         => 'http://www.example.com', }, };
                         
my $mp3 = MP3::Mplib->new(File::Spec->catfile("t", "test_cp.mp3"));
ok(1, 
    "instantiating MP3::Mplib object");

ok($mp3->set_v1tag($v1t) == 1,       
    "id3v1: set tag");
ok(my $tag = $mp3->get_v1tag,
    "id3v1: get tag");
for my $k (keys %$v1t) {
    ok($tag->{$k} eq $v1t->{$k},
        "id3v1: " . lc($k));
}

ok($mp3->set_v2tag($v2t) == 1,
    "id3v2: set tag");
ok($tag = $mp3->get_v2tag,  
    "id3v2: get tag I");
ok($tag->{TIT2} eq 'NEWTIT2',
    "id3v2: TIT2");
ok($tag->{COMM}->{text}  eq 'NEWCOMM-text',  
    "id3v2: COMM->text");
ok($tag->{COMM}->{short} eq 'NEWCOMM-short', 
    "id3v2: COMM->short");
ok($tag->{COMM}->{lang}  eq 'ENG',
    "id3v2: COMM->lang");
ok($tag->{WXXX}->{description} eq 'NEWWXX-description', 
   "id3v2: WXXX->description");
ok($tag->{WXXX}->{url} eq 'http://www.example.com',
   "id3v2: WXXX->url");

ok($mp3->add_to_v2tag( { TYER => 1900 } ), 
    "id3v2: add to tag");
ok($tag = $mp3->get_v2tag, 
    "id3v2: get tag II");
ok($tag->{TYER} == 1900,
    "id3v2: TYER");
ok($tag->{TIT2} eq 'NEWTIT2', 
    "id3v2: TIT2 still there");

