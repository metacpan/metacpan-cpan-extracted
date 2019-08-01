use strict;
use warnings;
use FindBin;
 
my @const = qw(
RD_KAFKA_PRODUCER
RD_KAFKA_CONSUMER
RD_KAFKA_PARTITION_UA
RD_KAFKA_TIMESTAMP_NOT_AVAILABLE
RD_KAFKA_TIMESTAMP_CREATE_TIME
RD_KAFKA_TIMESTAMP_LOG_APPEND_TIME
);
 
open my $fh, ">", "$FindBin::Bin/../const_xs.inc" or die $!;
 
for (sort @const) {
    print $fh <<EOC;
int
krd_$_()
    CODE:
        RETVAL = $_;
    OUTPUT:
        RETVAL
 
EOC
}
