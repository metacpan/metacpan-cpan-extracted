#!/usr/bin/perl
use strict;
use warnings;
use experimental qw< signatures >;
use Lib::PWQuality;
use Test::More 'tests' => 22;

sub check_settings ($settings) {
    is( $settings->diff_ok(),     '15', 'difok read correctly'      );
    is( $settings->min_length(),  '20', 'minlen read correctly'     );
    is( $settings->dig_credit(),  '-5', 'dcredit read correctly'    );
    is( $settings->up_credit(),   '-5', 'ucredit read correctly'    );
    is( $settings->low_credit(),  '-5', 'lcredit read correctly'    );
    is( $settings->oth_credit(),  '1',  'ocredit read correctly'    );
    is( $settings->min_class(),   '3',  'minclass read correctly'   );
    is( $settings->max_repeat(),  '2',  'maxrepeat read correctly'  );
    is( $settings->gecos_check(), '1',  'gecoscheck read correctly' );
}

my $pwq = Lib::PWQuality->new();
isa_ok( $pwq, 'Lib::PWQuality' );
can_ok( $pwq, 'read_config' );

my $config_file = 't/conf/pwquality.conf';
is(
    $pwq->read_config($config_file),
    'SUCCESS',
    'Successfully read config file',
);

my $settings = $pwq->settings();
check_settings($settings);

my $pwq1 = Lib::PWQuality->new($config_file);
is(
    $pwq1->read_config($config_file),
    'SUCCESS',
    'Successfully read config file',
);

my $settings1 = $pwq1->settings();
check_settings($settings1);
