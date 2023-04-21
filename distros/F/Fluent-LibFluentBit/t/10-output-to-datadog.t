use strict;
use warnings;
use Test::More;
use Time::HiRes qw( sleep time );
use Fluent::LibFluentBit;

plan skip_all => 'Require DATADOG_API_KEY for this test'
   unless defined $ENV{DATADOG_API_KEY};

my $flb= Fluent::LibFluentBit->default_instance;
$flb->configure(log_level => $ENV{DEBUG}? 'trace' : 'debug');

my $id= $flb->flb_output("datadog");
$flb->flb_output_set($id,
   Match => '*',
   Host => "http-intake.logs.datadoghq.com",
   TLS => 'on',
   compress => 'gzip',
   apikey => $ENV{DATADOG_API_KEY},
   dd_service => 'unit-test',
   dd_source => 'perl-Fluent-LibFluentBit',
);

my $in= $flb->add_input("lib");
$flb->start;
for my $i (0..5) {
   $flb->flb_lib_push($in->id, sprintf("[%.2f,{\"key1\":\"%ld\"}]", time, $i));
   sleep .2;
}

ok( my $logger= Fluent::LibFluentBit->new_logger, 'new_logger' );
for my $level (qw( trace debug info notice warn error )) {
   ok( $logger->$level($level), $level );
   sleep .2;
}
for my $level (qw( trace debug info notice warn error )) {
   ok( $logger->$level({ message => "testing $level", some_data => [ rand ] }), $level );
   sleep .2;
}


ok( $flb->stop >= 0, 'flb_stop' );
undef $flb;

done_testing;
