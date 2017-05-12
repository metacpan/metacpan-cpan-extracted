#! perl -T
use Test::More;

use Log::Log4perl;

my $conf = q|
log4perl.rootLogger=TRACE, Chunk

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%m%n

log4perl.appender.Chunk=Log::Log4perl::Appender::Chunk
log4perl.appender.Chunk.store_class=Memory
log4perl.appender.Chunk.layout=${layout_class}
log4perl.appender.Chunk.layout.ConversionPattern=${layout_pattern}

|;

Log::Log4perl::init(\$conf);

ok( my $ca =  Log::Log4perl->appender_by_name('Chunk') , "Ok got Chunk appender");
ok( my $store = $ca->store() , "Ok got store for the logger");

my $LOGGER = Log::Log4perl->get_logger();

$LOGGER->info("Something outside any context");

## Chunk 12345
Log::Log4perl::MDC->put('chunk', '12345');

$LOGGER->trace("Some trace inside the chunk");
$LOGGER->debug("Some debug inside the chunk");

$LOGGER->info("Some info inside the chunk");

Log::Log4perl::MDC->put('chunk', undef);
## End of Chunk 12345

$LOGGER->info("Outside context again");

## Chunk 0001
Log::Log4perl::MDC->put('chunk', '0001');
$LOGGER->info("Inside chunk 0001");
$LOGGER->info("Inside chunk 0001 again");


Log::Log4perl::MDC->put('chunk' , '0002' );
## End of Chunk 0001, start chunk 0002
$LOGGER->info("Inside a brand new chunk 0002");
$LOGGER->info("Inside a brand new chunk 0002 again");

Log::Log4perl::MDC->put('chunk' , undef );
## End of chunk 0002
$LOGGER->info("Left chunk context");
$LOGGER->info("Left chunk context again");

## One line chunks.
Log::Log4perl::MDC->put('chunk' , 'line1' );
$LOGGER->info("One line1");
Log::Log4perl::MDC->put('chunk' , 'line2' );
$LOGGER->info("One line2");
Log::Log4perl::MDC->put('chunk' , undef );
# $LOGGER->info("Outside any chunk");


# Artificially call DEMOLISH on the Appender.
# This simulates the fact we didn't output any log after the last chunked
# line.
$ca->DEMOLISH();



## Check the store has received the adequate chunks.
is_deeply( $store->chunks(),
           {
            '12345' => q/Some trace inside the chunk
Some debug inside the chunk
Some info inside the chunk
/,
            '0001' => q|Inside chunk 0001
Inside chunk 0001 again
|,
            '0002' => q|Inside a brand new chunk 0002
Inside a brand new chunk 0002 again
|,
            'line1' => q|One line1
|,
            'line2' => q|One line2
|,
           },
           "Ok good chunks were sent to the storage");

done_testing();
