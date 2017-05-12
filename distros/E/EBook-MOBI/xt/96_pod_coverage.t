#!perl -T

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all
    => "Test::Pod::Coverage 1.08 required for testing POD coverage"
        if $@;

plan tests => 6;

#all_pod_coverage_ok();
pod_coverage_ok('EBook::MOBI');
pod_coverage_ok('EBook::MOBI::Mhtml2Mobi');
pod_coverage_ok('EBook::MOBI::Converter');
pod_coverage_ok('EBook::MOBI::Driver');

my $nodoc = {trustme => [qr/^(begin_input|command|end_input|interior_sequence|textblock|verbatim)$/]};
pod_coverage_ok('EBook::MOBI::Driver::POD', $nodoc);
pod_coverage_ok('EBook::MOBI::Driver::Example');

