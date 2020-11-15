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
use vars qw($opt_a $opt_d $opt_r $opt_W $opt_A $opt_h);
use Getopt::Std;
use HTML::TagReader;
#
sub help();
sub checkonefile($$);
sub checkonefile_nameonly($);
sub dirname($);
sub linktype($);
#
getopts("aAhd:r:W")||die "ERROR: No such option. -h for help.\n";
help() if ($opt_h);
help() unless ($ARGV[0]);

my %count=('rel'=>0,'abs'=>0);
my @checklater=();
my %named_anchors;
my %checkedfiles;
my $later=1;
if ($opt_A || $opt_a){
    $later=0;
}
if ($opt_d && length($opt_d)> 1){
    $opt_d=~s/\/$//; # kill tailing slash
}
for my $f (@ARGV){
    if ( -r "$f" ){
        checkonefile($f,$later);
    }else{
        warn "ERROR: can not read $f\n";
    }
}
if ($later){
    my $file;
    for my $anchorpath (@checklater){
        $file=$anchorpath->[0];
        $file=~s/\#.*//; # strip after '#'
        if ($checkedfiles{$file}){
            unless($named_anchors{$anchorpath->[0]}){
                print $anchorpath->[1]; # print error message
            }
        }else{
            # we have not read this file yet
            checkonefile_nameonly($file);
            unless($named_anchors{$anchorpath->[0]}){
                print $anchorpath->[1]; # print error message
            }
        }
    }
}
#
# check one file but add only named anchors to
# the %named_anchors
#
sub checkonefile_nameonly($){
    my $file=shift;
    my @tag;
    my ($path,$line,$cpos);

    my $p=new HTML::TagReader "$file";
    $checkedfiles{"$file"}=1;
    while(@tag = $p->gettag(!$opt_W)){
        # read out the tags, note something like: 
        # <a name="xxxx" href="...."> .... </a>
        # is valid
        #
        # we search for " name": 
        next unless($tag[0]=~/ name/i); 
        # remove optional space before the equal sign:
        $tag[0]=~s/ ?= ?/=/g;
        $tag[0]=~s/^<//;
        $tag[0]=~s/>$//;
        $tag[0]=~s/[\"\']//g;
        $line=$tag[1];
        $cpos=$tag[2];
        if ($tag[0]=~/ name=(\S+)/i){
            $path=$1;
            $named_anchors{$file."#".$path}=$line;
        }
    }
}
# 
# check exactly one file 
#
sub checkonefile($$){
    my $file=shift;
    my $later=shift; # whether or not to fill the checklater array
    my @tag;
    my $linktype; # one of: name href src background
    my ($ckpath,$path,$ltype,$dir,$line,$origpath,$tagtype,$waitaclose,$cpos);

    my $p=new HTML::TagReader "$file";
    $checkedfiles{"$file"}=1;
    while(@tag = $p->gettag(!$opt_W)){
        # read out the tags, note something like: 
        # <a name="xxxx" href="...."> .... </a>
        # is valid
        #
        # we search for " name", " href", " src", " background"
        # there is max one space in the data returned by gettag:
        if ($tag[0]=~m!<a !i){
            $tagtype="aopen";
        }elsif ($tag[0]=~m!</a\W!i){
            $tagtype="aclose";
            $waitaclose=0;
        }else{
            $tagtype=""
        }
        next unless($tag[0]=~/ name ?=| href ?=| src ?=| background ?=/i); 
        # remove optional space before the equal sign:
        $tag[0]=~s/ ?= ?/=/g;
        $tag[0]=~s/^<//;
        $tag[0]=~s/>$//;
        $tag[0]=~s/[\"\']//g;
        $line=$tag[1];
        $cpos=$tag[2];
        if ($tag[0]=~/ href=(\S+)/i){
            $linktype='href';
            $path=$1;
            $ltype=linktype($path);
            if ($waitaclose){
                print "$file:$waitaclose: ERROR, <a href=... starting on line $waitaclose not terminated\n" unless($opt_W);
            }
            if ($tagtype eq "aopen"){
                $waitaclose=$line;
            }else{
                $waitaclose=0;
            }
            #
            # We must alwasy check for anchors (name= and href=)
            # A tag like <a name="xxxx" href="...."> .... </a> is possible.
            # It is not possible to have background together with an anchor.
            # It is also not possible to have nested anchors.
            #
            if ($tag[0]=~/ name=(\S+)/i){
                $named_anchors{$file."#".$1}=$line;
            }
        }elsif ($tag[0]=~/ name=(\S+)/i){
            $path=$1;
            $named_anchors{$file."#".$path}=$line;
            next;
        }elsif ($tag[0]=~/ src=(\S+)/i){
            $linktype='src';
            $path=$1;
            $ltype=linktype($path);
        }elsif ($tag[0]=~/ background=(\S+)/i){
            $linktype='background';
            $path=$1;
            $ltype=linktype($path);
        }else{
            print "$file:$tag[1]: ERROR, invalid or empty link $tag[0]\n" unless($opt_W);
            next;
        }
        unless($opt_a){
            # decode URL encoding unless -a is given:
            $path=~tr/+/ /;
            $path=~s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        }
        #---
        if ($ltype eq 'rel' || $ltype eq 'anchor' ){
            $count{'rel'}++;
        }else{
            $count{'abs'}++;
        }
        if ($opt_r && $ltype eq "proto://"){
            if ($path=~/$opt_r/io){
                print "$file:$line:$cpos: warning abs link to \"$path\"\n";
            }
        }
        if ($opt_a){
            if ($ltype eq "proto://"){
                print "$file:$line:$cpos: $linktype=\"$path\"\n";
            }
            #
            # !! here we ignore the rest of this function
            #
            next;
        }
        #---
        if ($ltype eq 'anchor'){ # relative anchor in the same file!
            # add path (with file name) and possible error message:
            push(@checklater,[$file.$path,"$file:$line:$cpos: reference to non existing anchor $linktype=\"$path\"\n"]) if ($later);
            next;
        }
        #---
        if ($ltype eq "/absfile"){
            unless($opt_d){
                print "$file:$line:$cpos: ERROR: can not check $linktype=\"$path\", specify docroot with option -d.\n";
                next;
            }
            if ($path=~/^(.+)#/){ # link to named anchor
                $ckpath=$1;
                if ( -f "$opt_d/$ckpath" ){
                    # add path and possible error message:
                    push(@checklater,["$opt_d/$path","$file:$line:$cpos: reference to non existing anchor $linktype=\"$path\"\n"]) if ($later);
                }else{
                    print "$file:$line:$cpos: reference to non existing file $linktype=\"$path\"\n";
                }
                next;
            }
            $ckpath=$path;
            unless ( -f "$opt_d/$ckpath" || -d "$opt_d/$ckpath" ){
                print "$file:$line:$cpos: broken link $linktype=\"$path\"\n";
            }
            next;
        }
        #---
        $dir=dirname($file);
        if ($path=~/^(.+)#/){ # link to named anchor
            $ckpath=$1;
            next if ($ltype ne 'rel');
            if ( -f "$dir/$ckpath" ){
                # ./index.html should be index.html, but don't remove ../index.html
                $path=~s/^\.\///;
                # add path and possible error message:
                push(@checklater,["$dir/$path","$file:$line:$cpos: reference to non existing anchor $linktype=\"$path\"\n"]) if ($later);
            }else{
                print "$file:$line:$cpos: reference to non existing file $linktype=\"$path\"\n";
            }
            next;
        }
        if ($ltype eq 'file:'){
            print "$file:$line:$cpos: warning link with \"file:$path\"\n" unless($opt_W);
            next;
        }
        # handle cgi's:
        $ckpath=$path;
        $ckpath=~s/\?.*//;
        #---
        # finally check if this is a broken link:
        if ($ltype eq 'rel'){
            unless ( -f "$dir/$ckpath" || -d "$dir/$ckpath" ){
                print "$file:$line:$cpos: broken link $linktype=\"$path\"\n";
            }
        }
    }
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
print "tr_blck -- check for broken relative links in html pages

USAGE: tr_blck [-AhW] [-d docroot] [-r regexp] html-files

blck searches html files for broken links. I searches
only the relative links and does not need a web-server. As
it does not need web-access it is very fast. The output of
tr_blck  is of the same format as gcc error messages and
can therefore be interpreted by many common  editors  (e.g
emacs  or  vim).   After editing a some html pages you can
just type:
tr_blck page1.html ../somewhere/page2.html
and tr_blck will check that the links in these pages are
correct.

tr_blck checks the relative filesystem links.  These are
links of the form:
href=\"index.html\"
href=\"../somepage.html#anchor1\"
etc...

but not
href=\"/notchecked.html\"
href=\"http://server.somewhere/something.html\"
href=\"javascript:history.back();\"

All tags containg relative links with  href=...,  src=...,
and background=...  are checked.

OPTIONS: -h this help

         -a print all links that were not checked (proto://) and
         do not check for any broken links. This output can be
         processed further with httpcheck.
         -A do not open any other files than the files given on the

         -d document root directory to check abs. filesystem links
         e.g -d /home/httpd/html

         -r warn about absolut links matching the given perl regexp
         E.g: -w \'www.linuxfocus.org|chem.pitt.edu\'
         This match is not case sensitive and only applied to links
         starting with proto:// (=absolut links).

         -W do not print warnings about html errors (not terminated
         tags etc ...).

EXAMPLE
       Check links in html files in the web server root directory
       (/home/httpd/html) and in all directories one level down:
       (cd /home/httpd/html; tr_blck *.html */*.html)

       Check links in all html files on the server:
       (cd  /home/httpd/html;  tr_blck  `find  . -name '*.htm*'
       -print` | sort)

       You  can  use  the  vim  editor  Quickfix  mode   or   the
       emacs/xemacs M-x compile to parse the output of tr_blck.
       Vim: :cf file_with_err_messages, :cn to go to the next message
       emacs: M-x compile, compile command: cat file_with_err_messages

       This gives you the possibility to open the  concerned  web
       page  and  jump directly to the line where the broken link
       is.  To do this you can write a Makefile that looks e.g as
       follows:

       all:
            tr_blck `find . -name '*.htm*' -print` | sort

tr_blck is part of the HTML::TagReader package.

version $VERSION
         \n";
exit(0);
}
__END__ 

=head1 NAME

tr_blck -- check for broken relative links in html pages

=head1 SYNOPSIS

    tr_blck [-AhW] [-d docroot] [-r regexp] html-files

=head1 DESCRIPTION

tr_blck searches html files for broken links. I searches
only the relative links and does not need a web-server. As
it does not need web-access it is very fast. The output of
tr_blck  is of the same format as gcc error messages and
can therefore be interpreted by many common  editors  (e.g
emacs  or  vim).   After editing a some html pages you can
just type:
tr_blck page1.html ../somewhere/page2.html
and tr_blck will check that the links in these pages are
correct.

tr_blck checks the relative filesystem links.  These are
links of the form:
href="index.html"
href="../somepage.html#anchor1"
etc...

but not
href="/notchecked.html"
href="http://server.somewhere/something.html"
href="javascript:history.back();"

All tags containg relative links with  href=...,  src=...,
and background=...  are checked.

=head1 OPTIONS

B<-h> short help message

B<-a> print all links that were not checked (proto://) and
do not check for any broken links. This output can be
processed further with httpcheck.

B<-A> do not open any other files than the files given on the

B<-d> document root directory to check abs. filesystem links
e.g B<-d> /home/httpd/html

B<-r> warn about absolut links matching the given perl regexp
E.g: B<-w> \'www.linuxfocus.org|chem.pitt.edu\'
This match is not case sensitive and only applied to links
starting with proto:// (=absolut links).

B<-W> do not print warnings about html errors (not terminated
tags etc ...).

=head1 EXAMPLE

Check links in html files in the web server root directory
(/home/httpd/html) and in all directories one level down:
(cd /home/httpd/html; tr_blck *.html */*.html)

Check links in all html files on the server:
(cd  /home/httpd/html;  tr_blck  `find  . -name '*.htm*'
-print` | sort)

You  can  use  the  vim  editor  Quickfix  mode   or   the
emacs/xemacs M-x compile to parse the output of tr_blck.
Vim: :cf file_with_err_messages, :cn to go to the next message
emacs: M-x compile, compile command: cat file_with_err_messages

This gives you the possibility to open the  concerned  web
page  and  jump directly to the line where the broken link
is.  To do this you can write a Makefile that looks e.g as
follows:

all:
    tr_blck `find . -name '*.htm*' -print` | sort

=head1 AUTHOR

tr_blck is part of the HTML::TagReader package and was written by
Guido Socher 

=cut

