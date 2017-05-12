#!/usr/bin/perl

use strict;
use warnings;
use LaTeX::Writer::Simple qw/_c _e p/;
use Test::More tests => 7;

is(_e("center","foo"), "\\begin{center}\nfoo\n\\end{center}", "Environment abbrev");

is(_c("alpha"), "\\alpha", "Command without arguments");
is(_c("textit","foo bar"), "\\textit{foo bar}", "Command with one argument");
is(_c("includegraphics",["width=\\textwidth"],"foo"),
   "\\includegraphics[width=\\textwidth]{foo}",
    "Command with optional arguments");
    
is(p("ola"), "ola\n\n", "Paragraph command, one string");
is(p("um\ndois\ntres\n"), "um\ndois\ntres\n\n\n", "Paragraph command, one multiline string");
is(p("um\ndois\ntres\n","quatro\ncinco."),
     "um\ndois\ntres\n\n\nquatro\ncinco.\n\n", "Paragraph command, two strings");