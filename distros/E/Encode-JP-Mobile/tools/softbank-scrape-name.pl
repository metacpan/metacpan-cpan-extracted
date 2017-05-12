#!/usr/bin/perl
use strict;
use warnings;
use Web::Scraper;
use URI;
use YAML;
use FindBin;
use File::Spec::Functions;
use Encode;

my $table_file = shift || catfile($FindBin::Bin, qw/.. dat softbank-table.yaml/);
my $table = YAML::LoadFile($table_file);

my $scraper = scraper {
    process '/html/body/div[3]/table/tr', 
        'list[]' => scraper { 
            process '//td[3]', name => 'TEXT';
            process '//td[5]', unicode => 'TEXT';
        };
    result 'list';
};

my $res = $scraper->scrape(URI->new('http://trialgoods.com/emoji/?career=sb&page=all'));
my %map = map { $_->{unicode} => $_->{name} } @$res;

for my $emoji (@$table) {
    $emoji->{name} = $map{ $emoji->{unicode} };
}

YAML::DumpFile($table_file, $table);

