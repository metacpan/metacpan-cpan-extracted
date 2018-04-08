package Druid::Constants;

use strict;
use warnings;
use Exporter 'import';

use constant {

    # Granularity
    ALL                => 'all',
    NONE               => 'none',
    SECOND             => 'second',
    MINUTE             => 'minute',
    FIFTEEN_MINUTE     => 'fifteen_minute',
    THIRTY_MINUTE      => 'thirty_minute',
    HOUR               => 'hour',
    DAY                => 'day',
    WEEK               => 'week',
    MONTH              => 'month',
    QUARTER            => 'quarter',
    YEAR               => 'year',

    # Aggregators
    COUNT              => 'count',
    LONG_SUM           => 'longSum',
    DOUBLE_SUM         => 'doubleSum',
    DOUBLE_MIN         => 'doubleMin',
    DOUBLE_MAX         => 'doubleMax',
    LONG_MIN           => 'longMin',
    LONG_MAX           => 'longMax',
    DOUBLE_FIRST       => 'doubleFirst',
    DOUBLE_LAST        => 'doubleLast',
    LONG_FIRST         => 'longFirst',
    LONG_LAST          => 'longLast',

    # ArthimeticPostAggregator
    SUM                => '+',
    MINUS              => '-',
    MULTIPLY           => '*',
    DIVIDE             => '/',
    QUOTIENT           => 'quotient',

    # QueryContext
    TIMEOUT            => 'timeout',
    PRIORITY           => 'priority',
    QUERY_ID           => 'queryId',
    USE_CACHE          => 'useCache',
    POPULATE_CACHE     => 'populateCache',
    BY_SEGMENT         => 'bySegment',
    FINALIZE           => 'finalize',
    CHUNK_PERIOD       => 'chunkPeriod',
    SKIP_EMPTY_BUCKETS => 'skipEmptyBuckets',
};

our %EXPORT_TAGS = (
    Granularity => [ qw<
        ALL NONE
        SECOND
        MINUTE
        FIFTEEN_MINUTE
        THIRTY_MINUTE
        HOUR
        DAY
        WEEK
        MONTH
        QUARTER
        YEAR
    > ],

    Aggregators => [ qw<
        COUNT
        LONG_SUM
        DOUBLE_SUM
        DOUBLE_MIN
        DOUBLE_MAX
        LONG_MIN
        LONG_MAX
        DOUBLE_FIRST
        DOUBLE_LAST
        LONG_FIRST
        LONG_LAST
    > ],

    ArthimeticPostAggregator => [ qw<
        SUM
        MINUS
        MULTIPLY
        DIVIDE
        QUOTIENT
    > ],

    QueryContext => [ qw<
        TIMEOUT
        PRIORITY
        QUERY_ID
        USE_CACHE
        POPULATE_CACHE
        BY_SEGMENT
        FINALIZE
        CHUNK_PERIOD
        SKIP_EMPTY_BUCKETS
    > ],
);

$EXPORT_TAGS{'ALL'} = [ map @{$_}, values %EXPORT_TAGS ];

our @EXPORT_OK = @{ $EXPORT_TAGS{'ALL'} };

1;
