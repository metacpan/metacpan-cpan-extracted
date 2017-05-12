#!/usr/bin/perl
use strict;
use warnings;

use File::Temp;
use Logging::Simple;
use Test::More;

my $mod = 'Logging::Simple';

{ # set/get
    my $log = Logging::Simple->new;

    is ($log->print, 1, "printing is enabled by default");
    $log->print(0);
    is ($log->print, 0, "printing can be disabled");
    $log->print(1);
    is ($log->print, 1, "...and enabled again");
}
{ # print vs return
    my $log = Logging::Simple->new;

    my $fn = _fname();
    $log->file($fn);

    $log->_generate_entry(label => '_7', msg => 'testing print');
    $log->file(0);

    open my $fh, '<', $fn or die $!;
    like (<$fh>, qr/lvl 7.*testing print/, "print(1) prints log entry");
    close $fh;

    $log->print(0);

    my $msg = $log->_generate_entry(label => '_7', msg => 'no print');
    like ($msg, qr/lvl 7.*no print/, "print(0) returns with no print");
}
{ # print to STDOUT
    my $log = $mod->new(display => 0);

    my $out;
    open my $stdout, '>', \$out or die $!;

    select $stdout;

    $log->_1('test');

    close $stdout;

    select STDOUT;

    is ($out, "test\n", "print prints to STDOUT with no log file");
}

sub _fname {
    my $fh = File::Temp->new(UNLINK => 1);
    my $fn = $fh->filename;
    close $fh;
    return $fn;
}
done_testing();

