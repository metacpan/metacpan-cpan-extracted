use strict;
use warnings;

use XML::LibXML;
use MARC::File::XML;
use Scalar::Util qw/refaddr/;
use Test::More tests => 3;

MARC::File::XML->set_parser('abc'); # pass an intentionally bogus parser
ok(!defined($MARC::File::XML::parser), 'cannot feed it a bogus parser');

my $external_parser = XML::LibXML->new();
MARC::File::XML->set_parser($external_parser);
ok(defined($MARC::File::XML::parser), 'gave it a parser');
ok(refaddr($external_parser) == refaddr($MARC::File::XML::parser), 'gave it a parser');
