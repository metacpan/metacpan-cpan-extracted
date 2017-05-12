
########################################################################
# Author:  Patrik Lambert (lambert@talp.ucp.es)
# Description: Provides methods to write a latex file.
#
#-----------------------------------------------------------------------
#
#  Copyright 2004 by Patrik Lambert
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
########################################################################

package Lingua::Latex;

use strict;

sub new {
    my ($pkg) = shift;   
    my $this = {};

    return bless $this,$pkg;    
}

sub startFile {
    my $this = shift;

    return '\documentclass[10pt]{article}       
\usepackage[dvips]{graphics}
\usepackage{amssymb,amsmath}
\topmargin 0pt

\headsep 0pt
\evensidemargin 0pt
\oddsidemargin \evensidemargin
\setlength{\headheight}{0cm}
\setlength{\textwidth}{17cm}
\setlength{\textheight}{24.5cm}

\begin{document}

\newcommand{\ver}[1]{\rotatebox{90}{#1}}

';
}

sub endFile {
    my $this = shift;

    return '
\end{document}
';
}

sub setTabcolsep {
    my ($this,$tabcolsep) = @_;
    return '
\tabcolsep'.$tabcolsep.'
';
}

# fromText: do the conversion from text to latex
# INPUT a string in text format 
# OUTPUT a string in latex-compatible format
sub fromText {
    my ($this,$txtString) = @_ ;
    my $line = $txtString;

  # Eliminate windows "^M" character
    $line =~ s/\//g;

  # Escape special characters
    $line =~ s/\\/{\\textbackslash}/g;
    $line =~ s/{/\\{/g;
    $line =~ s/}/\\}/g;
    $line =~ s/\\{\\textbackslash\\}/{\\textbackslash}/g;
    $line =~ s/\$/\\\$/g;
    $line =~ s/%/\\%/g;
    $line =~ s/_/\\_/g;
    $line =~ s/&/\\&/g;
    $line =~ s/\#/\\\#/g;
  
  # Ellipses
    $line =~ s/(^|[^.])\.\.\.([^.])/\1\\ldots\2/g;

  # Fix double quotes
    $line =~ s/(^|\s)\"/\1``/g;
    $line =~ s/\"(\W|$)/''\1/g;

  # Fix single quotes
    $line =~ s/(^|\s)'/\1`/g;

  # Convert return caracters
    $line =~ s/\n/\n\n/g;
#    $line =~ s/\n\n/\\\\/g;

	$line =~ s/\^/\$\\hat\{ \}\$/g; #must be before the s/ê/... 

  # Escape accents
    $line =~ s/à/\\`{a}/gi;
    $line =~ s/á/\\'{a}/gi;
    $line =~ s/ä/\\"{a}/gi;
    $line =~ s/â/\\^{a}/gi;

    $line =~ s/è/\\`{e}/gi;
    $line =~ s/é/\\'{e}/gi;
    $line =~ s/ë/\\"{e}/gi;
    $line =~ s/ê/\\^{e}/gi;

    $line =~ s/ì/\\`{i}/gi;
    $line =~ s/í/\\'{i}/gi;
    $line =~ s/ï/\\"{i}/gi;
    $line =~ s/î/\\^{i}/gi;

    $line =~ s/ò/\\`{o}/gi;
    $line =~ s/ó/\\'{o}/gi;
    $line =~ s/ö/\\"{o}/gi;
    $line =~ s/ô/\\^{o}/gi;

    $line =~ s/ù/\\`{u}/gi;
    $line =~ s/ú/\\'{u}/gi;
    $line =~ s/ü/\\"{u}/gi;
    $line =~ s/û/\\^{u}/gi;

    $line =~ s/ñ/\\~{n}/gi;

	# Escape punctuation
    $line =~ s/¿/?`/gi;
    $line =~ s/¡/!`/gi;    

  # Escape math characters
	$line =~ s/([<>]+)/\$$1\$/g;

    return $line;

}

sub fromTextFile{
	my ($this,$line) = @_;
	chomp $line;
	return $this->fromText($line)."\\\\","\n";		 	
}

1;
