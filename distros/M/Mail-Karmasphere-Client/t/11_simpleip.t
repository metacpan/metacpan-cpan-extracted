use strict;
use warnings;
use blib;

use YAML;
use Test::More tests => 2;

use_ok('Mail::Karmasphere::Parser::Simple::IPList');

use IO::File;
my $io = new IO::File ("t_data/ad.txt") or die "unable to open test data file t_data/bogons.cymru.com\n";
# expecs to be run from the t/.. directory
 
my $parser = new Mail::Karmasphere::Parser::Simple::IPList ( fh => $io, Value => "-1000" );

my @got_back;

while (my $record = $parser->parse) {
    push @got_back, $record;
}

is(Dump(@got_back),
   Dump(expected()));

sub expected {
    map { bless($_, "Mail::Karmasphere::Parser::Record") }
({
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '85.94.160.0-85.94.163.255'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '85.94.164.0-85.94.167.255'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '85.94.168.0-85.94.175.255'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '85.94.176.0-85.94.191.255'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '194.158.64.0-194.158.95.255'
  })
}
