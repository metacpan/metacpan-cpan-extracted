package Linux::Event::Error;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.114';

use overload '""' => 'as_string', fallback => 1;

sub new ($class, %arg) {
    return bless {
        type      => $arg{type} // 'event',
        operation => $arg{operation},
        option    => $arg{option},
        errno     => $arg{errno},
        message   => $arg{message} // 'Linux::Event error',
        pending_bytes => $arg{pending_bytes},
        pending_datagrams => $arg{pending_datagrams},
        datagram_size => $arg{datagram_size},
        limit         => $arg{limit},
        fatal          => $arg{fatal} ? 1 : 0,
        host           => $arg{host},
        port           => $arg{port},
        path           => $arg{path},
        family         => $arg{family},
        attempts       => $arg{attempts},
        resolver_message => $arg{resolver_message},
        timeout        => $arg{timeout},
        deadline       => $arg{deadline},
    }, $class;
}

sub type      ($self) { $self->{type} }
sub operation ($self) { $self->{operation} }
sub option    ($self) { $self->{option} }
sub errno     ($self) { $self->{errno} }
sub message   ($self) { $self->{message} }
sub pending_bytes ($self) { $self->{pending_bytes} }
sub pending_datagrams ($self) { $self->{pending_datagrams} }
sub datagram_size ($self) { $self->{datagram_size} }
sub limit         ($self) { $self->{limit} }
sub fatal         ($self) { $self->{fatal} }
sub host          ($self) { $self->{host} }
sub port          ($self) { $self->{port} }
sub path          ($self) { $self->{path} }
sub family        ($self) { $self->{family} }
sub attempts      ($self) { $self->{attempts} }
sub resolver_message ($self) { $self->{resolver_message} }
sub timeout       ($self) { $self->{timeout} }
sub deadline      ($self) { $self->{deadline} }

sub as_string ($self, @ignored) {
    my $text = $self->{message};
    $text = "$self->{operation}: $text" if defined $self->{operation};
    $text .= " (errno=$self->{errno})" if defined $self->{errno};
    return $text;
}

1;

__END__

=head1 NAME

Linux::Event::Error - structured Linux::Event failure details

=head1 SYNOPSIS

  sub on_error ($stream, $error) {
      warn $error->type . ': ' . $error->message . "\n";
      warn "system errno " . $error->errno . "\n"
          if defined $error->errno;
  }

=head1 DESCRIPTION

Linux::Event I/O and Kernel resource leaves pass this object to C<on_error>
where that resource supports an error callback; constructor-time setup failures
may also throw it. C<type>, C<operation>, C<errno>, and C<message> are the
common fields. Other accessors expose context only when it applies to the
specific operation.

Errors stringify to a concise diagnostic such as
C<connect: Connection refused (errno=111)>. Do not parse the string; use the
accessors for program logic.

=head1 ERROR TYPES

Common C<type> values include C<io>, C<framing>, C<output_limit>, C<resolve>,
C<socket>, C<socket_configuration>, C<connect>, C<timeout>, C<setup>,
C<accept>, C<resource>, C<listener>, C<callback>, C<datagram_size>,
C<process>, C<process_io>, and C<tls>. The list may grow as transports and
resource types are added. Code should handle the types it understands and
retain a general fallback.

=head1 METHODS

=head2 type / operation / option / errno / message

Return the common error fields. Fields that do not apply are undefined.
C<option> names the socket option when C<type> is C<socket_configuration>.

=head2 pending_bytes / pending_datagrams / datagram_size / limit

Return hard output-limit or oversized-packet details. Fields that do not apply
to the particular error are undefined.

=head2 fatal

True when a stream listener failure has made the listener unusable.

=head2 host / port / path / family

Return applicable connection or listener address details.

=head2 attempts / resolver_message

Return outbound connection-attempt and resolver details when available.

=head2 timeout / deadline

Return the configured relative duration and expired absolute monotonic deadline
for established ordered-byte timeout errors. C<timeout> is undefined for an
explicit absolute operation deadline and both values are undefined for
unrelated error types.

=head2 as_string

Return the operation-prefixed diagnostic used by string overloading.

=head1 IMMUTABILITY

Linux::Event treats Error objects as immutable values. Their constructor is
public for applications that want to report compatible failures, but there are
no mutators.

=cut
