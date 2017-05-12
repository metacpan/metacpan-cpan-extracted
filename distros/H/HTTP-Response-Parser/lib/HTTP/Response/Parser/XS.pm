package HTTP::Response::Parser::XS;

use strict;
use warnings;

our $VERSION = 0.01;
our @ISA = qw(Exporter);
our @EXPORT = qw(parse_http_response);

require XSLoader;
XSLoader::load('HTTP::Response::Parser', $VERSION);

1;
