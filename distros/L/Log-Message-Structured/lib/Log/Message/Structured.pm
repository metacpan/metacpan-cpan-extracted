package Log::Message::Structured;
use MooseX::Role::WithOverloading;
use Scalar::Util qw/ blessed /;
use namespace::clean -except => 'meta';

our $VERSION = '0.012';
$VERSION = eval $VERSION;

use overload
    q{""}    => 'as_string',
    fallback => 1;

has class => (
  init_arg => undef,
  is => 'ro',
  isa => 'Str',
  default => sub { blessed $_[0] },
);

my $GETOPT = do { local $@; eval { require MooseX::Getopt; 1 } };

sub BUILD {}

sub as_string { '' }

sub as_hash {
    my ($self) = @_;
    return { map { $_->name, $_->get_value($self) }
             $self->meta->get_all_attributes };
}

1;

__END__

=pod

=head1 NAME

Log::Message::Structured - Simple structured log messages

=head1 SYNOPSIS

    package MyLogEvent;
    use Moose;
    use namespace::autoclean;

    with qw/
        Log::Message::Structured
        Log::Message::Structured::Component::Date
        Log::Message::Structured::Component::Hostname
        Log::Message::Structured::Stringify::AsJSON
    /;

    has foo => ( is => 'ro', required => 1 );

    ... elsewhere ...

    use aliased 'My::Log::Event';

    $logger->log(message => Event->new( foo => "bar" ));
    # Logs:
    {"__CLASS__":"MyLogEvent","foo":1,"date":"2010-03-28T23:15:52Z","hostname":"mymachine.domain"}

=head1 DESCRIPTION

Logging lines to a file is a fairly useful and traditional way of recording what's going on in your application.

However, if you have another use for the same sort of data (for example, sending to another process via a
message queue, or storing in L<KiokuDB>), then you can be needlessly repeating your data marshalling.

Log::Message::Structured is a B<VERY VERY SIMPLE> set of roles to help you make
small structured classes which represent 'C<< something which happened >>',
that you can then either pass around in your application, log in a traditional
manor as a log line, or serialize to JSON or YAML for transmission over the
network.

=head1 COMPONENTS

The consuming class can include components, that will provide additional
attributes. Here is a list of the components included in the basic
distribution. More third party components may be available on CPAN.

=over

=item *

L<Log::Message::Structured::Component::Date>

=item *

L<Log::Message::Structured::Component::Hostname>

=item *

L<Log::Message::Structured::Component::AttributesFilter>

=back

=head1 ATTRIBUTES

Except for C<class>, the basic Log::Message::Structured role provides no
attributes. See available components in
L<Log::Message::Structured::Component::*> and consume them, or create
attributes yourself, to enrich your class

=head2 class

Str,ro

An attribute that returns the name of the class that were used when creating
the instance.

=head1 METHODS

The only non-accessor methods provided are those composed from L<MooseX::Storage> related to serialization
and deserialization.

=head2 as_string

Returns the event as a string. By default, returns an empty string. However as the
class composes stringifier roles, as_string will return the proper string
representation of the event instance.

=head2 as_hash

Returns the event as a hash. By default, returns a HashRef with all attributes,
and their values. However, as the class composes modifier roles, the hash (and
thus the string representation) will be changed accordingly

=head2 BUILD

An empty build method (which will be silently discarded if you have one
in your class) is provided, so that additional components can wrap it
(to farce lazy attributes to be built).

=head1 REQUIRED METHODS

None.

=head1 OVERLOADING

Log::Message::Structured overloads the stringify operator, and return the
result of the C<as_string> method.

=head1 A note about namespace::autoclean

L<namespace::autoclean> does not work correctly with roles that supply overloading. Therefore you should instead use:

    use namespace::clean -except => 'meta';

instead in all classes using L<Log::Message::Structured>.

=head1 SEE ALSO

=over

=item L<Log::Message::Structured::Stringify::Sprintf>

=item L<Log::Message::Structured::Stringify::AsJSON>

=item L<Log::Message::Structured::Stringify::AsYAML>

=back

=head1 AUTHOR AND COPYRIGHT

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>.
Damien Krotkine (dams) C<< <dams@cpan.org> >>.

=head1 LICENSE

Licensed under the same terms as perl itself.

=cut

