use inc::Module::Install;
use Config;

name     'IO-Pty-HalfDuplex';
all_from 'lib/IO/Pty/HalfDuplex.pm';
repository 'http://github.com/sorear/IO-Pty-HalfDuplex';

requires 'IO::Pty';
requires 'Time::HiRes';

my @chunks;

# XXX it would be nice if we could usefully probe for what works, but
# the source files need #ifdefs of their own

# be careful here; arch names depend on OS
# linux stupidly uses CPU model name.  who wants to regex every x86 model?
push @chunks, 'ptrace' if $^O eq 'freebsd' &&
    $Config{archname} =~ /i386|amd64/;

push @chunks, 'sysctl' if grep { $_ eq $^O } qw/freebsd netbsd openbsd/;

my @object;
my @c;
my $xs = '';

for my $chunk (@chunks) {
    push @c, "$chunk.c";
    push @object, "$chunk$Config{_o}";

    local $/;
    open FRAGMENT, "$chunk.xsf" or die
        "Failed to open fragment $chunk.xsf: $!";
    $xs .= "\n" . <FRAGMENT>;
    close FRAGMENT;
}

print "We are building ",
    (@chunks ? "with: " . join(", ", @chunks) : "without XS") . ".\n";

if ($xs) {
    open XS, ">HalfDuplex.xs" or
        die "Failed to open xs-file for output: $!";
    print XS <<HEADER ;
/* Automatically generated from *.xsf by Makefile.PL */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = IO::Pty::HalfDuplex  PACKAGE = IO::Pty::HalfDuplex

PROTOTYPES: ENABLE

HEADER
    print XS $xs;
    close XS or die "Failed to close xs-file: $!";
    push @object, "HalfDuplex$Config{_o}";
    push @c, "HalfDuplex.c";
} else {
    unlink "HalfDuplex.xs";
}

makemaker_args(OBJECT => join(" ",@object), C => \@c);
WriteAll;

