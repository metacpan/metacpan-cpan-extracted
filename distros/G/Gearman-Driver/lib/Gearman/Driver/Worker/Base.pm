package Gearman::Driver::Worker::Base;

use Moose;

=head1 NAME

Gearman::Driver::Worker::Base - Base class for workers without method attributes

=head1 DESCRIPTION

If you don't like method attributes you can use this base class
instead of L<Gearman::Driver::Worker> and use
L<Gearman::Driver/add_job>.

=cut

has 'server' => (
    is  => 'ro',
    isa => 'Str',
);

sub prefix {
    return ref(shift) . '::';
}

sub begin { }

sub end { }

sub on_exception { }

sub process_name {
    return 0;
}

sub override_attributes {
    return {};
}

sub default_attributes {
    return {};
}

sub decode {
    my ( $self, $result ) = @_;
    return $result;
}

sub encode {
    my ( $self, $result ) = @_;
    return $result;
}

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

=item * L<Gearman::Driver::Worker>

=item * L<Gearman::Driver::Worker::AttributeParser>

=back

=cut

1;
