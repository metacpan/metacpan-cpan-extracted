package Docker::Registry::Types;
use warnings;
use strict;

# ABSTRACT: Moose like types defined for Docker::Registry

use Types::Standard qw(Str);
use URI;
use Type::Library 
  -base,
  -declare => qw( DockerRegistryURI );
use Type::Utils -all;
use Types::Standard qw/Str/;

class_type DockerRegistryURI, { class => 'URI' };

coerce DockerRegistryURI, from Str, via { return URI->new($_); };

1;

__END__

=head1 DESCRIPTION

Defines custom types for Docker::Registry modules

=head1 SYNOPSIS

    package Foo;
    use Moose;

    use Docker::Registry::Types qw(DockerRegistryURI);

    has bar => (
        is => 'ro',
        isa => DockerRegistryURI,
    );


=head1 TYPES

=head2 DockerRegistryURI

Allows a scalar URI, eq 'https://foo.bar.nl', or a URI object.

=cut
