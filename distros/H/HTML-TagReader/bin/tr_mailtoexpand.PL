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
use vars qw($opt_p $opt_h);
use Getopt::Std;
use HTML::TagReader;
use IO::Handle;
#
sub help();
sub expmailto($$);
#
getopts("hp")||die "ERROR: No such option. -h for help.\n";
help() if ($opt_h);
help() unless ($ARGV[0]);

my $changecount=0;
my $mode;
for my $f (@ARGV){
    if ( -r "$f" ){
        if ($opt_p || $opt_h){
            $changecount=expmailto("$f","$f");
        }else{
            $mode=(stat(_))[2];
            rename($f,"$f.tr_fixltgt")||die "ERROR: can not rename $f to $f.tr_fixltgt, check directory permissions.\n";
            $changecount=expmailto("$f.tr_fixltgt",$f);
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
# handle one file
#
sub expmailto($$){
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
    while(@tag = $p->getbytoken(0)){
        #
        if ($tag[1] eq "a"){
            $tmp=$tag[0];
            $tmp=~s/\s/ /g;
            if ($tmp=~/href.+mailto:([\w\@\.\-\%]+)/i){
                $adr=lc $1;
                $adr=~s/\@/[at]/;
                $count++;
                if ($state != 0){
                    print STDERR "${outfile}:$tag[2]: syntax error, probably missing </a>\n";
                    $fd_out->print($buf);
                }
                $buf=$tag[1];
                $state=1;
                next;
            }
        }
        if ($state==0){
            $fd_out->print($tag[0]);
            next;
        }
        if ($tag[1] eq "" && $state==1){
            $name=$tag[0];
            $state=2;
            next;
        }
        if ($tag[1] eq "/a" && $state==2){
            $fd_out->print("$name <small>($adr)</small>");
            $state=0;
            next;
        }
        print STDERR "${outfile}:$tag[2]: syntax error in anchor \n";
        $fd_out->print($buf);
        $fd_out->print($tag[0]);
        $state=0;
    }
    $fd_out->flush;
    close(OUT) unless($opt_p);
    $fd_out->close;
    return($count);
}
#----------------------------------
sub help(){
print "tr_mailtoexpand -- expand mailto: into a non clickable
name and mail address. 

USAGE: tr_mailtoexpand [-hp]  html-files

tr_mailtoexpand modifies \"a href=mailto:\" tags such that the
mail address contails [at] instead of the \@ to protect it from spammers.
The anchor tag is completely removed and the address is just
inserted behind in the text the name.

File access permissions are preserved.

OPTIONS: 
     -h this help

     -p print to stdout and do not modify any files.

version $VERSION
         \n";
exit(0);
}
__END__ 

=head1 NAME

tr_mailtoexpand -- expand mailto: into a non clickable
name and mail address.

=head1 SYNOPSIS

 tr_mailtoexpand [-hp]  html-files

=head1 DESCRIPTION

tr_mailtoexpand modifies "a href=mailto:" tags such that the
mail address contails [at] instead of the @ to protect it from spammers.
The anchor tag is completely removed and the address is just
inserted behind in the text the name.

File access permissions are preserved.


=head1 OPTIONS

B<-h> short help

B<-p> print to stdout and do not modify any files.


=head1 EXAMPLE

tr_mailtoexpand -p index.html
or to really change the file:
tr_mailtoexpand index.html

=head1 AUTHOR

tr_mailtoexpand is part of the HTML::TagReader package and was written by
Guido Socher [guido(at)linuxfocus.org]

=cut

