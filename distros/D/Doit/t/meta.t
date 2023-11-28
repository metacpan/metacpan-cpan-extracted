#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use Test::More;
use Cwd 'realpath';

my $meta_json = realpath("$FindBin::RealBin/.."). "/META.json";
my $meta_yml  = realpath("$FindBin::RealBin/.."). "/META.yml";

plan skip_all => "CPAN::Meta not available"
    if !eval { require CPAN::Meta; 1 };
plan skip_all => "CPAN::Meta::Validator not available"
    if !eval { require CPAN::Meta::Validator; 1 };
plan tests => 2;

SKIP: {
    skip "$meta_json does not exist. It can be generated using: ./Build generate_META_json", 1
	if !-e $meta_json;
    my $meta = CPAN::Meta->load_file($meta_json);
    my $struct = $meta->as_struct;
    my $cmv = CPAN::Meta::Validator->new($struct);
    ok $cmv->is_valid, 'META.json is valid'
	or diag "Invalid META structure. Errors found:\n" . join("\n", $cmv->errors);
}

SKIP: {
    skip "$meta_yml does not exist. It can be generated using: ./Build generate_META_yml", 1
	if !-e $meta_yml;
    my $meta = CPAN::Meta->load_file($meta_yml);
    my $struct = $meta->as_struct;
    my $cmv = CPAN::Meta::Validator->new($struct);
    ok $cmv->is_valid, 'META.yml is valid'
	or diag "Invalid META structure. Errors found:\n" . join("\n", $cmv->errors);
}

__END__
