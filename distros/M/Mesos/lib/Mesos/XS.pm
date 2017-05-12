package Mesos::XS;
use strict;
use warnings;
use Mesos ();
use Scalar::Util qw(looks_like_number);
use XSLoader;
use parent 'Exporter';

Mesos::trace(split '=', $ENV{PERL_MESOS_TRACE}//'QUIET');

XSLoader::load('Mesos');

1;
