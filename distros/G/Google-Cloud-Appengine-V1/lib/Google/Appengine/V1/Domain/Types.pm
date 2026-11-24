package Google::Appengine::V1::Domain::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AuthorizedDomain',
    as InstanceOf['Google::Appengine::V1::Domain::AuthorizedDomain'];

coerce 'AuthorizedDomain',
    from HashRef, via { 'Google::Appengine::V1::Domain::AuthorizedDomain'->new($_) };

declare 'RepeatedAuthorizedDomain',
    as ArrayRef[AuthorizedDomain()];

coerce 'RepeatedAuthorizedDomain',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::Domain::AuthorizedDomain'->new($_) } @$_ ] };

declare 'MapStringAuthorizedDomain',
    as HashRef[AuthorizedDomain()];

1;

__END__

=head1 NAME

Google::Appengine::V1::Domain::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
