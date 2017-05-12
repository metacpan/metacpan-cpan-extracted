use strict;
use warnings;

use Test::More;

{
  package SuprLogr;
  use base 'Log::Sprintf';

  sub codes {
    return {
      c => 'coxyx',
      x => 'xylophone',
    }
  }

  sub coxyx { 'COXYX' }

  sub xylophone { 'doink' }
}


my $log_formatter = SuprLogr->new({ format => '[%c][%x] %m' });

is($log_formatter->sprintf({ message => 'GOGOGO' }), '[COXYX][doink] GOGOGO', 'overriding and defining new flags works');

done_testing;
