#!/usr/bin/perl -w
use Pod::Usage;
use HTML::Menu::TreeView qw(:all);
use Getopt::Long;
use strict;
my $htdocs  = documentRoot();
my $outpath = undef;
my $style   = 'Crystal';
my $size    = 32;
my ($mod, $recursive, @modules, @r, $p, $root);
my $help       = 0;
my $sort       = 0;
my $pre        = undef;
my $Changeroot = 1;
my $result = GetOptions(
                        'module=s'   => \$mod,
                        'htdocs=s'   => \$htdocs,
                        'style=s'    => \$style,
                        'size=s'     => \$size,
                        'recursive|' => \$recursive,
                        'help|?'     => \$help,
                        'sort'       => \$sort,
                        'prefix=s'   => \$pre,
                        'store=s'    => \$outpath
                       );
$help = 1 if ((not defined $mod) && (not defined $recursive));
pod2usage(1) if $help;
sortTree(1)  if $sort;
prefix($pre) if defined $pre;
$pre     = defined $pre     ? $pre     : '';
$outpath = defined $outpath ? $outpath : $htdocs;
my %Paths;

if ($recursive) {
    foreach my $key (@INC) {
        if (-d $key) {
            $Changeroot  = 1;
            $root        = $key;
            @r           = split "", $root;
            $Paths{$key} = $key;
            push @modules, &recursive($key);
        }
    }
    documentRoot($htdocs);
    Style($style);
    size(48);
    sortTree(1);
    folderFirst(1);
    my $css  = css();
    my $tree = Tree(\@modules);
    open OUT, ">$outpath/index.html" or warn "$!";
    print OUT qq(<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Perldoc Navigation</title>
<meta name="description" content="module2treeview"/>
<meta name="author" content="Dirk Lindner"/>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"/>
<meta name="robots" content="index"/>
<meta name="revisit-after" content="30 days"/>
<link href="$pre/style/$style/48/html-menu-treeview/$style.css" rel="stylesheet" type="text/css"/>
<script language="JavaScript1.5"  type="text/javascript" src="$pre/style/treeview.js"></script>
<script language="JavaScript1.5"  type="text/javascript" src="$pre/style/$style/48/html-menu-treeview/preload.js"></script>
</head>
<body>
<table align="left" class="mainborder" cellpadding="0"  cellspacing="0" summary="mainLayout" width="100%" >
<tr>
<td align="center">$tree</td>
</tr>
</table>
</body>
</html>);
    close(OUT);

} else {
    my $pref = $mod;
    $pref =~ s/(.+)::[^:]+$/$1/;
    $pref =~ s?::?/?g;
    &module2treeview($mod, $mod, $pref);
}

sub module2treeview {
    my $module    = shift;
    my $modulname = shift;
    my $ddir      = shift;
    recursiveMkDir("$outpath/$ddir");
    my $module2path = $module;
    $module2path =~ s?::?/?g;
    my $module2html = $modulname ? $modulname : $module;
    $module2html =~ s?::?-?g;
    $module2html =~ s?/([^/])$?$1?g;
    my $infile = undef;

    if (-e $module) {
        $infile = $module;
        $module =~ s?.*/([^/]+)$?$1?;
    }
    foreach my $key (@INC) {
        if (-e $key . "/" . $module2path . ".pm") {
            $infile = $key . "/" . $module2path . ".pm";
            last;
        }
    }
    $module =~ s/\.pm//;
    my $ffsrc = "$ddir/$module" . 'frame.html';
    my @t = (
             {
              text    => $module,
              href    => $ffsrc,
              target  => 'rightFrame',
              subtree => [openTree($module, $infile, $module2html, $ddir),],
             },
            );
    if ($recursive) {
        push @t,
          {
            text   => 'Index',
            href   => "/index.html",
            target => '_parent',
          };
    }
    documentRoot($htdocs);
    Style($style);
    size($size);
    my $nsrc  = "$outpath/$ddir/$module" . 'navi.html';
    my $nnsrc = "$ddir/$module" . 'navi.html';
    open OUT, ">$nsrc" or warn "$!";
    prefix($pre) if defined $pre;
    my $tree = Tree(\@t);
    print OUT qq(<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>$module2html</title>
<meta name="description" content="$module2html"/>
<meta name="author" content="Dirk Lindner"/>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"/>
<meta name="robots" content="index"/>
<meta name="revisit-after" content="30 days"/>
<link href="$pre/style/$style/$size/html-menu-treeview/$style.css" rel="stylesheet" type="text/css"/>
<script language="JavaScript1.5"  type="text/javascript" src="$pre/style/treeview.js"></script>
<script language="JavaScript1.5"  type="text/javascript" src="$pre/style/$style/$size/html-menu-treeview/preload.js"></script>
<script language="JavaScript1.5"  type="text/javascript">
    if (parent.frames.length == 0){
      location.href = "$ddir/$module.html";
    }
</script>
</head>
<body>
<table align="left" class="mainborder" cellpadding="0"  cellspacing="0" summary="mainLayout" width="100%" >
<tr>
<td align="left" >$tree</td>
</tr>
</table>
</body>
</html>);
    close(OUT);
    my $fsrc = "$outpath/$ddir/$module" . '.html';
    open FRAME, ">$fsrc" or warn $!;
    print FRAME
      qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html>
<head>
<title>$module</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<meta name="robots" content="index">
</head>
<frameset cols="300,*">
<frame src="$nnsrc" name="navi">
<frame src="$ffsrc" name="rightFrame">
</frameset>
</html>);
    close(FRAME);
}

sub recursive {
    my $d = shift;
    my @DIR;
    chomp($d);
    opendir(IN, $d) or warn "$d $!:$/";
    my @files = readdir(IN);
    closedir(IN);
    for (my $i = 0 ; $i <= $#files ; $i++) {
        my $newFile = "$d/$files[$i]";
        unless ($files[$i] =~ /^\./) {
            my $prefix = "";
            my @fields = split "", $d;
            for (my $j = 0 ; $j <= $#fields ; $j++) {
                $prefix .= $fields[$j] if not defined $r[$j];
            }
            my $module2html = "$prefix/$files[$i]";
            $module2html =~ s/\.pm$//;
            if (   -d $newFile
                && ((not defined $Paths{$newFile}))
                && ($files[$i] ne 'auto')
                && !(is_empty($newFile))) {
                my $node = {
                            text    => $files[$i],
                            subtree => [&recursive($newFile)]
                           };
                $node->{href} = "$module2html.html" if (-e "$newFile.pm");
                push @DIR, $node;
            } else {
                if ($files[$i] =~ /^.*\.pm$/ && has_pod($newFile)) {
                    my $m = "$prefix/$files[$i]";
                    $m =~ s?(\w)/?$1::?g;
                    $m =~ s/\///g;
                    $m =~ s/\.pm$//;
                    module2treeview($newFile, $m, $prefix);
                    push @DIR,
                      {
                        text => $m,
                        href => "$module2html.html",
                      }
                      unless -d $m
                      && !-e "$outpath/$module2html.html";
                }
            }
        }
    }
    return @DIR;
}

sub has_pod {
    my $m = shift;
    use Fcntl qw(:flock);
    use Symbol;
    my $fh = gensym;
    open $fh, $m or warn "$!: $m";
    seek $fh, 0, 0;
    my @lines = <$fh>;
    close $fh;

    for (@lines) {
        return 1 if ($_ =~ /^=head1/);
    }
    return 0;
}

sub openTree {
    my ($module, $infile, $m2, $ddir) = @_;
    my @TREEVIEW;
    $module =~ s/\.pm$//;
    my $fsrc = "$outpath/$ddir/$module" . 'frame.html';
    system("pod2html --quiet --noindex --title=$module --infile=$infile  --outfile=$fsrc");
    use Fcntl qw(:flock);
    use Symbol;
    my $fh = gensym;
    open $fh, $fsrc or warn "$!: $fsrc";
    seek $fh, 0, 0;
    my @lines = <$fh>;
    close $fh;

    for (@lines) {
        if ($_ =~ /<h\d id="([^"]+)">(.+)<\/h\d>/) {
            my $href  = $1;
            my $title = $2;
            push @TREEVIEW,
              {
                text   => $title,
                href   => "$ddir/$module" . "frame.html#$href",
                target => 'rightFrame',
              };
        }
        $_ =~
          s/<body([^>]+)>/<body $1 onload="if (parent.frames.length == 0){location.href = '$ddir\/$module.html';}">/;
        $_ =~ s/<a/<a target="_parent" /gi;
    }
    open OUT, ">$fsrc" or warn "$!: $fsrc";
    print OUT @lines;
    close OUT;
    return @TREEVIEW;
}

sub is_empty {
    my ($path) = @_;
    opendir DIR, $path;
    while (my $entry = readdir DIR) {
        next if ($entry =~ /^\.\.?$/);
        closedir DIR;
        return 0;
    }
    closedir DIR;
    return 1;
}

sub recursiveMkDir {
    my $d = shift;
    my @dirs = split "/", $d;
    my $x;
    for (my $i = 0 ; $i <= $#dirs ; $i++) {
        $x = '/' if $i == 0;
        $x .= $dirs[$i] . '/' if $dirs[$i];
        mkdir $x unless -d $x;
    }
}
 __END__

=head1 NAME

module2treeview.pl

=head1 SYNOPSIS

./module2treeview.pl --recursive --htdocs=/path/to/your/document/root/  --store=/srv/www/vhosts/perldoc


module2treeview.pl --module --htdocs --style --size --recursive --help

--module=HTML::Menu::TreeView the name of the modul that should be converted.

--htdocs=/path/to/your/document/root/

--size=16|32|48|64|128 #size of the treeview images

--style=$style|simple

--sort sort the TreeView.

--recursive=1  build documentation for all Perl modules found in your path.

Be carefull with this option it will write a lot of output.

--store /path/to store/Dokumentation

dafault: htdocs path

--prefix=localpath/

--help print this message


=head1 DESCRIPTION

modul2treeview converts the pod from a Perl modul to a frame based html Documentation

which makes usage of HTML::Menu::TreeView.

=head1 Changes

0.2.4

Fixed pod parser

=head1 AUTHOR

Dirk Lindner <dirk.lze@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2019 by Hr. Dirk Lindner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation;
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

=cut
