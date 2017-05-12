package Gearman::Driver;

use Moose;
use Moose::Util qw(apply_all_roles);
use Carp qw(croak);
use Gearman::Driver::Observer;
use Gearman::Driver::Console;
use Gearman::Driver::Job;
use Gearman::Driver::Job::Method;
use Log::Log4perl qw(:easy);
use MooseX::Types::Path::Class;
use POE;
with qw(MooseX::Log::Log4perl MooseX::SimpleConfig MooseX::Getopt Gearman::Driver::Loader);

our $VERSION = '0.02008';

=head1 NAME

Gearman::Driver - Manages Gearman workers

=head1 SYNOPSIS

    package My::Workers::One;

    # Yes, you need to do it exactly this way
    use base qw(Gearman::Driver::Worker);
    use Moose;

    # this method will be registered with gearmand as 'My::Workers::One::scale_image'
    sub scale_image : Job {
        my ( $self, $job, $workload ) = @_;
        # do something
    }

    # this method will be registered with gearmand as 'My::Workers::One::do_something_else'
    sub do_something_else : Job : MinProcesses(2) : MaxProcesses(15) {
        my ( $self, $job, $workload ) = @_;
        # do something
    }

    # this method wont be registered with gearmand at all
    sub do_something_internal {
        my ( $self, $job, $workload ) = @_;
        # do something
    }

    1;

    package My::Workers::Two;

    use base qw(Gearman::Driver::Worker);
    use Moose;

    # this method will be registered with gearmand as 'My::Workers::Two::scale_image'
    sub scale_image : Job {
        my ( $self, $job, $workload ) = @_;
        # do something
    }

    1;

    package main;

    use Gearman::Driver;

    my $driver = Gearman::Driver->new(
        namespaces => [qw(My::Workers)],
        server     => 'localhost:4730,otherhost:4731',
        interval   => 60,
    );

    #or should save all config into a YAML config file, then read config from it.
    my $driver = Gearman::Driver->new(configfile => '/etc/gearman-driver/config.yml');

    $driver->run;

=head1 DESCRIPTION

Warning: This framework is still B<EXPERIMENTAL>!

Having hundreds of Gearman workers running in separate processes can
consume a lot of RAM. Often many of these workers share the same
code/objects, like the database layer using L<DBIx::Class> for
example. This is where L<Gearman::Driver> comes in handy:

You write some base class which inherits from
L<Gearman::Driver::Worker>. Your base class loads your database layer
for example. Each of your worker classes inherit from that base
class. In the worker classes you can register single methods as jobs
with gearmand. It's even possible to control how many workers doing
that job/method in parallel. And this is the point where you'll
save some RAM: Instead of starting each worker in a separate process
L<Gearman::Driver> will fork each worker from the main process. This
will take advantage of copy-on-write on Linux and save some RAM.

There's only one mandatory parameter which has to be set when calling
the constructor: namespaces

    use Gearman::Driver;
    my $driver = Gearman::Driver->new( namespaces => [qw(My::Workers)] );

See also: L<namespaces|/namespaces>. If you do not set
L<server|/server> (gearmand) attribute the default will be used:
C<localhost:4730>

Each module found in your namespaces will be loaded and introspected,
looking for methods having the 'Job' attribute set:

    package My::Workers::ONE;

    sub scale_image : Job {
        my ( $self, $job, $workload ) = @_;
        # do something
    }

This method will be registered as job function with gearmand, verify
it by doing:

    plu@mbp ~$ telnet localhost 4730
    Trying ::1...
    Connected to localhost.
    Escape character is '^]'.
    status
    My::Workers::ONE::scale_image   0       0       1
    .
    ^]
    telnet> Connection closed.

If you dont like to use the full package name you can also specify
a custom prefix:

    package My::Workers::ONE;

    sub prefix { 'foo_bar_' }

    sub scale_image : Job {
        my ( $self, $job, $workload ) = @_;
        # do something
    }

This would register 'foo_bar_scale_image' with gearmand.

See also: L<prefix|Gearman::Driver::Worker/prefix>

=head1 ATTRIBUTES

See also L<Gearman::Driver::Loader/ATTRIBUTES>.

=head2 server

A list of Gearman servers the workers should connect to. The format
for the server list is: C<host[:port][,host[:port]]>

See also: L<Gearman::XS>

=over 4

=item * default: C<localhost:4730>

=item * isa: C<Str>

=back

=cut

has 'server' => (
    default       => 'localhost:4730',
    documentation => 'Gearman host[:port][,host[:port]]',
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
);

=head2 console_port

Gearman::Driver has a telnet management console, see also:

L<Gearman::Driver::Console>

=over 4

=item * default: C<47300>

=item * isa: C<Int>

=back

Set this to C<0> to disable management console at all.

=cut

has 'console_port' => (
    default       => 47300,
    documentation => 'Port of management console (default: 47300)',
    is            => 'rw',
    isa           => 'Int',
    required      => 1,
);

=head2 interval

Each n seconds L<Net::Telnet::Gearman> is used in
L<Gearman::Driver::Observer> to check status of free/running/busy
workers on gearmand. This is used to fork more workers depending
on the queue size and the MinProcesses/MaxProcesses
L<attribute|Gearman::Driver::Worker/METHODATTRIBUTES> of the
job method. See also: L<Gearman::Driver::Worker>

=over 4

=item * default: C<5>

=item * isa: C<Int>

=back

=cut

has 'interval' => (
    default       => '5',
    documentation => 'Interval in seconds (see Gearman::Driver::Observer)',
    is            => 'rw',
    isa           => 'Int',
    required      => 1,
);

=head2 max_idle_time

Whenever L<Gearman::Driver::Observer> notices that there are more
processes running than actually necessary (depending on min_processes
and max_processes setting) it will kill them. By default this happens
immediately. If you change this value to C<300>, a process which is
not necessary is killed after 300 seconds.

Please remember that this also depends on what value you set
L</interval> to. The max_idle_time is only checked each n seconds
where n is L</interval>. Besides that it makes only sense when you
have workers where L<Gearman::Driver::Worker/MinProcesses> is set to
C<0>.

=over 4

=item * default: C<0>

=item * isa: C<Int>

=back

=cut

has 'max_idle_time' => (
    default       => '0',
    documentation => 'How many seconds a worker may be idle before its killed',
    is            => 'rw',
    isa           => 'Int',
    required      => 1,
);

=head2 logfile

Path to logfile.

=over 4

=item * isa: C<Str>

=item * default: C<gearman_driver.log>

=back

=cut

has 'logfile' => (
    coerce        => 1,
    default       => 'gearman_driver.log',
    documentation => 'Path to logfile (default: gearman_driver.log)',
    is            => 'rw',
    isa           => 'Path::Class::File',
);

=head2 loglayout

See also L<Log::Log4perl>.

=over 4

=item * isa: C<Str>

=item * default: C<[%d] %p %m%n>

=back

=cut

has 'loglayout' => (
    default       => '[%d] %p %m%n',
    documentation => 'Log message layout (default: [%d] %p %m%n)',
    is            => 'rw',
    isa           => 'Str',
);

=head2 loglevel

See also L<Log::Log4perl>.

=over 4

=item * isa: C<Str>

=item * default: C<INFO>

=back

=cut

has 'loglevel' => (
    default       => 'INFO',
    documentation => 'Log level (default: INFO)',
    is            => 'rw',
    isa           => 'Str',
);

=head2 unknown_job_callback

Whenever L<Gearman::Driver::Observer> sees a job that isnt handled
it will call this CodeRef, passing following arguments:

=over 4

=item * C<$driver>

=item * C<$status>

=back

    my $driver = Gearman::Driver->new(
        namespaces           => [qw(My::Workers)],
        unknown_job_callback => sub {
            my ( $driver, $status ) = @_;
            # notify nagios here for example
        }
    );

C<$status> might look like:

    $VAR1 = {
        'busy'    => 0,
        'free'    => 0,
        'name'    => 'GDExamples::Convert::unknown_job',
        'queue'   => 6,
        'running' => 0
    };

=cut

has 'unknown_job_callback' => (
    default => sub {
        sub { }
    },
    is     => 'rw',
    isa    => 'CodeRef',
    traits => [qw(NoGetopt)],
);

=head2 worker_options

You can pass runtime options to the worker module, these will merged with 'GLOBAL' and pass to the worker constructor. ( worker options override globals )

=over 4

=item * default: C<{}>

=item * isa: C<HashRef>

=back

Example:

    my $driver = Gearman::Driver->new(
        namespaces     => [qw(My::Workers)],
        worker_options => {
            'GLOBAL' => {
                'config' => $config,
            },
            'My::Workers::MysqlPing' => {
                'dsn' => 'DBI:mysql:database=test;host=localhost;mysql_auto_reconnect=1;mysql_enable_utf8=1;mysql_server_prepare=1;',
            },
            'My::Workers::ImageThumbnail' => {
                'default_format' => 'jpeg',
                'default_size => ' 133 x 100 ',
            }
        }
    );

You should define these in a runtime config (See also L</configfile>), might be:

    ---
    worker_options:
        'My::App::Worker::MysqlPing':
            'dsn': 'DBI:mysql:database=test;host=localhost;mysql_auto_reconnect=1;mysql_enable_utf8=1;mysql_server_prepare=1;'
            'user': 'root'
            'password:': ''
        'My::App::Worker::ImageThumbnail':
            'default_format': 'jpeg'
            'default_size': '133x100'

=cut

has 'worker_options' => (
    isa => 'HashRef',
    is  => 'rw',
    default  => sub { {} },
    traits => [qw(Hash NoGetopt)],
);

=head2 Job runtime attributes

You can override a job attribute by its name here. This help to tuning job some runtime-related options (like max_processes, min_processes) handy.
You just change the options in a config file, no need to modify the worker code anymore.

Currently only 'max_processes', 'min_processes' make sense. The hash key is "worker_module::job_key", job_key is ProcessGroup attribute or
job method name.

    #in your config file: /etc/gearman-driver.yml (YAML)
    ---
    job_runtime_attributes:
        'My::App::Worker::job1':
            max_processes: 25
            min_processes: 2
        #job has a ProcessGroup attribute named 'group1'
        'My::App::Worker::group1':
            max_processes: 10
            min_processes: 2
    #then run as:
    gearman_driver.pl --configfile /etc/gearman_driver.yml

=cut

has 'job_runtime_attributes' => (
    isa => 'HashRef',
    is  => 'rw',
    default  => sub { {} },
    traits => [qw(Hash NoGetopt)],
);

=head2 configfile

Runtime config file path, You can provide a default configfile pathname like so:

    has +configfile ( default => '/etc/gearman-driver.yaml' );

You can pass an array of filenames if you want, like:

    has +configfile ( default => sub { [ '/etc/gearman-driver.yaml','/opt/my-app/etc/config.yml' ] });

=cut

has '+configfile' =>  (
    documentation => 'Gearman-driver runtime config path',
);

=head2 daemonize

Detach self and run as a daemon.

=cut

has 'daemonize' =>  (
    isa => 'Bool',
    is  => 'rw',
    default  => 0,
    documentation => 'Let Gearman-driver run as a daemon'
);

=head1 INTERNAL ATTRIBUTES

This might be interesting for subclassing L<Gearman::Driver>.

=head2 jobs

Stores all L<Gearman::Driver::Job> instances. There are also two
methods:

=over 4

=item * L<get_job|Gearman::Driver/get_job>

=item * L<has_job|Gearman::Driver/has_job>

=back

Example:

    {
        'My::Workers::ONE::scale_image'       => bless( {...}, 'Gearman::Driver::Job' ),
        'My::Workers::ONE::do_something_else' => bless( {...}, 'Gearman::Driver::Job' ),
        'My::Workers::TWO::scale_image'       => bless( {...}, 'Gearman::Driver::Job' ),
    }

=over 4

=item * isa: C<HashRef>

=item * readonly: C<True>

=back

=cut

has 'jobs' => (
    default => sub { {} },
    handles => {
        _set_job => 'set',
        get_job  => 'get',
        has_job  => 'defined',
        all_jobs => 'values',
    },
    is     => 'ro',
    isa    => 'HashRef',
    traits => [qw(Hash NoGetopt)],
);

=head2 observer

Instance of L<Gearman::Driver::Observer>.

=over 4

=item * isa: C<Gearman::Driver::Observer>

=item * readonly: C<True>

=back

=cut

has 'observer' => (
    is     => 'ro',
    isa    => 'Gearman::Driver::Observer',
    traits => [qw(NoGetopt)],
);

=head2 console

Instance of L<Gearman::Driver::Console>.

=over 4

=item * isa: C<Gearman::Driver::Console>

=item * readonly: C<True>

=back

=cut

has 'console' => (
    is     => 'ro',
    isa    => 'Gearman::Driver::Console',
    traits => [qw(NoGetopt)],
);

has 'session' => (
    is     => 'ro',
    isa    => 'POE::Session',
    traits => [qw(NoGetopt)],
);

has 'pid' => (
    default => $$,
    is      => 'ro',
    isa     => 'Int',
);


has '+logger'  => ( traits => [qw(NoGetopt)] );
has '+wanted'  => ( traits => [qw(NoGetopt)] );
has '+modules' => ( traits => [qw(NoGetopt)] );

=head1 METHODS

=head2 add_job

There's one mandatory param (hashref) with following keys:

=over 4

=item * max_processes (mandatory)

Maximum number of processes that may be forked.

=item * min_processes (mandatory)

Minimum number of processes that should be forked.

=item * name (mandatory)

Job name/alias that method should be registered with Gearman.

=item * methods (mandatory)

ArrayRef of HashRefs containing following keys:

=over 4

=item * body (mandatory)

CodeRef to the job method.

=item * name (mandatory)

The name this method should be registered with gearmand.

=item * decode (optionally)

Name of a decoder method in your worker object.

=item * encode (optionally)

Name of a encoder method in your worker object.

=back

=item * worker (mandatory)

Worker object that should be passed as first parameter to the job
method.

=back

Basically you never really need this method if you use
L</namespaces>. But L</namespaces> depends on method attributes which
some people do hate. In this case, feel free to setup your C<$driver>
this way:

    package My::Workers::One;

    use Moose;
    use JSON::XS;
    extends 'Gearman::Driver::Worker::Base';

    # this method will be registered with gearmand as 'My::Workers::One::scale_image'
    sub scale_image {
        my ( $self, $job, $workload ) = @_;
        # do something
    }

    # this method will be registered with gearmand as 'My::Workers::One::do_something_else'
    sub do_something_else {
        my ( $self, $job, $workload ) = @_;
        # do something
    }

    sub encode_json {
        my ( $self, $result ) = @_;
        return JSON::XS::encode_json($result);
    }

    sub decode_json {
        my ( $self, $workload ) = @_;
        return JSON::XS::decode_json($workload);
    }

    1;

    package main;

    use Gearman::Driver;
    use My::Workers::One;

    my $driver = Gearman::Driver->new(
        server   => 'localhost:4730,otherhost:4731',
        interval => 60,
    );

    my $worker = My::Workers::One->new();

    # run each method in an own process
    foreach my $method (qw(scale_image do_something_else)) {
        $driver->add_job(
            {
                max_processes => 5,
                min_processes => 1,
                name          => $method,
                worker        => $worker,
                methods       => [
                    {
                        body   => $w1->meta->find_method_by_name($method)->body,
                        decode => 'decode_json',
                        encode => 'encode_json',
                        name   => $method,
                    },
                ]
            }
        );
    }

    # share both methods in a single process
    $driver->add_job(
        {
            max_processes => 5,
            min_processes => 1,
            name          => 'some_alias',
            worker        => $worker,
            methods       => [
                {
                    body   => $w1->meta->find_method_by_name('scale_image')->body,
                    decode => 'decode_json',
                    encode => 'encode_json',
                    name   => 'scale_image',
                },
                {
                    body   => $w1->meta->find_method_by_name('do_something_else')->body,
                    decode => 'decode_json',
                    encode => 'encode_json',
                    name   => 'do_something_else',
                },
            ]
        }
    );

    $driver->run;

=cut

sub add_job {
    my ( $self, $params ) = @_;

    $params->{name} = $params->{worker}->prefix . $params->{name};

    foreach my $key ( keys %$params ) {
        delete $params->{$key} unless defined $params->{$key};
    }

    my @methods = ();
    foreach my $args ( @{ delete $params->{methods} } ) {
        foreach my $key ( keys %$args ) {
            delete $args->{$key} unless defined $args->{$key};
        }
        $args->{name} = $params->{worker}->prefix . $args->{name};
        push @methods, Gearman::Driver::Job::Method->new( %$args, worker => $params->{worker} );
    }

    my $job = Gearman::Driver::Job->new(
        driver  => $self,
        methods => \@methods,
        %$params
    );

    $self->_set_job( $params->{name} => $job );

    $self->log->debug( sprintf "Added new job: %s (processes: %d)", $params->{name}, $params->{min_processes} || 1 );

    return 1;
}

=head2 get_jobs

Returns all L<Gearman::Driver::Job> objects ordered by jobname.

=cut

sub get_jobs {
    my ($self) = @_;
    my @result = ();
    foreach my $name ( sort keys %{ $self->jobs } ) {
        push @result, $self->get_job($name);
    }
    return @result;
}

=head2 run

This must be called after the L<Gearman::Driver> object is instantiated.

=cut

sub run {
    my ($self) = @_;
    push @INC, @{ $self->lib };
    $self->load_namespaces;

    $self->_daemonize if $self->daemonize;

    $self->_start_observer;
    $self->_start_console;
    $self->_start_session;
    POE::Kernel->run();
}

=head2 shutdown

Sends TERM signal to all child processes and exits Gearman::Driver.

=cut

sub shutdown {
    my ($self) = @_;
    POE::Kernel->signal( $self->{session}, 'TERM' );
}

sub DEMOLISH {
    my ($self) = @_;
    if ( $self->pid eq $$ ) {
        $self->shutdown;
    }
}

=head2 has_job

Params: $name

Returns true/false if the job exists.

=head2 get_job

Params: $name

Returns the job instance.

=cut

sub BUILD {
    my ($self) = @_;
    $self->_setup_logger;
}

sub _setup_logger {
    my ($self) = @_;

    unless (Log::Log4perl->initialized()) {
        Log::Log4perl->easy_init(
            {
                file   => sprintf( '>>%s', $self->logfile ),
                layout => $self->loglayout,
                level  => $self->loglevel,
            },
        );
    }
}

sub _start_observer {
    my ($self) = @_;
    if ( $self->interval > 0 ) {
        $self->{observer} = Gearman::Driver::Observer->new(
            callback => sub {
                my ($response) = @_;
                $self->_observer_callback($response);
            },
            interval => $self->interval,
            server   => $self->server,
        );
    }
}

sub _start_console {
    my ($self) = @_;
    if ( $self->console_port > 0 ) {
        $self->{console} = Gearman::Driver::Console->new(
            driver => $self,
            port   => $self->console_port,
        );
    }
}

sub _observer_callback {
    my ( $self, $response ) = @_;

    # When $job->add_process is called and ProcessGroup is used
    # this may end up in a race condition and more processes than
    # wanted are started. To fix that we remember what kind of
    # processes we need to start in each single run of this callback.
    my %to_start = ();

    my $status = $response->{data};
    foreach my $row (@$status) {
        if ( my $job = $self->_find_job( $row->{name} ) ) {
            $to_start{$job->name} ||= 0;
            if ( $job->count_processes <= $row->{busy} && $row->{queue} ) {
                my $diff = $row->{queue} - $row->{busy};
                my $free = $job->max_processes - $job->count_processes;
                if ($free) {
                    my $start = $diff > $free ? $free : $diff;
                    $to_start{$job->name} += $start;
                }
            }

            elsif ( $job->count_processes && $job->count_processes > $job->min_processes && $row->{queue} == 0 ) {
                my $idle = time - $job->lastrun;
                if ( $job->lastrun && ($idle >= $self->max_idle_time) ) {
                    my $stop = $job->count_processes - $job->min_processes;
                    $self->log->debug( sprintf "Stopping %d process(es) of type %s (idle: %d)",
                        $stop, $job->name, $idle );
                    $job->remove_process for 1 .. $stop;
                }
            }
        }
        else {
            $self->unknown_job_callback->( $self, $row ) if $row->{queue} > 0;
        }
    }

    foreach my $name (keys %to_start) {
        my $job = $self->get_job($name);
        my $start = $to_start{$name};
        my $free = $job->max_processes - $job->count_processes;
        $start = $free if $start > $free;
        if ($start) {
            $self->log->debug( sprintf "Starting %d new process(es) of type %s", $start, $job->name );
            $job->add_process for 1 .. $start;
        }
    }

    my $error = $response->{error};
    foreach my $e (@$error) {
        $self->log->error( sprintf "Gearman::Driver::Observer: %s", $e );
    }
}

sub _find_job {
    my ( $self, $name ) = @_;
    foreach my $job ( $self->all_jobs ) {
        foreach my $method ( @{ $job->methods } ) {
            return $job if $method->name eq $name;
        }
    }
    return 0;
}

sub _start_session {
    my ($self) = @_;
    $self->{session} = POE::Session->create(
        object_states => [
            $self => {
                _start            => '_start',
                got_sig           => '_on_sig',
                monitor_processes => '_monitor_processes',
            }
        ]
    );
}

sub _on_sig {
    my ( $self, $kernel, $heap ) = @_[ OBJECT, KERNEL, HEAP ];

    foreach my $job ( $self->get_jobs ) {
        foreach my $process ( $job->get_processes ) {
            $self->log->info( sprintf '(%d) [%s] Process killed', $process->PID, $job->name );
            $process->kill();
        }
    }

    $kernel->sig_handled();

    exit(0);
}

sub _start {
    $_[KERNEL]->sig( $_ => 'got_sig' ) for qw(INT QUIT ABRT KILL TERM);
    $_[OBJECT]->_add_jobs;
    $_[OBJECT]->_start_jobs;
    $_[KERNEL]->delay( monitor_processes => 5 );
}

sub _add_jobs {
    my ($self) = @_;
    my $worker_options = $self->worker_options;
    my $job_runtime_attributes = $self->job_runtime_attributes;

    foreach my $module ( $self->get_modules ) {
        my %module_options = (
            %{ $worker_options->{GLOBAL}  || {} },
            %{ $worker_options->{$module} || {} },
        );
        $module_options{server} = $self->server;
        my $worker = $module->new( %module_options );
        my %methods = ();
        foreach my $method ( $module->meta->get_nearest_methods_with_attributes ) {
            apply_all_roles( $method => 'Gearman::Driver::Worker::AttributeParser' );

            $method->default_attributes( $worker->default_attributes );
            $method->override_attributes( $worker->override_attributes );

            next unless $method->has_attribute('Job');

            my $name = $method->get_attribute('ProcessGroup') || $method->name;
            $methods{$name} ||= [];
            push @{ $methods{$name} }, $method;
        }

        foreach my $name ( keys %methods ) {
            my @methods = ();
            my ( $min_processes, $max_processes );

            foreach my $method ( @{ $methods{$name} } ) {
                warn sprintf "MinProcesses redefined in ProcessGroup(%s) at %s::%s",
                  $method->get_attribute('ProcessGroup'), ref($worker), $method->name
                  if defined $min_processes && $method->has_attribute('MinProcesses');

                warn sprintf "MaxProcesses redefined in ProcessGroup(%s) at %s::%s",
                  $method->get_attribute('ProcessGroup'), ref($worker), $method->name
                  if defined $max_processes && $method->has_attribute('MaxProcesses');

                $min_processes ||= $method->get_attribute('MinProcesses');
                $max_processes ||= $method->get_attribute('MaxProcesses');

                push @methods,
                  {
                    body   => $method->body,
                    name   => $method->name,
                    decode => $method->get_attribute('Decode'),
                    encode => $method->get_attribute('Encode'),
                  };
            }

            my $job_runtime_attributes = $self->job_runtime_attributes->{$module.'::'.$name} || {};
            if (defined $job_runtime_attributes->{min_processes} ) {
                $min_processes = $job_runtime_attributes->{min_processes} ;
            }

            if (defined $job_runtime_attributes->{max_processes}) {
                $max_processes = $job_runtime_attributes->{max_processes};
            }

            $self->add_job(
                {
                    max_processes => $max_processes,
                    min_processes => $min_processes,
                    methods       => \@methods,
                    name          => $name,
                    worker        => $worker,
                }
            );
        }
    }
}

sub _start_jobs {
    my ($self) = @_;

    foreach my $job ( $self->get_jobs ) {
        for ( 1 .. $job->min_processes ) {
            $job->add_process();
        }
    }
}

sub _monitor_processes {
    my $self = $_[OBJECT];
    foreach my $job ( $self->get_jobs ) {
        if ( $job->count_processes < $job->min_processes ) {
            my $start = $job->min_processes - $job->count_processes;
            $self->log->debug( sprintf "Starting %d new process(es) of type %s", $start, $job->name );
            $job->add_process for 1 .. $start;
        }
    }
    $_[KERNEL]->delay( monitor_processes => 5 );
}


sub _daemonize {
    my $self = shift;
    my $logfile = $self->logfile || '/dev/null';
    # fallback to /dev/null
    $logfile = '/dev/null' unless -w $logfile;
    require POSIX;
    fork && exit;
    ## Detach ourselves from the terminal
    croak "Cannot detach from controlling terminal" unless POSIX::setsid();
    fork && exit;
    umask 0;
    close(STDIN);
    close(STDOUT);
    close(STDERR);
    ## Reopen stderr, stdout, stdin to $logfile
    open(STDIN,  "+>$logfile");
    open(STDOUT, "+>&STDIN");
    open(STDERR, "+>&STDIN");
    chdir "/";
}

no Moose;

__PACKAGE__->meta->make_immutable;

=head1 SCRIPT

There's also a script C<gearman_driver.pl> which is installed with
this distribution. It just instantiates L<Gearman::Driver> with its
default values, having most of the options exposed to the command
line using L<MooseX::Getopt>.

    usage: gearman_driver.pl [long options...]
            --loglevel          Log level (default: INFO)
            --lib               Example: --lib ./lib --lib /custom/lib
            --server            Gearman host[:port][,host[:port]]
            --logfile           Path to logfile (default: gearman_driver.log)
            --console_port      Port of management console (default: 47300)
            --interval          Interval in seconds (see Gearman::Driver::Observer)
            --loglayout         Log message layout (default: [%d] %p %m%n)
            --namespaces        Example: --namespaces My::Workers --namespaces My::OtherWorkers
            --configfile        Read options from this file. Example: --configfile ./etc/gearman-driver-config.yml
            --daemonize         Run as daemon.

=head1 AUTHOR

Johannes Plunien E<lt>plu@cpan.orgE<gt>

=head1 CONTRIBUTORS

Uwe Voelker, <uwe.voelker@gmx.de>

Night Sailer <nightsailer@gmail.com>

Robert Bohne, <rbo@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Johannes Plunien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<Gearman::Driver::Adaptor>

=item * L<Gearman::Driver::Console>

=item * L<Gearman::Driver::Console::Basic>

=item * L<Gearman::Driver::Console::Client>

=item * L<Gearman::Driver::Job>

=item * L<Gearman::Driver::Job::Method>

=item * L<Gearman::Driver::Loader>

=item * L<Gearman::Driver::Observer>

=item * L<Gearman::Driver::Worker>

=item * L<Gearman::XS>

=item * L<Gearman>

=item * L<Gearman::Server>

=item * L<Log::Log4perl>

=item * L<Module::Find>

=item * L<Moose>

=item * L<MooseX::Getopt>

=item * L<MooseX::Log::Log4perl>

=item * L<MooseX::MethodAttributes>

=item * L<Net::Telnet::Gearman>

=item * L<POE>

=item * L<http://www.gearman.org/>

=back

=head1 REPOSITORY

L<http://github.com/plu/gearman-driver/>

=cut

1;
