#!/usr/bin/perl -w

# make_manifest.pl - get ready to tarball a module for CPAN
# this script expects to be in the /misc dir. It makes really clean, writes
# a /html dir from the .pm pod, writes an accurate manifest and then fixes
# up all the line endings.

use strict;
use Pod::Html;

my $backup = 0;
my $root = shift @ARGV || '../';
$root =~ tr|\\|/|;
$root = "$root/" unless $root =~ m|/$|;

make_clean($root);
my $htmldir = $root."html/";
mkdir $htmldir, 0777;      # make the html dir
unlink <$htmldir*>;        # make sure it is empty

my ( $dirs, $files ) = recurse_tree($root);
my @files;
# erase any undesirable files ie .bak, .pbp
for (@$files) {
    unlink, next if m/\.(?:pbp|bak)$/;
    push @files, $_; # add files that we don't erase
}

# write the HTML
write_file( $htmldir."docs.css", (join'',<DATA>) ); # write the css
push @files, $htmldir."docs.css";
for my $pm (grep { m/\.pm$/ && ! m/lib\b/ } @files ) {
    my $name = make_html($pm);
    push @files, $htmldir.$name;
}

# clean up after pod2html!
unlink <./pod2htm*>;

# write the MANIFEST;
unshift @files, $root.'MANIFEST';
write_file( $root."MANIFEST", (join"\n", map{ m/\Q$root\E(.*)/o ;$1 }@files) );

# fix line endings
fix_line_endings($_) for @files;

# remove all the makefile/make rubbish
sub make_clean {
    my $root = shift;
    my ($dirs, $files) = recurse_tree( $root."blib/" );
    my @dirs  = @$dirs;
    my @files = @$files;
    unlink for @files;
    # need to do longest dir paths first - must be deepest
    rmdir for sort {length $b <=> length $a }@dirs;
    my @makefiles = grep { /makefile(?!\.PL)/i } <$root*>;
    unlink for ( @makefiles, $root.'&1', $root.'pm_to_blib', $root.'MANIFEST', $root.'manifest' );
    unlink <${root}pod2htm*>;
}

# recurse the directory tree
sub recurse_tree {
    my $root = shift;
    my @files;
    my @dirs = ($root);
    for my $dir (@dirs) {
        opendir DIR, $dir or next;
        while (my $file = readdir DIR) {
          next if $file eq '.' or $file eq '..';
          next if  -l "$dir$file";
            if ( -d "$dir$file" ) {
                push @dirs,  "$dir$file/";
            }
            elsif ( -f "$dir$file" ) {
                push @files, "$dir$file";
            }
        }
        closedir DIR;
    }
  return \@dirs, \@files;
}

# clean windows line ending away
sub fix_line_endings {
    my $file = shift;
    local $/;
    open my $fh, "+<$file" or die "Can't open $file for R/W $!\n";
    binmode $fh;
    my $data = <$fh>;
    write_file( "$file.bak" , $data ) if $backup;
    $data =~ s/\015\012/\012/g;
    $data =~ s/ +\012/\012/g;
    $data =~ s/\t/    /g;
    seek $fh, 0, 0;
    truncate $fh, 0;
    print $fh $data;
    close $fh;
    $file =~ s/\Q$root\E//o;
    print "Processed $file\n";
}

# make HTML from the pod
sub make_html {
    my $file = shift;
    (my $name) = $file =~ m/([^\/\\]+)\.pm$/;
    print "Writing html/$name.html\n";
    pod2html(   "--infile=$file",
                "--header",
                "--title=$name.pm",
                "--css=${htmldir}docs.css",
                "--outfile=$htmldir$name.html",
                "--quiet" );
  return "$name.html";
}

sub write_file {
    my $file = shift;
    open F, ">$file" or die "Can't write $file: $!\n";
    print F for @_;
    close F;
}

__DATA__
BODY {
    font: small verdana, arial, helvetica, sans-serif;
    color: black;
    background-color: white;
}

A:link    {color: #0000FF}
A:visited     {color: #666666}
A:active     {color: #FF0000}

H1 {
    font: bold large verdana, arial, helvetica, sans-serif;
    color: black;
}
H2 {
    font: bold large verdana, arial, helvetica, sans-serif;
    color: maroon;
}
H3 {
    font: bold medium verdana, arial, helvetica, sans-serif;
        color: blue;
}
H4 {
    font: bold small verdana, arial, helvetica, sans-serif;
        color: maroon;
}
H5 {
    font: bold small verdana, arial, helvetica, sans-serif;
        color: blue;
}
H6 {
    font: bold small verdana, arial, helvetica, sans-serif;
        color: black;
}
UL {
    font: small verdana, arial, helvetica, sans-serif;
        color: black;
}
OL {
    font: small verdana, arial, helvetica, sans-serif;
        color: black;
}
LI {
    font: small verdana, arial, helvetica, sans-serif;
    color: black;
}
TH {
    font: small verdana, arial, helvetica, sans-serif;
    color: black;
}
TD {
    font: small verdana, arial, helvetica, sans-serif;
    color: black;
}
TD.foot {
     font: medium sans-serif;
     color: #eeeeee;
    background-color="#cc0066"
}
DL {
    font: small verdana, arial, helvetica, sans-serif;
    color: black;
}
DD {
    font: small verdana, arial, helvetica, sans-serif;
    color: black;
}
DT {
    font: small verdana, arial, helvetica, sans-serif;
        color: black;
}
CODE {
    font: Courier, monospace;
}
PRE {
    font: Courier, monospace;
}
P.indent {
    font: small verdana, arial, helvetica, sans-serif;
    color: black;
    background-color: white;
    list-style-type : circle;
    list-style-position : inside;
    margin-left : 16.0pt;
}
PRE.programlisting
{
    font-size : 9.0pt;
    list-style-type : disc;
    margin-left : 16.0pt;
    margin-top : -14.0pt;
}
INPUT {
    font: bold small verdana, arial, helvetica, sans-serif;
    color: black;
    background-color: white;
}
TEXTAREA {
    font: bold small verdana, arial, helvetica, sans-serif;
    color: black;
    background-color: white;
}
.BANNER {
    background-color: "#cccccc";
    font: bold medium verdana, arial, helvetica, sans-serif;
}

