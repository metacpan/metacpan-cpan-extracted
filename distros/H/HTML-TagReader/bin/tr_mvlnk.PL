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
use vars qw($opt_v $opt_c $opt_a $opt_h);
use Getopt::Std;
use HTML::TagReader;
#
sub help();
sub expandonefile($$);
sub dirname($);
sub linktype($);
#
getopts("hcav")||die "ERROR: No such option. -h for help.\n";
help() if ($opt_h);
help() unless ($ARGV[1]);
my $expr;
($expr=shift)||help();
my $changecount=0;
my $mode;
for my $f (@ARGV){
    if ( -r "$f" ){
        $mode=(stat(_))[2];
        rename($f,"$f.bak")||die "ERROR: can not rename $f to $f.bak, check directory permissions.\n";
        $changecount=expandonefile("$f.bak",$f);
        print STDERR "$f:1: $changecount links changed\n\n";
        if ($changecount){
            chmod($mode,$f)||die "ERROR: chmod %o $f failed\n";
        }else{
            # undo
            unlink("$f")||die "ERROR: unlink $f failed\n";
            rename("$f.bak",$f)||die "ERROR: can not undo rename $f.bak to $f, check directory permissions.\n";
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
    my ($tagnospace,$ckpath,$path,$dir,$ltype,$origpath,$line,$found,$v);

    my $p=new HTML::TagReader "$infile";
    open(OUT,">$outfile")||die "ERROR: can not write $outfile\n";
    while(@tag = $p->getbytoken($opt_v)){
        # read out the tags:
        if($tag[1] eq ""){
            print OUT $tag[0];
            next;
        } 
        $line=$tag[2];
        if($tag[1] eq "!--"){
            # ignore comments unless opt_c is set:
            if (!$opt_c){
                print OUT $tag[0];
                next;
            }
        }else{ 
            if (!$opt_a){
                # we search for " href", " src", " background": 
                unless($tag[0]=~/\ssrc\s*=|\shref\s*=|\sbackground\s*=/i){
                    print OUT $tag[0];
                    next;
                }
            } 
        }
        $tagnospace=$tag[0];
        # decode URL encoding:
        $tagnospace=~tr/+/ /;
        $tagnospace=~s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $tagnospace=~s/\s+/ /g; # kill newline and double space
        $_=$tagnospace;
        eval $expr;
        if ($@){
            warn $@;
            $_=$tagnospace; # restore any messed up data in case of syntax error
        }
        if ($tagnospace ne $_){
            print OUT $_;
            $count++;
            print "$infile:$line: $tagnospace -\> $_\n";
        }else{
            # no change
            print OUT $tag[0];
        }
    }
    close OUT;
    return($count);
}
#----------------------------------
sub help(){
print "tr_mvlnk -- modify tags in html files with perl
commands.

USAGE: tr_mvlnk [-hacv] perlexpr html-files

tr_mvlnk provides the tags in html code in \$_ to perlexpr
and modifies the tags according to the perlexpr.
The original files are backed-up to filename.bak

Spaces, tabs and newline are removed from the tag and replaced
by just one space. This is to make it easier for the perlexpr.

OPTIONS: 
     -a include all tags. Normally only tags that contain links
     (e.g <a href=... and not <p> </p>) are passed to the perlexpr.
     That is all tags with href=, src= or background=. With this
     option set you can modify any tag.

     -h this help

     -c includes comments. Normally comment tags are not passed
     to perlexpr. With this option set you can modify also comments.

     -v verbous messages about html errors.

EXAMPLES: 
     Change links to tldp.org/linuxfocus to linuxfocus.org:
     tr_mvlnk 's|tldp.org/linuxfocus|linuxfocus.org|' index.html

tr_mvlnk is part of the HTML::TagReader package.

version $VERSION
         \n";
exit(0);
}
__END__ 

=head1 NAME

tr_mvlnk -- modify tags in html files with perl commands.

=head1 SYNOPSIS

USAGE: tr_mvlnk [-hacv] perlexpr html-files

=head1 DESCRIPTION

tr_mvlnk provides the tags in html code in \$_ to perlexpr
and modifies the tags according to the perlexpr.
The original files are backed-up to filename.bak

Spaces, tabs and newline are removed from the tag and replaced
by just one space. This is to make it easier for the perlexpr.

=head1 OPTIONS

B<-a> include all tags. Normally only tags that contain links
(e.g E<lt>a href=... and not E<lt>pE<gt> E<lt>/pE<gt>) are passed to the perlexpr.
That is all tags with href=, src= or background=. With this
option set you can modify any tag.

B<-h> this help

B<-c> includes comments. Normally comment tags are not passed
to perlexpr. With this option set you can modify also comments.

B<-v> verbous messages about html errors.

=head1 EXAMPLE

Change links to tldp.org/linuxfocus to linuxfocus.org:
tr_mvlnk 's|tldp.org/linuxfocus|linuxfocus.org|' index.html

=head1 AUTHOR

xlnk is part of the HTML::TagReader package and was written by
Guido Socher [guido(at)linuxfocus.org]

=cut
