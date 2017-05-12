package Log::Message::Structured::Component::Hostname;
use Moose::Role;
use namespace::autoclean;

use Sys::Hostname ();

my $GETOPT = do { local $@; eval { require MooseX::Getopt; 1 } };

has hostname => (
    is => 'ro',
    default => sub { Sys::Hostname::hostname() },
    $GETOPT ? ( traits => [qw/ NoGetopt /] ) : (),
);

1;

__END__

=pod

=head1 NAME

Log::Message::Structured::Component::Hostname

=head1 SYNOPSIS

    package MyLogEvent;
    use Moose;
    use namespace::autoclean;

    with qw/
        Log::Message::Structured
        Log::Message::Structured::Component::Hostname
    /;

    has foo => ( is => 'ro', required => 1 );

    ... elsewhere ...

    use aliased 'My::Log::Event';

    $logger->log(message => Event->new( foo => "bar" ));
    # Logs:
    {"__CLASS__":"MyLogEvent","foo":1,"hostname":"mymachine.domain"}

=head1 DESCRIPTION

Provides a C<'hostname'> attribute to the consuming class ( probably
L<Log::Message::Structured>).

=head1 ATTRIBUTES

=head2 hostname

The host name of the host the event was generated on. Defaults to the hostname
as returned by L<Sys::Hostname>.

=head1 AUTHOR AND COPYRIGHT

Damien Krotkine (dams) C<< <dams@cpan.org> >>.

=head1 LICENSE

Licensed under the same terms as perl itself.

=cut
