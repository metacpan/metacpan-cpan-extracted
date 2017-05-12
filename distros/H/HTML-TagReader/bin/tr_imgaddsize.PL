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
use vars qw($opt_v $opt_p $opt_h);
use Getopt::Std;
use Image::Size;
use HTML::TagReader;
use IO::Handle;
#
sub help();
sub expandonefile($$);
#
getopts("hpv")||die "ERROR: No such option. -h for help.\n";
help() if ($opt_h);
help() unless ($ARGV[0]);

my $changecount=0;
my $mode;
for my $f (@ARGV){
    if ( -r "$f" ){
        if ($opt_p){
            $changecount=expandonefile("$f","$f");
        }else{
            $mode=(stat(_))[2];
            rename($f,"$f.imgaddsize")||die "ERROR: can not rename $f to $f.imgaddsize, check directory permissions.\n";
            $changecount=expandonefile("$f.imgaddsize",$f);
            if ($changecount){
                chmod($mode,$f)||die "ERROR: chmod %o $f failed\n";
                unlink("$f.imgaddsize")||die "ERROR: unlink $f.imgaddsize failed\n";;
            }else{
                # nothing changed restore the old file and do not change
                # modification time
                unlink("$f");
                rename("$f.imgaddsize",$f)||die "ERROR: can not rename $f.imgaddsize to $f, check directory permissions.\n";
            }
        }
    }else{
        warn "ERROR: can not read $f\n";
    }
}
#----------------------------------
# 
# expand exactly one file 
#
sub expandonefile($$){
    my $infile=shift;
    my $outfile=shift; 
    my $dir=$infile; 
    my $count=0;
    my @tag;
    my ($origtag,$line,$path,$ltype);

    if ($dir=~m|/|){
        $dir=~s/\/[^\/]+$//; #basename, directory where file is
    }else{
        $dir=".";
    }
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
        $origtag=$tag[0];
        if($tag[1] ne "img" ){
            # not a img tag
            $fd_out->print($origtag);
            next;
        } 
        # we search for " src=" 
        unless($tag[0]=~/\ssrc\s*=/i){
            $fd_out->print($origtag);
            next;
        } 
        $line=$tag[2];
        $tag[0]=~s/\s+/ /g; # kill newline and double space
        if ($tag[0]=~/width/i && $tag[0]=~/height/i){
            # do not change tag if  width and height are there
            $fd_out->print($origtag);
            next;
        } 
        # remove optional space before the equal sign:
        $tag[0]=~s/ ?= ?/=/g;
        if ($tag[0]=~/ (src)=([^ >]+)/i){
            $path=$2;
            $path=~s/[\'\"]//g;
            $ltype=linktype($path);
        }else{
            print STDERR "$outfile:$line: Warning, invalid link in tag $tag[0]\n";
            $fd_out->print($origtag);
            next;
        }
        #---
        unless ($ltype eq 'rel' ){
            print STDERR "$outfile:$line: Warning, path $path not relative, ignored.\n";
            $fd_out->print($origtag);
            next;
        }
        # now it is definitly a relative link:
        unless ( -r "$dir/$path"){ 
            print STDERR "$outfile:$line: Warning, can not read file $dir/$path\n";
            $fd_out->print($origtag);
            next;
        }
        my $s=Image::Size::html_imgsize("$dir/$path");
        if ($s){
            $count++;
            $origtag=$tag[0]; # space reduced
            # modify now $origtag
            chop($origtag); # remove ">"
            # there could be single width or height left:
            $origtag=~s/ width=\S*//i;
            $origtag=~s/ height=\S*//i;
            $origtag.=" $s>";
            print STDERR "$outfile:$line: OK, $path, $s\n";
            $fd_out->print($origtag);
            next;
        }else{
            print STDERR "$outfile:$line: Warning, can not determine image size of $path\n";
            $fd_out->print($origtag);
            next;
        }
        $fd_out->print($origtag);
    }
    $fd_out->flush;
    close(OUT) unless($opt_p);
    $fd_out->close;
    return($count);
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
print "tr_imgaddsize -- add width and height to <img src=...>
tag 

USAGE: tr_imgaddsize [-hpv] html-files

tr_imgaddsize opens all files listed on the command line and
edits them if needed. All <img src=...> get width and height
added if not already there. This works only for relative
links (something like src=../images/cool.png)

File access permissions are preserved.

OPTIONS: 
     -h this help

     -p print to stdout and do not modify any files.

     -v verbous messages about html errors.

tr_imgaddsize is part of the HTML::TagReader package.
Note: This program needs Image::Size from
      http://www.cpan.org/authors/id/R/RJ/RJRAY/

version $VERSION
         \n";
exit(0);
}
__END__ 

=head1 NAME

tr_imgaddsize -- add width and height to E<lt>img src=...E<gt>

=head1 SYNOPSIS

    tr_imgaddsize [-hpv] html-files

=head1 DESCRIPTION

tr_imgaddsize opens all files listed on the command line and
edits them if needed. All E<lt>img src=...E<gt> get width and height
added if not already there. This works only for relative
links (something like src=../images/cool.png)

File access permissions are preserved.

=head1 OPTIONS

B<-h> short  help

B<-p> print to stdout and do not modify any files.

B<-v> verbous messages about html errors.

=head1 EXAMPLE

tr_imgaddsize file.html

=head1 AUTHOR

tr_imgaddsize is part of the HTML::TagReader package and was written by
Guido Socher [guido(at)linuxfocus.org]

This program needs Image::Size from
http://www.cpan.org/authors/id/R/RJ/RJRAY/

=cut

