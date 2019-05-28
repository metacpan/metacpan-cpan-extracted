#!/usr/bin/perl -w
use lib qw(lib);
use CGI;
use strict;
use HTML::Menu::TreeView;
my $q        = new CGI;
my $TreeView = new HTML::Menu::TreeView();
my $subfolder =
  defined $q->param('subfolder')
  ? $q->param('subfolder')
  : $TreeView->documentRoot() . "/";
my $style = $q->param('style')        ? $q->param('style') : 'Crystal';
my $size  = defined $q->param('size') ? $q->param('size')  : 16;
my @tree  = recursiveReadDir($subfolder);
$TreeView->Style($style);
$TreeView->columns(
    $q->a(
        {
            href  => "./columns.pl?style=$style&amp;size=$size&amp;sort=1",
            class => "treeviewLink$size"
        },
        'Name'
      )
      . '&#160;',
    $q->a(
        {
            href  => "./columns.pl?style=$style&amp;size=$size&amp;byColumn=0",
            class => "treeviewLink$size"
        },
        'Size'
      )
      . '&#160;',
    $q->a(
        {
            href  => "./columns.pl?style=$style&amp;size=$size&amp;byColumn=1",
            class => "treeviewLink$size"
        },
        'Permission'
      )
      . '&#160;',
    $q->a(
        {
            href  => "./columns.pl?style=$style&amp;size=$size&amp;byColumn=2",
            class => "treeviewLink$size"
        },
        'Last Modified'
      )
      . '&#160;'
);

if ( defined $q->param('byColumn') ) {
    $TreeView->orderByColumn( $q->param('byColumn') );
} elsif ( $q->param('sort') ) {
    $TreeView->sortTree(1);
} ## end elsif ( $q->param('sort'))
$TreeView->size($size);
$TreeView->border(1);
$TreeView->clasic(1) if ( defined $q->param('clasic') );
my $zoom = $q->div(
    { style => "font-size:$size px;" },
    $q->a(
        {
            href  => './columns.pl?style=Crystal&amp;size=16',
            class => "treeviewLink$size"
        },
        '16'
      )
      . '&#160;|&#160;'
      . $q->a(
        {
            href  => './columns.pl?style=Crystal&amp;size=22',
            class => "treeviewLink$size"
        },
        '22'
      )
      . '&#160;|&#160;'
      . $q->a(
        {
            href  => './columns.pl?style=Crystal&amp;size=32',
            class => "treeviewLink$size"
        },
        '32'
      )
      . '&#160;|&#160;'
      . $q->a(
        {
            href  => './columns.pl?style=Crystal&amp;size=48',
            class => "treeviewLink$size"
        },
        '48'
      )
      . '&#160;|&#160;'
      . $q->a(
        {
            href  => './columns.pl?style=Crystal&amp;size=64',
            class => "treeviewLink$size"
        },
        '64'
      )
      . '&#160;|&#160;'
      . $q->a(
        {
            href  => './columns.pl?style=Crystal&amp;size=64',
            class => "treeviewLink$size"
        },
        '128'
      )
      . '&#160;|&#160;'
      . $q->a(
        {
            -href  => './columns.pl?style=simple&amp;size=16',
            -class => "treeviewLink$size"
        },
        'simple'
      )
);
print( $q->header,
    $q->start_html(
        -title  => 'Columns',
        -script => $TreeView->jscript() . $TreeView->preload(),
        -style  => { -code => $TreeView->css() },
    ),
    $q->div( { align => 'center' }, $zoom . $q->br() . $TreeView->Tree( \@tree ) ),
    $q->end_html
);

sub recursiveReadDir {
    my $dir = shift;
    chomp($dir);
    opendir( DIR, "$dir" ) or die ":$dir $!";
    my @files = readdir(DIR);
    closedir(DIR);
    my @t;
    for ( my $i = 0 ; $i <= $#files ; $i++ ) {
        unless ( $files[$i] =~ /^\./ ) {
            use File::stat;
            my $sb = stat( $dir . $files[$i] );
            unless ( -d $dir . $files[$i] ) {
                push @t,
                  {
                    text    => $files[$i],
                    columns => [ sprintf( "%s", $sb->size ), sprintf( "%04o", $sb->mode & 07777 ), sprintf( "%s", scalar localtime $sb->mtime ) ],
                  };
            } else {
                my @st = recursiveReadDir("$dir$files[$i]/");
                push @t,
                  {
                    text    => "$files[$i]",
                    subtree => [@st],
                    href    => "./columns.pl?style=$style&amp;size=$size&amp;subfolder=$dir$files[$i]/",
                    columns => [ sprintf( "%s", $sb->size ), sprintf( "%04o", $sb->mode & 07777 ), sprintf( "%s", scalar localtime $sb->mtime ) ]
                  };
            } ## end else
        } ## end unless ( $files[$i] =~ /^\./)
    } ## end for ( my $i = 0 ; $i <=...)
    return @t;
} ## end sub recursiveReadDir
1;
