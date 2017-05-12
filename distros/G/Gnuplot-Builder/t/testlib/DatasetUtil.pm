package testlib::DatasetUtil;
use strict;
use warnings FATAL => "all";
use Test::Builder;
use Test::Identity;
use Exporter qw(import);

our @EXPORT_OK = qw(get_data_and_count get_data);

sub get_data_and_count {
    my ($dataset) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $inline_data = "";
    my $count = 0;
    my $result = $dataset->write_data_to(sub {
        my $part = shift;
        $inline_data .= $part;
        $count++;
    });
    identical $result, $dataset, "write_data_to() returns the object";
    return ($inline_data, $count);
}

sub get_data {
    my ($dataset) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($data, $count) = get_data_and_count($dataset);
    return $data;
}

