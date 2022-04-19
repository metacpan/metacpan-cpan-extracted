use strict;
use warnings;

use Test::More tests => 6;

use_ok('Getopt::optparse', 'Loaded Getopt::optparse');
ok( my $parser = Getopt::optparse->new(), 'Can create instance of Getopt::optparse');
isa_ok( $parser, 'Getopt::optparse' );
ok($parser->add_option('--hostname', {dest => 'hostname', default => 'localhost', help => 'Remote hostname'}), 'Can add_option');
ok(my $options = $parser->parse_args(), 'Can parse_args');
cmp_ok($options->{hostname}, 'eq', 'localhost', 'Can pass default');
