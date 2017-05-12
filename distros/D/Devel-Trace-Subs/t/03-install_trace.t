#!perl
use 5.006;
use strict;
use warnings;

use File::Copy;

use Test::More tests => 224;

BEGIN {
    use_ok( 'Devel::Trace::Subs' ) || print "Bail out!\n";
}

use Devel::Trace::Subs qw(install_trace);

eval { mkdir 't/ext' or die "can't create t/ext test dir!: $!"; };
is ($@, '', "successfully created t/ext test dir");
$@ = '';
{
    my $orig = 't/install_trace_orig.pl';
    my $work = 't/install_trace.pl';
    my $base = 't/orig/install_trace.pl';

    copy $orig, $work;

    install_trace(file => $work);

    open my $work_fh, '<', $work or die $!;
    open my $base_fh, '<', $base or die $!;

    my @work = <$work_fh>;
    my @base = <$base_fh>;

    close $work_fh;
    close $base_fh;

    my $i = -1;

    for my $e (@work){
        $i++;
        last if $i == 55;
        ok ($e eq $base[$i], "work line $i matches base")
    }
}
{
    my $orig = 't/install_trace_orig.pl';
    my $in_pl = 't/ext/install_trace.pl';
    my $in_pm = 't/ext/install_trace.pm';
    my $base = 't/orig/install_trace.pl';
    my $dir = 't/ext';

    copy $orig, $in_pl;
    copy $orig, $in_pm;

    install_trace(file => $dir, extensions => [qw(*.pm)]);

    open my $in_pl_fh, '<', $in_pl or die $!;
    open my $in_pm_fh, '<', $in_pm or die $!;
    open my $base_fh, '<', $base or die $!;

    my @in_pl = <$in_pl_fh>;
    my @in_pm = <$in_pm_fh>;
    my @base = <$base_fh>;

    close $in_pl_fh;
    close $in_pm_fh;
    close $base_fh;

    my $i = -1;
    for my $e (@base){
        $i++;
        last if $i == 54;
        ok ($e eq $in_pm[$i], "work line $i matches base")
    }

    ok (@base == @in_pm || @base == @in_pm + 1, "with *.pm extension, file is correct");
    ok (@base - @in_pl == 6 || @base - @in_pl == 7, "with *.pm extension, *.pl is untouched");
}
{
    my $orig = 't/install_trace_orig.pl';
    my $in_pl = 't/ext/install_trace.pl';
    my $in_pm = 't/ext/install_trace.pm';
    my $base = 't/orig/install_trace.pl';
    my $dir = 't/ext';

    copy $orig, $in_pl;
    copy $orig, $in_pm;

    install_trace(file => $dir, extensions => [qw(*.pm *.pl)]);

    open my $in_pl_fh, '<', $in_pl or die $!;
    open my $in_pm_fh, '<', $in_pm or die $!;
    open my $base_fh, '<', $base or die $!;

    my @in_pl = <$in_pl_fh>;
    my @in_pm = <$in_pm_fh>;
    my @base = <$base_fh>;

    close $in_pl_fh;
    close $in_pm_fh;
    close $base_fh;

    my $i = -1;
    for my $e (@base){
        $i++;
        last if $i == 54;
        ok ($e eq $in_pm[$i], "work line $i matches base in pm with exts *.pm & *.pl");
        ok ($e eq $in_pl[$i], "work line $i matches base in pl with exts *.pm & *.pl");
    }

    ok (@base == @in_pm || @base == @in_pm + 1, "with *.pm and *.pl extension, files are correct");
}

{
    $ENV{EVAL_TEST} = 1;
    eval { install_trace(); };
    like ($@, qr/can't load Devel::Examine::Subs/, "install_trace() dies if there is an eval error");

    delete $ENV{EVAL_TEST};

    my $warning;
    $SIG{__WARN__} = sub { $warning = shift; };

    eval {install_trace(); };
    like ($warning, qr/uninitialized value/, "install_trace() restored after eval test complete");
}



__END__

# we need these files in t/04

my @files = qw(
                t/ext/install_trace.pl
                t/ext/install_trace.pm
);

for (@files){
    eval { unlink $_ or die "can't unlink test file $_: $!"; };
    is ($@, '', "unlinked $_ test file ok");
}

