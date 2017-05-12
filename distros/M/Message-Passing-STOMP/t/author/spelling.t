use strict;
use warnings;
use Test::More;
use Test::Spelling;

add_stopwords(qw(
    adaptor
    ActiveMQ
    RabbitMQ
    hostname
    username
    destination
    connected
    SureVoIP
    VoIP
    lossy
    STOMP's
    Starman
    STOMP
    API
    Affero
    FCGI
    JSON
    Tomas
    Doran
    t0m
    Jorden
    Logstash
    Sissel
    Suretec
    TODO
    STDIN
    STDOUT
    STDERR
    logstash
    centralised
));
set_spell_cmd('aspell list -l en');
all_pod_files_spelling_ok();

done_testing();
