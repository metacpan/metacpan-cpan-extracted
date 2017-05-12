package Plack::Handler::Fliggy;

use strict;
use warnings;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub run {
    my ($self, $app) = @_;

    my $class = 'Fliggy::Server';
    eval "require $class";
    die if $@;

    $class->new(%{$self})->run($app);
}

1;
__END__

=head1 NAME

Plack::Handler::Fliggy - Adapter for Fliggy

=head1 SYNOPSIS

  plackup -s Fliggy --port 9090

=head1 DESCRIPTION

This is an adapter to run L<PSGI> apps on L<Fliggy> via L<plackup>.

=head1 METHODS

=head2 C<new>

    my $handler = Plack::Handler::Fliggy->new;

Create new instance.

=head2 C<run>

    $handler->run;

Run the server.

=head1 SEE ALSO

L<plackup>

=cut
