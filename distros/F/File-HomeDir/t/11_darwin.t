#!/usr/bin/perl

use strict;

BEGIN
{
    $|  = 1;
    $^W = 1;
}

use Test::More;
use File::HomeDir;

if ($File::HomeDir::IMPLEMENTED_BY->isa('File::HomeDir::Darwin'))
{
    # Force pure perl since it should work everywhere
    $File::HomeDir::IMPLEMENTED_BY = 'File::HomeDir::Darwin';
    plan(tests => 9);
}
else
{
    plan(skip_all => "Not running on Darwin");
    exit(0);
}

SKIP:
{
    my $user;
    foreach (0 .. 9)
    {
        my $temp = sprintf 'fubar%04d', rand(10000);
        getpwnam $temp and next;
        $user = $temp;
        last;
    }
    $user or skip("Unable to find non-existent user", 1);
    $@ = undef;
    my $home = eval { File::HomeDir->users_home($user) };
    $@ and skip("Unable to execute File::HomeDir->users_home('$user')", 1);
    ok(!defined $home, "Home of non-existent user should be undef");
}

SCOPE:
{
    # Reality Check
    my $music    = File::HomeDir->my_music;
    my $videos   = File::HomeDir->my_videos;
    my $pictures = File::HomeDir->my_pictures;
    my $data     = File::HomeDir->my_data;
  SKIP:
    {
        skip("No music directory", 1) unless defined $music;
        like($music, qr/Music/);
    }
  SKIP:
    {
        skip("Have music directory", 1) if defined $music;
        is_deeply([File::HomeDir->my_music], [undef], "Returns undef in list context",);
    }
  SKIP:
    {
        skip("No videos directory", 1) unless defined $videos;
        like($videos, qr/Movies/);
    }
  SKIP:
    {
        skip("Have videos directory", 1) if defined $videos;
        is_deeply([File::HomeDir->my_videos], [undef], "Returns undef in list context",);
    }
  SKIP:
    {
        skip("No pictures directory", 1) unless defined $pictures;
        like($pictures, qr/Pictures/);
    }
  SKIP:
    {
        skip("Have pictures directory", 1) if defined $pictures;
        is_deeply([File::HomeDir->my_pictures], [undef], "Returns undef in list context",);
    }
  SKIP:
    {
        skip("No application support directory", 1) unless defined $data;
        like($data, qr/Application Support/);
    }
  SKIP:
    {
        skip("Have data directory", 1) if defined $data;
        is_deeply([File::HomeDir->my_data], [undef], "Returns undef in list context",);
    }
}
