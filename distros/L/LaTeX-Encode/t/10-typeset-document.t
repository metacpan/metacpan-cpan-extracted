#!/usr/bin/perl
# $Id: 10-typeset-document.t 27 2012-08-30 19:54:25Z andrew $

use strict;
use warnings;

use blib;
use FindBin;
use File::Basename;
use IO::File;
use LaTeX::Encode;
use charnames qw();

use Test::More;

my $latex_bin = find_latex();

if ($latex_bin) {
    plan skip_all => 'This is failing on some platforms due to dependencies';
    #plan tests => 1;
}
else {
    plan skip_all => 'cannot find \'latex\' binary';
}


my $table_body = '';
my %latex_encoding = %LaTeX::Encode::latex_encoding;
foreach my $char (sort keys %latex_encoding) {
    my $charcode = ord($char);
    my $charname = charnames::viacode($charcode);
    my $encoding = $latex_encoding{$char};

    $table_body .= sprintf("  U+%04x & %s & \\verb@%s@ & %s \\\\\n",
                           $charcode, $encoding, $encoding,
                           $charname || 'unnamed character');
}

my $document = <<EOS;
\\documentclass{article}
\\usepackage[T1]{fontenc}
\\usepackage{booktabs}
\\usepackage{textcomp}
\\usepackage{amssymb}
\\usepackage{amsfonts}
\\usepackage{amsmath}
\\usepackage{marvosym}
\\usepackage{wasysym}
\\begin{document}
\\begin{tabular}{clll}
  \\toprule
  \\textbf{Code} & \\textbf{Char} & \\textbf{Encoding} & \\textbf{Name} \\\\
  \\midrule
$table_body
  \\bottomrule
\\end{tabular}
\\end{document}
EOS

my $basename = basename($0, ".t");
my $fh = IO::File->new(">$FindBin::Bin/$basename.tex");
$fh->print($document);
undef $fh;

my $rc = system("cd $FindBin::Bin; $latex_bin '\\nonstopmode\\input{$basename.tex}'");


is($rc, 0, "typesetting table");


foreach my $ext (qw(aux dvi log tex)) {
    unlink "$FindBin::Bin/$basename.$ext";
}


sub find_latex {
    foreach my $dir (qw{ /usr/bin /bin }) {
        my $prog = "$dir/latex";
        return $prog if -x $prog;
    }
    return;
}

            
