#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

eval { require Archive::Tar; 1 } or plan skip_all => 'Archive::Tar required';
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);

# Direction 1: Archive::Tar writes; we read.
{
    my $path = "$dir/at-out.tar";
    my $tar = Archive::Tar->new;
    $tar->add_data('one.txt',   'one content');
    $tar->add_data('two.txt',   'two content');
    $tar->add_data('three.txt', 'three' x 1000);
    $tar->write($path);

    my $r = File::Raw::Archive->open($path);
    my @names;
    while (my $e = $r->next) {
        push @names, $e->name;
        if ($e->name eq 'three.txt') {
            is($e->size, 5000, 'three.txt size matches');
            is($e->slurp, 'three' x 1000, 'three.txt content matches');
        }
    }
    $r->close;
    is_deeply(\@names, ['one.txt', 'two.txt', 'three.txt'],
        'Archive::Tar output reads via plugin');
}

# Direction 2: We write; Archive::Tar reads.
{
    my $path = "$dir/our-out.tar";
    my $w = File::Raw::Archive->create($path);
    $w->add(name => 'alpha', content => 'A' x 100);
    $w->add(name => 'beta',  content => 'B' x 200);
    $w->add(name => 'gamma', content => 'G' x 300);
    $w->close;

    my $tar = Archive::Tar->new($path);
    my @names = $tar->list_files;
    is_deeply(\@names, ['alpha', 'beta', 'gamma'],
        'our output reads via Archive::Tar');
    is($tar->get_content('alpha'), 'A' x 100, 'alpha content via Archive::Tar');
    is($tar->get_content('gamma'), 'G' x 300, 'gamma content via Archive::Tar');
}

done_testing;
