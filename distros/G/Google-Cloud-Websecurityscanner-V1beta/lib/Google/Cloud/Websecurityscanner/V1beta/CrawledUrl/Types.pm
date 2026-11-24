package Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CrawledUrl',
    as InstanceOf['Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::CrawledUrl'];

coerce 'CrawledUrl',
    from HashRef, via { 'Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::CrawledUrl'->new($_) };

declare 'RepeatedCrawledUrl',
    as ArrayRef[CrawledUrl()];

coerce 'RepeatedCrawledUrl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::CrawledUrl'->new($_) } @$_ ] };

declare 'MapStringCrawledUrl',
    as HashRef[CrawledUrl()];

1;

__END__

=head1 NAME

Google::Cloud::Websecurityscanner::V1beta::CrawledUrl::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
