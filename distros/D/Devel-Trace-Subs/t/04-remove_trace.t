#!perl
use 5.006;
use strict;
use warnings;

use File::Copy;

use Test::More tests => 149;

BEGIN {
    use_ok( 'Devel::Trace::Subs' ) || print "Bail out!\n";
}

use Devel::Trace::Subs qw(remove_trace);

my $default = 't/install_trace.pl';
my $pl = 't/ext/install_trace.pl';
my $pm = 't/ext/install_trace.pm';
my $base = 't/orig/remove_trace.pl';
my $dir = 't/ext';

{
    remove_trace(file => $default);

    open my $work_fh, '<', $default or die $!;
    open my $base_fh, '<', $base or die $!;

    my @work = <$work_fh>;
    my @base = <$base_fh>;

    close $work_fh;
    close $base_fh;

    my $i = -1;

    for my $e (@work){
        $i++;
        last if $i == 48;
        ok ($e eq $base[$i], "work line $i matches base")
    }
}
{
    remove_trace(file => $dir);

    open my $pl_fh, '<', $pl or die $!;
    open my $pm_fh, '<', $pm or die $!;
    open my $base_fh, '<', $base or die $!;

    my @pl = <$pl_fh>;
    my @pm = <$pm_fh>;
    my @base = <$base_fh>;

    close $pl_fh;
    close $pm_fh;

    my $i = -1;

    for my $e (@base){
        $i++;
        last if $i == 47;
        ok ($e eq $pl[$i], "base line $i matches *.pl");
        ok ($e eq $pm[$i], "base line $i matches *.pm");
    }
}
{
    $ENV{EVAL_TEST} = 1;
    eval { remove_trace(); };
    like ($@, qr/can't load Devel::Examine::Subs/, "remove_trace() dies if there is an eval error");

    delete $ENV{EVAL_TEST};

    my $warning;
    $SIG{__WARN__} = sub { $warning = shift; };

    eval {remove_trace(); };
    like ($warning, qr/uninitialized value/, "remove_trace() restored after eval test complete");
}
for ($default, $pl, $pm){
    eval { unlink $_; };
    ok (! $@, "$_ test file unlinked successfully");
}

eval { rmdir 't/ext' or die "can't remove t/ext test dir!: $!"; };
is ($@, '', "successfully rmdir t/ext test dir");

