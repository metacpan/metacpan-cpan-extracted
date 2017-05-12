#!/usr/bin/perl
no locale;
use Config;
# vim: set sw=4 ts=4 si et:
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
        if ($Config{'osname'} eq 'VMS' or
            $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

my $VERSION="unknown";
if (-r "../TagReader.pm"){ # get version
    open(F,"../TagReader.pm")||die;
    while(<F>){
        if (/\$VERSION *= *(.+)/){
            $VERSION=$1;
            $VERSION=~s/[^\.\d]//g;
        }
    }
    close F;
}

print OUT "$Config{'startperl'} -w
my \$VERSION = \"$VERSION\";
";

while(<DATA>){
    print OUT;
}

__END__ 
# vim: set sw=4 ts=4 si et: 
# Copyright: GPL
# Author: Guido Socher
#
no locale;
use strict;
use vars qw($opt_h $opt_l);
use Getopt::Std;
# 
sub help();
#------------------
getopts("lh")||die "ERROR: No such option. -h for help.\n";
help() if ($opt_h);
help() unless($ARGV[0]);
my $pattern=shift;
$/='<'; # record seperator, normally "\n" but in html "\n" means nothing
my $i=1;
my $l=1;
while(<>){
    while(s/\r?\n/ /){
        # keep track of line numbers
        $i++;
    }
    # take away the end tag:
    s/>.*//;
    # kill multiple space
    s/[ \t]+/ /g;
    if(/$pattern/io){
        # matches this tag. Print filename:linenumber: matched tag
        print "${ARGV}:${i}: " if ($opt_l);
        print "<$_>\n";
        $l=$i; # we want to count the line where the tag starts
        next;
    }
    $l=$i; # we want to count the line where the tag starts
}
#
sub help(){
    print "tr_tagcontentgrep -- grep for a xml/sgml/html tag

USAGE: tr_tagcontentgrep [-hl] regexp-pattern [file ...]

tr_tagcontentgrep opens all files provided on the command line
and searches for the given pattern in the tags. The search
is not case sensitive.

All space in the tags is reduced to max. one space. You can
search for \"a href\" even if the original tag had
multiple spaces between \"a\" and \"href\".

OPTIONS: 
     -h this help

     -l list filename and line number

EXAMPLE:
    tr_tagcontentgrep -l img file.html

would e.g print something like:

index.html:53: <IMG src=\"../images/transpix.gif\" alt=\"\">
index.html:257: <IMG SRC=\"../Logo.gif\" width=128 height=53>

tr_tagcontentgrep is part of the HTML::TagReader package
but is an example that you can also do 'reading by tag'
without HTML::TagReader. tr_tagcontentgrep uses plain perl
and sets the \$/ variable. 
Working without HTML::TagReader causes however problems when working
with faulty html code where single '<'-characters appear 
somewhere in the text.

version $VERSION
";
    exit(0);
}
__END__ 

=head1 NAME

tr_tagcontentgrep -- grep for a xml/sgml/html tag

=head1 SYNOPSIS

 tr_tagcontentgrep [-hl] regexp-pattern [file ...]

=head1 DESCRIPTION

tr_tagcontentgrep opens all files provided on the command line
and searches for the given pattern in the tags. The search
is not case sensitive.

tr_tagcontentgrep is part of the HTML::TagReader package
but is an example that you can also do 'reading by tag'
without HTML::TagReader. tr_tagcontentgrep uses plain perl
and sets the $/ variable. 
Working without HTML::TagReader causes however problems when working
with faulty html code where single 'E<lt>'-characters appear 
somewhere in the text.

All space in the tags is reduced to max. one space. You can
search for "a href" even if the original tag had 
multiple spaces between "a" and "href".

=head1 OPTIONS

B<-h> this help

B<-l> list filename and line number

=head1 EXAMPLE

tr_tagcontentgrep -l img file.html

would e.g print something like:

index.html:53: E<lt>IMG src="../images/transpix.gif" alt=""E<gt>
index.html:257: E<lt>IMG SRC="../Logo.gif" width=128 height=53E<gt>

=head1 AUTHOR

tr_tagcontentgrep is part of the HTML::TagReader package and was written by
Guido Socher [guido(at)linuxfocus.org]

=cut

