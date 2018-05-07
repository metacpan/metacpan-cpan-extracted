#!/usr/bin/perl

use strict;

BEGIN
{
    $|  = 1;
    $^W = 1;
}

use Test::More;
use File::HomeDir;

if ($File::HomeDir::IMPLEMENTED_BY->isa('File::HomeDir::Darwin::Carbon'))
{
    plan(tests => 5);
}
else
{
    plan(skip_all => "Not running on 32-bit Darwin");
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
    $@ and skip("Unable to execute File::HomeDir->users_home('$user')");
    ok(!defined $home, "Home of non-existent user should be undef");
}

# CPAN Testers results suggest we can't reasonably assume these directories
# will always exist
SKIP:
{
    my $dir = File::HomeDir->my_music;
    unless (defined $dir)
    {
        skip("Testing user does not have a Music directory", 1);
    }
    like($dir, qr/Music/);
}
SKIP:
{
    my $dir = File::HomeDir->my_videos;
    unless (defined $dir)
    {
        skip("Testing user does not have a Movies directory", 1);
    }
    like($dir, qr/Movies/);
}
SKIP:
{
    my $dir = File::HomeDir->my_pictures;
    unless (defined $dir)
    {
        skip("Testing user does not have a Pictures directory", 1);
    }
    like($dir, qr/Pictures/);
}

SKIP:
{
    my $data = File::HomeDir->my_data;
    skip("No application support directory", 1) unless defined $data;
    like($data, qr/Application Support/);
}
