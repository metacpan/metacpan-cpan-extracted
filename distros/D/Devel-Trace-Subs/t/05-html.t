#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Storable;
use Test::More tests => 17;

BEGIN {
    use_ok( 'Devel::Trace::Subs::HTML' ) || print "Bail out!\n";
}

use Devel::Trace::Subs::HTML qw(html);

my $file = 't/test.html';
my $store = 't/orig/store.fil';
my $data = retrieve($store);

is (ref $data, 'HASH', 'the test store data is correct');

{
    html(file => $file, want => 'stack', data => $data->{stack});
    is (-f $file, 1, 'html output creates a file with file param');

    open my $fh, '<', $file or die $!;
    my @lines = <$fh>;
    close $fh;

    is (@lines, 29, "html output has correct lines for stack");

    _reset();
}
{
    html(file => $file, want => 'flow', data => $data->{flow});
    is (-f $file, 1, 'html output creates a file with file param');

    open my $fh, '<', $file or die $!;
    my @lines = <$fh>;
    close $fh;

    is (@lines, 20, "html output has correct lines for flow");

    _reset();
}
{
    html(file => $file, data => $data);
    is (-f $file, 1, 'html output creates a file with file param');

    open my $fh, '<', $file or die $!;
    my @lines = <$fh>;
    close $fh;

    is (@lines, 43, "html output has correct lines for all");

    _reset();
}
{
    my $stdout_var;
    open my $stdout, '>', \$stdout_var or die $!;
    my $orig_stdout = select $stdout;

    html(want => 'flow', data => $data->{flow});
    is (-f $file, undef, 'html output doesnt create a file with no file param');

    close $stdout;
    select $orig_stdout;

    my @lines = split /\n/, $stdout_var;

    is (@lines, 20, "with no file, flow has proper line count");
}
{
    my $stdout_var;
    open my $stdout, '>', \$stdout_var or die $!;
    my $orig_stdout = select $stdout;

    html(want => 'stack', data => $data->{stack});
    is (-f $file, undef, 'html output doesnt create a file with no file param');

    close $stdout;
    select $orig_stdout;

    my @lines = split /\n/, $stdout_var;

    is (@lines, 29, "with no file, stack has proper line count");
}
{
    my $stdout_var;
    open my $stdout, '>', \$stdout_var or die $!;
    my $orig_stdout = select $stdout;

    html(data => $data);
    is (-f $file, undef, 'html output doesnt create a file with no file param');

    close $stdout;
    select $orig_stdout;

    my @lines = split /\n/, $stdout_var;

    is (@lines, 43, "with no file, all has proper line count");
}

if (-f $file){
    _reset();
}

sub _reset {
    eval { unlink $file or die !$; };
    ok (! -f $file, "file unlinked successfully");
}

