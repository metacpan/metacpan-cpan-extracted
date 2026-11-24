package Google::Cloud::Ces::V1::SearchSuggestions::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoogleSearchSuggestions',
    as InstanceOf['Google::Cloud::Ces::V1::SearchSuggestions::GoogleSearchSuggestions'];

coerce 'GoogleSearchSuggestions',
    from HashRef, via { 'Google::Cloud::Ces::V1::SearchSuggestions::GoogleSearchSuggestions'->new($_) };

declare 'RepeatedGoogleSearchSuggestions',
    as ArrayRef[GoogleSearchSuggestions()];

coerce 'RepeatedGoogleSearchSuggestions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SearchSuggestions::GoogleSearchSuggestions'->new($_) } @$_ ] };

declare 'MapStringGoogleSearchSuggestions',
    as HashRef[GoogleSearchSuggestions()];

declare 'WebSearchQuery',
    as InstanceOf['Google::Cloud::Ces::V1::SearchSuggestions::WebSearchQuery'];

coerce 'WebSearchQuery',
    from HashRef, via { 'Google::Cloud::Ces::V1::SearchSuggestions::WebSearchQuery'->new($_) };

declare 'RepeatedWebSearchQuery',
    as ArrayRef[WebSearchQuery()];

coerce 'RepeatedWebSearchQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::SearchSuggestions::WebSearchQuery'->new($_) } @$_ ] };

declare 'MapStringWebSearchQuery',
    as HashRef[WebSearchQuery()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::SearchSuggestions::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
