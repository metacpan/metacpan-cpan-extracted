package HTTP::Balancer::Command;

use Modern::Perl;

use Moose;

with qw( HTTP::Balancer::Role::Command );

sub run {
    my ($self, ) = @_;
    $self->dispatch("help")->new_with_options->prepare->run;
}

1;
__END__

=head1 NAME

HTTP::Balancer::Command - root node of handlers of HTTP::Balancer

=head1 SYNOPSIS

    use HTTP::Balancer::Command;

    HTTP::Balancer
    ->dispatch(@consequence)
    ->new_with_options()
    ->prepare()
    ->run();

=head1 SEE ALSO

L<Namespace::Dispatch>

=cut
