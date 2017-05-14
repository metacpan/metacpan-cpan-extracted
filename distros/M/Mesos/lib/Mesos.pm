package Mesos;
use strict;
use warnings;

=pod

=head1 NAME

Mesos - perl bindings for Apache Mesos

=head1 DESCRIPTION

This is a collection of perl bindings for Apache Mesos. This requires having the mesos shared library installed, in order to link against(much like python's mesos library).

=head2 Protobuf Messages

Frameworks, masters, and slaves all communicate using google protocol buffers. The Mesos module handles protobuf messages using the Google::ProtocolBuffers library, which is what's used to generate the message classes in Mesos::Messages from resources/mesos.proto. It is encouraged to look over Google::ProtocolBuffers documentation before using Mesos.

The Mesos module ships with message classes generated from v0.20.0. Messages are still backwards compatible with previous versions, but please make sure to check the mesos.proto file from your Mesos installation, to see what fields are and are not allowed.

=head2 Internal POSIX Threads

The Apache Mesos library is multithreaded, which is problematic when dealing with perl. The solution Mesos currently goes with is to create C++ proxy classes, which registers callbacks that send notifications event handlers. The two event handlers currently implemented are AnyEvent watchers(the default) and a Async::Interrupt object(the *::Interrupt drivers). Mesos then handles these notifications, and executes the corresponding perl code, inside of an AnyEvent loop.

Launching internal POSIX threads also means that Mesos drivers are not fork safe, and only exec and POSIX::_exit can be guaranteed to work safely in the child process after forking. One should definitely not call any driver code in the child process after forking.

=head1 SYNOPSIS

    package MyScheduler {
        use Moo;
        extends 'Mesos::Scheduler';
        use Mesos::Messages; # load protobuf messages

        sub resourceOffers {
                my ($self, $driver, $offers) = @_;
                for my $offer (@$offers) {
                    my $task = Mesos::TaskInfo->new({
                        # task_id is a Mesos::TaskID message
                        task_id   => Mesos::TaskID->new({value => "a unique id"}),
                        slave_id  => $offer->slave_id,
                        name      => "does something cool",
                        # executor is a Mesos::ExecutorInfo message
                        # Google::ProtocolBuffers will let you pass the constructor args
                        #  and will instantiate the message for you
                        executor  => {
                            executor_id => {value => "does cool tasks"},
                            command     => {value => "/path/to/executor"},
                        },
                        resources => [
                            {name => "cpus", type => Mesos::Value::Type::SCALAR, scalar => {value => 1}},
                            {name => "mem",  type => Mesos::Value::Type::SCALAR, scalar => {value => 32}},
                        ],
                    });
                    $driver->launchTasks([$offer->{id}], [$task]);
                }
        }
    };

    use Mesos::SchedulerDriver;
    my $driver = Mesos::SchedulerDriver->new(
        master    => "mesoshost:5050",
        framework => {user => "mesos user", name => "awesome framework"},
        scheduler => MyScheduler->new,
    );
    $driver->run;

=head1 INSTALL

First make sure the apache mesos library is installed. This is easiest either with your native package manager, or with a package from L<mesosphere|http://mesosphere.io/downloads/>.

Make sure Google Protocol Buffers headers are installed, and the version is compatible with your Mesos installation.

Next just install like any other Module::Build distribution with C<perl Build.PL && ./Build install>

Note that Mesos before v0.20 has issues with include headers not being very smart(L<MESOS-1504|https://issues.apache.org/jira/browse/MESOS-1504>). Compiling against these earlier versions requires explicitly including the directory for mesos headers. By default Build.PL will check /usr/local/include/mesos, but you will be prompted to enter another path if that directory does not exist.

=head1 CAVEATS

Be aware that Mesos drivers are not able to talk to remote servers from behind a NAT. Drivers are required to start an http server that the mesos master will send post requests to.

=head1 TODO

=over 4

=item maybe work on pure perl drivers

=back

=head1 SEE ALSO
 
More information about Apache Mesos, projects using Mesos, or the underlying Mesos drivers can be found at the Apache Mesos project's L<home page|http://mesos.apache.org/> or L<mesosphere|http://mesosphere.io>. 

=head1 AUTHOR

Mark Flickinger E<lt>maf@cpan.orgE<gt>

=cut

use XSLoader;
use Exporter 5.57 'import';

use version; our $VERSION = qv( 1.05.1 );
our %EXPORT_TAGS = ( 'all' => [] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

XSLoader::load('Mesos', $VERSION);

1;
