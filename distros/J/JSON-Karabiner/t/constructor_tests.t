#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;
use File::HomeDir;












my $tests = 7; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

# test that it dies if file not passed
dies_ok { JSON::Karabiner->new() } 'dies if no file name passed';

throws_ok { JSON::Karabiner->new() } qr/requires a title/, 'gives correct error message';

dies_ok { JSON::Karabiner->new('file') } 'dies when no title is passed';

dies_ok { JSON::Karabiner->new('title', 'some_file') } 'dies when file does not end in json extension file name is passed';

is 'some_file.json', JSON::Karabiner->new('title', 'some_file.json')->{_file}, 'sets file';

my $home = File::HomeDir->my_home;
is "$home/.config/karabiner/assets/complex_modifications/", JSON::Karabiner->new('title', 'some_file.json')->{_mod_file_dir}, 'sets mod path';

SKIP: {
  skip 'probably a windows machine', 1 if (!-d '/tmp');
  is "/tmp", JSON::Karabiner->new('title', 'some_file.json', {mod_file_dir => '/tmp'})->{_mod_file_dir}, 'can create a custom mod dir';
}
