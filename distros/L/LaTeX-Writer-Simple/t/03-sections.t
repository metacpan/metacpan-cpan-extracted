#!/usr/bin/perl

use strict;
use warnings;
use LaTeX::Writer::Simple;
use Test::More tests => 5;

is(section("foo"),"\\section{foo}\n", "Section command");    
is(chapter("foo"),"\\chapter{foo}\n", "Chapter command");    
is(part("foo"),"\\part{foo}\n", "Part command");    
is(subsection("foo"),"\\subsection{foo}\n", "Subsection command");    
is(subsubsection("foo"),"\\subsubsection{foo}\n", "Subsubsection command");    
