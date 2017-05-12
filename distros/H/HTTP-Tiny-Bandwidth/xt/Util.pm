package xt::Util;
use strict;
use warnings;
use utf8;
use Exporter 'import';
our @EXPORT = qw(elapsed write_25MB_content);
use Time::HiRes ();

sub elapsed (&) {
    my $cb = shift;
    my $start = [Time::HiRes::gettimeofday];
    $cb->();
    Time::HiRes::tv_interval($start);
}

sub write_25MB_content {
    my $file = shift;
    open my $fh, ">", $file or die;
    my $x = ( ("x" x 1023) . "\n" ) x 1024;
    print {$fh} $x for 1..25;
    close $fh;
}


1;
