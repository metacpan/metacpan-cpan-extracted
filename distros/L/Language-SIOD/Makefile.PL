#!/usr/bin/perl

use strict;
use Config;
use IPC::Open3;
use inc::Module::Install;

name('Language-SIOD');
version_from('lib/Language/SIOD.pm');
abstract_from('lib/Language/SIOD.pm');
author('Autrijus Tang <autrijus@autrijus.org>');
license('perl');
can_cc() or die "This module requires a C compiler";

if (-e 'inc/.author') {
    my ($swig_version) = (run('swig', '-version') =~ /([\d\.]+)/g)
        or die "SWIG not found - http://www.swig.org/";

    (v($swig_version) ge v('1.3.24'))
        or die "SWIG 1.3.24+ not found - http://www.swig.org/";

    system(
        'swig',
        qw(-noproxy -module Language::SIOD -includeall -exportall -perl5 siod.i)
    );

    unlink('lib/Language/SIOD_in.pm');
    rename('SIOD.pm' => 'lib/Language/SIOD_in.pm');
}

makemaker_args(
    OBJECT => join(' ', map "$_$Config{obj_ext}", qw(siod_wrap sliba slibu)),
);

WriteAll( sign => 1 );

sub v {
    my $v = shift;
    join('', map chr, $v =~ /(\d+)/g);
}

sub run {
    my ($wtr, $rdr, $err);

    local $SIG{__WARN__} = sub { 1 };

    my $pid = open3($wtr, $rdr, $err, @_);
    my $out = join('', map $_ && readline($_), $rdr, $err);
    chomp $out;
    return $out;
}
