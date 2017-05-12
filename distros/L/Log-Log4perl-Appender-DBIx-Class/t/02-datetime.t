use strict;
use warnings;

use lib 't/lib';

use Log::Log4perl;
use Log::Log4perl::Level;
use Test::More;

use LogTest;

BEGIN {
    eval "use DBD::SQLite";

    my $dbd = $@;

    eval "use DateTime";
    my $dt = $@;

    if($dt || $dbd) {
        plan (skip_all => 'Needs DateTime and DBD::SQLite for testing');
    } else {
        plan ( tests => 5 );
    }
}

my $schema = LogTest->init_schema();
ok($schema, 'Got a schema');

my $log = Log::Log4perl->get_logger("Foo::Bar");

eval {
    my $failed_appender = Log::Log4perl::Appender->new(
        'Log::Log4perl::Appender::DBIx::Class',
    );
};
ok($@, 'failed due to missing schema');


my $dbic_appender = Log::Log4perl::Appender->new(
    'Log::Log4perl::Appender::DBIx::Class',
    schema => $schema,
    class => 'Message',
    datetime_column => 'date_occurred',
    datetime_subref => sub { DateTime->now }
);

isa_ok($dbic_appender, 'Log::Log4perl::Appender');

$log->add_appender($dbic_appender);
$log->level($INFO);

$log->error('Hello!');

my $messages = $schema->resultset('Message')->search;
cmp_ok($messages->count, '==', 1, '1 message');

my $message = $messages->first;
isa_ok($message->date_occurred, 'DateTime');
