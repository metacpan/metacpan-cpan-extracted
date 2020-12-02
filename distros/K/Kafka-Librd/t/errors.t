use strict;
use warnings;
use Test::More;
use Scalar::Util qw(looks_like_number);
use Kafka::Librd qw();

my $errors = Kafka::Librd::Error::rd_kafka_get_err_descs();
cmp_ok keys(%$errors), '>', 50, 'found a reasonable number of errors';

for my $error_name (keys %$errors) {
    my $val = $errors->{$error_name};
    ok looks_like_number($val), "$error_name values looks like a number";
    no strict 'refs';
    is &{"Kafka::Librd::RD_KAFKA_RESP_ERR_${error_name}"}, $val, "generated subroutine for $error_name returns expected value";
    ok Kafka::Librd::Error::to_string($val), "successful to_string call for code=$val";
    if ($error_name !~ /^(_BEGIN|_END)$/) { # these errors look special and don't roundtrip correctly
        is Kafka::Librd::Error::to_name($val), $error_name, "to_name returns error name";
    }
}

done_testing;

__END__
