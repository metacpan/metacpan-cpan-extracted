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
# Copyright: GPL, Author: Guido Socher
#
no locale;
use strict;
use vars qw($opt_p $opt_v $opt_h);
use Getopt::Std;
use HTML::TagReader;
use IO::Handle;
#
sub help();
sub fixfile($$);
#
getopts("hpv")||die "ERROR: No such option. -h for help.\n";
help() if ($opt_h);
help() unless ($ARGV[0]);

my $changecount=0;
my $mode;
for my $f (@ARGV){
    if ( -r "$f" ){
        if ($opt_p || $opt_h){
            $changecount=fixfile("$f","$f");
        }else{
            $mode=(stat(_))[2];
            rename($f,"$f.tr_fixltgt")||die "ERROR: can not rename $f to $f.tr_fixltgt, check directory permissions.\n";
            $changecount=fixfile("$f.tr_fixltgt",$f);
            if ($changecount){
                chmod($mode,$f)||die "ERROR: chmod %o $f failed\n";
                unlink("$f.tr_fixltgt")||die "ERROR: unlink $f.tr_fixltgt failed\n";;
            }else{
                # nothing changed restore the old file and do not change
                # modification time
                unlink("$f");
                rename("$f.tr_fixltgt",$f)||die "ERROR: can not rename $f.tr_fixltgt to $f, check directory permissions.\n";
            }
        }
    }else{
        warn "ERROR: can not read $f\n";
    }
}
# 
# fix < and > 
#
sub fixfile($$){
    my $infile=shift;
    my $outfile=shift; 
    my $count=0;
    my @tag;

    my $p=new HTML::TagReader "$infile";
    my $fd_out=new IO::Handle;
    unless($opt_p){
        open(OUT,">$outfile")||die "ERROR: can not write $outfile\n";
        $fd_out->fdopen(fileno(OUT),"w")||die;
        autoflush OUT 1;
    }else{
        $fd_out->fdopen(fileno(STDOUT),"w")||die "ERROR: can not write to stdout\n";
    }
    while(@tag = $p->getbytoken(0)){
        #
        unless($tag[1] eq ""){
            # not a text part
            $fd_out->print($tag[0]) unless($opt_v);
            next;
        } 
        while ($tag[0]=~/(.{0,3}<.{0,3})/){
            print STDERR "${outfile}:$tag[2]: changing < in ..$1.. to &lt;\n";
            $tag[0]=~s/</&lt;/;
            $count++;
        }
        while ($tag[0]=~/(.{0,3}>.{0,3})/){
            print STDERR "${outfile}:$tag[2]: changing > in ..$1.. to &gt;\n";
            $tag[0]=~s/>/&gt;/;
            $count++;
        }
        $fd_out->print($tag[0]) unless($opt_v);
    }
    $fd_out->flush;
    close(OUT) unless($opt_p);
    $fd_out->close;
    return($count);
}
#----------------------------------
sub help(){
print "tr_fixltgt -- fix < and > in text parts of html files to become 
&lt; and &gt;

USAGE: tr_fixltgt [-hpv]  html-files

tr_fixltgt opens all files listed on the command line and
edits these files. It will fix < and > in text parts (not in Tags)
and change them to &lt; and &gt;. This works of course only where
the < and > are recognized as misplaced. 

File access permissions are preserved.

OPTIONS: 
     -h this help

     -p print to stdout and do not modify any files.

     -v show only what would be changed but do not change anything

tr_fixltgt is part of the HTML::TagReader package.

version $VERSION
         \n";
exit(0);
}
__END__ 

=head1 NAME

tr_fixltgt -- fix E<lt> and E<gt> in text parts of html files to become 
&lt; and &gt;

=head1 SYNOPSIS

 tr_fixltgt [-hpv]  html-files

=head1 DESCRIPTION

tr_fixltgt opens all files listed on the command line and
edits these files. It will fix E<lt> and E<gt> in text parts (not in Tags)
and change them to &lt; and &gt;. This works of course only where
the E<lt> and E<gt> are recognized as misplaced. 

File access permissions are preserved.

=head1 OPTIONS

B<-h> short help

B<-p> print to stdout and do not modify any files.

B<-v> show only what would be changed but do not change anything

=head1 EXAMPLE

tr_fixltgt -v index.html
or to really change the file:
tr_fixltgt index.html

=head1 AUTHOR

tr_fixltgt is part of the HTML::TagReader package and was written by
Guido Socher 

=cut

