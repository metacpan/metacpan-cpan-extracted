use strict;
use warnings;
use blib;

use YAML;
use Test::More tests => 2;

use_ok('Mail::Karmasphere::Parser::RBL::SimpleIP');

use IO::File;
my $io = new IO::File ("t_data/rbl.simpleip") or die "unable to open test data file t_data/mixed-rbl.txt\n";
# expecs to be run from the t/.. directory
 
my $parser = new Mail::Karmasphere::Parser::RBL::SimpleIP ( fh => $io, Value => "-1000" );

my @got_back;

while (my $record = $parser->parse) {
    push @got_back, $record;
}

is(Dump(@got_back),
   Dump(expected()));

sub expected {
    map { bless($_, "Mail::Karmasphere::Parser::Record") }
(


{
  'd' => 'Blocked by Admin Request See: http://www.sorbs.net/lookup.shtml?$',
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '127.0.0.2'
},
{
  'd' => 'Dynamic IP Addresses See: http://www.sorbs.net/lookup.shtml?$',
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '127.0.0.2'
},
{
  'd' => 'Dynamic IP Addresses See: http://www.sorbs.net/lookup.shtml?$',
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '0.214.192.0/19'
},
{
  'd' => 'Dynamic IP Addresses See: http://www.sorbs.net/lookup.shtml?$',
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '0.43.57.0/24'
},
{
  'd' => 'Dynamic IP Addresses See: http://www.sorbs.net/lookup.shtml?$',
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '0.43.58.0/24'
},
{
  'd' => 'Dynamic IP Addresses See: http://www.sorbs.net/lookup.shtml?$',
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '0.43.59.0/24'
},
{
  'd' => 'Dynamic IP Addresses See: http://www.sorbs.net/lookup.shtml?$',
  'v' => '+1000',
  's' => '0',
  't' => 'ip4',
  'i' => '12.1.235.0/24'
},
{
  'd' => 'Dynamic IP Addresses See: http://www.sorbs.net/lookup.shtml?$',
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '12.10.110.0/25'
},
{
  'd' => 'Dynamic IP Addresses See: http://www.sorbs.net/lookup.shtml?$',
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '12.10.110.128/26'
},

)
}

