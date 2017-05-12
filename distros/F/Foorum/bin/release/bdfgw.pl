#!/usr/bin/perl

######################
# Build Docs From GoogleCode wiki
######################

use strict;
use warnings;
use Text::GooglewikiFormat;
use Pod::From::GoogleWiki;
use FindBin qw/$Bin/;
use Cwd qw/abs_path/;
use File::Copy;
use File::Spec;

my $trunk_dir = abs_path( File::Spec->catdir( $Bin,       '..', '..' ) );
my $wiki_dir  = abs_path( File::Spec->catdir( $trunk_dir, '..', 'wiki' ) );
my $project_url = 'http://code.google.com/p/foorum';

my @filenames = (
    'README',          'INSTALL',    'Configure', 'I18N',
    'TroubleShooting', 'AUTHORS',    'RULES',     'HowRSS',
    'Tutorial1',       'Tutorial2',  'Tutorial3', 'Tutorial4',
    'Tutorial5',       'PreRelease', 'Upgrade'
);

my %tags = %Text::GooglewikiFormat::tags;
my $pfg  = Pod::From::GoogleWiki->new();

# replace link sub
my $linksub = sub {
    my ( $link, $opts ) = @_;
    $opts ||= {};

    my $ori_text = $link;
    ( $link, my $title )
        = Text::GooglewikiFormat::find_link_title( $link, $opts );
    ( $link, my $is_relative )
        = Text::GooglewikiFormat::escape_link( $link, $opts );
    unless ($is_relative) {
        return qq|<a href="$link" rel="nofollow">$title</a>|;
    } elsif (
        grep {
            $link eq $_
        } @filenames
        ) {
        return qq|<a href="$link\.html">$ori_text</a>|;
    } else {
        return $ori_text;
    }
};
$tags{link} = $linksub;

my $indexpage;

# build in trunk/docs dir
foreach my $filename (@filenames) {
    {
        local $/;
        open( my $fh, '<',
            File::Spec->catfile( $wiki_dir, "$filename\.wiki" ) )
            or do {
            print "Skip $filename\n";
            next;
            };
        flock( $fh, 1 );
        my $string = <$fh>;
        close($fh);
        my $org_string = $string;    # back for later to POD
        $string =~ s/&/&amp;/gs;
        $string =~ s/>/&gt;/gs;
        $string =~ s/</&lt;/gs;
        my $html = Text::GooglewikiFormat::format( $string, \%tags );
        buildhtml( $filename, $html );

        $indexpage .= qq~<li><a href="$filename\.html">$filename</a></li>~;

        if (   'AUTHORS' eq $filename
            or 'README'  eq $filename
            or 'INSTALL' eq $filename ) {

            # convert to Pod

            # change build-in links
            foreach my $f (@filenames) {
                $org_string =~ s/\[$f\]/\[Foorum\:\:Manual\:\:$f\]/isg;
            }
            my $pod = $pfg->wiki2pod($org_string);

            open( my $fh2, '>',
                File::Spec->catfile( $trunk_dir, $filename ) );
            print $fh2 "\n=pod\n$pod\n\n=cut\n";
            close($fh2);
        }
    }
}

buildhtml( 'index', qq~<ul>$indexpage</ul>~ );

sub buildhtml {
    my ( $filename, $html ) = @_;

    my $wiki_url = "$project_url/wiki/$filename";
    $wiki_url = 'http://code.google.com/p/foorum/w/list'
        if ( 'index' eq $filename );

    $html = <<HTML;
<html>
<head>
<title>$filename</title>
<link type="text/css" rel="stylesheet" href="static/d_20071112.css" />
<!--[if IE]>
<link type="text/css" rel="stylesheet" href="static/d_ie.css" />
<![endif]--> 
</head>
<body class="t6">
<div id="wikicontent">
$html
</div>
<h1>WHERE TO GO NEXT</h1>
<ul>
<li>Get the lastest version from <a href="$wiki_url">$wiki_url</a></li>
<li><a href="index.html">Index Page</a></li>
</ul>
<script src="static/prettify.js"></script>
<script>
 prettyPrint();
</script>
</body>
</html>
HTML
    open( my $fh, '>',
        File::Spec->catfile( $trunk_dir, 'docs', "$filename\.html" ) );
    flock( $fh, 2 );
    print $fh $html;
    close($fh);
    print "format $filename OK\n";
}

1;
