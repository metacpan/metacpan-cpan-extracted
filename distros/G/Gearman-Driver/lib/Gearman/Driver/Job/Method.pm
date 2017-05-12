package Gearman::Driver::Job::Method;

use Moose;

=head1 NAME

Gearman::Driver::Job::Method - Wraps a single job method

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 name

Name of the job method.

=cut

has 'name' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

=head2 body

Code reference which is called by L<Gearman::XS::Worker>.
Actually it's not called directly by it, but in a wrapped coderef.

=cut

has 'body' => (
    is       => 'rw',
    isa      => 'CodeRef',
    required => 1,
);

=head2 worker

Reference to the worker object.

=cut

has 'worker' => (
    is       => 'rw',
    isa      => 'Any',
    required => 1,
);

=head2 encode

This may be set to a method name which is implemented in the worker
class or any subclass. If the method is not available, it will fail.
The returned value of the job method is passed to this method and
the return value of this method is sent back to the Gearman server.

See also: L<Gearman::Driver::Worker/Encode>.

=cut

has 'encode' => (
    default  => '',
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

=head2 decode

This may be set to a method name which is implemented in the worker
class or any subclass. If the method is not available, it will fail.
The workload from L<Gearman::XS::Job> is passed to this method and
the return value is passed as argument C<$workload> to the job
method.

See also: L<Gearman::Driver::Worker/Decode>.

=cut

has 'decode' => (
    default  => '',
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'wrapper' => (
    is  => 'rw',
    isa => 'CodeRef',
);

sub BUILD {
    my ($self) = @_;

    my $decoder = sub { shift };
    my $encoder = sub { shift };

    if ( my $decoder_method = $self->decode ) {
        $decoder = sub { return $self->worker->$decoder_method(@_) };
    }
    if ( my $encoder_method = $self->encode ) {
        $encoder = sub { return $self->worker->$encoder_method(@_) };
    }

    $self->wrapper(
        sub {
            my ($job) = @_;

            my @args = ($job);

            push @args, $decoder->( $job->workload );

            $self->worker->begin(@args);

            my $error;
            my $result;
            eval { $result = $self->body->( $self->worker, @args ); };
            if ($@) {
                $error = $@;
                printf "lasterror %d\n",     time;
                printf "lasterror_msg %s\n", $error;
                $self->worker->on_exception( @args, $error );
            }

            printf "lastrun %d\n", time;

            $self->worker->end(@args, $error);

            die $error if $error;

            return $encoder->($result);
        }
    );
}

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

=item * L<Gearman::Driver::Loader>

=item * L<Gearman::Driver::Observer>

=item * L<Gearman::Driver::Worker>

=back

=cut

1;
