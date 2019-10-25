use strict;
use warnings;
use Test::More;
use Scalar::Util qw(looks_like_number);
use Kafka::Librd qw();

{
    my $kafka = Kafka::Librd->new(
        Kafka::Librd::RD_KAFKA_CONSUMER,
        {
            'group.id' => 'consumer_id',
	    'default_topic_config' => {
		'auto.offset.reset' => 'smallest',
	    },
        },
    );
    isa_ok $kafka, 'Kafka::Librd';
}

{
    eval {
	Kafka::Librd->new(0);
    };
    like $@, qr{(Kafka::Librd::_new: )?params is not a (HASH|hash) reference}, 'params argument seems to be mandatory';
}

{
    eval {
	Kafka::Librd->new(
	    Kafka::Librd::RD_KAFKA_CONSUMER,
	    {
		'non-existing.config.property' => 42,
	    }
	);
    };
    like $@, qr{No such configuration property}, 'non-existing global config property';
}

{
    eval {
	Kafka::Librd->new(
	    Kafka::Librd::RD_KAFKA_CONSUMER,
	    {
		'default_topic_config' => {
		    'non-existing.config.property' => 42,
		},
	    }
	);
    };
    like $@, qr{No such configuration property}, 'non-existing topic config property';
}

{
    eval {
	Kafka::Librd->new(
	    Kafka::Librd::RD_KAFKA_CONSUMER,
	    {
		'default_topic_config' => ['wrong type'],
	    }
	);
    };
    like $@, qr{default_topic_config must be a hash reference}, 'wrong type for default_topic_config';
}

{
    my $kafka_version = Kafka::Librd::rd_kafka_version();
    ok looks_like_number($kafka_version), 'return value of rd_kafka_version looks like a number';
}

{
    my $kafka_version_str = Kafka::Librd::rd_kafka_version_str();
    like $kafka_version_str, qr{^\d+\.\d+\.\d+$}, 'return value of rd_kafka_version_str looks like a version';
}

done_testing;

__END__
