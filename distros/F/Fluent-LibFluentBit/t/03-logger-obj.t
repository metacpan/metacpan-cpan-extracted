use strict;
use warnings;
use Test::More;
use Fluent::LibFluentBit -config => {
   log_level => $ENV{DEBUG}? 'debug' : 'info',
   outputs => [ 'stdout' ],
};

ok( my $logger= Fluent::LibFluentBit->new_logger, 'new_logger' );
for my $level (qw( trace debug info notice warn error )) {
   ok( $logger->$level($level), $level );
}

$logger->include_caller(1);
ok( $logger->info("called from main at ".__FILE__.' '.__LINE__), 'caller from main' );
sub test {
   ok( $logger->info("called from main::test at ".__FILE__.' '.__LINE__), 'caller from sub' );
}
test();

done_testing;
