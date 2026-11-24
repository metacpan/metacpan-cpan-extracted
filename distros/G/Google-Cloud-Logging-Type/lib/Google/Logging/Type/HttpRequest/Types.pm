package Google::Logging::Type::HttpRequest::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HttpRequest',
    as InstanceOf['Google::Logging::Type::HttpRequest::HttpRequest'];

coerce 'HttpRequest',
    from HashRef, via { 'Google::Logging::Type::HttpRequest::HttpRequest'->new($_) };

declare 'RepeatedHttpRequest',
    as ArrayRef[HttpRequest()];

coerce 'RepeatedHttpRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::Type::HttpRequest::HttpRequest'->new($_) } @$_ ] };

declare 'MapStringHttpRequest',
    as HashRef[HttpRequest()];

1;

__END__

=head1 NAME

Google::Logging::Type::HttpRequest::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
