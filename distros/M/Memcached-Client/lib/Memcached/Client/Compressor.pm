package Memcached::Client::Compressor;
BEGIN {
  $Memcached::Client::Compressor::VERSION = '2.01';
}
#ABSTRACT: Abstract Base Class For Memcached::Client Compressor

use strict;
use warnings;
use Memcached::Client::Log qw{LOG};


sub new {
    my $class = shift;
    my $self = bless {compress_threshold => 0}, $class;
    return $self;
}


sub compress_threshold {
    my ($self, $new) = @_;
    my $ret = $self->{compress_threshold};
    $self->{compress_threshold} = $new if ($new);
    return $ret;
}


sub decompress {
    die "You must implement decompress";
}


sub compress {
    die "You must implement compress";
}


sub log {
    my ($self, $format, @args) = @_;
    my $prefix = ref $self || $self;
    $prefix =~ s,Memcached::Client::Compressor::,Compressor/,;
    LOG ("$prefix> " . $format, @args);
}

1;

__END__
=pod

=head1 NAME

Memcached::Client::Compressor - Abstract Base Class For Memcached::Client Compressor

=head1 VERSION

version 2.01

=head1 SYNOPSIS

  package NewCompresor;
  use strict;
  use base qw{Memcached::Client::Compressor};

=head1 METHODS

=head2 new

C<new()> builds a new object.  It takes no parameters.

=head2 compress_threshold()

Retrieve or change the compress_threshold value.

=head2 decompress()

C<decompress()> will do its best to uncompress and/or deserialize the
data that has been returned.

=head2 compress()

C<compress()> will (if the compression code is loadable) compress the
data it is given, and if the data is large enough and the savings
significant enough, it will compress it as well.

=head2 C<log>

Log the specified message with an appropriate prefix derived from the
class name.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

