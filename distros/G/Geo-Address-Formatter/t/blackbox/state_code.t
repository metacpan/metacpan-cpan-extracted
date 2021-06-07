use strict;
use warnings;

use lib 'lib';
use feature qw(say);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;
use Test::More;

use utf8;

# nicer output for diag and failures, see
# http://perldoc.perl.org/Test/More.html#CAVEATS-and-NOTES
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

my $af_path = dirname(__FILE__) . '/../../address-formatting';
my $verbose = 0;

my $conf_path = $af_path . '/conf/';

my $CLASS = 'Geo::Address::Formatter';
use_ok($CLASS);

my $GAF = $CLASS->new(conf_path => $conf_path);

{
    # is the correct state_code set in German?
    # 48.15101/11.58440
    my %input = (
        "city"         => "München",
        "country"      => "Deutschland",
        "country_code" => "de",
        "house_number" => "42",
        "postcode"     => "80539",
        "road"         => "Kaulbachstraße",
        "state"        => "Bayern",
    );

    my $formatted = $GAF->format_address(\%input);
    my $rh_comp   = $GAF->final_components();
    is($rh_comp->{state_code}, 'BY', 'correct state_code for Bayern');
}

{
    # is the correct state_code set in English?
    # 48.15101/11.58440
    my %input = (
        "city"         => "Munich",
        "country"      => "Germany",
        "country_code" => "de",
        "house_number" => "42",
        "postcode"     => "80539",
        "road"         => "Kaulbachstraße",
        "state"        => "Bavaria",
    );

    my $formatted = $GAF->format_address(\%input);
    my $rh_comp   = $GAF->final_components();
    is($rh_comp->{state_code}, 'BY', 'correct state_code for Bavaria');
}


{
    # is the correct state_code set in France
    my %input = (
        'city'           => 'Sommières-du-Clain',
        'country'        => 'France',
        'country_code'   => 'fr',
        'state_district' => 'Vienne',
        'place'          => 'Moulin Bois',
        'postcode'       => '86160',
        'state'          => 'Nouvelle-Aquitaine',
    );

    my $formatted = $GAF->format_address(\%input);
    my $rh_comp   = $GAF->final_components();
    is($rh_comp->{state_code}, 'NAQ', 'correct state_code for N-A');
}


done_testing();

1;
