#!/usr/bin/env perl
use warnings;
use strict;
use Hash::Rename;
use Test::More;
use Test::Exception;
use Test::Differences;

sub test_rename {
    my %args = @_;
    my %hash = (
        '-noforce' => 1,
        scheme     => 'http',
        enjoy      => { yapc => 2014 },
    );
    hash_rename %hash, %args;
    wantarray ? %hash : \%hash;
}
eq_or_diff
  scalar(test_rename(prepend => '-')),
  { '--noforce' => 1, '-scheme' => 'http', '-enjoy' => { yapc => 2014 } },
  'prepend dash';
eq_or_diff
  scalar(test_rename(append => '=')),
  { '-noforce=' => 1, 'scheme=' => 'http', 'enjoy=' => { yapc => 2014 } },
  'append equal sign';
eq_or_diff
  scalar(test_rename(prepend => '-', append => '=')),
  { '--noforce=' => 1, '-scheme=' => 'http', '-enjoy=' => { yapc => 2014 } },
  'prepend and append';
eq_or_diff
  scalar(test_rename(code => sub { s/^(?!-)/-/ })),
  { '-noforce' => 1, '-scheme' => 'http', '-enjoy' => { yapc => 2014 } },
  'code';
eq_or_diff
  scalar(test_rename(code => sub { $_ = 'foo' })),
  { foo => 'http' },
  'code producing duplicates, no strict';
eq_or_diff
  scalar(test_rename(append => '=', recurse => 1)),
  { '-noforce=' => 1, 'scheme=' => 'http', 'enjoy=' => { 'yapc=' => 2014 } },
  'append equal sign recursively';
throws_ok {
    is_deeply(
        scalar(test_rename(strict => 1, code => sub { $_ = 'foo' })),
        { foo => 'http' },
        'code producing duplicates',
    );
}
qr/duplicate result key \[foo\] from original key \[(scheme|enjoy)\]/,
  'code producing duplicates, with strict';
done_testing;
