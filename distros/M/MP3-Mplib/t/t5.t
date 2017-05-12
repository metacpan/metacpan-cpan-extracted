use Test::More;

plan tests => 21;

use MP3::Mplib qw(:all);

for (@MP3::Mplib::EXPORT_OK[0 .. 20]) {
    ok(&$_ == 0, $_), next if $_ eq 'ISO_8859_1';
    ok(&$_, $_);
}
