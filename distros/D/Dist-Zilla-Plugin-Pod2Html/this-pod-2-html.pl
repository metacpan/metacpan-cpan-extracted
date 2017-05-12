#!/usr/bin/perl
#
#   Usage: ./this-pod-2-html.pl
#
#    OR (better)
#          dzil run ./this-pod-2-html.pl
#
#       (this take longer but it is better because it uses the POD
#       input from a file that was already munged by the Dist::Filla
#       file mungers, e.g. it has a NAME and VERSION section)
#
#   Make an HTML documentation from a POD-containing file, adding some
#   CSS-style declaration in order to get the same/similar look&feel
#   as the HTML documentation on CPAN site.
#
#   Martin Senger <martin.senger@gmail.com>
#   March 2012
# -----------------------------------------------------------------

use warnings;
use strict;
use Pod::Simple::HTML;

# ----------------------------------------------------------------------
# Edit these if you want to copy/paste this script to a different
# project:
my $doc_input_file = 'lib/Dist/Zilla/Plugin/Pod2Html.pm';
my $doc_output_file = 'Pod2Html.html';
# ----------------------------------------------------------------------

use Cwd;
my $dir = getcwd;
my $outfile;
if ($dir =~ m{/.build/}) {
    # we are running this script from within 'dzil run...'
    $outfile = "../../$doc_output_file";
} else {
    # we are running this script directly
    $outfile = $doc_output_file;
}

# CSS-style to be added to the result
my @style = <DATA>;
my $style = join ("", @style);

# make the POD to HTMl conversion
my $p = Pod::Simple::HTML->new;
$p->index (1);
$p->html_css ("\n$style\n");
$p->output_string (\my $result);
$p->parse_file ($doc_input_file);
open my $out, '>', $outfile or die "Cannot create '$outfile': $!\n";
print $out $result;

__DATA__
<style type="text/css">
 <!--/*--><![CDATA[/*><!--*/
BODY {
  background: white;
  color: black;
  font-family: arial,sans-serif;
  margin: 0;
  padding: 1ex;
}

A:link, A:visited {
  background: transparent;
  color: #006699;
}

A[href="#POD_ERRORS"] {
  background: transparent;
  color: #FF0000;
}

DIV {
  border-width: 0;
}

DT {
  margin-top: 1em;
  margin-left: 1em;
}

.pod { margin-right: 20ex; }

.pod PRE     {
  background: #eeeeee;
  border: 1px solid #888888;
  color: black;
  padding: 1em;
  white-space: pre;
}

.pod H1      {
  background: transparent;
  color: #006699;
  font-size: large;
}

.pod H1 A { text-decoration: none; }
.pod H2 A { text-decoration: none; }
.pod H3 A { text-decoration: none; }
.pod H4 A { text-decoration: none; }

.pod H2      {
  background: transparent;
  color: #006699;
  font-size: medium;
}

.pod H3      {
  background: transparent;
  color: #006699;
  font-size: medium;
  font-style: italic;
}

.pod H4      {
  background: transparent;
  color: #006699;
  font-size: medium;
  font-weight: normal;
}

.pod IMG     {
  vertical-align: top;
}

.pod .toc A  {
  text-decoration: none;
}

.pod .toc LI {
  line-height: 1.2em;
  list-style-type: none;
}

  /*]]>*/-->
</style>
