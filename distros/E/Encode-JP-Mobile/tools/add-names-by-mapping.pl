#!/usr/bin/perl
use strict;
use lib "lib";

use warnings;
use YAML;
use Encode;
use Encode::JP::Mobile 0.20;
use Encode::JP::Mobile::Charnames qw( unicode2name unicode2name_en );

my($file, $to, $force) = @ARGV;

my $dat = YAML::LoadFile($file);
my $from = ($file =~ /(\w*)-table\.yaml/)[0] or die;
$to ||= 'docomo';

warn "Updating $from table by mapping to $to pictograms\n";

for my $r (@$dat) {
    for my $key ( qw( name name_en ) ) {
        next if exists $r->{$key} && !$force;
        my $code = $from eq 'kddi' ? 'unicode_auto' : 'unicode';
        my $char = chr hex $r->{$code};
        eval {
            my $mapped = decode("x-utf8-$to", encode("x-utf8-$to", $char, Encode::FB_CROAK));
            my $func   = $key eq 'name' ? \&unicode2name : \&unicode2name_en;
            my $name   = $func->(ord $mapped);
            $r->{$key} = encode_utf8($name) if $name;
        };
        warn $@ if $@;
    }
}

YAML::DumpFile($file, $dat);
