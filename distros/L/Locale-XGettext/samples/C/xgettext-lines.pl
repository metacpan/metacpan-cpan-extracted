#! /usr/bin/env perl

package Locale::XGettext::C;
 
use strict;

use File::Spec;

use base qw(Locale::XGettext);

my $code;

BEGIN {
    my @spec = File::Spec->splitpath(__FILE__);
    $spec[2] = 'CXGettext.c';
    my $filename = File::Spec->catpath(@spec);
    open HANDLE, "<$filename"
        or die "Cannot open '$filename': $!\n";
    $code = join '', <HANDLE>;
}

use Inline C => $code;

package main;

Locale::XGettext::C->newFromArgv(\@ARGV)->run->output;
