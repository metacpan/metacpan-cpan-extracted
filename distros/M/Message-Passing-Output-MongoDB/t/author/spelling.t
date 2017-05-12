use strict;
use warnings;
use Test::More;
use Test::Spelling;

add_stopwords(qw(
    username
    namespace
    POSIX
    init
    fh
    privileged
    conf
    daemonize
    ARGV
    Recipies
    recipies
    multi
    rsyslogd
    syslogd
    AnyEvent
    DSL
    SureVoIP
    VoIP
    Starman
    ZeroMQ
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
    MongoDB
    mongodb
    conserver
    Str
));
set_spell_cmd('aspell list -l en');
all_pod_files_spelling_ok();

done_testing();
