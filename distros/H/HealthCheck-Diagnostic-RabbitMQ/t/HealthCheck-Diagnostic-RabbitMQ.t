use strict;
use warnings;
use Test::More;

use HealthCheck::Diagnostic::RabbitMQ;

my $nl = $] >= 5.016 ? ".\n" : "\n";

my $must_have = "'rabbit_mq' must have 'get_server_properties' method"
    . " at %s line %d$nl";

eval { HealthCheck::Diagnostic::RabbitMQ->check };
is $@, sprintf( $must_have, __FILE__, __LINE__ - 1 ), "No params to class check";

eval { HealthCheck::Diagnostic::RabbitMQ->new->check };
is $@, sprintf( $must_have, __FILE__, __LINE__ - 1 ), "No params to instance check";

eval { HealthCheck::Diagnostic::RabbitMQ->new( rabbit_mq => {} )->check };
is $@, sprintf( $must_have, __FILE__, __LINE__ - 1 ), "rabbit_mq as hashref";

eval { HealthCheck::Diagnostic::RabbitMQ->check( rabbit_mq => bless {} ) };
is $@, sprintf( $must_have, __FILE__, __LINE__ - 1 ), "rabbit_mq as anonymous object";

eval { HealthCheck::Diagnostic::RabbitMQ->check( rabbit_mq => sub {} ) };
is $@, sprintf( $must_have, __FILE__, __LINE__ - 1 ), "rabbit_mq as empty coderef";

eval { HealthCheck::Diagnostic::RabbitMQ->check( queue => undef ) };
is $@, sprintf( $must_have, __FILE__, __LINE__ - 1 ),
    "A queue with an empty name is ignored";

$must_have =~ s/get_server_properties/queue_declare/;
eval { HealthCheck::Diagnostic::RabbitMQ->check( queue => 'a.queue' ) };
is $@, sprintf( $must_have, __FILE__, __LINE__ - 1 ),
    "The required method changes with a queue";

eval { HealthCheck::Diagnostic::RabbitMQ->check( queue => 0 ) };
is $@, sprintf( $must_have, __FILE__, __LINE__ - 1 ),
    "An falsy queue with length (0) is understood";

eval { HealthCheck::Diagnostic::RabbitMQ->check( queue => '' ) };
is $@, sprintf( $must_have, __FILE__, __LINE__ - 1 ),
    "An empty string queue is understood";


my $rabbit_mq = sub { My::RabbitMQ->new };

{
    no warnings 'once';
    local *My::RabbitMQ::get_server_properties
        = sub { +{ fake => 'properties' } };
    use warnings 'once';

    is_deeply(
        HealthCheck::Diagnostic::RabbitMQ->new( rabbit_mq => $rabbit_mq )
            ->check,
        {   label    => 'rabbit_mq',
            'status' => 'OK',
            'data'   => { 'fake' => 'properties' }
        },
        "OK status as expected"
    );

    is_deeply(
        HealthCheck::Diagnostic::RabbitMQ->check(
            rabbit_mq => $rabbit_mq->()
        ),
        { 'status' => 'OK', 'data' => { 'fake' => 'properties' } },
        "OK status as expected with rabbit_mq object passed to check()"
    );

    is_deeply(
        HealthCheck::Diagnostic::RabbitMQ->new(rabbit_mq => sub { die "oops\n" })
            ->check,
        {   label => 'rabbit_mq',
            status => 'CRITICAL',
            info   => "oops\n",
        },
        "CRITICAL + label for bad rabbitmq"
    );
}

{
    no warnings 'once';
    local *My::RabbitMQ::get_server_properties = sub { Carp::croak('ded') };
    use warnings 'once';

    is_deeply(
        HealthCheck::Diagnostic::RabbitMQ->check( rabbit_mq => $rabbit_mq ),
        { 'status' => 'CRITICAL', info => 'ded' },
        "CRITICAL status as expected"
    );
}

{
    no warnings 'once';
    local *My::RabbitMQ::get_server_properties = sub { Carp::confess('ded') };
    use warnings 'once';

    my $res
        = HealthCheck::Diagnostic::RabbitMQ->check( rabbit_mq => $rabbit_mq );
    my $at = sprintf "at %s line .*"
        . "HealthCheck::Diagnostic::RabbitMQ::check\(.*\)"
        . " called at %s line %s.",
        __FILE__, __FILE__, __LINE__ - 5;

    my $info = delete $res->{info};
    like $info, qr/^ded $at$/ms, "Got full stack trace without trimming";

    is_deeply $res, { 'status' => 'CRITICAL' },
        "CRITICAL status with stack trace as expected";
}

{
    my $exception;
    no warnings 'once';
    local *My::RabbitMQ::queue_declare
        = sub { Carp::croak("Declaring queue: $exception") };
    use warnings 'once';

    foreach (
        q{server connection error 504, message: CHANNEL_ERROR - expected 'channel.open'},
        q{server channel error 404, message: NOT_FOUND - no queue 'nonexist' in vhost 'test'},
        )
    {
        $exception = $_;
        is_deeply(
            HealthCheck::Diagnostic::RabbitMQ->check(
                rabbit_mq => $rabbit_mq,
                queue     => 'nonexist',
            ),
            {   'status' => 'CRITICAL',
                info     => $exception,
                data     => {
                    queue   => 'nonexist',
                    channel => 1,
                },
            },
            "CRITICAL status with expected exception"
        );
    }
}

{
    my @args;
    no warnings 'once';
    local *My::RabbitMQ::queue_declare
        = sub { @args = @_; 'fake.queue', 100, 3 };
    use warnings 'once';

    is_deeply(
        HealthCheck::Diagnostic::RabbitMQ->new(
            rabbit_mq => $rabbit_mq,
            queue     => 'a.queue',
            )->check,
        {   label  => 'rabbit_mq',
            status => 'OK',
            data   => {
                queue     => 'a.queue',
                channel   => 1,
                name      => 'fake.queue',
                messages  => 100,
                listeners => 3,
            },
        },
        "OK status as expected"
    );
    isa_ok shift(@args), 'My::RabbitMQ';
    is_deeply \@args, [ 1, 'a.queue', { passive => 1 } ],
        "Object passed expected args to queue_declare";

    is_deeply(
        HealthCheck::Diagnostic::RabbitMQ->new(
            rabbit_mq => $rabbit_mq,
            queue     => 'a.queue',
            channel   => 123,

            listeners_min_critical => 0,
            listeners_min_warning  => 1,
            listeners_max_critical => 4,
            listeners_max_warning  => 4,    # noop, matches critical

            messages_critical => 10_000,
            messages_warning  => 1_000,
            )->check,
        {   label  => 'rabbit_mq',
            status => 'OK',
            data   => {
                queue   => 'a.queue',
                channel => 123,

                listeners_min_critical => 0,
                listeners_min_warning  => 1,
                listeners_max_critical => 4,
                listeners_max_warning  => 4,

                messages_critical => 10_000,
                messages_warning  => 1_000,

                name      => 'fake.queue',
                messages  => 100,
                listeners => 3,
            },
        },
        "OK status as expected"
    );
    isa_ok shift(@args), 'My::RabbitMQ';
    is_deeply \@args, [ 123, 'a.queue', { passive => 1 } ],
        "Object passed expected args to queue_declare with custom channel";

    is_deeply(
        HealthCheck::Diagnostic::RabbitMQ->check(
            rabbit_mq => $rabbit_mq->(),
            queue     => 'a.queue',
        ),
        {   status => 'OK',
            data   => {
                queue     => 'a.queue',
                channel   => 1,
                name      => 'fake.queue',
                messages  => 100,
                listeners => 3,
            }
        },
        "OK status as expected with rabbit_mq object passed to check()"
    );
    isa_ok shift(@args), 'My::RabbitMQ';
    is_deeply \@args, [ 1, 'a.queue', { passive => 1 } ],
        "Class passed expected args to queue_declare";

    is_deeply(
        HealthCheck::Diagnostic::RabbitMQ->check(
            rabbit_mq => $rabbit_mq->(),
            queue     => 'a.queue',
            channel   => 321,
        ),
        {   status => 'OK',
            data   => {
                queue     => 'a.queue',
                channel   => 321,
                name      => 'fake.queue',
                messages  => 100,
                listeners => 3,
            }
        },
        "OK status as expected with rabbit_mq object passed to check()"
    );
    isa_ok shift(@args), 'My::RabbitMQ';
    is_deeply \@args, [ 321, 'a.queue', { passive => 1 } ],
        "Class passed expected args to queue_declare with custom channel";

    is_deeply(
        HealthCheck::Diagnostic::RabbitMQ->new(
            rabbit_mq => 'ignored_mq',
            queue     => 'ignored.queue',
            channel   => 'ignored channel',
            copied    => 'copied.value',

            listeners_min_critical => 5,
            listeners_min_warning  => 6,
            listeners_max_critical => 2,
            listeners_max_warning  => 1,

            messages_critical => 10_000,
            messages_warning  => 1_000,
            )->check(
            label     => 'ignored_label',
            rabbit_mq => $rabbit_mq->(),
            queue     => 'a.queue',
            channel   => 321,

            listeners_min_critical => 0,
            listeners_min_warning  => 1,
            listeners_max_critical => 4,
            listeners_max_warning  => 4,    # noop, matches critical

            messages_critical => 10_000,
            messages_warning  => 1_000,

            copied => 'passed to check',
            ),
        {   label  => 'rabbit_mq',
            status => 'OK',
            data   => {
                queue                  => 'a.queue',
                channel                => 321,

                listeners_min_critical => 0,
                listeners_min_warning  => 1,
                listeners_max_critical => 4,
                listeners_max_warning  => 4,

                messages_critical => 10_000,
                messages_warning  => 1_000,

                name      => 'fake.queue',
                messages  => 100,
                listeners => 3,
            },
        },
        "Copied somewhat expected params to result"
    );
    isa_ok shift(@args), 'My::RabbitMQ';
    is_deeply \@args, [ 321, 'a.queue', { passive => 1 } ],
        "Class passed expected args to queue_declare with custom channel";


    foreach my $limit (qw(
        listeners_min_critical
        listeners_min_warning
        listeners_max_critical
        listeners_max_warning

        messages_critical
        messages_warning
    )) {
        my $status = $limit =~ /critical/  ? 'CRITICAL'  : 'WARNING';
        my $value  = $limit =~ /min/       ? 50          : 2;
        my $info   = $limit =~ /listeners/ ? 'Listeners' : 'Messages';

        is_deeply(
            HealthCheck::Diagnostic::RabbitMQ->check(
                rabbit_mq => $rabbit_mq->(),
                queue     => 'a.queue',
                $limit    => $value,
            ),
            {   status => $status,
                info   => "$info out of range!",
                data   => {
                    queue   => 'a.queue',
                    channel => 1,
                    $limit  => $value,

                    name      => 'fake.queue',
                    messages  => 100,
                    listeners => 3,
                },
            },
            "[$limit] caused expected status"
        );
    }


    foreach my $limits (
        { listeners_min_critical => 5, listeners_min_warning => 4 },
        { listeners_max_critical => 2, listeners_max_warning => 1 },
        { messages_critical => 50, messages_warning => 25 },
    ) {
        my ($limit) = keys %{$limits};
        $limit =~ s/_[^_]+$//;
        my $info = $limit =~ /listeners/ ? 'Listeners' : 'Messages';
        is_deeply(
            HealthCheck::Diagnostic::RabbitMQ->check(
                rabbit_mq => $rabbit_mq->(),
                queue     => 'a.queue',
                %{ $limits },
            ),
            {   status => 'CRITICAL',
                info   => "$info out of range!",
                data   => {
                    queue   => 'a.queue',
                    channel => 1,
                    %{ $limits },

                    name      => 'fake.queue',
                    messages  => 100,
                    listeners => 3,
                },
            },
            "[$limit] critical overides warning"
        );
    }
}

done_testing;

package My::RabbitMQ;

sub new { return bless {}, $_[0] }
