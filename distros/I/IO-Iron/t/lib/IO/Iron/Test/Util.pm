package IO::Iron::Test::Util;

use strict;
use warnings;

# Utilities for running tests

use Exporter 'import';
our @EXPORT_OK = qw(
  create_unique_queue_name
  create_unique_cache_name
  create_unique_code_package_name
);
our %EXPORT_TAGS = (
    'all' => [
        qw(
          create_unique_queue_name
          create_unique_cache_name
          create_unique_code_package_name
        )
    ],
);

use Const::Fast;
const my $QUEUE_NAME_LENGTH        => 12;
const my $CACHE_NAME_LENGTH        => 12;
const my $CODE_PACKAGE_NAME_LENGTH => 12;

use Data::UUID;

sub create_unique_queue_name {
    my $ug                = Data::UUID->new();
    my $uuid1             = $ug->create();
    my $unique_queue_name = 'TESTQUEUE_' . ( substr $ug->to_string($uuid1), 1, $QUEUE_NAME_LENGTH );

    return $unique_queue_name;
}

sub create_unique_cache_name {
    my $ug                = Data::UUID->new();
    my $uuid1             = $ug->create();
    my $unique_cache_name = 'TESTCACHE_' . ( substr $ug->to_string($uuid1), 1, $CACHE_NAME_LENGTH );

    return $unique_cache_name;
}

sub create_unique_code_package_name {
    my $ug                       = Data::UUID->new();
    my $uuid1                    = $ug->create();
    my $unique_code_package_name = 'TESTWORKER_' . ( substr $ug->to_string($uuid1), 1, $CODE_PACKAGE_NAME_LENGTH );

    return $unique_code_package_name;
}

1;
