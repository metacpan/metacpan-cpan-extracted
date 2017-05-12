#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Storable;
use Test::More tests => 18;

BEGIN {
    use_ok( 'Devel::Trace::Subs::Text' ) || print "Bail out!\n";
}

use Devel::Trace::Subs::Text qw(text);

my $file = 't/test.txt';
my $store = 't/orig/store.fil';
my $data = retrieve($store);

is (ref $data, 'HASH', 'the test store data is correct');

{
    text(file => $file, want => 'stack', data => $data->{stack});
    is (-f $file, 1, 'text output creates a file with file param');

    open my $fh, '<', $file or die $!;
    my @lines = <$fh>;
    close $fh;

    is (@lines, 9, "text output has correct lines for stack");

    _reset();
}
{
    text(file => $file, want => 'flow', data => $data->{flow});
    is (-f $file, 1, 'text output creates a file with file param');

    open my $fh, '<', $file or die $!;
    my @lines = <$fh>;
    close $fh;

    is (@lines, 5, "text output has correct lines for flow");

    _reset();
}
{
    text(file => $file, data => $data);
    is (-f $file, 1, 'text output creates a file with file param');

    open my $fh, '<', $file or die $!;
    my @lines = <$fh>;
    close $fh;

    is (@lines, 13, "text output has correct lines for all");

    _reset();
}
{
    my $ret = text(want => 'flow', data => $data->{flow});
    is ($ret, 1, "flow template processed ok without file");
    is (-f $file, undef, 'text output doesnt create a file with no file param');

}
{
    my $ret = text(want => 'stack', data => $data->{stack});
    is ($ret, 1, "stack template processed ok without file");
    is (-f $file, undef, 'text output doesnt create a file with no file param');
}
{
    my $ret = text(data => $data);
    is ($ret, 1, "all template processed ok without file");
    is (-f $file, undef, 'text output doesnt create a file with no file param');
}
if (-f $file){
    _reset();
}

eval { unlink $store or die $!; };
ok (! -f $store, "store unlinked successfully");

sub _reset {
    eval { unlink $file or die !$; };
    ok (! -f $file, "file unlinked successfully");
}

