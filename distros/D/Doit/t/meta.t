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

plan skip_all => "CPAN::Meta not available"
    if !eval { require CPAN::Meta; 1 };
plan skip_all => "CPAN::Meta::Validator not available"
    if !eval { require CPAN::Meta::Validator; 1 };
plan skip_all => "$meta_json does not exist"
    if !-e $meta_json;
plan tests => 1;

my $meta = CPAN::Meta->load_file($meta_json);
my $struct = $meta->as_struct;
my $cmv = CPAN::Meta::Validator->new($struct);
ok $cmv->is_valid
    or diag "Invalid META structure. Errors found:\n" . join("\n", $cmv->errors);

__END__
