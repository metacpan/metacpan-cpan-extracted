package Memcached::Client::Serializer;
BEGIN {
  $Memcached::Client::Serializer::VERSION = '2.01';
}
#ABSTRACT: Abstract Base Class For Memcached::Client Serializer

use strict;
use warnings;


sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}


sub deserialize {
    die "You must implement deserialize";
}


sub serialize {
    die "You must implement serialize";
}

1;

__END__
=pod

=head1 NAME

Memcached::Client::Serializer - Abstract Base Class For Memcached::Client Serializer

=head1 VERSION

version 2.01

=head1 SYNOPSIS

  package NewSerializer;
  use strict;
  use base qw{Memcached::Client::Serializer};

=head1 METHODS

=head2 new

C<new()> builds a new object.  It takes no parameters.

=head2 deserialize()

C<deserialize()> will do its best to uncompress and/or deserialize the
data that has been returned.

=head2 serialize()

C<serialize()> will serialize the data it is given (if it's a
reference), and if the data is large enough and the savings
significant enough (and the compression code is loadable), it will
compress it as well.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

