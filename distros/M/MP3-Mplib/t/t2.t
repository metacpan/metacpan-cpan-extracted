use Test::More;
use File::Spec;
use Data::Dumper;

BEGIN { 
    my $ret = do File::Spec->catfile("t", "copy.pl");
    if ($ret) {
        plan tests => 5;
    } else {
        plan skip_all;
    }
}

use MP3::Mplib;

my $mp3 = MP3::Mplib->new(File::Spec->catfile("t", "test_cp.mp3"));

ok(1);
ok($mp3->del_v1tag, 
    "id3v1: delete tag");
ok(keys %{$mp3->get_v1tag} == 0,
    "id3v1: get_v1tag returns empty hash");
ok($mp3->del_v2tag,
    "id3v2: delete tag");
ok(keys %{$mp3->get_v2tag} == 0, 
    "id3v2: get_v2tag returns empty hash");

