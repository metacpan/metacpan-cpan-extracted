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
use vars qw($opt_p $opt_i $opt_h $opt_v);
use Getopt::Std;
use HTML::TagReader;
use IO::Handle;
#
sub help();
sub expandonefile($$);
sub dirname($);
sub linktype($);
#
getopts("hpv:i:")||die "ERROR: No such option. -h for help.\n";
help() if ($opt_h);
help() unless ($ARGV[0]);

my @possibilities= qw(index.html index.htm index.shtml default.htm index.php3 index.php index.wml);
my $verbous=1; # default verbosity
my $changecount=0;
if (defined $opt_v){
    if ($opt_v >=0 && $opt_v < 4){
        $verbous=$opt_v;
    }else{
        die "ERROR: verbosity level must be an integer between 0 and 3\n";
    }
}
if ($opt_i){
    @possibilities=split(/,/,$opt_i);
}
my $mode;
for my $f (@ARGV){
    if ( -r "$f" ){
        if ($opt_p){
            $changecount=expandonefile("$f","$f");
            if ($verbous>=1){
                print STDERR "$f:1: $changecount links changed\n";
            }
        }else{
            $mode=(stat(_))[2];
            rename($f,"$f.xlnk")||die "ERROR: can not rename $f to $f.xlnk, check directory permissions.\n";
            $changecount=expandonefile("$f.xlnk",$f);
            if ($verbous>=1){
                print STDERR "$f:1: $changecount links changed\n";
            }
            if ($changecount){
                chmod($mode,$f)||die "ERROR: chmod %o $f failed\n";
                unlink("$f.xlnk")||die "ERROR: unlink $f.xlnk failed\n";;
            }else{
                # nothing changed restore the old file and do not change
                # modification time
                unlink("$f");
                rename("$f.xlnk",$f)||die "ERROR: can not rename $f.xlnk to $f, check directory permissions.\n";
            }
        }
    }else{
        warn "ERROR: can not read $f\n";
    }
}
# 
# expand exactly one file 
#
sub expandonefile($$){
    my $infile=shift;
    my $outfile=shift; 
    my $count=0;
    my @tag;
    my $linktype; # one of: name href src background
    my ($origtag,$ckpath,$path,$dir,$ltype,$origpath,$line,$found,$v);

    my $p=new HTML::TagReader "$infile";
    my $fd_out=new IO::Handle;
    unless($opt_p){
        open(OUT,">$outfile")||die "ERROR: can not write $outfile\n";
        $fd_out->fdopen(fileno(OUT),"w")||die;
        autoflush OUT 1;
    }else{
        $fd_out->fdopen(fileno(STDOUT),"w")||die "ERROR: can not write to stdout\n";
    }
    $v=0;
    if ($verbous>=2){
        $v=1;
    }
    while(@tag = $p->getbytoken($v)){
        # read out the tags, note something like: 
        # <a name="xxxx" href="...."> .... </a>
        # is valid
        #
        $origtag=$tag[0];
        if($tag[1] eq "" || $tag[1] eq "!--"){
            # not a tag or a comment
            $fd_out->print($origtag);
            next;
        } 
        # we search for " href", " src", " background": 
        unless($tag[0]=~/\ssrc|\shref|\sbackground/i){
            $fd_out->print($origtag);
            next;
        } 
        $line=$tag[2];
        $tag[0]=~s/\s+/ /g; # kill newline and double space
        next unless ($tag[0]=~/ (href|src|background) ?=/i);
        # remove optional space before the equal sign:
        $tag[0]=~s/ ?= ?/=/g;
        if ($tag[0]=~/ (href|src|background)=([^ >]+)/i){
            $linktype=$1;
            $path=$2;
            $origpath=$path;
            $path=~s/[\'\"]//g;
            $ltype=linktype($path);
        }else{
            print STDERR "$outfile:$line: Warning, invalid link in tag $tag[0]\n" if ($verbous >=2);
            $fd_out->print($origtag);
            next;
        }
        #---
        unless ($ltype eq 'rel' ){
            $fd_out->print($origtag);
            next;
        }
        if ($path=~/[\?\#]/){ # some anchor or php stuff-> not a directory
            $fd_out->print($origtag);
            next;
        }
        # decode URL encoding:
        $path=~tr/+/ /;
        $path=~s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $dir=dirname($outfile);
        $ckpath="$dir/$path";
        if ( -f "$ckpath"){
            $fd_out->print($origtag);
            next;
        }
        if ( -d "$ckpath"){
            # remove optional '/'
            $path=~s/\/$//;
            if ($path eq "."){ # remove single '.'
                $ckpath=$dir;
                $path="";
            }else{
                $path.="/";
                $ckpath="$dir/$path";
            }
            $found=0;
            for my $i (@possibilities){
                if ( -f "$ckpath/$i"){
                    $path.=$i;
                    $found=1;
                    last;
                }
            }
            if ($found){
                # change the link;
                my $pos=index($tag[0],"$linktype=$origpath",0);
                if ($pos){
                    print STDERR "$outfile:$line: expanding $linktype=$origpath -> $linktype=\"$path\"\n" if ($verbous >= 3);
                    substr($tag[0],$pos,length("$linktype=$origpath"))="$linktype=\"$path\"";
                    $count++;
                }else{
                    print STDERR "$outfile:$line: PROGRAM ERROR, \"$tag[0]\" does not contain \"$linktype=$origpath\"\n" if ($verbous>=1);
                }
                $fd_out->print($tag[0]);
                next;
            }else{
                print STDERR "$outfile:$line: Warning, broken link $linktype=$origpath, can not find index file.\n" if ($verbous >=2);
            }
        }else{
            print STDERR "$outfile:$line: Warning, broken link $linktype=$origpath\n" if ($verbous >=2);
        }
        $fd_out->print($origtag);
    }
    $fd_out->flush;
    close(OUT) unless($opt_p);
    $fd_out->close;
    return($count);
}
#----------------------------------
# get the directory name from file name
sub dirname($){
    my $f=shift;
    if ($f=~m=/=){
        $f=~s=/[^/]*$==;
        return("$f");
    }else{
        return(".");
    }
}
#----------------------------------
# find out if this is an abs link (proto://, file:, rel, /absfile)
sub linktype($){
    my $pathstr=shift; # no quotes must be arround the path
    if ($pathstr=~ m=^/=){
        return('/absfile');
    }elsif ($pathstr=~ m=^\.=){
        return('rel'); # may still contain a ref to named anchor
    }elsif ($pathstr=~ m=^\#=){
        return('anchor'); # relative anchor in the same file!
    }elsif ($pathstr=~ m=^file:=i){
        return('file:');
    }elsif ($pathstr=~ m=^\w+://=i){
        return('proto://');
    }elsif ($pathstr=~ m=^\w+:=i){
        return('proto:'); # mailto: or javascript:
    }else{
        return('rel');
    }
}
#----------------------------------
sub help(){
print "tr_xlnk -- expand links on directories

USAGE: tr_xlnk [-hp] [-v level] [-i fname-list] html-files

tr_xlnk opens all files listed on the command line and
searches for realtive links on directories. These links
are expanded to point to the default file (e.g index.html).

This is useful if you want to click through html files without
a web-server.

File access permissions are preserved.

OPTIONS: 
     -h this help

     -i index list. Comma seperated list of files to search
     for. Default is:
     index.html,index.htm,index.shtml,default.htm,index.php3,
     index.php,index.wml

     -p print to stdout and do not modify any files.

     -v verbosity. Number between 0-3. Print information on what is done.
     Default is 1.

tr_xlnk is part of the HTML::TagReader package.

version $VERSION
         \n";
exit(0);
}
__END__ 

=head1 NAME

tr_xlnk -- process html files and expand links on directories 

=head1 SYNOPSIS

    tr_xlnk [-hp] [-v level] [-i fname-list] html-files

=head1 DESCRIPTION

tr_xlnk opens all files listed on the command line and
searches for realtive links on directories. These links
are expanded to point to the default file (e.g index.html).

This is useful if you want to click through html files without
a web-server.

File access permissions are preserved.

=head1 OPTIONS

B<-h> short  help

B<-i> index list. Comma seperated list of files to search
for. Default is:
index.html,index.htm,index.shtml,default.htm,index.php3,
index.php,index.wml

B<-p> print to stdout and do not modify any files.

B<-v> verbosity. Number between 0-3. Print information on what is done.
Default is 1.

=head1 EXAMPLE

tr_xlnk `find . -name '*.htm*'`

will seach for all html files in this directroy and subdirectories
and modify the html files such that all links point to the default index
files.
E.g href="../" would become href="../index.html" if index.html exists.

=head1 AUTHOR

tr_xlnk is part of the HTML::TagReader package and was written by
Guido Socher [guido(at)linuxfocus.org]

=cut

