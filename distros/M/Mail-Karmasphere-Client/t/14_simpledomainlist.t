use strict;
use warnings;
use blib;

use YAML;
use Test::More tests => 2;

use_ok('Mail::Karmasphere::Parser::Simple::DomainList');

use IO::File;
my $io = new IO::File ("t_data/simple.domainlist") or die "unable to open test data file t_data/simple-emaillist.txt\n";
# expecs to be run from the t/.. directory
 
my $parser = new Mail::Karmasphere::Parser::Simple::DomainList ( fh => $io, Value => "-1000" );

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
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'hotmail.com'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'yahoo.com'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'aol.com'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'lists.ieeesb.etsit.upm.es'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'wipro.com'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'comcast.net'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'msn.com'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'uol.com.br'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'atento.com.br'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'earthlink.net'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'sbcglobal.net'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'yahoo.com.br'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'customerfocusservices.com'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'cox.net'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'domain',
  'i' => 'ig.com.br'
},
)

}

