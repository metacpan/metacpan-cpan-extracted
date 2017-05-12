use Test::More;
use File::Spec;
use Data::Dumper;
BEGIN { 
    my $ret = do File::Spec->catfile("t", "copy.pl");
    if ($ret) {
        plan tests => 7;
    } else {
        plan skip_all;
    }
}

use MP3::Mplib;

my $mp3 = MP3::Mplib->new(File::Spec->catfile("t", "test.mp3"));

ok(1,
    "instantiating an MP3::Mplib object");
    
ok(!defined($mp3->set_v1tag({ NOT_THERE => 1 })),  
    "id3v1: setting invalid field");
    
ok(MP3::Mplib->error->{NOT_THERE} == &MP_EFNF, 
    "id3v1: MP_EFNF set");
    
ok($mp3->get_v1tag->{TITLE}, 
    "id3v1: TITLE still there");

ok($mp3 = MP3::Mplib->new("not_there.mp3"),
    "instantiate object from non-existing mp3");
    
ok(! $mp3->set_v1tag( { TITLE => 'title' } ),
    "id3v1: setting field on non-existing file");

ok(MP3::Mplib->error->{mp_file} == &MP_EERROR,
    "id3v1: MP_EERROR set");
