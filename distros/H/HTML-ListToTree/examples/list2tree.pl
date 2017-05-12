#!perl
#!/usr/bin/perl -w

use HTML::ListToTree;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case permute);

use strict;
use warnings;

my $help = 0;
my ($headlink, $title);
my $closeimg = 'closedbook.gif';
my $openimg = 'openbook.gif';
my $rootimg = 'openbook.gif';
my $outdir = './';
my $widget = 'HTML::ListToTree::DTree';
my $for_projdocs = 0;
my $noicons = 0;
my @source = ();
GetOptions(
    '-c=s' => \$closeimg,
    '-h'  => \$help,
    '-l=s' => \$headlink,
    '-n'	=> \$noicons,
    '-o=s' => \$outdir,
    '-p' => \$for_projdocs,
	'-r=s' => \$rootimg,
    '-t=s' => \$title,
    '-w=s' => \$widget,
    '-x=s' => \$openimg,
    '<>'   => sub { push @source, @_; }
);

pod2usage(1) if $help;


$/ = undef;
open(INF, $source[0]) or die "Can't open $source[0]: $!";
my $html = <INF>;
close INF;

my $index = '';

$title = $1 if (!$title) && ($html=~s/<title>([^<]+)<\/title>//s);

die "No index. "
	unless ($html=~s/<!--\s+INDEX START\s+-->\s+(.+)<!--\s+INDEX END\s+-->//s);
$index = $1;

if ($for_projdocs) {
	$html=~s/\.\.\/podstyle\.css/css\/podstyle.css/;
	$html=~s/<a\s+href="\#TOP".+?<\/a>//sg;
}

my $frame = "$outdir/$source[0]";
die "Not a valid HTML filename\n"
	unless $frame=~s/\.htm[l]?$/_frame.html/;

$headlink ||= "#TOP";

my $idx = "$outdir/$source[0]";
$idx=~s/\.htm[l]?$/_main.html/;

my $jstree = "$outdir/$source[0]";
$jstree=~s/\.htm[l]?$/_tree.html/;

my $tree = HTML::ListToTree->new(
		Text => $title, 
		Link => "$frame$headlink", 
		Source => $index,
		Widget => $widget)
	or die $@;

$tree->render(
	CloseIcon => $closeimg,
	OpenIcon => $openimg,
	RootIcon => $rootimg || $openimg,
	IconPath => "$outdir/img",
	CSSPath => "$outdir/css/tree.css",
	JSPath => "$outdir/js/tree.js",
	UseIcons => (!$noicons),
) or die $@;

foreach ($outdir, "$outdir/css", "$outdir/js", "$outdir/img") {
	die "Cannot use $outdir as directory"
		unless -d $_ || mkdir $_;
}

die $@ 
	unless $tree->writeJavascript() && $tree->writeCSS() && $tree->writeIcons();

open FRAME, ">$frame" or die "Can't open $frame: $!";
open INDEX, ">$idx" or die "Can't open $idx: $!";
open TREE, ">$jstree" or die "Can't open $jstree: $!";

print INDEX
"<html>
<head>
<title>$title</title>
</head>
<frameset cols='12%,*'>
<frame name='navbar' src='$jstree' frameborder=1>
<frame name='mainframe' src='$frame'>
</frameset>
</html>
";

close INDEX;

print FRAME $html;
close FRAME;

print TREE $tree;
close TREE;

=pod

=head1 NAME

list2tree.pl

=head1 SYNOPSIS

list2tree.pl [ options ] < sourcefile.html

 Options:
    -c closeimg    image file used for closed nodes; default 'closedbook.gif'
    -h             display this help and exit
    -l link        set tree head link to link; default '#TOP'
    -n             no icons in tree widget; default is icons on
    -o output      path of root directory where output files are written;
                      default './'
    -p             input is a Pod::ProjectDocs output file
    -r rootimg     image file used for root of tree; default is openimg
    -t title       tree head title text; default is <title> of source file;
                      enclose title in quotes if includes spaces
    -w widgetpkg   name of a Perl package implementing the widget;
                      default 'HTML::ListToTree::DTree'
    -x openimg     image file used for open nodes; default 'openbook.gif'

=head1 DESCRIPTION

Convert HTML nested lists within a source document to Javascript tree widget.

Reads input from STDIN. Input should be an HTML file with an ordered (<ol>) or 
unordered (<ul>) list (possibly nested) preceded by

	<!-- INDEX START -->

and followed by

	<!-- INDEX END -->

Outputs several files:

   <output>/sourcefile_main.html  - a frameset container
   <output>/sourcefile_frame.html - the original sourcefile.html with the nested
                                        list index removed
   <output>/sourcefile_tree.html  - the Javascripted tree widget
   <output>/css/tree.css    - CSS for the widget (if any)
   <output>/js/tree.js      - Javascript for the widget (if any)
   <output>/img/*            - icon image files (if any)   

Directories will be created as needed.

