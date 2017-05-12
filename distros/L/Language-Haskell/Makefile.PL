#!/usr/bin/perl

use strict;
use FindBin;
use Config;
use IPC::Open3;
use inc::Module::Install;

name('Language-Haskell');
version_from('lib/Language/Haskell.pm');
abstract_from('lib/Language/Haskell.pm');
author('Autrijus Tang <autrijus@autrijus.org>');
license('perl');
can_cc() or die "This module requires a C compiler";

my $src = "$FindBin::Bin/hugs98-Nov2003/src";

if (!-e "$src/Makefile") {
    chdir "$src/unix";
    system( sh => 'configure' );
}

chdir $src;
system { $Config{make} } $Config{make};
chdir $FindBin::Bin;

if (-e 'inc/.author') {
    make_vtable();
    my ($swig_version) = (run('swig', '-version') =~ /([\d\.]+)/g)
        or die "SWIG not found - http://www.swig.org/";

    (v($swig_version) ge v('1.3.24'))
        or die "SWIG 1.3.24+ not found - http://www.swig.org/";

    system(
        'swig', "-I$src",
        qw(-noproxy -module Language::Haskell -includeall -exportall -perl5 hugs.i)
    );

    unlink('lib/Language/Haskell_in.pm');
    rename('Haskell.pm' => 'lib/Language/Haskell_in.pm');
}

makemaker_args(
    INC => "-I$src",
    LIBS => "-lreadline -lncurses -lm",
    OBJECT => "hugs_wrap$Config{obj_ext}",
    MYEXTLIB => join(
        ' ', 
        map "$src/$_$Config{obj_ext}", qw(
            server
            builtin compiler errors evaluator
            ffi goal input machdep machine
            module opts output plugin script
            static storage strutil subst
            type version
        ),
        #grep !/(?:observe|hugs)[.\w]*$/, glob("$src/*$Config{obj_ext}")
    )
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

sub make_vtable {
    my @func;
    open FH, "$src/HugsAPI.h" or die $!;
    open VTABLE, ">vtable.i" or die $!;
    while (<FH>) {
        next if 1 .. /typedef struct _HugsServerAPI/;
        last if /^\} HugsServerAPI/;
        /^\s*(\S+)\s*\(\*(\w+)\s*\)\s*Args\(\((.+)\)\);/ or next;
        
        my ($type, $name, $vars) = ($1, $2, $3);
        my @vars = split(/,/, $vars);
        @vars = () if $vars eq 'void';
        my $sig = join(', ', 'HugsServerAPI*', @vars);
        print VTABLE "$type __HugsServerAPI__$name ($sig);\n";
        push @func, [$name, \@vars];
    }

    print VTABLE "\%{\n";
    foreach (@func) {
        my ($name, $vars) = @$_;
        my @args = map "hugs_var$_", 1..@$vars;
        my $alist1 = join(', ', 'hugs', @args);
        my $alist2 = join(', ', @args);
        print VTABLE "#define __HugsServerAPI__$name($alist1) (hugs->$name($alist2))\n";
    }
    print VTABLE "\%}\n";

    close FH;
    close VTABLE;
}
