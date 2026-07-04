#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

eval { require Archive::Tar; 1 }
    or plan skip_all => 'Archive::Tar required for PAX fixture';
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);

# Use Archive::Tar's PAX-equivalent (long names trigger gnu/pax extensions).
{
    my $path = "$dir/pax-fixture.tar";
    my $tar = Archive::Tar->new;
    my $longname = 'sub/' . ('p' x 240) . '.txt';
    $tar->add_data($longname, 'pax content');
    $tar->add_data('short.txt', 'short content');
    $tar->write($path);

    my $r = File::Raw::Archive->open($path);
    my @names;
    while (my $e = $r->next) {
        push @names, $e->name;
    }
    $r->close;

    is(scalar @names, 2, 'PAX/long-name fixture: 2 entries');
    is($names[0], $longname, 'long name decoded fully');
    is($names[1], 'short.txt', 'short name decoded');
}

# Round-trip via our PAX writer.
{
    my $path = "$dir/our-pax.tar";
    my $w = File::Raw::Archive->create($path, format => 'pax');
    $w->add(name => 'huge_uid_owner.txt', content => 'data',
            uid => 5_000_000, gid => 6_000_000);  # > 2M, won't fit ustar
    $w->close;

    my $r = File::Raw::Archive->open($path);
    my $e = $r->next;
    is($e->name, 'huge_uid_owner.txt', 'name read back');
    is($e->uid, 5_000_000, 'large uid read back via PAX');
    is($e->gid, 6_000_000, 'large gid read back via PAX');
    $r->close;
}

done_testing;
