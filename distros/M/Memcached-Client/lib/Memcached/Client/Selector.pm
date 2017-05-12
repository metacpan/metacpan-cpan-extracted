package Memcached::Client::Selector;
BEGIN {
  $Memcached::Client::Selector::VERSION = '2.01';
}
# ABSTRACT: Abstract Base Class For Memcached::Client Selector

use strict;
use warnings;
use Memcached::Client::Log qw{LOG};


sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}


sub log {
    my ($self, $format, @args) = @_;
    my $prefix = ref $self || $self;
    $prefix =~ s,Memcached::Client::Selector::,Selector/,;
    LOG ("$prefix> " . $format, @args);
}


sub set_servers {
    die "You must implement set_servers";
}


sub get_server {
    die "You must implement get_sock";
}

1;

__END__
=pod

=head1 NAME

Memcached::Client::Selector - Abstract Base Class For Memcached::Client Selector

=head1 VERSION

version 2.01

=head1 SYNOPSIS

  package NewHash;
  use strict;
  use base qw{Memcached::Client::Selector};

=head1 METHODS

=head2 new

C<new()> builds a new object.  It takes no parameters.

=head2 C<log>

Log the specified message with an appropriate prefix derived from the
class name.

=head2 set_servers

C<set_servers()> will initialize the selector from the arrayref of
servers (or server => weight tuples) passed to it.

=head2 get_server

C<get_server()> will use the object's list of servers to extract the
proper server name from the list of connected servers, so the protocol
object can use it to make a request.

This routine can return undef, if called before set_servers has been
called, whether explicitly, or implicitly by handling a list of
servers to the constructor.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

