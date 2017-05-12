#!perl

use strict;
use warnings;

use FindBin;
use File::Spec::Functions;

use lib catdir($FindBin::Bin, updir, updir, 'lib');

use FCGI::Engine;

{
    package Bar;
    sub handler { () }
}

FCGI::Engine->new_with_options(handler_class => 'Bar')->run;