use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use version();

plan tests => 4;

my @mn = qw/
    Log::Log4perl::Appender::Elasticsearch
    Log::Log4perl::Appender::Elasticsearch::Bulk
    /;

my $v = version->parse("0.09");

foreach my $n (@mn) {
    use_ok($n);
    my $_v = eval '$' . $n . '::VERSION';
    diag("Testing $n $v, Perl $], $^X");
    is($_v, $v, "$n version is $v");
} ## end foreach my $n (@mn)

