use strict;
use warnings;

use Test::More tests => 2;
use File::XDG;
use File::Temp;
use File::Path qw(make_path);

local $ENV{HOME} = File::Temp->newdir();
local $ENV{XDG_DATA_DIRS} = File::Temp->newdir();
local $ENV{XDG_CONFIG_DIRS} = File::Temp->newdir();

subtest 'data_home' => sub {
    plan tests => 6;
    test_lookup('data_home', 'data_dirs', 'lookup_data_file');
};

subtest 'config_home' => sub {
    plan tests => 6;
    test_lookup('config_home', 'config_dirs', 'lookup_config_file');
};

sub test_lookup {
    my ($home_m, $dirs_m, $lookup_m) = @_;

    my $name = 'test';
    my $xdg = File::XDG->new(name => $name);

    my @subpath = ('subdir', 'filename');
    my $home = ($xdg->$home_m =~ /(.*)$name/)[0];
    my $dir  = $xdg->$dirs_m;

    make_file($home, @subpath);
    make_file($dir, @subpath);

    my $home_file = File::Spec->join($home, @subpath);
    my $dir_file = File::Spec->join($dir, @subpath);

    ok(-f $home_file, "created file in $home_m");
    ok(-f $dir_file, "created file in $dirs_m");

    isnt($home_file, $dir_file, "created distinct files in $home_m and $dirs_m");
    is($xdg->$lookup_m(@subpath), $home_file, "lookup found file in $home_m");
    unlink($home_file);
    is($xdg->$lookup_m(@subpath), $dir_file, "after removing file in $home_m, lookup found file in $dirs_m");
    unlink($dir_file);
    is($xdg->$lookup_m(@subpath), undef, "after removing file in $dirs_m, lookup did not find file");
}

sub make_file {
    my (@path) = @_;

    my $filename = pop @path;
    my $directory = File::Spec->join(@path);
    my $path = File::Spec->join($directory, $filename);

    make_path($directory);

    my $file = IO::File->new($path, 'w');
    $file->close;
}
