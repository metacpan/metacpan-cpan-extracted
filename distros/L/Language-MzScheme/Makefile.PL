#!/usr/bin/perl

use strict;
use Config;
use IPC::Open3;
use inc::Module::Install;

name('Language-MzScheme');
version_from('lib/Language/MzScheme.pm');
abstract_from('lib/Language/MzScheme.pm');
author('Autrijus Tang <autrijus@autrijus.org>');
license('perl');
build_requires('Test::More');
install_script('script/mzperl');
can_cc() or die "This module requires a C compiler";

my ($mz_version) = (run('mzscheme', '--version') =~ /([\d\.]+)/g)
  or die "MzScheme not found - http://plt-scheme.org/software/mzscheme/";

my $plt_path = $ENV{PLT_PATH} || do {
    my $show = run(qw(mzc --ldl-show --help))
      or die 'Cannot run mzc; please set $ENV{PLT_PATH}';
    $show =~ m!\("([^"]+)/lib/!i
      or die 'Cannot find PLT path; please set $ENV{PLT_PATH}';
    $1;
};

my $include = "$plt_path/include";
-d $include or die "Cannot find 'include' path under $plt_path; please set \$ENV{PLT_PATH}";

if (-e 'inc/.author') {
    my ($swig_version) = (run('swig', '-version') =~ /([\d\.]+)/g)
        or die "SWIG not found - http://www.swig.org/";

    (v($swig_version) ge v('1.3.24'))
        or die "SWIG 1.3.24+ not found - http://www.swig.org/";

    make_h();

    system(
        'swig',
        "-I$include",
        qw(-noproxy -module Language::MzScheme -includeall -exportall -perl5 mzscheme.i)
    );

    unlink('lib/Language/MzScheme_in.pm');
    rename('MzScheme.pm' => 'lib/Language/MzScheme_in.pm');
}

makemaker_args(
    LIBS => "-L$plt_path/lib -lmzgc -lmzscheme",
    INC => "-I$include",
    OBJECT => "mzscheme_wrap$Config{obj_ext}",
);

WriteAll( sign => 1 );

sub make_h {
    open IN, "$include/scheme.h" or die $!;
    open OUT, "> mzscheme_wrap.h" or die $!;
    while (<IN>) {
        next if /^#include\b/;
        next if /typedef struct Scheme_Jumpup_Buf \{/ .. /\} Scheme_Jumpup_Buf/;
        next if /typedef struct Scheme_Thread \{/ .. /\} Scheme_Thread/;
        next if /^MZ_EXTERN/;
        print OUT $_;
    }
    close OUT;
    close IN;

    open IN, "$include/schemex.h" or die $!;
    open OUT, ">> mzscheme_wrap.h" or die $!;
    while (<IN>) {
        next if /^#include\b/;
        next if /^typedef struct \{/;
        next if /^\} Scheme_Extension_Table;/;
        s/\(\*(\w+)\)/$1/;
        print OUT $_;
    }
    close OUT;
    close IN;

    open IN, "$include/stypes.h" or die $!;
    open OUT, ">> mzscheme_wrap.h" or die $!;
    while (<IN>) {
        print OUT $_;
    }
    close OUT;
    close IN;
}

sub make_c {
    local $/;
    open IN, "mzscheme_wrap.c" or die $!;

    my $text = '';
    while (<IN>) {
        if (/^static\s+swig_type_info\s+_swigt__p_(Scheme_(\w+))\[\]/o){
            my $fromType = $1;
            my $toType = "Language::MzScheme::".munge($1);
            print << "END";
static void *_p_${fromType}To_p_${toType}(void *x) {
return (void *)(($toType *) (($fromType *) x));
}  
END
            s/("$toType\s*\*"\}),/$1,{"_p_$fromType",_p_${fromType}To_p_${toType}},/;
        }
        $text .= $_;
    }

    close IN;

    open OUT, "> mzscheme_wrap.c" or die $!;
    print OUT $text;
    close OUT;
}

sub munge {
    my $func = shift;
    $func =~ s/_(?:[A-Z])//g;
    $func;
}

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
