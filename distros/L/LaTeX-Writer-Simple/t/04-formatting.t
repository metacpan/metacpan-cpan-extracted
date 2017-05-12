#!/usr/bin/perl

use strict;
use warnings;
use LaTeX::Writer::Simple;
use Test::More tests => 6;

is(textit("foo"),"\\textit{foo}","Test textit");
is(textbf("foo"),"\\textbf{foo}","Test textbf");
is(texttt("foo"),"\\texttt{foo}","Test textrt");

is(it("foo"),textit("foo"),"Test it/textit");
is(bf("foo"),textbf("foo"),"Test bf/textbf");
is(tt("foo"),texttt("foo"),"Test tt/texttt");