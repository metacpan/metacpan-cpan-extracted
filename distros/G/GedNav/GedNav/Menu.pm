package GedNav::Menu;

use strict;

use File::Basename;

# Define external interface
use Exporter;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
@ISA = qw( Exporter );
($VERSION) = ('$Revision: 1.1.1.1 $' =~ / ([\d\.]+) \$$/);

# Always exported into callers namespace
@EXPORT = qw(
        gednav_menu
);

# Externally visible if specified
@EXPORT_OK = qw(
);

sub gednav_menu
{
   my $report = shift;
   my $indi = shift;

   my $html = '';

   $html .= sprintf("<h3>Gedcom Dataset: %s</h3>Last modified %s<p>",
	$indi ? basename($indi->dataset) . ".ged" : '',
	$indi ? $indi->gedcom->lastmod : '',
	);

   $html .= "<a href=\"\">Top</a><br>\n";

#   $html .= "<a href=\"surnames\">Surname Index</a><br>\n";

   $html .= sprintf("<a href=\"surname?choice=%s\">Individuals with surname %s</a><br>\n",
        $indi->surname,
        $indi->surname,
	) if ($indi);

#   $html .= sprintf("<a href=\"list?soundex=%s\">All with the same Soundex</a><br>\n",
#        soundex($indi->surname));

   $html .= sprintf("<a href=\"outline?indi=%s\">Outline Descendant Tree</a><br>\n",
        $indi->code,
        ) if ($report !~ /outline/i && $indi && $indi->fams);

   $html .= sprintf("<a href=\"register?indi=%s\">Descendant Register Report</a><br>\n",
        $indi->code,
        ) if ($report !~ /register/i && $indi && $indi->fams);

   $html .= "<hr>\n";

}

1;
