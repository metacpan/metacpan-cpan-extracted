use strict;
use warnings;
use blib;

use YAML;
use Test::More tests => 2;

use_ok('Mail::Karmasphere::Parser::RBL::Mixed');

# 20061109-22:10:46 mengwong@newyears-wired:~/src/Mail-Karmasphere-Client/trunk% DEBUG=1 perl -Mlib=lib ./karma-publish --magic=RBL::Mixed --file ~/src/karma/src/tests/data/master/mixed-rbl.txt
# returning Record: identity=203.230.186.163; value=-31337; additional=listed; stream=0
# returning Record: identity=209.67.220.164; value=-31337; additional=listed; stream=0
# returning Record: identity=66.246.225.167; value=-31337; additional=listed; stream=0
# returning Record: identity=16dsurf.com; value=-31337; additional=listed; stream=1
# returning Record: identity=16incher.com; value=-31337; additional=listed; stream=1
# returning Record: identity=1728j.net; value=-31337; additional=listed; stream=1
# returning Record: identity=210.3.43.177; value=-31337; additional=listed; stream=0
# returning Record: identity=72.9.255.178; value=-31337; additional=listed; stream=0
# returning Record: identity=1800refinowok.com; value=-31337; additional=listed; stream=1
# returning Record: identity=1800sensuals.info; value=-31337; additional=listed; stream=1
# returning Record: identity=1800studstuff.info; value=-31337; additional=listed; stream=1
# returning Record: identity=6.45.123; value=-31337; additional=listed; stream=0
# 20061109-22:11:05 mengwong@newyears-wired:~/src/Mail-Karmasphere-Client/trunk%

use IO::File;
my $io = new IO::File ("t_data/mixed-rbl.txt") or die "unable to open test data file t_data/mixed-rbl.txt\n";
# expecs to be run from the t/.. directory
 
my $parser = new Mail::Karmasphere::Parser::RBL::Mixed ( fh => $io, Value => "-1000" );

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
  'i' => '203.230.186.163'
},
{
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '209.67.220.164'
},
{
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '66.246.225.167'
},
{
  'v' => '-1000',
  's' => '1',
  't' => 'domain',
  'i' => '16dsurf.com'
},
{
  'v' => '-1000',
  's' => '1',
  't' => 'domain',
  'i' => '16incher.com'
},
{
  'v' => '-1000',
  's' => '1',
  't' => 'domain',
  'i' => '1728j.net'
},
{
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '210.3.43.177'
},
{
  'v' => '-1000',
  's' => '0',
  't' => 'ip4',
  'i' => '72.9.255.178'
},
{
  'v' => '-1000',
  's' => '1',
  't' => 'domain',
  'i' => '1800refinowok.com'
},
 {
   'v' => '-1000',
   's' => '1',
   't' => 'domain',
   'i' => '1800sensuals.info'
 },
 {
   'v' => '-1000',
   's' => '1',
   't' => 'domain',
   'i' => '1800studstuff.info'
 },
 {
   'v' => '-1000',
   's' => '0',
   't' => 'ip4',
   'i' => '6.45.123'
 })
}
