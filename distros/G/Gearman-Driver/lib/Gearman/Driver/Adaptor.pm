package Gearman::Driver::Adaptor;

use Moose;
use Class::MOP;

=head1 NAME

Gearman::Driver::Adaptor - Adaptor to gearman libraries

=head1 DESCRIPTION

L<Gearman::Driver> works with L<Gearman::XS> as well as with the pure
Perl modules L<Gearman> and L<Gearman::Server>. By default it tries
to use L<Gearman::XS>. If that fails L<Gearman> is used. You can
also export an environment variable C<GEARMAN_DRIVER_ADAPTOR> to
force usage of L<Gearman> even if you have L<Gearman::XS>.

Example:

=over 4

=item * C<export GEARMAN_DRIVER_ADAPTOR="Gearman::Driver::Adaptor::XS">

=item * C<export GEARMAN_DRIVER_ADAPTOR="Gearman::Driver::Adaptor::PP">

=back

=cut

has 'backend' => (
    builder => '_build_backend',
    handles => [
        qw(
          add_servers
          add_function
          error
          work
          )
    ],
    is => 'ro',
);

has 'server' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

sub _build_backend {
    my ($self) = @_;

    my @classes = qw(Gearman::Driver::Adaptor::XS Gearman::Driver::Adaptor::PP);

    unshift @classes, $ENV{GEARMAN_DRIVER_ADAPTOR} if defined $ENV{GEARMAN_DRIVER_ADAPTOR};

    foreach my $class (@classes) {
        eval "require $class";
        unless ($@) {
            return $class->new( server => $self->server );
        }
    }

    die "None of the supported adaptors could be loaded: %s\n", join ', ', @classes;
}

sub BUILD {
    my ($self) = @_;
    $self->add_servers( $self->server );
}

=head1 AUTHOR

See L<Gearman::Driver>.

=head1 COPYRIGHT AND LICENSE

See L<Gearman::Driver>.

=head1 SEE ALSO

=over 4

=item * L<Gearman::Driver>

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
