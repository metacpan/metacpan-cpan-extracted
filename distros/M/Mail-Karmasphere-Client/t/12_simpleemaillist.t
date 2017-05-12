use strict;
use warnings;
use blib;

use YAML;
use Test::More tests => 2;

use_ok('Mail::Karmasphere::Parser::Simple::EmailList');

use IO::File;
my $io = new IO::File ("t_data/simple-emaillist.txt") or die "unable to open test data file t_data/simple-emaillist.txt\n";
# expecs to be run from the t/.. directory
 
my $parser = new Mail::Karmasphere::Parser::Simple::EmailList ( fh => $io, Value => "-1000" );

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
  't' => 'email',
  'i' => 'fred@nowhere.net'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'email',
  'i' => '@everywhere.com'
  },
{
  'v' => '-1000',
  's' => '0',
  't' => 'email',
  'i' => 'foo@bar.com'
  },
)
}
