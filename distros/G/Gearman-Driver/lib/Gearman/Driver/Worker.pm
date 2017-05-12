package Gearman::Driver::Worker;

use base qw(MooseX::MethodAttributes::Inheritable Gearman::Driver::Worker::Base);
use Moose;

=head1 NAME

Gearman::Driver::Worker - Base class for workers

=head1 SYNOPSIS

    package My::Worker;

    use base qw(Gearman::Driver::Worker);
    use Moose;

    sub begin {
        my ( $self, $job, $workload ) = @_;
        # called before each job
    }

    sub prefix {
        # default: return ref(shift) . '::';
        return join '_', split /::/, __PACKAGE__;
    }

    sub do_something : Job : MinProcesses(2) : MaxProcesses(15) {
        my ( $self, $job, $workload ) = @_;
        # $job => Gearman::XS::Job instance
    }

    sub end {
        my ( $self, $job, $workload ) = @_;
        # called after each job
    }

    sub spread_work : Job {
        my ( $self, $job, $workload ) = @_;

        my $gc = Gearman::XS::Client->new;
        $gc->add_servers( $self->server );

        $gc->do_background( 'some_job_1' => $job->workload );
        $gc->do_background( 'some_job_2' => $job->workload );
        $gc->do_background( 'some_job_3' => $job->workload );
        $gc->do_background( 'some_job_4' => $job->workload );
        $gc->do_background( 'some_job_5' => $job->workload );
    }

    1;

=head1 ATTRIBUTES

=head2 server

L<Gearman::Driver> connects to the L<server|Gearman::Driver/server>
passed to its constructor. This value is also stored in this class.
This can be useful if a job uses L<Gearman::XS::Client> to add
another job. See 'spread_work' method in L</SYNOPSIS> above.

=head1 METHODATTRIBUTES

=head2 Job

This will register the method with gearmand.

=head2 MinProcesses

Minimum number of processes working parallel on this job/method.

=head2 MaxProcesses

Maximum number of processes working parallel on this job/method.

=head2 Encode

This will automatically look for a method C<encode> in this object
which has to be defined in the subclass. It will call the C<encode>
method passing the return value from the job method. The return
value of the C<encode> method will be returned to the Gearman
client. This is useful to serialize Perl datastructures to JSON
before sending them back to the client.

    sub do_some_job : Job : Encode : Decode {
        my ( $self, $job, $workload ) = @_;
        return { message => 'OK', status => 1 };

        # calls 'encode' and returns JSON string: {"status":1,"message":"OK"}
    }

    sub custom_encoder : Job : Encode(enc_yaml) : Decode(dec_yaml) {
        my ( $self, $job, $workload ) = @_;
        return { message => 'OK', status => 1 };

        # calls 'enc_yaml' and returns YAML string:
        # ---
        # message: OK
        # status: 1
    }

    sub encode {
        my ( $self, $result ) = @_;
        return JSON::XS::encode_json($result);
    }

    sub decode {
        my ( $self, $workload ) = @_;
        return JSON::XS::decode_json($workload);
    }

    sub enc_yaml {
        my ( $self, $result ) = @_;
        return YAML::XS::Dump($result);
    }

    sub dec_yaml {
        my ( $self, $workload ) = @_;
        return YAML::XS::Load($workload);
    }


=head2 Decode

This will automatically look for a method C<decode> in this object
which has to be defined in the subclass. It will call the C<decode>
method passing the workload value (C<< $job->workload >>). The return
value of the C<decode> method will be passed as 3rd argument to the
job method. This is useful to deserialize JSON workload to Perl
datastructures for example. If this attribute is not set,
C<< $job->workload >> and C<$workload> is the same.

Example, workload is this string: C<{"status":1,"message":"OK"}>

    sub decode {
        my ( $self, $workload ) = @_;
        return JSON::XS::decode_json($workload);
    }

    sub job1 : Job {
        my ( $self, $job, $workload ) = @_;
        # $workload eq $job->workload eq '{"status":1,"message":"OK"}'
    }

    sub job2 : Job : Decode {
        my ( $self, $job, $workload ) = @_;
        # $workload ne $job->workload
        # $job->workload eq '{"status":1,"message":"OK"}'
        # $workload = { status => 1, message => 'OK' }
    }

=head2 ProcessGroup

Forking each job method in an own process may not always be the way
to go. It's possible to run many job methods in a single process by
defining C<ProcessGroup> attribute. This process group alias will
also show up in L<Gearman::Driver::Console> instead of the single
method names. The workers process name will also be affected.

    sub process_name {
        my ( $self, $orig, $job_name ) = @_;
        return "$orig ($job_name)";
    }

    sub scale_image : Job : ProcessGroup(image_worker) {
        my ( $self, $job, $workload ) = @_;
    }

    sub convert_image : Job : ProcessGroup(image_worker) {
        my ( $self, $job, $workload ) = @_;
    }

    # $ ~/Gearman-Driver$ ps ux|grep image_worker
    # plu   2608   0.0  0.1  2466720   4200 s001  S    12:46PM   0:00.01 script/gearman_driver.pl (XxX::image_worker)

    # $ ~/Gearman-Driver$ telnet localhost 47300
    # Trying ::1...
    # telnet: connect to address ::1: Connection refused
    # Trying fe80::1...
    # telnet: connect to address fe80::1: Connection refused
    # Trying 127.0.0.1...
    # Connected to localhost.
    # Escape character is '^]'.
    # status
    # XxX::image_worker  1  1  1  1970-01-01T00:00:00  1970-01-01T00:00:00

It's possible to combine C<ProcessGroup> and C<MinProcesses> +
C<MaxProcesses>. But there's one small caveat: Because one single
process shares many methods, you can only set the min/max process
amount once per C<ProcessGroup>:

    sub scale_image : Job : ProcessGroup(image_worker) : MinProcesses(5) : MaxProcesses(10) {
        my ( $self, $job, $workload ) = @_;
    }

    sub convert_image : Job : ProcessGroup(image_worker) {
        my ( $self, $job, $workload ) = @_;
    }

If you do not obey this restriction, L<Gearman::Driver> will barf:

    sub scale_image : Job : ProcessGroup(image_worker) : MinProcesses(5) : MaxProcesses(10) {
        my ( $self, $job, $workload ) = @_;
    }

    sub convert_image : Job : ProcessGroup(image_worker) : MinProcesses(6) : MaxProcesses(12) {
        my ( $self, $job, $workload ) = @_;
    }

C<MinProcesses redefined in ProcessGroup(image_worker) at XxX::convert_image at lib/Gearman/Driver.pm line 850.>

=head1 METHODS

=head2 prefix

Having the same method name in two different classes would result
in a clash when registering it with gearmand. To avoid this,
all jobs are registered with the full package and method name
(e.g. C<My::Worker::some_job>). The default prefix is
C<ref(shift . '::')>, but this can be changed by overriding the
C<prefix> method in the subclass, see L</SYNOPSIS> above.

=head2 begin

This method is called before a job method is called. In this base
class this methods just does nothing, but can be overridden in a
subclass.

The parameters are the same as in the job method:

=over 4

=item * C<$self>

=item * C<$job>

=back

=head2 end

This method is called after a job method has been called. In this
base class this methods just does nothing, but can be overridden
in a subclass.

The parameters are the same as in the job method:

=over 4

=item * C<$self>

=item * C<$job>

=back

=head2 process_name

If this method is overridden in the subclass it will change the
process name after a job has been forked.

The following parameters are passed to this method:

=over 4

=item * C<$self>

=item * C<$orig> - the original process name ( C<$0> )

=item * C<$job_name> - the name of the job

=back

Example:

    sub process_name {
        my ( $self, $orig, $job_name ) = @_;
        return "$orig ($job_name)";
    }

This may look like:

    plu       2034  0.0  1.7  22392 17948 pts/2    S    21:17   0:00 gearman_driver.pl (GDExamples::Convert::convert_to_jpeg)
    plu       2035  0.0  1.7  22392 17944 pts/2    S    21:17   0:00 gearman_driver.pl (GDExamples::Convert::convert_to_gif)

=head2 override_attributes

If this method is overridden in the subclass it will change B<all>
attributes of your job methods. It must return a reference to a hash
containing valid L<attribute keys|/METHODATTRIBUTES>. E.g.:

    sub override_attributes {
        return {
            MinProcesses => 1,
            MaxProcesses => 1,
        }
    }

    sub job1 : Job : MinProcesses(10) : MaxProcesses(20) {
        my ( $self, $job, $workload ) = @_;
        # This will get MinProcesses(1) MaxProcesses(1) from override_attributes
    }

=head2 default_attributes

If this method is overridden in the subclass it can supply default
attributes which are added to all job methods. This is useful if
you want to Encode/Decode all your jobs:

    sub default_attributes {
        return {
            Encode => 'encode',
            Decode => 'decode',
        }
    }

    sub decode {
        my ( $self, $workload ) = @_;
        return JSON::XS::decode_json($workload);
    }

    sub encode {
        my ( $self, $result ) = @_;
        return JSON::XS::encode_json($result);
    }

    sub job1 : Job {
        my ( $self, $job, $workload ) = @_;
    }

=cut

no Moose;

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

See L<Gearman::Driver>.

=head1 COPYRIGHT AND LICENSE

See L<Gearman::Driver>.

=head1 SEE ALSO

=over 4

=item * L<Gearman::Driver>

=item * L<Gearman::Driver::Adaptor>

=item * L<Gearman::Driver::Console>

=item * L<Gearman::Driver::Console::Basic>

=item * L<Gearman::Driver::Console::Client>

=item * L<Gearman::Driver::Job>

=item * L<Gearman::Driver::Job::Method>

=item * L<Gearman::Driver::Loader>

=item * L<Gearman::Driver::Observer>

=item * L<Gearman::Driver::Worker::AttributeParser>

=item * L<Gearman::Driver::Worker::Base>

=back

=cut

1;
