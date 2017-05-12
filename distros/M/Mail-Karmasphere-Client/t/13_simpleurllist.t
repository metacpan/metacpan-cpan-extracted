use strict;
use warnings;
use blib;

use YAML;
use Test::More tests => 2;

use_ok('Mail::Karmasphere::Parser::Simple::URLList');

use IO::File;
my $io = new IO::File ("t_data/simple.urllist") or die "unable to open test data file t_data/simple.urllist\n";
# expecs to be run from the t/.. directory
 
my $parser = new Mail::Karmasphere::Parser::Simple::URLList ( fh => $io, Value => "-1000" );

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
  't' => 'url',
  'i' => 'http://foo:bar@abc.example1.com/'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'url',
  'i' => 'ftp://fred:quux@hij.example3.com/'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'url',
  'i' => 'https://sheila:jim@klm.example4.com/'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'url',
  'i' => 'http://nop.example5.com:1234/'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'url',
  'i' => 'http://qrs.example6.com/this/is/a/path'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'url',
  'i' => 'http://tuv.example7.com:4321/some/other/path'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'url',
  'i' => 'http://a:b@wxy.example8.com:567/'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'url',
  'i' => 'http://c:d@zab.example9.com:437/a/path/through/a/park'
  },
)
}
