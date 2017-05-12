#! /usr/bin/perl -w

# Sometimes it's useful to change &prompt's response to a newline...

use IO::Prompt;

prompt "type something: ", -nl => '';

prompt " and something else -->", -newline => "<--\n";
