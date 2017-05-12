#!perl

use lib 'lib';
use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok( 'Getopt::Declare' ); }


# Build parser
my $spec = q{
	-a <aval>		option 1
};
ok my $config = Getopt::Declare->new($spec, -BUILD), 'build the parser';

# Get parser code
ok my $code = $config->code();

# Parse arguments
@ARGV = ( '-aA' );
ok $config->parse();
is $config->{'-a'}, 'A';

