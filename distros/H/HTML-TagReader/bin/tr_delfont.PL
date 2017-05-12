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
use vars qw($opt_a $opt_v $opt_p $opt_h);
use Getopt::Std;
use HTML::TagReader;
use IO::Handle;
#
sub help();
sub dfont($$);
#
getopts("hpva")||die "ERROR: No such option. -h for help.\n";
help() if ($opt_h);
help() unless ($ARGV[0]);

my $changecount=0;
my $mode;
for my $f (@ARGV){
    if ( -r "$f" ){
        if ($opt_p || $opt_h){
            $changecount=dfont("$f","$f");
        }else{
            $mode=(stat(_))[2];
            rename($f,"$f.tr_delf")||die "ERROR: can not rename $f to $f.tr_delf, check directory permissions.\n";
            $changecount=dfont("$f.tr_delf",$f);
            if ($changecount){
                chmod($mode,$f)||die "ERROR: chmod %o $f failed\n";
                unlink("$f.tr_delf")||die "ERROR: unlink $f.tr_delf failed\n";;
            }else{
                # nothing changed restore the old file and do not change
                # modification time
                unlink("$f");
                rename("$f.tr_delf",$f)||die "ERROR: can not rename $f.tr_delf to $f, check directory permissions.\n";
            }
        }
    }else{
        warn "ERROR: can not read $f\n";
    }
}
# 
# handle one file
#
sub dfont($$){
    my $infile=shift;
    my $outfile=shift; 
    my $count=0;
    my @tag;
    my $state=0;
    my ($adr,$name,$buf,$tmp);

    my $p=new HTML::TagReader "$infile";
    my $fd_out=new IO::Handle;
    unless($opt_p){
        open(OUT,">$outfile")||die "ERROR: can not write $outfile\n";
        $fd_out->fdopen(fileno(OUT),"w")||die;
        autoflush OUT 1;
    }else{
        $fd_out->fdopen(fileno(STDOUT),"w")||die "ERROR: can not write to stdout\n";
    }
    while(@tag = $p->getbytoken($opt_v)){
        #
        if ($tag[1] eq "font"){
            $tmp=$tag[0];
            $count++;
            $tmp=~s/\s/ /g;
            if (!$opt_a && $tmp=~/color ?= ?(['"#\w]+)/i){
                # keep at least part of this tag
                $state=0;
                # remove all but color:
                $tmp="<font color=$1>";
                $fd_out->print($tmp);
            }else{
                # remove totally
                $state=1; 
            }
            next;
        }
        if ($tag[1] eq "/font"){
            if ($state==1){
                next; # remove
            }
            $state=0;
            $fd_out->print($tag[0]);
            next;
        }
        $fd_out->print($tag[0]);
    }
    $fd_out->flush;
    close(OUT) unless($opt_p);
    $fd_out->close;
    return($count);
}
#----------------------------------
sub help(){
print "tr_delfont -- delete font tags that hardcode the size or
the font face.

USAGE: tr_delfont [-hpv]  html-files

tr_delfont deletes all font tags that hardcode the size or the font face.
The font color is not changed

File access permissions are preserved.

OPTIONS: 
     -h this help

     -a delete all font tags even the color attributes 

     -p print to stdout and do not modify any files.

     -v verbous messages about html errors.

version $VERSION
         \n";
exit(0);
}
__END__ 

=head1 NAME

tr_delfont -- delete font tags that hardcode the size or the font face.

=head1 SYNOPSIS

 tr_delfont [-hpv]  html-files

=head1 DESCRIPTION

tr_delfont deletes all font tags that hardcode the size or the font face.
The font color is not changed

File access permissions are preserved.

=head1 OPTIONS

B<-h> short help

B<-a> delete all font tags even the color attributes 

B<-p> print to stdout and do not modify any files.

B<-v> verbous messages about html errors.

=head1 EXAMPLE

tr_delfont -p index.html
or to really change the file:
tr_delfont index.html

=head1 AUTHOR

tr_delfont is part of the HTML::TagReader package and was written by
Guido Socher [guido(at)linuxfocus.org]

=cut

