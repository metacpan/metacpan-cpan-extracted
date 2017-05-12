#!/usr/bin/perl
# stupidly minimal Froody dispatch CGI script, mostly as an example, but
# you can call it from the command line as
#
#   perl bin/froody.pl method=test&test=foo
#
# if you want,

use warnings;
use strict;
use Froody::Server;
Froody::Server->dispatch()
