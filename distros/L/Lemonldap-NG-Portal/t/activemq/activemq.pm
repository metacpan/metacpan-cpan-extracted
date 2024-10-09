use strict;

use constant MQTT_PARAMS => {
    server   => 'localhost:61883',
};
use constant CONTNAME => 'llng-mqtt-test';

sub startActiveMq {
    system(
        'docker', 'run',
        '-d',     '--name',
        CONTNAME, '--rm',
        "-p",     "61883:1883",
        "apache/activemq-classic"
    );
    sleep 3;
}

sub stopActiveMq {
    system( 'docker', 'stop', CONTNAME );
}

1;
