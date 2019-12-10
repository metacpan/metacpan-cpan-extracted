use strict;
use warnings;
use utf8;
use v5.24;

use Test::More;

my $package;

BEGIN {
  $package = 'Digest::QuickXor';
  use_ok $package or exit;
}

note 'Functions';
my @functions = qw|quickxorhash|;
can_ok $package, $_ for @functions;

is_deeply \@Digest::QuickXor::EXPORT_OK, \@functions, 'All functions exported';

note 'Calculate digest';
my $qx   = $package->can('quickxorhash');
my @data = ('A ', 'short', ' text');
is $qx->(@data), 'QQDBHNDwBjnQAQR0JAMe6AAAAAA=', 'Digest for text';

done_testing();
