package Log::Message::Structured::Component::Date;
use Moose::Role;
use namespace::autoclean;

use DateTime;
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;

my $GETOPT = do { local $@; eval { require MooseX::Getopt; 1 } };

has epochtime => (
    isa => 'Int',
    is => 'ro',
    default => sub { time() },
    $GETOPT ? ( traits => [qw/ NoGetopt /] ) : (),
);

has date => (
    is => 'ro',
    isa => ISO8601DateTimeStr,
    lazy => 1,
    default => sub { DateTime->from_epoch(epoch => shift()->epochtime) },
    coerce => 1,
    $GETOPT ? ( traits => [qw/ NoGetopt /] ) : (),
);

after BUILD => sub { shift()->date };

1;

__END__

=pod

=head1 NAME

Log::Message::Structured::Component::Date

=head1 SYNOPSIS

    package MyLogEvent;
    use Moose;
    use namespace::autoclean;

    with qw/
        Log::Message::Structured
        Log::Message::Structured::Component::Date
    /;

    has foo => ( is => 'ro', required => 1 );

    ... elsewhere ...

    use aliased 'My::Log::Event';

    $logger->log(message => Event->new( foo => "bar" ));
    # Logs:
    {"__CLASS__":"MyLogEvent","foo":1,"date":"2010-03-28T23:15:52Z"}

=head1 DESCRIPTION

Provides C<'epochtime'> and C<'date'> attributes to the consuming class ( that should also
consume L<Log::Message::Structured>).

=head1 METHODS

=head2 BUILD

The BUILD method is wrapped to make sure the date is inflated at
construction time.

=head1 ATTRIBUTES

=head2 date

The date and time on which the event occured, as an ISO8601 date time string
(from L<MooseX::Types::ISO8601>). Defaults to the time the object is
constructed.

=head2 epochtime

The date and time on which the event occurred, as an no of seconds since Jan
1st 1970 (i.e. the output of time()). Defaults to the time the object is
constructed.

=head1 AUTHOR AND COPYRIGHT

Damien Krotkine (dams) C<< <dams@cpan.org> >>.

=head1 LICENSE

Licensed under the same terms as perl itself.

=cut
