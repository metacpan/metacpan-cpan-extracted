#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);

# 250-char path; ustar's name field is 100, so this triggers either
# GNU @LongLink or PAX depending on `format`.
my $longname = 'sub/' . ('a' x 240) . '.txt';

# Default 'auto' should use GNU @LongLink for long-name-only.
{
    my $path = "$dir/auto.tar";
    my $w = File::Raw::Archive->create($path);
    $w->add(name => $longname, content => 'long-named content', mode => 0644);
    $w->close;
    my $r = File::Raw::Archive->open($path);
    my $e = $r->next;
    isnt($e, undef, 'got an entry');
    is($e->name, $longname, 'long name read back');
    is($e->slurp, 'long-named content', 'content matches');
    $r->close;
}

# format=pax should also work.
{
    my $path = "$dir/pax.tar";
    my $w = File::Raw::Archive->create($path, format => 'pax');
    $w->add(name => $longname, content => 'pax content', mode => 0644);
    $w->close;
    my $r = File::Raw::Archive->open($path);
    my $e = $r->next;
    is($e->name, $longname, 'pax: long name read back');
    is($e->slurp, 'pax content', 'pax: content matches');
    $r->close;
}

# format=ustar should croak on long names.
{
    my $path = "$dir/ustar.tar";
    my $w = File::Raw::Archive->create($path, format => 'ustar');
    eval { $w->add(name => $longname, content => 'x'); 1 };
    my $err = $@;
    ok($err, "format=ustar croaks on long name");
    $w->close;
}

done_testing;
